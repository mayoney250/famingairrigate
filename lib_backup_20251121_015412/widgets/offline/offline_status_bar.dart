import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../config/colors.dart';

/// Widget to display offline/sync status
class OfflineStatusBar extends StatelessWidget {
  const OfflineStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline && !connectivity.hasUnsyncedData) {
          // Fully online with no pending syncs
          return const SizedBox.shrink();
        }

        final isOffline = !connectivity.isOnline;
        final backgroundColor = isOffline 
            ? Colors.orangeAccent.shade700
            : Colors.amber.shade600;
        
        final icon = isOffline ? Icons.cloud_off : Icons.cloud_queue;
        final message = isOffline
            ? '📴 Offline - Using cached data'
            : '⬆️ Syncing ${connectivity.pendingSyncCount} item${connectivity.pendingSyncCount == 1 ? '' : 's'}...';

        return Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isOffline && connectivity.pendingSyncCount > 0)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                )
              else if (isOffline)
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
            ],
          ),
        );
      },
    );
  }
}
