import 'dart:math';

import 'package:clickpix_ramon/core/i18n/ui_text.dart';
import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/repositories/local_client_repository.dart';
import 'package:clickpix_ramon/data/repositories/local_order_repository.dart';
import 'package:clickpix_ramon/data/repositories/local_photo_asset_repository.dart';
import 'package:clickpix_ramon/data/services/upload_queue_service.dart';
import 'package:clickpix_ramon/data/services/upload_worker.dart';
import 'package:clickpix_ramon/domain/entities/order.dart' as domain;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';

enum DeliveryPaymentChoice {
  pix(domain.PaymentMethod.pix),
  paypal(domain.PaymentMethod.paypal),
  cardCredit(domain.PaymentMethod.card),
  cardDebit(domain.PaymentMethod.card);

  const DeliveryPaymentChoice(this.paymentMethod);

  final domain.PaymentMethod paymentMethod;
}

extension DeliveryPaymentChoiceLocalizedLabel on DeliveryPaymentChoice {
  String label(BuildContext context) {
    switch (this) {
      case DeliveryPaymentChoice.pix:
        return 'Pix';
      case DeliveryPaymentChoice.paypal:
        return 'PayPal';
      case DeliveryPaymentChoice.cardCredit:
        return tr(
          context,
          pt: 'Cartão de crédito',
          es: 'Tarjeta de crédito',
          en: 'Credit card',
        );
      case DeliveryPaymentChoice.cardDebit:
        return tr(
          context,
          pt: 'Cartão de débito',
          es: 'Tarjeta de débito',
          en: 'Debit card',
        );
    }
  }
}

class RecentPhotosPage extends StatefulWidget {
  const RecentPhotosPage({
    required this.database,
    required this.settingsStore,
    required this.requirePayment,
    this.onDeliveryRegistered,
    super.key,
  });

  final AppDatabase database;
  final AppSettingsStore settingsStore;
  final bool requirePayment;
  final VoidCallback? onDeliveryRegistered;

  @override
  State<RecentPhotosPage> createState() => _RecentPhotosPageState();
}

class _RecentPhotosPageState extends State<RecentPhotosPage> {
  static const List<int> _timeFiltersInMinutes = [10, 30, 60];

  late final LocalOrderRepository _orderRepository;
  late final UploadQueueService _uploadQueueService;
  late final LocalPhotoAssetRepository _photoRepository;
  late final LocalClientRepository _clientRepository;
  late final TextEditingController _unitPriceController;

  int _selectedFilter = _timeFiltersInMinutes.first;
  final Set<String> _selectedPhotoIds = <String>{};
  final Map<String, AssetEntity> _selectedAssetsById = <String, AssetEntity>{};
  List<_GalleryPhoto> _photos = const [];
  bool _isLoading = true;
  bool _hasPermission = true;
  bool _isSubmittingOrder = false;
  DeliveryPaymentChoice _selectedPaymentChoice = DeliveryPaymentChoice.pix;

