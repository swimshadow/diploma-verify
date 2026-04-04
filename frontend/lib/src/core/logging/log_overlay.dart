import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_logger.dart';
import 'log_entry.dart';
import 'log_viewer_screen.dart';

/// Floating action button overlay that shows error count badge
/// and opens the LogViewer on tap. Only visible in debug mode.
class LogOverlay extends StatefulWidget {
  final Widget child;

  const LogOverlay({super.key, required this.child});

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay>
    with SingleTickerProviderStateMixin {
  final _logger = AppLogger.instance;
  int _errorCount = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _logger.addListener(_onLogChanged);
  }

  @override
  void dispose() {
    _logger.removeListener(_onLogChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onLogChanged() {
    if (!mounted) return;
    final newCount =
        _logger.entries.where((e) => e.level == LogLevel.error).length;
    if (newCount > _errorCount) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
    setState(() => _errorCount = newCount);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 16,
          bottom: 80,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: FloatingActionButton.small(
              heroTag: '__log_viewer_fab__',
              backgroundColor: _errorCount > 0
                  ? Colors.redAccent.withAlpha(220)
                  : const Color(0xFF0F3460).withAlpha(220),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LogViewerScreen(),
                  ),
                );
              },
              child: Badge(
                isLabelVisible: _errorCount > 0,
                label: Text(
                  '$_errorCount',
                  style: const TextStyle(fontSize: 9),
                ),
                child: const Icon(
                  Icons.bug_report,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
