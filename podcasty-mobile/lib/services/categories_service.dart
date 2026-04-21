import 'api_client.dart';
import '../models/category.dart';

/// Service for category-related API operations
class CategoriesService {
  /// Fetch all categories with podcast counts
  static Future<List<Category>> fetchCategories() async {
    final data = await ApiClient.request(endpoint: '/api/categories');
    return _parse(data);
  }

  /// Fetch categories (public endpoint)
  static Future<List<Category>> fetchCategoriesPublic() async {
    final data = await ApiClient.publicRequest(endpoint: '/api/categories');
    return _parse(data);
  }

  static List<Category> _parse(dynamic data) {
    if (data is! List) return [];
    return data
        .map((item) {
          if (item is Map<String, dynamic>) return Category.fromJson(item);
          if (item is Map) return Category.fromJson(Map<String, dynamic>.from(item));
          return Category(name: item.toString());
        })
        .where((c) => c.name.isNotEmpty)
        .toList();
  }
}
