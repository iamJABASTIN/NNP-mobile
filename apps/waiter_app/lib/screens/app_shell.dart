import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'new_order_screen.dart';
import 'order_list_screen.dart';
import 'qr_scanner_screen.dart';
import '../services/auth_service.dart';

/// Root shell with bottom navigation: New Order | Orders and center QR FAB.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentTab = 0;
  String? _editingOrderId;
  Map<String, dynamic>? _prefilledData;

  void _switchToOrders() {
    setState(() {
      _currentTab = 1;
      _editingOrderId = null; 
      _prefilledData = null;
    });
  }

  void _switchToPOS() {
    setState(() {
      _currentTab = 0;
      _prefilledData = null;
      _editingOrderId = null;
    });
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _currentTab = 0;
        _editingOrderId = null;
        _prefilledData = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.primaryYellow,
                title: const Text('LOGOUT?', style: TextStyle(fontWeight: FontWeight.w900)),
                content: const Text('Are you sure you want to exit the kitchen?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('CANCEL', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('LOGOUT', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await AuthService.logout();
            }
          },
        ),
        title: Text(
          _editingOrderId != null
              ? 'EDIT ORDER'
              : (_currentTab == 0 ? 'NEW ORDER' : 'ORDER LIST'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (_editingOrderId != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _editingOrderId = null),
            ),
          if (_currentTab == 0 && _editingOrderId == null && _prefilledData == null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.primaryYellow,
              child: const Text(
                'POS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 3,
                  color: AppColors.black,
                ),
              ),
            ),
          if (_currentTab == 0 && _prefilledData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _prefilledData = null),
              tooltip: 'Clear scanned data',
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          NewOrderScreen(
            key: ValueKey('new_order_tab_${_editingOrderId}_${_prefilledData?['tableId']}'),
            editingOrderId: _editingOrderId,
            prefilledData: _prefilledData,
            onOrderComplete: _switchToOrders,
          ),
          OrderListScreen(
            onEdit: (orderId) {
              setState(() {
                _editingOrderId = orderId;
                _prefilledData = null;
                _currentTab = 0;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        backgroundColor: AppColors.primaryYellow,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.black, width: BrutalDecorations.borderWidth),
        ),
        elevation: 0,
        child: const Icon(Icons.qr_code_scanner, color: AppColors.black, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.add_shopping_cart,
              label: 'NEW ORDER',
              isSelected: _currentTab == 0,
              onTap: _switchToPOS,
            ),
            const SizedBox(width: 48), // Space for FAB
            _NavBarItem(
              icon: Icons.receipt_long,
              label: 'ORDERS',
              isSelected: _currentTab == 1,
              onTap: () => setState(() => _currentTab = 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primaryYellow,
                      border: Border.all(color: AppColors.black, width: 2),
                    )
                  : null,
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.black : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 10,
                letterSpacing: isSelected ? 2 : 1,
                color: isSelected ? AppColors.black : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
