class Category {
  final String name;
  final int count;

  const Category({required this.name, this.count = 0});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name']?.toString() ?? '',
      count: (json['count'] is int) ? json['count'] as int : 0,
    );
  }
}
