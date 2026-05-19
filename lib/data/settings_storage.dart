import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const _groupIdKey = 'selected_group_id';
  static const _groupNameKey = 'selected_group_name';
  static const _groupDescriptionKey = 'selected_group_description';

  Future<void> saveGroup(Map<String, String> group) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupIdKey, group['id'] ?? '');
    await prefs.setString(_groupNameKey, group['name'] ?? '');
    await prefs.setString(_groupDescriptionKey, group['description'] ?? '');
  }

  Future<Map<String, String>?> loadGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_groupIdKey);
    final name = prefs.getString(_groupNameKey);

    if (id != null && name != null) {
      return {
        'id': id,
        'name': name,
        'description': prefs.getString(_groupDescriptionKey) ?? '',
      };
    }
    return null;
  }
}