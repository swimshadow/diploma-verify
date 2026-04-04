import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_logger.dart';
import 'log_entry.dart';
import 'log_viewer_screen.dart';

/// Floating action button overlay that shows error count badge
/// and opens the LogViewer on tap. Only visible in debug mode.
///
/// Uses [Overlay] so the FAB never interferes with the child's layout.
class LogOverlay extends StatefulWidget {
  final Widget child;

  const LogOverlay({super.key, required this.child});

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  final _logger = AppLogger.instance;
  OverlayEntry? _overlayEntry;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _logger.addListener(_onLogChanged);
      // Insert overlay after the first frame when Overlay is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _insertOverlay();
      });
    }
  }

  @override
  void dispose() {
    _logger.removeListener(_onLogChanged);
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _onLogChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final newCount =
          _logger.entries.where((e) => e.level == LogLevel.error).length;
      if (newCount != _errorCount) {
        _errorCount = newCount;
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _insertOverlay() {
    if (!mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        right: 16,
        bottom: 80,
        child: _LogFab(
          errorCount: _errorCount,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogViewerScreen()),
            );
          },
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    // Just pass through — the FAB lives in the Overlay
    return widget.child;
  }
}

class _LogFab extends StatelessWidget {
  final int errorCount;
  final VoidCallback onTap;

  const _LogFab({required this.errorCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: FloatingActionButton.small(
        heroTag: '__log_viewer_fab__',
        backgroundColor: errorCount > 0
            ? Colors.redAccent.withAlpha(220)
            : const Color(0xFF0F3460).withAlpha(220),
        onPressed: onTap,
        child: Badge(
          isLabelVisible: errorCount > 0,
          label: Text(
            '$errorCount',
            style: const TextStyle(fontSize: 9),
          ),
          child: const Icon(
            Icons.bug_report,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
