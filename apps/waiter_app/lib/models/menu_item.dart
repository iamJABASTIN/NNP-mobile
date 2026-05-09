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
      categoryName:
          (json['categories'] as Map<String, dynamic>?)?['name'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      vegType: json['veg_type'] as String? ?? 'veg',
    );
  }

  bool get isVeg => vegType == 'veg';
}
