import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'log_entry.dart';
import 'app_logger.dart';

/// Beautiful in-app log viewer with level filtering, search, and copy.
///
/// Access via the 🐛 button in the bottom-right corner.
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final _logger = AppLogger.instance;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  LogLevel? _activeFilter;
  String _searchQuery = '';
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _logger.addListener(_onNewLog);
  }

  @override
  void dispose() {
    _logger.removeListener(_onNewLog);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNewLog() {
    if (!mounted) return;
    // Defer to avoid setState during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      if (_autoScroll && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  List<LogEntry> get _filteredEntries {
    var entries = _logger.entries;
    if (_activeFilter != null) {
      entries = entries.where((e) => e.level == _activeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      entries = entries
          .where((e) =>
              e.message.toLowerCase().contains(q) ||
              e.tag.toLowerCase().contains(q))
          .toList();
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '🔬 DiplomaVerify Logs',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
              color: _autoScroll ? Colors.greenAccent : Colors.grey,
            ),
            tooltip: _autoScroll ? 'Авто-прокрутка: ВКЛ' : 'Авто-прокрутка: ВЫКЛ',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          // Copy all
          IconButton(
            icon: const Icon(Icons.copy_all, color: Colors.white70),
            tooltip: 'Скопировать все',
            onPressed: () {
              final text =
                  entries.map((e) => e.formatted).join('\n\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📋 Скопировано ${entries.length} записей'),
                  backgroundColor: const Color(0xFF0F3460),
                ),
              );
            },
          ),
          // Clear
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: 'Очистить',
            onPressed: () {
              _logger.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search bar ─────────────────────────
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '🔍 Поиск по логам...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ─── Level filter chips ─────────────────
          Container(
            color: const Color(0xFF16213E),
            height: 46,
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildFilterChip(null, 'Все', '📊', entries.length),
                _buildFilterChip(LogLevel.network, 'HTTP', '🌐', null),
                _buildFilterChip(LogLevel.bloc, 'BLoC', '🧊', null),
                _buildFilterChip(LogLevel.navigation, 'Nav', '🧭', null),
                _buildFilterChip(LogLevel.error, 'Ошибки', '❌', null),
                _buildFilterChip(LogLevel.warning, 'Warn', '⚠️', null),
                _buildFilterChip(LogLevel.info, 'Инфо', '💡', null),
                _buildFilterChip(LogLevel.debug, 'Debug', '🔍', null),
              ],
            ),
          ),

          // ─── Stats bar ──────────────────────────
          Container(
            color: const Color(0xFF0F3460),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${entries.length} записей',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                _statBadge('❌', _countByLevel(LogLevel.error), Colors.redAccent),
                const SizedBox(width: 8),
                _statBadge('🌐', _countByLevel(LogLevel.network), Colors.purpleAccent),
                const SizedBox(width: 8),
                _statBadge('🧊', _countByLevel(LogLevel.bloc), Colors.greenAccent),
              ],
            ),
          ),

          // ─── Log entries list ───────────────────
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bug_report_outlined,
                            size: 64, color: Colors.white.withAlpha(40)),
                        const SizedBox(height: 12),
                        Text(
                          'Логи пока пусты',
                          style: TextStyle(
                            color: Colors.white.withAlpha(80),
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: entries.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (_, i) => _LogTile(
                      entry: entries[i],
                      isEven: i.isEven,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      LogLevel? level, String label, String emoji, int? count) {
    final isActive = _activeFilter == level;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilterChip(
        selected: isActive,
        label: Text(
          '$emoji $label${count != null ? ' ($count)' : ''}',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        selectedColor: const Color(0xFF0F3460),
        checkmarkColor: Colors.cyanAccent,
        side: BorderSide(
          color: isActive ? Colors.cyanAccent : Colors.white24,
        ),
        onSelected: (_) {
          setState(() => _activeFilter = isActive ? null : level);
        },
      ),
    );
  }

  Widget _statBadge(String emoji, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$emoji $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int _countByLevel(LogLevel level) =>
      _logger.entries.where((e) => e.level == level).length;
}

// ─── Single log entry tile ─────────────────────────────────────

class _LogTile extends StatelessWidget {
  final LogEntry entry;
  final bool isEven;

  const _LogTile({required this.entry, required this.isEven});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven
          ? const Color(0xFF1A1A2E)
          : const Color(0xFF16213E).withAlpha(120),
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: entry.formatted));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📋 Запись скопирована'),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF0F3460),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(
                    entry.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _levelColor(entry.level).withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.levelName,
                      style: TextStyle(
                        color: _levelColor(entry.level),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.tag,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(entry.timestamp),
                    style: TextStyle(
                      color: Colors.white.withAlpha(80),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Message
              Text(
                entry.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
              // Error if present
              if (entry.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '⤷ ${entry.error}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.cyanAccent;
      case LogLevel.warning:
        return Colors.orangeAccent;
      case LogLevel.error:
        return Colors.redAccent;
      case LogLevel.network:
        return Colors.purpleAccent;
      case LogLevel.navigation:
        return Colors.blueAccent;
      case LogLevel.bloc:
        return Colors.greenAccent;
    }
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}.'
        '${dt.millisecond.toString().padLeft(3, '0')}';
  }
}
