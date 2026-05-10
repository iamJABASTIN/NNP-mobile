/// Represents a dish from the `menu_items` table.
class MenuItem {
  final String id;
  final String name;
  final double price;
  final String? categoryName;
  final bool isAvailable;
  final String vegType;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.categoryName,
    this.isAvailable = true,
    this.vegType = 'veg',
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      categoryName: json['category_name'] as String? ??
          (json['categories'] as Map<String, dynamic>?)?['name'] as String?,
      isAvailable: (json['is_available'] is int) 
          ? json['is_available'] == 1 
          : json['is_available'] as bool? ?? true,
      vegType: json['veg_type'] as String? ?? 'veg',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category_name': categoryName,
      'is_available': isAvailable,
      'veg_type': vegType,
    };
  }

  bool get isVeg => vegType == 'veg';
}
