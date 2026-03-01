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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:photo_manager/photo_manager.dart';

class RecentPhotosPage extends StatefulWidget {
  const RecentPhotosPage({required this.database, super.key});

  final AppDatabase database;

  @override
  State<RecentPhotosPage> createState() => _RecentPhotosPageState();
}

class _RecentPhotosPageState extends State<RecentPhotosPage> {
  static const List<int> _timeFiltersInMinutes = [10, 30, 60];

  late final LocalOrderRepository _orderRepository;
  late final UploadQueueService _uploadQueueService;
  late final LocalPhotoAssetRepository _photoRepository;
  late final LocalClientRepository _clientRepository;

  int _selectedFilter = _timeFiltersInMinutes.first;
  final Set<String> _selectedPhotoIds = <String>{};
  final Map<String, AssetEntity> _selectedAssetsById = <String, AssetEntity>{};
  List<_GalleryPhoto> _photos = const [];
  bool _isLoading = true;
  bool _hasPermission = true;
  bool _isSubmittingOrder = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadGallery() async {
    setState(() => _isLoading = true);
    final permissionState = await PhotoManager.requestPermissionExtend();
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
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final threshold = DateTime.now().subtract(Duration(minutes: _selectedFilter));
    final filteredPhotos = _photos.where((photo) => photo.capturedAt.isAfter(threshold)).toList(growable: false);
    final isLandscape = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final crossAxisCount = isLandscape ? 4 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.latestPhotos, style: Theme.of(context).textTheme.headlineSmall)),
            IconButton(
              onPressed: _loadGallery,
              tooltip: l10n.refreshGallery,
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
                  label: Text(l10n.minutesFilter(minutes)),
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
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (!_hasPermission)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.galleryPermissionRequired)),
          )
        else if (filteredPhotos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.noPhotosInSelectedPeriod,
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
            onPressed: _selectedPhotoIds.isEmpty || _isSubmittingOrder ? null : _createOrder,
            icon: const Icon(Icons.shopping_cart_checkout, size: 24),
            label: Text(l10n.createOrderWithSelection(_selectedPhotoIds.length)),
          ),
        ),
      ],
    );
  }

  Future<void> _createOrder() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedClient = await _showClientSelector();
    if (selectedClient == null) {
      return;
    }

    final selectedAssets = _selectedAssetsById.values.toList(growable: false);
    if (selectedAssets.isEmpty) {
      return;
    }

    setState(() => _isSubmittingOrder = true);
    await _photoRepository.persistAssets(selectedAssets);

    final itemIds = selectedAssets.map((asset) => 'asset_${asset.id}').toList(growable: false);
    final orderId = 'order_${DateTime.now().microsecondsSinceEpoch}';
    final order = domain.Order(
      id: orderId,
      clientId: selectedClient.id,
      itemIds: itemIds,
      totalAmountCents: itemIds.length * 1500,
      externalReference: orderId,
      status: domain.OrderStatus.created,
      paymentMethod: domain.PaymentMethod.pix,
    );
    await _orderRepository.createOrder(order);
    await _uploadQueueService.processQueue();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmittingOrder = false;
      _selectedPhotoIds.clear();
      _selectedAssetsById.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.orderCreatedOffline(itemIds.length))),
    );
  }

  Future<ClientSummary?> _showClientSelector() {
    return showModalBottomSheet<ClientSummary>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ClientSelectorSheet(clientRepository: _clientRepository),
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
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AssetEntityImage(
                photo.asset,
                thumbnailSize: const ThumbnailSize(256, 256),
                fit: BoxFit.cover,
                isOriginal: false,
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

class _ClientSelectorSheet extends StatefulWidget {
  const _ClientSelectorSheet({required this.clientRepository});

  final LocalClientRepository clientRepository;

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
    final rows = await widget.clientRepository.listClients();
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.selectOrCreateClient, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
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
              Text(l10n.newClient, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.clientNameLabel),
              ),
              TextField(
                controller: _whatsController,
                decoration: InputDecoration(labelText: l10n.clientWhatsAppLabel),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l10n.clientEmailLabel),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _createAndSelectClient,
                  child: Text(l10n.createClientAndContinue),
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
    if (name.isEmpty || whatsapp.isEmpty) {
      return;
    }

    final id = 'client_${DateTime.now().microsecondsSinceEpoch}';
    await widget.clientRepository.createClient(
      id: id,
      name: name,
      whatsapp: whatsapp,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      ClientSummary(
        id: id,
        name: name,
        whatsapp: whatsapp,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
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
