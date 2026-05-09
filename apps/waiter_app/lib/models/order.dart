/// Represents an order from the `orders` table with joined data.
class Order {
  final String id;
  final double totalAmount;
  final String status;
  final String? tableNumber;
  final String? tableId;
  final String? customerName;
  final String? customerPhone;
  final String? specialInstructions;
  final String? kotNumber;
  final DateTime? placedAt;
  final List<OrderItemDetail> items;

  const Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    this.tableNumber,
    this.tableId,
    this.customerName,
    this.customerPhone,
    this.specialInstructions,
    this.kotNumber,
    this.placedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = (json['order_items'] as List<dynamic>?)
            ?.map(
              (e) => OrderItemDetail.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return Order(
      id: json['id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      tableNumber:
          (json['tables'] as Map<String, dynamic>?)?['table_number']
              ?.toString(),
      tableId: (json['tables'] as Map<String, dynamic>?)?['id'] as String?,
      customerName:
          (json['profiles'] as Map<String, dynamic>?)?['display_name']
              as String?,
      customerPhone:
          (json['profiles'] as Map<String, dynamic>?)?['phone'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      kotNumber: json['kot_number']?.toString(),
      placedAt: json['placed_at'] != null
          ? DateTime.tryParse(json['placed_at'] as String)
          : null,
      items: items,
    );
  }
}

/// A single item within an order, joined with its menu_item name.
class OrderItemDetail {
  final String id;
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? status;
  final String vegType;

  const OrderItemDetail({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.status,
    this.vegType = 'veg',
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      id: json['id'] as String,
      menuItemId: json['menu_item_id'] as String,
      name: (json['menu_items'] as Map<String, dynamic>?)?['name'] as String? ??
          'Unknown Item',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num).toDouble(),
      status: json['status'] as String?,
      vegType: (json['menu_items'] as Map<String, dynamic>?)?['veg_type']
              as String? ??
          'veg',
    );
  }
}
