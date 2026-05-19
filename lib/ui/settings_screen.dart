import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/ui/categories_page.dart';
import 'package:flutter7/ui/schedule_page.dart';
import 'package:flutter7/ui/teacher_search_page.dart';

class SettingsPage extends StatefulWidget {
  final String groupId;
  final ValueChanged<String>? onGroupChanged;

  const SettingsPage({
    super.key,
    required this.groupId,
    this.onGroupChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Настройки"),
      ),
      body: ListView(
        children: [
          // Секция: Поиск преподавателя
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

          // Здесь будут другие настройки позже
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
}
