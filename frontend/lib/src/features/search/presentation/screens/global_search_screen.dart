import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/search_model.dart';
import '../../../../core/di/service_locator.dart';
import '../../../admin/data/admin_repository.dart';
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
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = getIt<AdminRepository>();
      final results = <SearchResult>[];

      // Search accounts
      if (_typeFilter == null ||
          _typeFilter == SearchResultType.user ||
          _typeFilter == SearchResultType.university) {
        final accounts = await repo.fetchAccounts();
        for (final a in accounts) {
          final email = (a['email'] ?? '').toString().toLowerCase();
          final role = (a['role'] ?? '').toString().toLowerCase();
          final id = (a['id'] ?? a['account_id'] ?? '').toString();
          if (email.contains(q) || id.contains(q)) {
            final type = role == 'university'
                ? SearchResultType.university
                : SearchResultType.user;
            if (_typeFilter != null && _typeFilter != type) continue;
            results.add(SearchResult(
              id: id,
              type: type,
              title: email,
              subtitle: role,
            ));
          }
        }
      }

      // Search diplomas
      if (_typeFilter == null || _typeFilter == SearchResultType.diploma) {
        final diplomas = await repo.fetchDiplomas();
        for (final d in diplomas) {
          final title =
              (d['full_name'] ?? d['title'] ?? '').toString().toLowerCase();
          final number =
              (d['diploma_number'] ?? d['number'] ?? '').toString().toLowerCase();
          final id = (d['id'] ?? d['diploma_id'] ?? '').toString();
          if (title.contains(q) || number.contains(q) || id.contains(q)) {
            results.add(SearchResult(
              id: id,
              type: SearchResultType.diploma,
              title: d['full_name']?.toString() ?? d['title']?.toString() ?? id,
              subtitle: d['diploma_number']?.toString() ?? '',
            ));
          }
        }
      }

      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              onChanged: _onQueryChanged,
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
                    _onQueryChanged(_controller.text);
                  },
                ),
                _FilterChip(
                  label: 'Дипломы',
                  icon: Icons.description,
                  selected: _typeFilter == SearchResultType.diploma,
                  onTap: () {
                    setState(() => _typeFilter = SearchResultType.diploma);
                    _onQueryChanged(_controller.text);
                  },
                ),
                _FilterChip(
                  label: 'Сотрудники',
                  icon: Icons.people,
                  selected: _typeFilter == SearchResultType.employee,
                  onTap: () {
                    setState(() => _typeFilter = SearchResultType.employee);
                    _onQueryChanged(_controller.text);
                  },
                ),
                _FilterChip(
                  label: 'Вузы',
                  icon: Icons.account_balance,
                  selected: _typeFilter == SearchResultType.university,
                  onTap: () {
                    setState(() => _typeFilter = SearchResultType.university);
                    _onQueryChanged(_controller.text);
                  },
                ),
                _FilterChip(
                  label: 'Пользователи',
                  icon: Icons.person,
                  selected: _typeFilter == SearchResultType.user,
                  onTap: () {
                    setState(() => _typeFilter = SearchResultType.user);
                    _onQueryChanged(_controller.text);
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
                : _loading
                    ? const Center(child: CircularProgressIndicator())
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
