import '../core/supabase_config.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// Service for CRUD operations on orders — mirrors QuickPOS.jsx logic.
class OrderService {
  static const String _defaultRid = '00000000-0000-0000-0000-000000000001';

  /// Fetch orders with joined data, optionally filtered by date range.
  static Future<List<Order>> fetchOrders({
    DateTime? since,
  }) async {
    var query = SupabaseConfig.client.from('orders').select(
      'id, total_amount, status, special_instructions, kot_number, placed_at, '
      'tables(table_number), profiles(display_name, phone), '
      'order_items(id, menu_item_id, quantity, unit_price, status, menu_items(name))',
    );

    if (since != null) {
      query = query.gte('placed_at', since.toUtc().toIso8601String());
    }

    final response = await query.order('placed_at', ascending: false);

    return (response as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single order by ID.
  static Future<Order> fetchOrderById(String orderId) async {
    final response = await SupabaseConfig.client
        .from('orders')
        .select(
          'id, total_amount, status, special_instructions, kot_number, placed_at, '
          'tables(id, table_number), profiles(display_name, phone), '
          'order_items(id, menu_item_id, quantity, unit_price, status, menu_items(id, name, price, veg_type))',
        )
        .eq('id', orderId)
        .single();

    return Order.fromJson(response);
  }

  /// Create a new order with its items.
  static Future<void> createOrder({
    required List<CartItem> cart,
    required String orderType,
    String? tableId,
    String? customerName,
    String? customerPhone,
  }) async {
    final totalAmount =
        cart.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final timestamp = DateTime.now().toUtc().toIso8601String();

    // 1. Handle profile (customer)
    String? profileId;
    if (customerPhone != null && customerPhone.isNotEmpty) {
      final results = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('phone', customerPhone)
          .order('created_at', ascending: false)
          .limit(1);
      
      final existing = (results as List).isNotEmpty ? results.first : null;

      if (existing != null) {
        profileId = existing['id'] as String;
      } else if (customerName != null && customerName.isNotEmpty) {
        final created = await SupabaseConfig.client
            .from('profiles')
            .insert({
              'display_name': customerName,
              'phone': customerPhone,
              'restaurant_id': _defaultRid,
            })
            .select()
            .single();
        profileId = created['id'] as String;
      }
    }

    // 2. Handle effective table for takeaway
    String? effectiveTableId = tableId;

    if (orderType == 'takeaway') {
      // Find the 'Takeout' table for takeaway orders
      final takeoutResults = await SupabaseConfig.client
          .from('tables')
          .select('id')
          .ilike('table_number', 'Takeout%')
          .limit(1);
      final takeoutTable = (takeoutResults as List).isNotEmpty ? takeoutResults.first : null;
      if (takeoutTable != null) {
        effectiveTableId = takeoutTable['id'] as String;
      }
    }

    // 3. Create order (No session management)
    final orderData = await SupabaseConfig.client
        .from('orders')
        .insert({
          'total_amount': totalAmount,
          'table_id': effectiveTableId,
          'session_id': null, // Sessions are no longer maintained
          'user_id': profileId,
          'restaurant_id': _defaultRid,
          'status': 'pending',
          'special_instructions':
              'Waiter POS Order: ${customerName ?? "Guest"}',
          'placed_at': timestamp,
          'last_activity_at': timestamp,
        })
        .select()
        .single();

    final orderId = orderData['id'] as String;

    // 4. Create order items
    final orderItems = cart.map((item) => {
      'order_id': orderId,
      'menu_item_id': item.menuItem.id,
      'quantity': item.quantity,
      'unit_price': item.menuItem.price,
      'status': 'pending',
      'station': 'Main Kitchen',
    }).toList();

    await SupabaseConfig.client.from('order_items').insert(orderItems);

    // 5. Mark table as occupied for dine-in
    if (orderType == 'dine-in' && tableId != null) {
      await SupabaseConfig.client
          .from('tables')
          .update({'status': 'occupied'})
          .eq('id', tableId);
    }
  }

  /// Update an existing order — deletes old items and re-inserts new ones.
  static Future<void> updateOrder({
    required String orderId,
    required List<CartItem> cart,
    required String orderType,
    String? tableId,
    String? customerName,
    String? customerPhone,
  }) async {
    final totalAmount =
        cart.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final timestamp = DateTime.now().toUtc().toIso8601String();

    // Handle session
    String? sessionId;
    String? effectiveTableId = tableId;

    if (orderType == 'takeaway') {
      final takeoutTable = await SupabaseConfig.client
          .from('tables')
          .select('id')
          .ilike('table_number', 'Takeout%')
          .maybeSingle();
      if (takeoutTable != null) {
        effectiveTableId = takeoutTable['id'] as String;
      }
    }

    if (effectiveTableId != null) {
      final activeSession = await SupabaseConfig.client
          .from('table_sessions')
          .select('id')
          .eq('table_id', effectiveTableId)
          .eq('status', 'active')
          .maybeSingle();

      sessionId = activeSession?['id'] as String?;
    }

    // Update the order record
    await SupabaseConfig.client
        .from('orders')
        .update({
          'total_amount': totalAmount,
          'table_id': effectiveTableId,
          'session_id': sessionId,
          'special_instructions':
              'Waiter POS Order: ${customerName ?? "Guest"} [Edited]',
          'last_activity_at': timestamp,
        })
        .eq('id', orderId);

    // Delete old items and re-insert
    await SupabaseConfig.client
        .from('order_items')
        .delete()
        .eq('order_id', orderId);

    final orderItems = cart.map((item) => {
      'order_id': orderId,
      'menu_item_id': item.menuItem.id,
      'quantity': item.quantity,
      'unit_price': item.menuItem.price,
      'status': item.status ?? 'pending',
      'station': 'Main Kitchen',
    }).toList();

    await SupabaseConfig.client.from('order_items').insert(orderItems);
  }
}
