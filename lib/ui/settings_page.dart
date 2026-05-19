import 'package:flutter/material.dart';
import 'package:flutter7/api/api_client.dart';
import 'package:flutter7/ui/group_search_page.dart';
import 'package:flutter7/ui/teacher_search_page.dart';

class SettingsPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final ValueChanged<Map<String, String>>? onGroupChanged;

  const SettingsPage({
    super.key,
    required this.groupId,
    this.groupName = '',
    this.onGroupChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Настройки"),
      ),
      body: ListView(
        children: [
          // Текущая группа
          _buildInfoSection(
            title: "Текущая группа",
            value: widget.groupName.isNotEmpty ? widget.groupName : widget.groupId,
            icon: Icons.group,
          ),
          const Divider(height: 1),

          // Выбор группы
          _buildSection(
            title: "Выбрать группу",
            subtitle: "Поиск по номеру или названию группы",
            icon: Icons.group_add,
            onTap: () async {
              final result = await Navigator.push<Map<String, String>>(
                context,
                MaterialPageRoute(
                  builder: (_) => const GroupSearchPage(),
                ),
              );

              if (result != null && mounted) {
                widget.onGroupChanged?.call(result);
                setState(() {}); // обновить отображение
              }
            },
          ),
          const Divider(height: 1),

          // Поиск преподавателя
          _buildSection(
            title: "Поиск преподавателя",
            subtitle: "Найти расписание по ФИО преподавателя",
            icon: Icons.person_search,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherSearchPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      enabled: false,
    );
  }
}
