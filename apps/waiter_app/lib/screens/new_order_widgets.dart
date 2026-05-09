import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../models/table_info.dart';
import '../widgets/brutal_card.dart';
import '../widgets/brutal_button.dart';
import '../widgets/brutal_text_field.dart';
import '../widgets/quantity_stepper.dart';

/// Form for Order Details (Type, Table, Customer) - used inside Checkout Modal.
class OrderDetailsForm extends StatelessWidget {
  final String type;
  final ValueChanged<String> onTypeChanged;
  final List<TableInfo> tables;
  final String? selectedTableId;
  final ValueChanged<String?> onTableChanged;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final bool isPrefilled;

  const OrderDetailsForm({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.tables,
    required this.selectedTableId,
    required this.onTableChanged,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.isPrefilled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
          // Inline Toggle
          Container(
            decoration: BoxDecoration(color: AppColors.background, border: Border.all(color: AppColors.black, width: 2)),
            padding: const EdgeInsets.all(2),
            height: 36,
            child: Row(
              children: [
                _CompactToggleBtn(
                  active: type == 'dine-in', 
                  label: 'DINE-IN', 
                  onTap: () => onTypeChanged('dine-in')
                ),
                _CompactToggleBtn(
                  active: type == 'takeaway', 
                  label: 'TAKEAWAY', 
                  onTap: () => onTypeChanged('takeaway')
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Inline Details
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (type == 'dine-in') ...[
                  Expanded(
                    flex: 3,
                    child: isPrefilled
                        ? Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              border: Border.all(color: AppColors.black, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'TABLE ${tables.firstWhere((t) => t.id == selectedTableId, orElse: () => const TableInfo(id: '', tableNumber: '?', status: '')).tableNumber}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2), color: AppColors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedTableId,
                                hint: Text('TABLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.black.withAlpha(64))),
                                items: tables.map((t) => DropdownMenuItem(value: t.id, child: Text('T-${t.tableNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)))).toList(),
                                onChanged: onTableChanged,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 4,
                  child: BrutalTextField(
                    hintText: 'Customer Name',
                    controller: nameCtrl,
                    readOnly: isPrefilled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          BrutalTextField(
            hintText: 'Mobile Number (Optional)',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            readOnly: isPrefilled,
          ),
        ],
      );
    }
  }

/// A modern bottom sheet for final checkout.
class CheckoutDetailsModal extends StatelessWidget {
  final String type;
  final ValueChanged<String> onTypeChanged;
  final List<TableInfo> tables;
  final String? selectedTableId;
  final ValueChanged<String?> onTableChanged;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final bool isPrefilled;
  final VoidCallback onConfirm;
  final bool isSubmitting;

  const CheckoutDetailsModal({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.tables,
    required this.selectedTableId,
    required this.onTableChanged,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.isPrefilled,
    required this.onConfirm,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.black, width: 4)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ORDER DETAILS', style: BrutalText.heading),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OrderDetailsForm(
              type: type,
              onTypeChanged: onTypeChanged,
              tables: tables,
              selectedTableId: selectedTableId,
              onTableChanged: onTableChanged,
              nameCtrl: nameCtrl,
              phoneCtrl: phoneCtrl,
              isPrefilled: isPrefilled,
            ),
            const SizedBox(height: 24),
            BrutalButton(
              label: isSubmitting ? 'PLACING ORDER...' : 'CONFIRM & SUBMIT',
              icon: isSubmitting ? null : Icons.check_circle_outline,
              isLoading: isSubmitting,
              backgroundColor: AppColors.black,
              textColor: AppColors.white,
              onPressed: isSubmitting ? null : onConfirm,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _CompactToggleBtn extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;
  const _CompactToggleBtn({required this.active, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: active ? AppColors.black : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 10, 
              letterSpacing: 1.5, 
              color: active ? AppColors.white : AppColors.black
            ),
          ),
        ),
      ),
    );
  }
}

/// Search bar with live dropdown results.
class MenuSearchSection extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String query;
  final List<MenuItem> results;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MenuItem> onItemTap;
  final bool isEmptyState;
  
  const MenuSearchSection({
    super.key, 
    required this.searchCtrl, 
    required this.query, 
    required this.results, 
    required this.onQueryChanged, 
    required this.onItemTap,
    this.isEmptyState = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrutalTextField(
          hintText: 'Search menu items...',
          controller: searchCtrl,
          prefix: const Icon(Icons.search, color: AppColors.textMuted),
          suffix: query.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { searchCtrl.clear(); onQueryChanged(''); }) : null,
          onChanged: onQueryChanged,
        ),
        if (results.isNotEmpty)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BrutalDecorations.card,
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: AppColors.white,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(height: 0, thickness: 2, color: AppColors.black),
                  itemBuilder: (_, i) => SearchResultTile(
                    item: results[i],
                    onTap: () => onItemTap(results[i]),
                  ),
                ),
              ),
            ),
          )
        else if (isEmptyState)
          const Expanded(
            child: Center(
              child: Text(
                'SEARCH TO ADD ITEMS',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.textMuted),
              ),
            ),
          ),
      ],
    );
  }
}

