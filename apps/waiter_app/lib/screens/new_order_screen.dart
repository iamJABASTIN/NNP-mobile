import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../models/table_info.dart';
import '../services/menu_service.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../services/offline/database_service.dart';
import '../services/offline/offline_sync_service.dart';
import 'new_order_widgets.dart';
import 'dart:convert';

/// POS screen for creating / editing orders — search focused.
class NewOrderScreen extends StatefulWidget {
  final String? editingOrderId;
  final Map<String, dynamic>? prefilledData;
  final VoidCallback? onOrderComplete;

  const NewOrderScreen({
    super.key, 
    this.editingOrderId, 
    this.prefilledData,
    this.onOrderComplete,
  });

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  List<MenuItem> _menuItems = [];
  List<TableInfo> _tables = [];
  final List<CartItem> _cart = [];
  bool _loading = true;
  bool _isSubmitting = false;
  bool _success = false;

  String _orderType = 'dine-in';
  String? _selectedTableId;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isCartExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeFromPrefill();
    _fetchData();
  }

  void _initializeFromPrefill() {
    if (widget.prefilledData != null) {
      _selectedTableId = widget.prefilledData!['tableId'] as String?;
      _nameCtrl.text = widget.prefilledData!['customerName'] as String? ?? '';
      _phoneCtrl.text = widget.prefilledData!['customerPhone'] as String? ?? '';
      _orderType = _selectedTableId != null ? 'dine-in' : 'takeaway';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    bool hasLocalData = false;

    try {
      // 1. Load from local cache first (Instant)
      final localItems = await DatabaseService.getMenuItems();
      final localTables = await DatabaseService.getTables();

      if (localItems.isNotEmpty) {
        setState(() {
          _menuItems = localItems;
          _tables = localTables;
          _loading = false; // Stop showing the main loader early
        });
        hasLocalData = true;
      }
    } catch (e) {
      print('Error loading local cache: $e');
    }

    try {
      // 2. Try to refresh from network
      final results = await Future.wait([
        MenuService.fetchAvailableItems(),
        MenuService.fetchTables(),
        if (widget.editingOrderId != null)
          OrderService.fetchOrderById(widget.editingOrderId!),
      ]).timeout(const Duration(seconds: 4));

      if (mounted) {
        setState(() {
          _menuItems = results[0] as List<MenuItem>;
          _tables = results[1] as List<TableInfo>;

          // Update local cache with fresh data for next time
          DatabaseService.saveMenuItems(_menuItems);
          DatabaseService.saveTables(_tables);

          if (widget.editingOrderId != null && results.length > 2) {
            final order = results[2] as Order;
            _cart.clear();
            for (final item in order.items) {
              _cart.add(CartItem(
                menuItem: MenuItem(
                  id: item.menuItemId,
                  name: item.name,
                  price: item.unitPrice,
                  vegType: item.vegType,
                  isAvailable: true,
                ),
                quantity: item.quantity,
                status: item.status,
              ));
            }
            _nameCtrl.text = order.customerName ?? '';
            _phoneCtrl.text = order.customerPhone ?? '';
            _selectedTableId = order.tableId;
            _orderType = order.tableId != null ? 'dine-in' : 'takeaway';
          }
          _loading = false;
        });
      }
    } catch (e) {
      print('Network fetch failed: $e');
      // ONLY show the error snackbar if we have NO local data to show
      if (!hasLocalData && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offline: Using local menu ($e)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MenuItem> get _filtered => _searchQuery.isEmpty
      ? []
      : _menuItems
          .where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  void _addToCart(MenuItem item) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.menuItem.id == item.id);
      if (idx != -1) {
        _cart[idx].quantity++;
      } else {
        _cart.add(CartItem(menuItem: item));
        _isCartExpanded = true; // Auto-expand cart when first item added
      }
      _searchCtrl.clear();
      _searchQuery = '';
    });
  }

  double get _total => _cart.fold(0.0, (s, i) => s + i.lineTotal);

  Future<void> _submit() async {
    if (_cart.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _success = false;
    });

    try {
      if (widget.editingOrderId != null) {
        // 1. Editing existing order (Online required for edits)
        await OrderService.updateOrder(
          orderId: widget.editingOrderId!,
          cart: _cart,
          orderType: _orderType,
          tableId: _selectedTableId,
          customerName: _nameCtrl.text,
          customerPhone: _phoneCtrl.text,
        );
      } else {
        // 2. New Order (Offline-First Queueing)
        final String encodedCart = jsonEncode(
          _cart.map((item) => item.toJson()).toList(),
        );

        await DatabaseService.queueOrder(
          tableId: _selectedTableId,
          orderType: _orderType,
          customerName: _nameCtrl.text.isEmpty ? 'Guest' : _nameCtrl.text,
          customerPhone: _phoneCtrl.text,
          cartJson: encodedCart,
          totalAmount: _total,
        );

        // Try to sync in background immediately
        OfflineSyncService().syncPendingOrders();
      }

      // 3. Success Handling
      _success = true;
      
      if (mounted) {
        // Clear all fields for next order
        setState(() {
          _cart.clear();
          _nameCtrl.clear();
          _phoneCtrl.clear();
          _selectedTableId = null;
          _isCartExpanded = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ORDER PLACED SUCCESSFULLY!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Smoothly notify parent to switch tabs or refresh
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) widget.onOrderComplete?.call();
        });
      }
    } catch (e) {
      print('Submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission Failed: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showCheckoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => CheckoutDetailsModal(
          type: _orderType,
          onTypeChanged: (t) => setState(() { _orderType = t; setModalState(() {}); }),
          tables: _tables,
          selectedTableId: _selectedTableId,
          onTableChanged: (t) => setState(() { _selectedTableId = t; setModalState(() {}); }),
          nameCtrl: _nameCtrl,
          phoneCtrl: _phoneCtrl,
          isPrefilled: widget.prefilledData != null,
          isSubmitting: _isSubmitting,
          onConfirm: () async {
            // 1. Validation before loading
            if (_orderType == 'dine-in' && _selectedTableId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PLEASE SELECT A TABLE NUMBER'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            // 2. Set loading state in modal
            setModalState(() { _isSubmitting = true; }); 
            
            // 3. Execute submission
            await _submit();
            
            // 4. Handle result
            if (mounted) {
              if (_success) {
                Navigator.pop(context); // Close modal on success
              } else {
                // If it failed (e.g. database error), reset button
                setModalState(() { _isSubmitting = false; });
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Text('INITIALIZING POS...', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 6, color: AppColors.textMuted)),
      );
    }

    return Column(
      children: [
        // 1. Main Search Area (Expanded)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: MenuSearchSection(
              searchCtrl: _searchCtrl,
              query: _searchQuery,
              results: _filtered,
              onQueryChanged: (v) => setState(() => _searchQuery = v),
              onItemTap: _addToCart,
              isEmptyState: _searchQuery.isEmpty && _cart.isEmpty,
            ),
          ),
        ),
        
        // 2. Collapsible Cart
        if (_cart.isNotEmpty)
          CollapsibleCartSection(
            cart: _cart,
            isExpanded: _isCartExpanded,
            onToggle: () => setState(() => _isCartExpanded = !_isCartExpanded),
            onQuantity: (i, q) => setState(() => _cart[i].quantity = q),
            onRemove: (i) => setState(() => _cart.removeAt(i)),
          ),

        // 3. Footer
        OrderFooter(
          total: _total,
          isSubmitting: _isSubmitting,
          success: _success,
          disabled: _cart.isEmpty || _isSubmitting,
          onSubmit: _showCheckoutModal,
        ),
      ],
    );
  }
}
