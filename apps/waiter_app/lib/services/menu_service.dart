import '../core/supabase_config.dart';
import '../models/menu_item.dart';
import '../models/table_info.dart';

/// Service for fetching menu items and tables from Supabase.
class MenuService {
  static Future<List<MenuItem>> fetchAvailableItems() async {
    final response = await SupabaseConfig.client
        .from('menu_items')
        .select('id, name, price, is_available, veg_type')
        .eq('is_available', true)
        .eq('is_deleted', false);

    return (response as List)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<TableInfo>> fetchTables() async {
    final response = await SupabaseConfig.client
        .from('tables')
        .select('id, table_number, status')
        .order('table_number');

    return (response as List)
        .map((e) => TableInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
