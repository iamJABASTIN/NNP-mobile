import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/brutal_card.dart';
import '../widgets/brutal_button.dart';

/// Order List screen — mirrors OrderList.jsx with expandable detail view.
class OrderListScreen extends StatefulWidget {
  final void Function(String orderId)? onEdit;

  const OrderListScreen({super.key, this.onEdit});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final since = DateTime(now.year, now.month, now.day);
      _orders = await OrderService.fetchOrders(since: since);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = local.hour > 12 ? local.hour - 12 : local.hour;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Text(
          'LOADING ORDERS...',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        _buildHeader(),
        // Content
        Expanded(
          child: _orders.isEmpty ? _buildEmptyState() : _buildOrderList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ORDER LIST', style: BrutalText.heading),
                  const SizedBox(height: 2),
                  Text("TODAY'S ORDERS", style: BrutalText.label),
                ],
              ),
              GestureDetector(
                onTap: _fetchOrders,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BrutalDecorations.card,
                  child: const Icon(Icons.refresh, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: BrutalCard(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.black.withAlpha(51),
            ),
            const SizedBox(height: 16),
            Text('NO ORDERS FOUND', style: BrutalText.heading),
            const SizedBox(height: 4),
            Text(
              'ORDERS WILL APPEAR HERE ONCE PLACED',
              style: BrutalText.label,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final isExpanded = _expandedId == order.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _OrderCard(
            order: order,
            isExpanded: isExpanded,
            onTap: () =>
                setState(() => _expandedId = isExpanded ? null : order.id),
            onEdit: widget.onEdit != null
                ? () => widget.onEdit!(order.id)
                : null,
            formatTime: _formatTime,
          ),
        );
      },
    );
  }
}

/// A single expandable order card.
class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final String Function(DateTime?) formatTime;

  const _OrderCard({
    required this.order,
    required this.isExpanded,
    required this.onTap,
    this.onEdit,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BrutalDecorations.card,
        child: Column(
          children: [
            // Summary row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.kotNumber ?? order.id.substring(0, 8)}',
                          style: BrutalText.body,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatTime(order.placedAt),
                          style: BrutalText.caption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'T-${order.tableNumber ?? '?'}',
                        style: BrutalText.body,
                      ),
                      Text(
                        order.customerName ?? 'Guest',
                        style: BrutalText.caption,
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: BrutalText.price,
                      ),
                      Text(
                        '${order.items.length} ITEMS',
                        style: BrutalText.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded detail
            if (isExpanded) ...[
              Container(height: 2, color: AppColors.black.withAlpha(26)),
              Container(
                color: AppColors.primaryYellow.withAlpha(26),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ORDER ITEMS', style: BrutalText.label),
                        if (order.customerPhone != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            color: AppColors.black,
                            child: Text(
                              'PHONE: ${order.customerPhone}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 2,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Item chips in a wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: order.items
                          .map((item) => _OrderItemChip(item: item))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    // Notes
                    if (order.specialInstructions != null &&
                        order.specialInstructions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'NOTE: ${order.specialInstructions}',
                          style: BrutalText.caption,
                        ),
                      ),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onEdit != null)
                          BrutalButton(
                            label: 'Edit Order',
                            icon: Icons.edit,
                            isCompact: true,
                            backgroundColor: AppColors.black,
                            textColor: AppColors.white,
                            shadowColor: AppColors.primaryYellow,
                            onPressed: onEdit,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A chip displaying one order item.
class _OrderItemChip extends StatelessWidget {
  final OrderItemDetail item;
  const _OrderItemChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('×${item.quantity}', style: BrutalText.caption),
              const SizedBox(width: 12),
              Text(
                '₹${item.unitPrice.toStringAsFixed(0)}',
                style: BrutalText.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