  @override
  void initState() {
    super.initState();
    _unitPriceController = TextEditingController(text: '15.00');
    _uploadQueueService = UploadQueueService(
      database: widget.database,
      settingsStore: AppSettingsStore(widget.database),
      networkConstraint: ConnectivityNetworkConstraint(Connectivity()),
      syncGateway: const NoopUploadSyncGateway(),
    );
    _orderRepository = LocalOrderRepository(
      widget.database,
      uploadQueueService: _uploadQueueService,
    );
    _photoRepository = LocalPhotoAssetRepository(widget.database);
    _clientRepository = LocalClientRepository(widget.database);
    _loadGallery();
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadGallery() async {
    setState(() => _isLoading = true);
    PermissionState permissionState;
    try {
      permissionState = await PhotoManager.requestPermissionExtend().timeout(
        const Duration(seconds: 2),
        onTimeout: () => PermissionState.denied,
      );
    } on MissingPluginException {
      permissionState = PermissionState.denied;
    } on Object {
      permissionState = PermissionState.denied;
    }
    if (!permissionState.isAuth) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
          _photos = const [];
        });
      }
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false)
        ],
      ),
    );

    if (paths.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasPermission = true;
          _photos = const [];
        });
      }
      return;
    }

    final assets = await paths.first.getAssetListPaged(page: 0, size: 300);
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _hasPermission = true;
      _photos = assets
          .map(
            (asset) => _GalleryPhoto(
              id: asset.id,
              capturedAt: asset.createDateTime,
              asset: asset,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final threshold =
        DateTime.now().subtract(Duration(minutes: _selectedFilter));
    final List<_GalleryPhoto> filteredPhotos = _photos
        .where((photo) => photo.capturedAt.isAfter(threshold))
        .toList(growable: false);
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final crossAxisCount = isLandscape ? 4 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.requirePayment
              ? tr(
                  context,
                  pt: 'Fotos para atendimento rÃ¡pido',
                  es: 'Fotos para atenciÃ³n rÃ¡pida',
                  en: 'Photos for quick service',
                )
              : tr(
                  context,
                  pt: 'Fotos para envio sem pagamento',
                  es: 'Fotos para envÃ­o sin pago',
                  en: 'Photos for no-payment dispatch',
                ),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          widget.requirePayment
              ? tr(
                  context,
                  pt: 'Selecione fotos, crie pedido com pagamento e envie ao cliente.',
                  es: 'Selecciona fotos, crea pedido con pago y envÃ­a al cliente.',
                  en: 'Select photos, create a paid order and send to the client.',
                )
              : tr(
                  context,
                  pt: 'Selecione fotos e envie imediatamente sem etapa de pagamento.',
                  es: 'Selecciona fotos y envÃ­a sin etapa de pago.',
                  en: 'Select photos and dispatch immediately without payment.',
                ),
        ),
        const SizedBox(height: 12),
        if (widget.requirePayment)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      context,
                      pt: 'ParÃ¢metros de pagamento',
                      es: 'ParÃ¡metros de pago',
                      en: 'Payment parameters',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<DeliveryPaymentChoice>(
                    value: _selectedPaymentChoice,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: tr(
                        context,
                        pt: 'MÃ©todo',
                        es: 'MÃ©todo',
                        en: 'Method',
                      ),
                    ),
                    items: DeliveryPaymentChoice.values
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method.label(context)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedPaymentChoice = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _unitPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Valor por foto (R\$)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                tr(
                  context,
                  pt: 'Ãšltimas fotos capturadas',
                  es: 'Ãšltimas fotos capturadas',
                  en: 'Latest captured photos',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: _loadGallery,
              tooltip: tr(
                context,
                pt: 'Atualizar galeria',
                es: 'Actualizar galerÃ­a',
                en: 'Refresh gallery',
              ),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _timeFiltersInMinutes
              .map(
                (minutes) => FilterChip(
                  label: Text('$minutes min'),
                  selected: _selectedFilter == minutes,
                  selectedColor: colorScheme.primaryContainer,
                  side: BorderSide(color: colorScheme.outline),
                  showCheckmark: true,
                  onSelected: (_) {
                    setState(() => _selectedFilter = minutes);
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (!_hasPermission)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                tr(
                  context,
                  pt: 'PermissÃ£o de galeria nÃ£o concedida.',
                  es: 'Permiso de galerÃ­a no concedido.',
                  en: 'Gallery permission not granted.',
                ),
              ),
            ),
          )
        else if (filteredPhotos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                tr(
                  context,
                  pt: 'Nenhuma foto no perÃ­odo selecionado.',
                  es: 'No hay fotos en el perÃ­odo seleccionado.',
                  en: 'No photos in the selected period.',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filteredPhotos.length,
            itemBuilder: (context, index) {
              final photo = filteredPhotos[index];
              final isSelected = _selectedPhotoIds.contains(photo.id);

              return _PhotoTile(
                photo: photo,
                isSelected: isSelected,
                onToggle: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPhotoIds.remove(photo.id);
                      _selectedAssetsById.remove(photo.id);
                    } else {
                      _selectedPhotoIds.add(photo.id);
                      _selectedAssetsById[photo.id] = photo.asset;
                    }
                  });
                },
              );
            },
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _selectedPhotoIds.isEmpty || _isSubmittingOrder
                ? null
                : _createOrder,
            icon: const Icon(Icons.send, size: 24),
            label: Text(
              widget.requirePayment
                  ? tr(
                      context,
                      pt: 'Criar pedido e preparar envio (${_selectedPhotoIds.length})',
                      es: 'Crear pedido y preparar envÃ­o (${_selectedPhotoIds.length})',
                      en: 'Create order and prepare dispatch (${_selectedPhotoIds.length})',
                    )
                  : tr(
                      context,
                      pt: 'Enviar sem pagamento (${_selectedPhotoIds.length})',
                      es: 'Enviar sin pago (${_selectedPhotoIds.length})',
                      en: 'Send without payment (${_selectedPhotoIds.length})',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createOrder() async {
    final history = await widget.settingsStore.loadDeliveryHistory();
    final selectedClient = await _showClientSelector(history);
    if (selectedClient == null) {
      return;
    }

    final List<AssetEntity> selectedAssets =
        _selectedAssetsById.values.toList(growable: false);
    if (selectedAssets.isEmpty) {
      return;
    }

    setState(() => _isSubmittingOrder = true);
    await _photoRepository.persistAssets(selectedAssets);

    final List<String> itemIds = selectedAssets
        .map((asset) => 'asset_${asset.id}')
        .toList(growable: false);
    final orderId = 'order_${DateTime.now().microsecondsSinceEpoch}';
    final amountPerPhotoCents = _parseCurrencyCents(_unitPriceController.text);
    final totalAmountCents =
        widget.requirePayment ? itemIds.length * amountPerPhotoCents : 0;
    final order = domain.Order(
      id: orderId,
      clientId: selectedClient.id,
      itemIds: itemIds,
      totalAmountCents: totalAmountCents,
      externalReference: orderId,
      status: widget.requirePayment
          ? domain.OrderStatus.created
          : domain.OrderStatus.delivered,
      paymentMethod: widget.requirePayment
          ? _selectedPaymentChoice.paymentMethod
          : domain.PaymentMethod.pix,
    );
    await _orderRepository.createOrder(order);
    await _uploadQueueService.processQueue();

    if (!mounted) {
      return;
    }

    final businessProfile = await widget.settingsStore.loadBusinessProfile();
    await _showDeliveryActions(
      client: selectedClient,
      order: order,
      businessProfile: businessProfile,
    );

    setState(() {
      _isSubmittingOrder = false;
      _selectedPhotoIds.clear();
      _selectedAssetsById.clear();
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.requirePayment
              ? tr(
                  context,
                  pt: 'Pedido criado com sucesso. Link e cÃ³digo prontos para envio.',
                  es: 'Pedido creado con Ã©xito. Enlace y cÃ³digo listos para enviar.',
                  en: 'Order created successfully. Link and code are ready to send.',
                )
              : tr(
                  context,
                  pt: 'Envio sem pagamento preparado com sucesso.',
                  es: 'EnvÃ­o sin pago preparado con Ã©xito.',
                  en: 'No-payment dispatch prepared successfully.',
                ),
        ),
      ),
    );
  }

  Future<ClientSummary?> _showClientSelector(
      List<DeliveryHistoryEntry> history) {
    return showModalBottomSheet<ClientSummary>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ClientSelectorSheet(
        clientRepository: _clientRepository,
        history: history,
      ),
    );
  }

  Future<void> _showDeliveryActions({
    required ClientSummary client,
    required domain.Order order,
    required BusinessProfileSettings businessProfile,
  }) async {
    final link = 'https://clickpix.app/gallery/${order.id}';
    final code = (100000 + Random().nextInt(900000)).toString();
    final currency = _toCurrency(order.totalAmountCents);
    final paymentText = widget.requirePayment
        ? '\n${tr(context, pt: 'Pagamento', es: 'Pago', en: 'Payment')}: ${_selectedPaymentChoice.label(context)} ($currency)\nPix: ${businessProfile.photographerPixKey.isEmpty ? tr(context, pt: 'NÃ£o informado', es: 'No informado', en: 'Not provided') : businessProfile.photographerPixKey}'
        : '\n${tr(context, pt: 'Envio livre (sem pagamento).', es: 'EnvÃ­o libre (sin pago).', en: 'Free dispatch (no payment).')}';
    final message =
        '${tr(context, pt: 'OlÃ¡', es: 'Hola', en: 'Hello')} ${client.name}! ${tr(context, pt: 'Suas fotos estÃ£o prontas.', es: 'Tus fotos estÃ¡n listas.', en: 'Your photos are ready.')}\nLink: $link\n${tr(context, pt: 'CÃ³digo', es: 'CÃ³digo', en: 'Code')}: $code$paymentText\n${tr(context, pt: 'FotÃ³grafo', es: 'FotÃ³grafo', en: 'Photographer')}: ${businessProfile.photographerName}';

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    tr(
                      context,
                      pt: 'AÃ§Ãµes de envio',
                      es: 'Acciones de envÃ­o',
                      en: 'Dispatch actions',
                    ),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                    '${tr(context, pt: 'Cliente', es: 'Cliente', en: 'Client')}: ${client.name}'),
                Text('Link: $link'),
                Text(
                    '${tr(context, pt: 'CÃ³digo', es: 'CÃ³digo', en: 'Code')}: $code'),
                if (widget.requirePayment)
                  Text(
                      '${tr(context, pt: 'Pagamento', es: 'Pago', en: 'Payment')}: ${_selectedPaymentChoice.label(context)}'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: client.whatsapp.isEmpty
                        ? null
                        : () async {
                            await _sendViaWhatsApp(client.whatsapp, message);
                            await _saveHistory(client, order, 'whatsapp');
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.chat),
                    label: Text(
                      tr(
                        context,
                        pt: 'Enviar por WhatsApp',
                        es: 'Enviar por WhatsApp',
                        en: 'Send via WhatsApp',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: client.email == null || client.email!.isEmpty
                        ? null
                        : () async {
                            await _sendViaEmail(client.email!, message);
                            await _saveHistory(client, order, 'email');
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.email),
                    label: Text(
                      tr(
                        context,
                        pt: 'Enviar por e-mail',
                        es: 'Enviar por correo',
                        en: 'Send via email',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: message));
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(
                      tr(
                        context,
                        pt: 'Copiar mensagem',
                        es: 'Copiar mensaje',
                        en: 'Copy message',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveHistory(
    ClientSummary client,
    domain.Order order,
    String channel,
  ) async {
    await widget.settingsStore.appendDeliveryHistory(
      DeliveryHistoryEntry(
        id: 'log_${DateTime.now().microsecondsSinceEpoch}',
        orderId: order.id,
        clientName: client.name,
        clientWhatsapp: client.whatsapp,
        clientEmail: client.email ?? '',
        channel: channel,
        paymentRequired: widget.requirePayment,
        paymentMethodLabel: widget.requirePayment
            ? _selectedPaymentChoice.label(context)
            : tr(
                context,
                pt: 'Sem pagamento',
                es: 'Sin pago',
                en: 'No payment',
              ),
        photoCount: order.itemIds.length,
        totalAmountCents: order.totalAmountCents,
        createdAt: DateTime.now(),
      ),
    );
    widget.onDeliveryRegistered?.call();
  }

  Future<void> _sendViaWhatsApp(String phone, String message) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    final encodedMessage = Uri.encodeComponent(message);
    final uri =
        Uri.parse('https://wa.me/$normalizedPhone?text=$encodedMessage');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _sendViaEmail(String email, String message) async {
    final subject = Uri.encodeComponent('Entrega de fotos - ClickPix');
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  int _parseCurrencyCents(String rawText) {
    final sanitized = rawText.replaceAll(',', '.').trim();
    final value = double.tryParse(sanitized);
    if (value == null || value <= 0) {
      return 1500;
    }
    return (value * 100).round();
  }

  String _toCurrency(int cents) {
    final value = cents / 100.0;
    return 'R\$ ${value.toStringAsFixed(2)}';
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.isSelected,
    required this.onToggle,
  });

  final _GalleryPhoto photo;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _AssetThumbnail(
                asset: photo.asset,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? colorScheme.primary : colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetThumbnail extends StatelessWidget {
  const _AssetThumbnail({
    required this.asset,
    required this.borderRadius,
  });

  final AssetEntity asset;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(256, 256)),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            child:
                const Center(child: Icon(Icons.image_not_supported_outlined)),
          );
        }

        return Image.memory(
          data,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }
}

class _ClientSelectorSheet extends StatefulWidget {
  const _ClientSelectorSheet({
    required this.clientRepository,
    required this.history,
  });

  final LocalClientRepository clientRepository;
  final List<DeliveryHistoryEntry> history;

  @override
  State<_ClientSelectorSheet> createState() => _ClientSelectorSheetState();
}

class _ClientSelectorSheetState extends State<_ClientSelectorSheet> {
  final _nameController = TextEditingController();
  final _whatsController = TextEditingController();
  final _emailController = TextEditingController();

  List<ClientSummary> _clients = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final List<ClientSummary> rows =
        await widget.clientRepository.listClients();
    if (!mounted) {
      return;
    }
    setState(() {
      _clients = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reusableHistory = widget.history.take(3).toList(growable: false);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  tr(
                    context,
                    pt: 'Selecionar cliente',
                    es: 'Seleccionar cliente',
                    en: 'Select client',
                  ),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (reusableHistory.isNotEmpty) ...[
                Text(
                    tr(
                      context,
                      pt: 'Reutilizar envio recente',
                      es: 'Reutilizar envÃ­o reciente',
                      en: 'Reuse recent dispatch',
                    ),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                ...reusableHistory.map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.clientName),
                    subtitle: Text(entry.clientWhatsapp.isNotEmpty
                        ? entry.clientWhatsapp
                        : entry.clientEmail),
                    trailing: const Icon(Icons.replay),
                    onTap: () {
                      _nameController.text = entry.clientName;
                      _whatsController.text = entry.clientWhatsapp;
                      _emailController.text = entry.clientEmail;
                      setState(() {});
                    },
                  ),
                ),
                const Divider(height: 24),
              ],
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_clients.isNotEmpty)
                ..._clients.map(
                  (client) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(client.name),
                    subtitle: Text(client.whatsapp),
                    onTap: () => Navigator.of(context).pop(client),
                  ),
                ),
              const Divider(height: 24),
              Text(
                  tr(
                    context,
                    pt: 'Novo cliente',
                    es: 'Nuevo cliente',
                    en: 'New client',
                  ),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tr(
                    context,
                    pt: 'Nome',
                    es: 'Nombre',
                    en: 'Name',
                  ),
                ),
              ),
              TextField(
                controller: _whatsController,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: tr(
                    context,
                    pt: 'E-mail',
                    es: 'Correo',
                    en: 'Email',
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _createAndSelectClient,
                  child: Text(
                    tr(
                      context,
                      pt: 'Criar cliente e continuar',
                      es: 'Crear cliente y continuar',
                      en: 'Create client and continue',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAndSelectClient() async {
    final name = _nameController.text.trim();
    final whatsapp = _whatsController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || whatsapp.isEmpty) {
      return;
    }

    final id = 'client_${DateTime.now().microsecondsSinceEpoch}';
    await widget.clientRepository.createClient(
      id: id,
      name: name,
      whatsapp: whatsapp,
      email: email.isEmpty ? null : email,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      ClientSummary(
        id: id,
        name: name,
        whatsapp: whatsapp,
        email: email.isEmpty ? null : email,
      ),
    );
  }
}

class _GalleryPhoto {
  const _GalleryPhoto({
    required this.id,
    required this.capturedAt,
    required this.asset,
  });

  final String id;
  final DateTime capturedAt;
  final AssetEntity asset;
}
