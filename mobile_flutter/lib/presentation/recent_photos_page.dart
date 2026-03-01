import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecentPhotosPage extends StatefulWidget {
  const RecentPhotosPage({super.key});

  @override
  State<RecentPhotosPage> createState() => _RecentPhotosPageState();
}

class _RecentPhotosPageState extends State<RecentPhotosPage> {
  static const List<int> _timeFiltersInMinutes = [10, 30, 60];

  final List<_RecentPhotoItem> _photos = [
    _RecentPhotoItem(id: 'IMG_2026-01-18_1130', minutesAgo: 4),
    _RecentPhotoItem(id: 'IMG_2026-01-18_1126', minutesAgo: 8),
    _RecentPhotoItem(id: 'IMG_2026-01-18_1118', minutesAgo: 16),
    _RecentPhotoItem(id: 'IMG_2026-01-18_1109', minutesAgo: 25),
    _RecentPhotoItem(id: 'IMG_2026-01-18_1050', minutesAgo: 44),
    _RecentPhotoItem(id: 'IMG_2026-01-18_1038', minutesAgo: 58),
  ];

  int _selectedFilter = _timeFiltersInMinutes.first;
  final Set<String> _selectedPhotoIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final filteredPhotos = _photos.where((photo) => photo.minutesAgo <= _selectedFilter).toList(growable: false);
    final isLandscape = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final crossAxisCount = isLandscape ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.latestPhotos, style: Theme.of(context).textTheme.headlineSmall),
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
        if (filteredPhotos.isEmpty)
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
              childAspectRatio: isLandscape ? 1.35 : 1.15,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
                    } else {
                      _selectedPhotoIds.add(photo.id);
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
            onPressed: _selectedPhotoIds.isEmpty ? null : () {},
            icon: const Icon(Icons.photo_library_outlined, size: 28),
            label: Text(l10n.quickSelection(_selectedPhotoIds.length)),
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.isSelected,
    required this.onToggle,
  });

  final _RecentPhotoItem photo;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 28,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  _GalleryThumbnail(photo: photo),
                ],
              ),
              const Spacer(),
              Text(
                photo.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(l10n.photoCapturedMinutesAgo(photo.minutesAgo), style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.photo});

  final _RecentPhotoItem photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        color: Theme.of(context).colorScheme.surface,
        child: photo.thumbnailProvider != null
            ? Image(
                image: ResizeImage(photo.thumbnailProvider!, width: 176, height: 176),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
              )
            : Icon(
                Icons.image_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

class _RecentPhotoItem {
  const _RecentPhotoItem({
    required this.id,
    required this.minutesAgo,
    this.thumbnailProvider,
  });

  final String id;
  final int minutesAgo;
  final ImageProvider? thumbnailProvider;
}
