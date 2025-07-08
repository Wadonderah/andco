import 'package:flutter/material.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class OfflineModeWidget extends StatefulWidget {
  final Widget child;
  final bool showOfflineIndicator;

  const OfflineModeWidget({
    super.key,
    required this.child,
    this.showOfflineIndicator = true,
  });

  @override
  State<OfflineModeWidget> createState() => _OfflineModeWidgetState();
}

class _OfflineModeWidgetState extends State<OfflineModeWidget>
    with TickerProviderStateMixin {
  final OfflineService _offlineService = OfflineService();
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isOnline = true;
  SyncStatus _syncStatus = SyncStatus.completed;
  OfflineStats? _stats;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeOfflineService();
  }

  Future<void> _initializeOfflineService() async {
    try {
      await _offlineService.initialize();
      
      // Listen to connectivity changes
      _offlineService.connectivityStream.listen((isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
        
        if (widget.showOfflineIndicator) {
          if (!isOnline) {
            _slideController.forward();
          } else {
            _slideController.reverse();
          }
        }
      });
      
      // Listen to sync status changes
      _offlineService.syncStream.listen((status) {
        setState(() {
          _syncStatus = status;
        });
      });
      
      // Update stats periodically
      _updateStats();
      
      setState(() {
        _isOnline = _offlineService.isOnline;
      });
    } catch (e) {
      debugPrint('Failed to initialize offline service: $e');
    }
  }

  void _updateStats() {
    setState(() {
      _stats = _offlineService.getStats();
    });
    
    // Update stats every 30 seconds
    Future.delayed(const Duration(seconds: 30), _updateStats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          widget.child,
          
          // Offline indicator
          if (widget.showOfflineIndicator)
            SlideTransition(
              position: _slideAnimation,
              child: _buildOfflineIndicator(),
            ),
          
          // Sync indicator
          if (_syncStatus == SyncStatus.syncing)
            Positioned(
              top: MediaQuery.of(context).padding.top + (_isOnline ? 0 : 60),
              left: 0,
              right: 0,
              child: _buildSyncIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: _isOnline ? AppColors.success : AppColors.warning,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isOnline ? 1.0 : _pulseAnimation.value,
                child: Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isOnline ? 'Back Online' : 'Offline Mode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isOnline 
                      ? 'All features available'
                      : 'Limited features available. Data will sync when connected.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!_isOnline && _stats != null) ...[
            GestureDetector(
              onTap: _showOfflineStats,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_stats!.unsyncedItems}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Syncing data...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showOfflineStats() {
    if (_stats == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.offline_bolt, color: AppColors.warning),
                const SizedBox(width: 12),
                const Text(
                  'Offline Mode Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildStatRow('Total Items', _stats!.totalItems.toString()),
            _buildStatRow('Synced Items', _stats!.syncedItems.toString()),
            _buildStatRow('Unsynced Items', _stats!.unsyncedItems.toString()),
            _buildStatRow('Pending Sync', _stats!.pendingSyncItems.toString()),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearCache();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Cache'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _forcSync();
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Force Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCache() async {
    try {
      await _offlineService.clearCache();
      _updateStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _forcSync() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    // Force sync would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync started...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
