/// Represents a restaurant table from the `tables` table.
class TableInfo {
  final String id;
  final String tableNumber;
  final String status; // 'available', 'occupied', 'reserved'

  const TableInfo({
    required this.id,
    required this.tableNumber,
    required this.status,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      id: json['id'] as String,
      tableNumber: json['table_number']?.toString() ?? '?',
      status: json['status'] as String? ?? 'available',
    );
  }
}
