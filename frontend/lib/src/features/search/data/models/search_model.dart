import 'package:equatable/equatable.dart';

enum SearchResultType {
  diploma,
  employee,
  university,
  user,
}

class SearchResult extends Equatable {
  final String id;
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String? route;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.route,
  });

  @override
  List<Object?> get props => [id, type];
}
