import 'menu_item.dart';

/// An item in the waiter's current order cart.
class CartItem {
  final MenuItem menuItem;
  int quantity;
  final String? status; // e.g. 'pending', 'preparing', 'served'
  final String? oiId; // order_item id when editing existing orders

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.status,
    this.oiId,
  });

  double get lineTotal => menuItem.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuItem: MenuItem.fromJson(json['menuItem']),
      quantity: json['quantity'] as int,
      status: json['status'] as String?,
      oiId: json['oiId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'status': status,
      'oiId': oiId,
    };
  }
}