/// A single search result tile.
class SearchResultTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  const SearchResultTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 14, height: 14, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(border: Border.all(color: item.isVeg ? AppColors.success : AppColors.danger, width: 2)),
            child: Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: item.isVeg ? AppColors.success : AppColors.danger))),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name.toUpperCase(), style: BrutalText.body),
            if (item.categoryName != null) Text(item.categoryName!.toUpperCase(), style: BrutalText.caption),
          ])),
          Text('₹${item.price.toStringAsFixed(0)}', style: BrutalText.price),
        ]),
      ),
    );
  }
}

/// Collapsible Cart items list.
class CollapsibleCartSection extends StatelessWidget {
  final List<CartItem> cart;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(int index, int qty) onQuantity;
  final void Function(int index) onRemove;
  
  const CollapsibleCartSection({
    super.key, 
    required this.cart, 
    required this.isExpanded,
    required this.onToggle,
    required this.onQuantity, 
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.black, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (Tappable)
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                      const SizedBox(width: 8),
                      Text('CURRENT ORDER', style: BrutalText.heading.copyWith(fontSize: 16)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: AppColors.primaryYellow,
                    child: Text('${cart.length} ITEMS', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded List
          if (isExpanded)
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                shrinkWrap: true,
                itemCount: cart.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CartItemTile(item: cart[i], onQuantity: (q) => onQuantity(i, q), onRemove: () => onRemove(i)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single cart item row.
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;
  const CartItemTile({super.key, required this.item, required this.onQuantity, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return BrutalCard(
      hasShadow: false, 
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(item.menuItem.name.toUpperCase(), style: BrutalText.body),
                const SizedBox(height: 4),
                Text('₹${item.menuItem.price.toStringAsFixed(0)} per unit', style: BrutalText.caption),
              ]
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuantityStepper(quantity: item.quantity, onChanged: onQuantity),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRemove, 
                    child: const Icon(Icons.delete_outline, size: 24, color: AppColors.danger)
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('₹${item.lineTotal.toStringAsFixed(0)}', style: BrutalText.price),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom footer with total + submit.
class OrderFooter extends StatelessWidget {
  final double total;
  final bool isSubmitting;
  final bool success;
  final bool disabled;
  final VoidCallback onSubmit;
  const OrderFooter({super.key, required this.total, required this.isSubmitting, required this.success, required this.disabled, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      decoration: const BoxDecoration(color: AppColors.black, border: Border(top: BorderSide(color: AppColors.black, width: 3))),
      child: SafeArea(top: false, bottom: false, child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('TOTAL AMOUNT', style: BrutalText.label.copyWith(color: AppColors.white.withAlpha(102))),
          const SizedBox(height: 2),
          Text('₹${total.toStringAsFixed(0)}', style: BrutalText.bigPrice),
        ])),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: BrutalButton(
            label: success ? 'ORDER PLACED!' : isSubmitting ? 'PROCESSING...' : 'CONTINUE',
            icon: success ? Icons.check_circle : isSubmitting ? null : Icons.arrow_forward,
            isLoading: isSubmitting,
            backgroundColor: success ? AppColors.success : AppColors.primaryYellow,
            textColor: success ? AppColors.white : AppColors.black,
            shadowColor: AppColors.white,
            onPressed: disabled ? null : onSubmit,
          ),
        ),
      ])),
    );
  }
}
