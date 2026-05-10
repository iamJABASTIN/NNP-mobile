import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import '../order_service.dart';
import '../../models/cart_item.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  void initialize() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      // Check if any result is not 'none'
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        syncPendingOrders();
      }
    });
    
    // Initial check
    syncPendingOrders();
  }

  Future<void> syncPendingOrders() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await DatabaseService.getPendingOrders();
      if (pending.isEmpty) return;

      print('Starting sync for ${pending.length} orders...');

      for (var orderData in pending) {
        final id = orderData['id'] as int;
        try {
          final cartList = jsonDecode(orderData['cart_json']) as List;
          final cart = cartList.map((i) => CartItem.fromJson(i as Map<String, dynamic>)).toList();

          await OrderService.createOrder(
            cart: cart,
            orderType: orderData['order_type'],
            tableId: orderData['table_id'],
            customerName: orderData['customer_name'],
            customerPhone: orderData['customer_phone'],
          );

          await DatabaseService.markAsSynced(id);
          print('Successfully synced order $id');
        } catch (e) {
          print('Sync failed for order $id: $e');
          // We don't mark as failed immediately if it's a network error, 
          // but for validation errors we might. For now just let it retry.
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
