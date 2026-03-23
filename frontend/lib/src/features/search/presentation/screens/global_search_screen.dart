import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/search_model.dart';
import '../../data/mock_data.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  SearchResultType? _typeFilter;
  List<SearchResult> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _results = searchableItems.where((item) {
        if (_typeFilter != null && item.type != _typeFilter) return false;
        return item.title.toLowerCase().contains(q) ||
            item.subtitle.toLowerCase().contains(q) ||
            item.id.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Поиск',
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Диплом, ФИО, вуз, ID, номер...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _search,
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: _typeFilter == null,
                  onTap: () {
                    setState(() => _typeFilter = null);
                    _search(_controller.text);
                  },
                ),
                _FilterChip(
                  label: 'Дипломы',
                  icon: Icons.description,
                  selected: _typeFilter == SearchResultType.diploma,
                  onTap: () {
                    setState(() => _typeFilter = SearchResultType.diploma);
                    _search(_controller.text);
                  },
                ),
                _FilterChip(
                  label: 'Сотрудники',
                  icon: Icons.people,
                  selected: _typeFilter == SearchResultType.employee,
                  onTap: () {
                    setState(() => _typeFilter = SearchResultType.employee);
                    _search(_controller.text);
                  },
                ),
                _FilterChip(
                  label: 'Вузы',
                  icon: Icons.account_balance,
                  selected: _typeFilter == SearchResultType.university,
                  onTap: () {
                    setState(() => _typeFilter = SearchResultType.university);
                    _search(_controller.text);
                  },
                ),
                _FilterChip(
                  label: 'Пользователи',
                  icon: Icons.person,
                  selected: _typeFilter == SearchResultType.user,
                  onTap: () {
                    setState(() => _typeFilter = SearchResultType.user);
                    _search(_controller.text);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _controller.text.isEmpty
                ? _EmptyHint(theme: theme)
                : _results.isEmpty
                    ? Center(
                        child: Text('Ничего не найдено',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, i) =>
                            _ResultTile(result: _results[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 16) : null,
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final ThemeData theme;
  const _EmptyHint({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Введите запрос для поиска',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Дипломы, сотрудники, вузы, пользователи',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (result.type) {
      SearchResultType.diploma => (Icons.description, Colors.blue),
      SearchResultType.employee => (Icons.person, Colors.teal),
      SearchResultType.university => (Icons.account_balance, Colors.deepPurple),
      SearchResultType.user => (Icons.manage_accounts, Colors.brown),
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(result.title,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(result.subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: result.route != null
          ? const Icon(Icons.chevron_right, size: 20)
          : null,
      onTap: result.route != null
          ? () => context.push(result.route!)
          : null,
    );
  }
}
