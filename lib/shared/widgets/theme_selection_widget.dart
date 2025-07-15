import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/theme_service.dart';
import '../../core/theme/app_colors.dart';

class ThemeSelectionWidget extends ConsumerWidget {
  final bool showAccentColors;
  final bool isCompact;

  const ThemeSelectionWidget({
    super.key,
    this.showAccentColors = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeServiceProvider);
    final themeService = ref.read(themeServiceProvider.notifier);

    if (isCompact) {
      return _buildCompactView(context, themeState, themeService);
    }

    return _buildFullView(context, themeState, themeService);
  }

  Widget _buildCompactView(BuildContext context, AppThemeState themeState, ThemeService themeService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildThemeModeDropdown(themeState, themeService),
              ],
            ),
            if (showAccentColors) ...[
              const SizedBox(height: 12),
              _buildAccentColorRow(themeState, themeService),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(BuildContext context, AppThemeState themeState, ThemeService themeService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Appearance Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Theme Mode Selection
            Text(
              'Theme Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildThemeModeGrid(themeState, themeService),
            
            if (showAccentColors) ...[
              const SizedBox(height: 24),
              Text(
                'Accent Color',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildAccentColorGrid(themeState, themeService),
            ],
            
            const SizedBox(height: 16),
            _buildResetButton(themeService),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeDropdown(AppThemeState themeState, ThemeService themeService) {
    return DropdownButton<AppThemeMode>(
      value: themeState.themeMode,
      underline: Container(),
      items: AppThemeMode.values.map((mode) {
        return DropdownMenuItem(
          value: mode,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ThemeService.getThemeModeIcon(mode),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(ThemeService.getThemeModeDisplayName(mode)),
            ],
          ),
        );
      }).toList(),
      onChanged: (mode) {
        if (mode != null) {
          themeService.setThemeMode(mode);
        }
      },
    );
  }

  Widget _buildThemeModeGrid(AppThemeState themeState, ThemeService themeService) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: AppThemeMode.values.map((mode) {
        final isSelected = themeState.themeMode == mode;
        return _buildThemeModeCard(mode, isSelected, themeService);
      }).toList(),
    );
  }

  Widget _buildThemeModeCard(AppThemeMode mode, bool isSelected, ThemeService themeService) {
    return InkWell(
      onTap: () => themeService.setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              ThemeService.getThemeModeIcon(mode),
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ThemeService.getThemeModeDisplayName(mode),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentColorRow(AppThemeState themeState, ThemeService themeService) {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ThemeService.availableAccentColors.length,
        itemBuilder: (context, index) {
          final color = ThemeService.availableAccentColors[index];
          final isSelected = themeState.accentColor == color;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildAccentColorItem(color, isSelected, themeService),
          );
        },
      ),
    );
  }

  Widget _buildAccentColorGrid(AppThemeState themeState, ThemeService themeService) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 6,
      childAspectRatio: 1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: ThemeService.availableAccentColors.map((color) {
        final isSelected = themeState.accentColor == color;
        return _buildAccentColorItem(color, isSelected, themeService);
      }).toList(),
    );
  }

  Widget _buildAccentColorItem(Color color, bool isSelected, ThemeService themeService) {
    return InkWell(
      onTap: () => themeService.setAccentColor(color),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }

  Widget _buildResetButton(ThemeService themeService) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => themeService.resetToDefault(),
        icon: const Icon(Icons.refresh),
        label: const Text('Reset to Default'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// Theme selection dialog
class ThemeSelectionDialog extends ConsumerWidget {
  const ThemeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Theme Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ThemeSelectionWidget(showAccentColors: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show theme selection dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ThemeSelectionDialog(),
    );
  }
}
