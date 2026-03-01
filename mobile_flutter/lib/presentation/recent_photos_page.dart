import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final filteredPhotos = _photos
        .where((photo) => photo.minutesAgo <= _selectedFilter)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimas fotos',
            style: Theme.of(context).textTheme.headlineSmall,
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
                    labelStyle: const TextStyle(fontSize: 18),
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
          Expanded(
            child: filteredPhotos.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma foto no período selecionado.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
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
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedPhotoIds.isEmpty ? null : () {},
              icon: const Icon(Icons.photo_library_outlined, size: 28),
              label: Text(
                'Seleção rápida (${_selectedPhotoIds.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
              ),
            ),
          ),
        ],
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

  final _RecentPhotoItem photo;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  Icon(Icons.image_outlined, size: 28, color: colorScheme.onSurfaceVariant),
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
              Text(
                'capturada há ${photo.minutesAgo} min',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentPhotoItem {
  const _RecentPhotoItem({required this.id, required this.minutesAgo});

  final String id;
  final int minutesAgo;
}
