import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:clickpix_ramon/core/i18n/ui_text.dart';
import 'package:clickpix_ramon/core/payments/payment_integration_client.dart';
import 'package:clickpix_ramon/core/payments/pix_payload.dart';
import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/repositories/local_client_repository.dart';
import 'package:clickpix_ramon/data/repositories/local_order_repository.dart';
import 'package:clickpix_ramon/data/repositories/local_photo_asset_repository.dart';
import 'package:clickpix_ramon/data/services/upload_queue_service.dart';
import 'package:clickpix_ramon/data/services/upload_worker.dart';
import 'package:clickpix_ramon/domain/entities/order.dart' as domain;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show OrderingMode, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum DeliveryPaymentChoice {
  pix(domain.PaymentMethod.pix),
  paypal(domain.PaymentMethod.paypal);

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
  static const int _allPhotosFilter = -1;
  static const List<int> _timeFiltersInMinutes = [_allPhotosFilter, 10, 30, 60];
  static const int _devicePageSize = 180;
  static const int _allPhotosChunkSize = 90;

  late final LocalOrderRepository _orderRepository;
  late final UploadQueueService _uploadQueueService;
  late final LocalPhotoAssetRepository _photoRepository;
  late final LocalClientRepository _clientRepository;
  late final TextEditingController _unitPriceController;

  int _selectedFilter = 10;
  final Set<String> _selectedPhotoIds = <String>{};
  final Map<String, AssetEntity> _selectedAssetsById = <String, AssetEntity>{};
  final Set<String> _selectedImportedPhotoIds = <String>{};
  List<_GalleryPhoto> _devicePhotos = const [];
  List<_GalleryPhoto> _importedPhotos = const [];
  List<_GalleryPhoto> _photos = const [];
  AssetPathEntity? _devicePath;
  int _nextDevicePage = 0;
  int _visibleAllPhotosCount = _allPhotosChunkSize;
  bool _hasMoreDevicePhotos = false;
  bool _isLoadingMorePhotos = false;
  bool _isLoading = true;
  bool _hasPermission = true;
  bool _isSubmittingOrder = false;
  bool _useComboPricing = false;
  List<PictureComboPricing> _pictureCombos = const [];
  String _selectedComboId = '';
  DeliveryPaymentChoice _selectedPaymentChoice = DeliveryPaymentChoice.pix;

  @override
  void initState() {
    super.initState();
    _unitPriceController = TextEditingController(text: '15.00');
    _unitPriceController.addListener(_onUnitPriceChanged);
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
    _loadPictureCombos();
    _loadGallery();
  }

  @override
  void dispose() {
    _unitPriceController.removeListener(_onUnitPriceChanged);
    _unitPriceController.dispose();
    super.dispose();
  }

  void _onUnitPriceChanged() {
    if (!_useComboPricing && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPictureCombos() async {
    final combos = await widget.settingsStore.loadPictureCombos();
    final preferredComboId =
        await widget.settingsStore.loadLastSelectedPictureComboId();
    final validIds = combos.map((combo) => combo.id).toSet();
    var nextSelectedId = _selectedComboId;
    if (!validIds.contains(nextSelectedId)) {
      if (validIds.contains(preferredComboId)) {
        nextSelectedId = preferredComboId;
      } else if (combos.isNotEmpty) {
        nextSelectedId = combos.first.id;
      } else {
        nextSelectedId = '';
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _pictureCombos = combos;
      _selectedComboId = nextSelectedId;
    });
  }

  Future<void> _loadGallery() async {
    setState(() => _isLoading = true);
    _importedPhotos = await _loadImportedPhotos();
    _devicePhotos = const [];
    _nextDevicePage = 0;
    _hasMoreDevicePhotos = false;
    _devicePath = null;
    _visibleAllPhotosCount = _allPhotosChunkSize;
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
          _mergePhotos();
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
          _mergePhotos();
        });
      }
      return;
    }

    _devicePath = paths.first;
    _hasMoreDevicePhotos = true;
    await _loadNextDevicePhotosPage();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _hasPermission = true;
      _mergePhotos();
    });
  }

  Future<void> _loadNextDevicePhotosPage() async {
    if (!_hasMoreDevicePhotos || _devicePath == null) {
      return;
    }

    final assets = await _devicePath!.getAssetListPaged(
      page: _nextDevicePage,
      size: _devicePageSize,
    );
    if (assets.isEmpty) {
      _hasMoreDevicePhotos = false;
      return;
    }

    final pagePhotos = assets
        .map(
          (asset) => _GalleryPhoto(
            id: asset.id,
            capturedAt: asset.createDateTime,
            asset: asset,
          ),
        )
        .toList(growable: false);

    _devicePhotos = [..._devicePhotos, ...pagePhotos];
    _nextDevicePage += 1;
    if (assets.length < _devicePageSize) {
      _hasMoreDevicePhotos = false;
    }
  }

  void _mergePhotos() {
    final merged = <String, _GalleryPhoto>{
      for (final photo in _devicePhotos) photo.id: photo,
    };
    for (final imported in _importedPhotos) {
      merged.putIfAbsent(imported.id, () => imported);
    }
    _photos = merged.values.toList(growable: false)
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  Future<void> _loadMoreAllPhotos() async {
    if (_isLoadingMorePhotos) {
      return;
    }
    setState(() => _isLoadingMorePhotos = true);

    if (_visibleAllPhotosCount < _photos.length) {
      setState(() {
        _visibleAllPhotosCount += _allPhotosChunkSize;
        _isLoadingMorePhotos = false;
      });
      return;
    }

    if (_hasMoreDevicePhotos) {
      await _loadNextDevicePhotosPage();
      if (!mounted) {
        return;
      }
      setState(() {
        _mergePhotos();
        _visibleAllPhotosCount += _allPhotosChunkSize;
        _isLoadingMorePhotos = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _isLoadingMorePhotos = false);
    }
  }

  Future<List<_GalleryPhoto>> _loadImportedPhotos() async {
    final rows = await (widget.database.select(widget.database.photoAssets)
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.capturedAt, mode: OrderingMode.desc)
          ])
          ..limit(300))
        .get();

    final photos = <_GalleryPhoto>[];
    for (final row in rows) {
      if (row.localPath.startsWith('asset://')) {
        continue;
      }
      final file = File(row.localPath);
      if (!await file.exists()) {
        continue;
      }

      photos.add(
        _GalleryPhoto(
          id: row.id,
          capturedAt: row.capturedAt,
          localPath: row.localPath,
        ),
      );
    }
    return photos;
  }

  _PricingCalculation _calculatePricing(int photoCount) {
    final basePriceCents = _parseCurrencyCents(_unitPriceController.text);
    if (!widget.requirePayment) {
      return _PricingCalculation(
        unitPriceCents: 0,
        totalAmountCents: 0,
      );
    }

    if (_useComboPricing) {
      final activeCombo = _selectedCombo();
      final comboEligible =
          activeCombo != null && photoCount >= activeCombo.minimumPhotos;
      final comboUnitPrice = activeCombo == null
          ? basePriceCents
          : photoCount >= activeCombo.minimumPhotos
              ? activeCombo.unitPriceCents
              : basePriceCents;
      return _PricingCalculation(
        unitPriceCents: comboUnitPrice,
        totalAmountCents: comboUnitPrice * photoCount,
        combo: activeCombo,
        comboEligible: comboEligible,
      );
    }

    return _PricingCalculation(
      unitPriceCents: basePriceCents,
      totalAmountCents: basePriceCents * photoCount,
    );
  }

  PictureComboPricing? _selectedCombo() {
    if (_selectedComboId.isEmpty) {
      return null;
    }
    for (final combo in _pictureCombos) {
      if (combo.id == _selectedComboId) {
        return combo;
      }
    }
    return null;
  }

  void _setComboPricing(bool enabled) {
    var selectedComboId = _selectedComboId;
    if (enabled && selectedComboId.isEmpty && _pictureCombos.isNotEmpty) {
      selectedComboId = _pictureCombos.first.id;
    }
    setState(() {
      _useComboPricing = enabled;
      _selectedComboId = selectedComboId;
    });
    if (enabled && selectedComboId.isNotEmpty) {
      _savePreferredCombo(selectedComboId);
    }
  }

  Future<void> _savePreferredCombo(String comboId) {
    return widget.settingsStore.saveLastSelectedPictureComboId(comboId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAllPhotosFilter = _selectedFilter == _allPhotosFilter;
    final threshold = isAllPhotosFilter
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.now().subtract(Duration(minutes: _selectedFilter));
    final List<_GalleryPhoto> filteredPhotos = isAllPhotosFilter
        ? _photos.take(_visibleAllPhotosCount).toList(growable: false)
        : _photos
            .where((photo) => photo.capturedAt.isAfter(threshold))
            .toList(growable: false);
    final canLoadMoreAllPhotos = isAllPhotosFilter &&
        (_visibleAllPhotosCount < _photos.length || _hasMoreDevicePhotos);
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final crossAxisCount = isLandscape ? 4 : 3;
    final pricing = _calculatePricing(_selectedPhotoIds.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.requirePayment
              ? tr(
                  context,
                  pt: 'Fotos para atendimento rápido',
                  es: 'Fotos para atención rápida',
                  en: 'Photos for quick service',
                )
              : tr(
                  context,
                  pt: 'Fotos para envio sem pagamento',
                  es: 'Fotos para envío sin pago',
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
                  es: 'Selecciona fotos, crea pedido con pago y envía al cliente.',
                  en: 'Select photos, create a paid order and send to the client.',
                )
              : tr(
                  context,
                  pt: 'Selecione fotos e envie imediatamente sem etapa de pagamento.',
                  es: 'Selecciona fotos y envía sin etapa de pago.',
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
                      pt: 'Parâmetros de pagamento',
                      es: 'Parámetros de pago',
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
                        pt: 'Método',
                        es: 'Método',
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
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          value: false,
                          groupValue: _useComboPricing,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            tr(
                              context,
                              pt: 'Foto única',
                              es: 'Foto única',
                              en: 'Single photo',
                            ),
                          ),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            _setComboPricing(value);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          value: true,
                          groupValue: _useComboPricing,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            tr(
                              context,
                              pt: 'Combo',
                              es: 'Combo',
                              en: 'Combo',
                            ),
                          ),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            _setComboPricing(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_useComboPricing) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedComboId.isEmpty ? null : _selectedComboId,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: tr(
                          context,
                          pt: 'Combo selecionado',
                          es: 'Combo seleccionado',
                          en: 'Selected combo',
                        ),
                      ),
                      items: _pictureCombos
                          .map(
                            (combo) => DropdownMenuItem(
                              value: combo.id,
                              child: Text(
                                '${combo.name} (${combo.minimumPhotos}+ / ${_toCurrency(combo.unitPriceCents)})',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _pictureCombos.isEmpty
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _selectedComboId = value);
                              _savePreferredCombo(value);
                            },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _unitPriceController,
                    enabled: !_useComboPricing,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: tr(
                        context,
                        pt: 'Valor por foto (R\$)',
                        es: 'Valor por foto (R\$)',
                        en: 'Price per photo (R\$)',
                      ),
                      helperText: _useComboPricing
                          ? tr(
                              context,
                              pt: 'Campo desativado enquanto o modo combo estiver ativo.',
                              es: 'Campo desactivado mientras el modo combo está activo.',
                              en: 'Field disabled while combo mode is active.',
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_useComboPricing)
                    Text(
                      pricing.combo == null
                          ? tr(
                              context,
                              pt: _pictureCombos.isEmpty
                                  ? 'Nenhum combo configurado em Configurações. Usando preço unitário.'
                                  : 'Selecione um combo para aplicar nesta venda.',
                              es: _pictureCombos.isEmpty
                                  ? 'No hay combos configurados en Configuración. Usando precio unitario.'
                                  : 'Selecciona un combo para esta venta.',
                              en: _pictureCombos.isEmpty
                                  ? 'No combos configured in Settings. Using single-photo price.'
                                  : 'Pick a combo for this sale.',
                            )
                          : tr(
                              context,
                              pt: pricing.comboEligible
                                  ? 'Combo ativo: ${pricing.combo!.name} (a partir de ${pricing.combo!.minimumPhotos} fotos, ${_toCurrency(pricing.combo!.unitPriceCents)} por foto)'
                                  : 'Combo ${pricing.combo!.name} ainda não aplicado: mínimo de ${pricing.combo!.minimumPhotos} foto(s).',
                              es: 'Combo activo: ${pricing.combo!.name} (desde ${pricing.combo!.minimumPhotos} fotos, ${_toCurrency(pricing.combo!.unitPriceCents)} por foto)',
                              en: 'Active combo: ${pricing.combo!.name} (from ${pricing.combo!.minimumPhotos} photos, ${_toCurrency(pricing.combo!.unitPriceCents)} per photo)',
                            ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      context,
                      pt: 'Valor devido: ${_toCurrency(pricing.totalAmountCents)} (${_toCurrency(pricing.unitPriceCents)} x ${_selectedPhotoIds.length} foto(s))',
                      es: 'Valor debido: ${_toCurrency(pricing.totalAmountCents)} (${_toCurrency(pricing.unitPriceCents)} x ${_selectedPhotoIds.length} foto(s))',
                      en: 'Amount due: ${_toCurrency(pricing.totalAmountCents)} (${_toCurrency(pricing.unitPriceCents)} x ${_selectedPhotoIds.length} photo(s))',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
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
                  pt: 'Últimas fotos capturadas',
                  es: 'Últimas fotos capturadas',
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
                es: 'Actualizar galería',
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
                  label: Text(
                    minutes == _allPhotosFilter
                        ? tr(
                            context,
                            pt: 'Todas',
                            es: 'Todas',
                            en: 'All',
                          )
                        : '$minutes min',
                  ),
                  selected: _selectedFilter == minutes,
                  selectedColor: colorScheme.primaryContainer,
                  side: BorderSide(color: colorScheme.outline),
                  showCheckmark: true,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = minutes;
                      if (_selectedFilter == _allPhotosFilter &&
                          _visibleAllPhotosCount < _allPhotosChunkSize) {
                        _visibleAllPhotosCount = _allPhotosChunkSize;
                      }
                    });
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
        else if (!_hasPermission && filteredPhotos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                tr(
                  context,
                  pt: 'Permissão de galeria não concedida.',
                  es: 'Permiso de galería no concedido.',
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
                  pt: 'Nenhuma foto no período selecionado.',
                  es: 'No hay fotos en el período seleccionado.',
                  en: 'No photos in the selected period.',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          )
        else
          Column(
            children: [
              if (!_hasPermission)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    tr(
                      context,
                      pt: 'Permissão de galeria não concedida. Exibindo fotos importadas da pasta.',
                      es: 'Permiso de galería no concedido. Mostrando fotos importadas de la carpeta.',
                      en: 'Gallery permission not granted. Showing photos imported from folder.',
                    ),
                  ),
                ),
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
                          _selectedImportedPhotoIds.remove(photo.id);
                        } else {
                          _selectedPhotoIds.add(photo.id);
                          if (photo.asset != null) {
                            _selectedAssetsById[photo.id] = photo.asset!;
                          } else {
                            _selectedImportedPhotoIds.add(photo.id);
                          }
                        }
                      });
                    },
                  );
                },
              ),
              if (canLoadMoreAllPhotos) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingMorePhotos ? null : _loadMoreAllPhotos,
                    icon: _isLoadingMorePhotos
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(
                      tr(
                        context,
                        pt: _isLoadingMorePhotos
                            ? 'Carregando...'
                            : 'Carregar mais fotos',
                        es: _isLoadingMorePhotos
                            ? 'Cargando...'
                            : 'Cargar más fotos',
                        en: _isLoadingMorePhotos
                            ? 'Loading...'
                            : 'Load more photos',
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
                      pt: 'Criar pedido e QR Code (${_selectedPhotoIds.length})',
                      es: 'Crear pedido y código QR (${_selectedPhotoIds.length})',
                      en: 'Create order and QR code (${_selectedPhotoIds.length})',
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

    final selectedAssets = _selectedAssetsById.values.toList(growable: false);
    final selectedImportedIds =
        _selectedImportedPhotoIds.toList(growable: false);
    if (selectedAssets.isEmpty && selectedImportedIds.isEmpty) {
      return;
    }

    setState(() => _isSubmittingOrder = true);
    await _photoRepository.persistAssets(selectedAssets);

    final itemIds = <String>[
      ...selectedAssets.map((asset) => 'asset_${asset.id}'),
      ...selectedImportedIds,
    ];
    final orderId = 'order_${DateTime.now().microsecondsSinceEpoch}';
    final pricing = _calculatePricing(itemIds.length);
    final totalAmountCents =
        widget.requirePayment ? pricing.totalAmountCents : 0;
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
      _selectedImportedPhotoIds.clear();
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
                  pt: 'Pedido criado com sucesso. Link e código prontos para envio.',
                  es: 'Pedido creado con éxito. Enlace y código listos para enviar.',
                  en: 'Order created successfully. Link and code are ready to send.',
                )
              : tr(
                  context,
                  pt: 'Envio sem pagamento preparado com sucesso.',
                  es: 'Envío sin pago preparado con éxito.',
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
    final isPixPayment =
        widget.requirePayment && _selectedPaymentChoice == DeliveryPaymentChoice.pix;

    final paymentIntegration = isPixPayment
        ? await widget.settingsStore.loadPaymentIntegrationSettings()
        : const PaymentIntegrationSettings();

    final localPixPayload = isPixPayment
        ? PixPayload.build(
            pixKey: businessProfile.photographerPixKey,
            amountCents: order.totalAmountCents,
            merchantName: businessProfile.photographerName,
            merchantCity: 'Sao Paulo',
            txid: order.id,
            description: 'Pedido ${order.id}',
          )
        : '';

    var pixPayload = localPixPayload;
    PaymentChargeSession? pixSession;
    var pixSourceHint = '';

    if (isPixPayment && paymentIntegration.isApiEnabled) {
      final integrationClient = PaymentIntegrationClient();
      try {
        pixSession = await integrationClient.createPixCharge(
          settings: paymentIntegration,
          orderId: order.id,
          txid: order.id,
          amountCents: order.totalAmountCents,
          pixKey: businessProfile.photographerPixKey,
          payerName: client.name,
          payerWhatsapp: client.whatsapp,
          payerEmail: client.email ?? '',
          description: 'Pedido ${order.id}',
        );
      } on Object {
        pixSession = null;
      }

      if (pixSession != null && pixSession.pixCode.trim().isNotEmpty) {
        pixPayload = pixSession.pixCode.trim();
        pixSourceHint = tr(
          context,
          pt: 'QR Pix obtido pela API do banco/provedor selecionado.',
          es: 'QR Pix obtenido por la API del banco/proveedor seleccionado.',
          en: 'Pix QR obtained from the selected bank/provider API.',
        );
      } else if (localPixPayload.isNotEmpty) {
        pixSourceHint = tr(
          context,
          pt: 'API indisponível no momento. Usando QR Pix local.',
          es: 'API no disponible en este momento. Usando QR Pix local.',
          en: 'API unavailable right now. Using local Pix QR.',
        );
      }
    } else if (isPixPayment && localPixPayload.isNotEmpty) {
      pixSourceHint = tr(
        context,
        pt: 'QR Pix local gerado pelo app.',
        es: 'QR Pix local generado por la app.',
        en: 'Local Pix QR generated by the app.',
      );
    }

    final paymentText = widget.requirePayment
        ? switch (_selectedPaymentChoice) {
            DeliveryPaymentChoice.pix =>
              '\n${tr(context, pt: 'Pagamento', es: 'Pago', en: 'Payment')}: ${_selectedPaymentChoice.label(context)} ($currency)\n'
                  'Pix: ${businessProfile.photographerPixKey.isEmpty ? tr(context, pt: 'Não informado', es: 'No informado', en: 'Not provided') : businessProfile.photographerPixKey}'
                  '${pixSourceHint.isEmpty ? '' : '\n$pixSourceHint'}',
            DeliveryPaymentChoice.paypal =>
              '\n${tr(context, pt: 'Pagamento', es: 'Pago', en: 'Payment')}: ${_selectedPaymentChoice.label(context)} ($currency)\n'
                  'PayPal: ${businessProfile.photographerPaypal.isEmpty ? tr(context, pt: 'Não informado', es: 'No informado', en: 'Not provided') : businessProfile.photographerPaypal}',
          }
        : '\n${tr(context, pt: 'Envio livre (sem pagamento).', es: 'Envío libre (sin pago).', en: 'Free dispatch (no payment).')}';

    final message =
        '${tr(context, pt: 'Olá', es: 'Hola', en: 'Hello')} ${client.name}! ${tr(context, pt: 'Suas fotos estão prontas.', es: 'Tus fotos están listas.', en: 'Your photos are ready.')}\nLink: $link\n${tr(context, pt: 'Código', es: 'Código', en: 'Code')}: $code$paymentText\n${tr(context, pt: 'Fotógrafo', es: 'Fotógrafo', en: 'Photographer')}: ${businessProfile.photographerName}';

    if (!mounted) {
      return;
    }

    var markedAsPaid = false;
    Future<void> markAsPaid() async {
      if (markedAsPaid) {
        return;
      }
      markedAsPaid = true;
      await _orderRepository.updateOrderStatus(order.id, domain.OrderStatus.paid);
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      tr(
                        context,
                        pt: 'Ações de envio',
                        es: 'Acciones de envío',
                        en: 'Dispatch actions',
                      ),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                      '${tr(context, pt: 'Cliente', es: 'Cliente', en: 'Client')}: ${client.name}'),
                  Text('Link: $link'),
                  Text(
                      '${tr(context, pt: 'Código', es: 'Código', en: 'Code')}: $code'),
                  if (widget.requirePayment)
                    Text(
                      '${tr(context, pt: 'Pagamento', es: 'Pago', en: 'Payment')}: ${_selectedPaymentChoice.label(context)} ($currency)',
                    ),
                  if (_selectedPaymentChoice == DeliveryPaymentChoice.paypal &&
                      widget.requirePayment)
                    Text(
                      '${tr(context, pt: 'Conta PayPal', es: 'Cuenta PayPal', en: 'PayPal account')}: ${businessProfile.photographerPaypal.isEmpty ? tr(context, pt: 'Não informada', es: 'No informada', en: 'Not provided') : businessProfile.photographerPaypal}',
                    ),
                  if (_selectedPaymentChoice == DeliveryPaymentChoice.pix &&
                      widget.requirePayment) ...[
                    const SizedBox(height: 12),
                    _PixPaymentCard(
                      payload: pixPayload,
                      sourceHint: pixSourceHint,
                      paymentIntegration: paymentIntegration,
                      session: pixSession,
                      onPaid: markAsPaid,
                    ),
                  ],
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
    final pricing = _calculatePricing(order.itemIds.length);
    final comboLabel = pricing.combo?.name;
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
            ? comboLabel == null
                ? _selectedPaymentChoice.label(context)
                : pricing.comboEligible
                    ? '${_selectedPaymentChoice.label(context)} - $comboLabel'
                    : '${_selectedPaymentChoice.label(context)} - $comboLabel (mínimo não atingido)'
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

class _PixPaymentCard extends StatefulWidget {
  const _PixPaymentCard({
    required this.payload,
    required this.sourceHint,
    required this.paymentIntegration,
    required this.session,
    required this.onPaid,
  });

  final String payload;
  final String sourceHint;
  final PaymentIntegrationSettings paymentIntegration;
  final PaymentChargeSession? session;
  final Future<void> Function() onPaid;

  @override
  State<_PixPaymentCard> createState() => _PixPaymentCardState();
}

class _PixPaymentCardState extends State<_PixPaymentCard> {
  late final PaymentIntegrationClient _integrationClient;
  Timer? _statusTimer;
  String _status = '';
  bool _paid = false;
  bool _checkingStatus = false;
  String _statusError = '';

  @override
  void initState() {
    super.initState();
    _integrationClient = PaymentIntegrationClient();
    _status = widget.session?.status.trim().isEmpty ?? true
        ? 'pending'
        : widget.session!.status.trim();
    _paid = _isPaidStatus(_status);

    if (_paid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPaid();
      });
    }

    if (widget.paymentIntegration.isApiEnabled && widget.session != null) {
      _refreshStatus();
      _statusTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refreshStatus(),
      );
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_checkingStatus || widget.session == null) {
      return;
    }
    _checkingStatus = true;
    try {
      final status = await _integrationClient.fetchPixStatus(
        settings: widget.paymentIntegration,
        session: widget.session!,
      );
      if (!mounted) {
        return;
      }
      if (status != null) {
        final paid = status.paid || _isPaidStatus(status.status);
        setState(() {
          _status = status.status;
          _paid = paid;
          _statusError = '';
        });
        if (paid) {
          await widget.onPaid();
        }
      }
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusError = tr(
          context,
          pt: 'Não foi possível atualizar o status Pix agora.',
          es: 'No fue posible actualizar el estado Pix ahora.',
          en: 'Could not refresh Pix status now.',
        );
      });
    } finally {
      _checkingStatus = false;
    }
  }

  bool _isPaidStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'paid' ||
        normalized == 'approved' ||
        normalized == 'completed' ||
        normalized == 'settled' ||
        normalized == 'succeeded';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                context,
                pt: 'QR Code Pix',
                es: 'Código QR Pix',
                en: 'Pix QR code',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.sourceHint.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(widget.sourceHint),
            ],
            if (widget.paymentIntegration.isApiEnabled && widget.session != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        _paid ? Icons.check_circle : Icons.schedule,
                        color: _paid ? Colors.green.shade700 : null,
                      ),
                      label: Text(
                        _paid
                            ? tr(
                                context,
                                pt: 'Pagamento confirmado',
                                es: 'Pago confirmado',
                                en: 'Payment confirmed',
                              )
                            : tr(
                                context,
                                pt: 'Status: $_status',
                                es: 'Estado: $_status',
                                en: 'Status: $_status',
                              ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _checkingStatus ? null : _refreshStatus,
                      icon: _checkingStatus
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        tr(
                          context,
                          pt: 'Atualizar status',
                          es: 'Actualizar estado',
                          en: 'Refresh status',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_statusError.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_statusError),
            ],
            const SizedBox(height: 8),
            if (widget.payload.isEmpty)
              Text(
                tr(
                  context,
                  pt: 'Defina uma chave Pix válida em Configurações para gerar o QR.',
                  es: 'Define una clave Pix válida en Configuración para generar el QR.',
                  en: 'Set a valid Pix key in Settings to generate the QR.',
                ),
              )
            else ...[
              Center(
                child: QrImageView(
                  data: widget.payload,
                  size: 220,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  context,
                  pt: 'Pix copia e cola:',
                  es: 'Pix copia y pega:',
                  en: 'Pix copy and paste:',
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SelectableText(widget.payload),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.payload),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr(
                              context,
                              pt: 'Código Pix copiado.',
                              es: 'Código Pix copiado.',
                              en: 'Pix code copied.',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(
                    tr(
                      context,
                      pt: 'Copiar código Pix',
                      es: 'Copiar código Pix',
                      en: 'Copy Pix code',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
              child: photo.asset != null
                  ? _AssetThumbnail(
                      asset: photo.asset!,
                      borderRadius: BorderRadius.circular(14),
                    )
                  : _FileThumbnail(
                      filePath: photo.localPath ?? '',
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

class _FileThumbnail extends StatelessWidget {
  const _FileThumbnail({
    required this.filePath,
    required this.borderRadius,
  });

  final String filePath;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (filePath.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: const Center(child: Icon(Icons.image_not_supported_outlined)),
      );
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, _, __) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: const Center(child: Icon(Icons.broken_image_outlined)),
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
                      es: 'Reutilizar envío reciente',
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

    FocusManager.instance.primaryFocus?.unfocus();
    final summary = ClientSummary(
      id: id,
      name: name,
      whatsapp: whatsapp,
      email: email.isEmpty ? null : email,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(summary);
    });
  }
}

class _GalleryPhoto {
  const _GalleryPhoto({
    required this.id,
    required this.capturedAt,
    this.asset,
    this.localPath,
  });

  final String id;
  final DateTime capturedAt;
  final AssetEntity? asset;
  final String? localPath;
}

class _PricingCalculation {
  const _PricingCalculation({
    required this.unitPriceCents,
    required this.totalAmountCents,
    this.combo,
    this.comboEligible = false,
  });

  final int unitPriceCents;
  final int totalAmountCents;
  final PictureComboPricing? combo;
  final bool comboEligible;
}




