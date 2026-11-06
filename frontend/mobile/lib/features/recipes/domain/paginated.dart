/// The contract's list envelope: `{ "<items>": [...], "page", "totalPages" }`.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<T> items;
  final int page;

  /// 0 when the list is empty.
  final int totalPages;

  bool get isEmpty => items.isEmpty;
  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  factory Paginated.fromJson(
    Map<String, dynamic> json, {
    required String itemsKey,
    required T Function(Map<String, dynamic>) fromJson,
  }) => Paginated(
    items: (json[itemsKey] as List<dynamic>)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    page: json['page'] as int,
    totalPages: json['totalPages'] as int,
  );
}
