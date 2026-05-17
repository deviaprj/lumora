import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Indicateur de synchronisation cloud.
/// - Vert : tout est synchronisé.
/// - Orange : modifications locales en attente.
/// - Rouge : erreur de sync. Tap = retry.
enum SyncStatus { synced, pending, error }

class SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onRetry;
  final double size;

  const SyncIndicator({
    super.key,
    required this.status,
    this.onRetry,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (status) {
      SyncStatus.synced => (Icons.cloud_done_rounded, LumoraColors.syncGreen, 'Synchronisé'),
      SyncStatus.pending => (Icons.cloud_upload_rounded, LumoraColors.waitOrange, 'Sync en cours...'),
      SyncStatus.error => (Icons.cloud_off_rounded, LumoraColors.errorRose, 'Erreur sync. Tap pour réessayer.'),
    };

    return GestureDetector(
      onTap: status == SyncStatus.error ? onRetry : null,
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(24),
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            color: color,
            size: size,
          ),
        ),
      ),
    );
  }
}
