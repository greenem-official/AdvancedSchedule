import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/data/settings_storage.dart';
import 'package:flutter7/ui/categories_page.dart';
import 'package:flutter7/ui/schedule_page.dart';
import 'package:flutter7/ui/settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final ScheduleRepository repo = ScheduleRepository();
  final CategoryRepository categoryRepo = CategoryRepository();
  final SettingsStorage settingsStorage = SettingsStorage();

  String currentGroupId = "154481";
  String currentGroupName = "";
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Загружаем сохраненную группу
    final savedGroup = await settingsStorage.loadGroup();
    if (savedGroup != null) {
      currentGroupId = savedGroup['id']!;
      currentGroupName = savedGroup['name']!;
    }

    // Инициализируем категории
    await categoryRepo.addCategory(title: "blacklist");

    if (mounted) {
      setState(() {
        isInitialized = true;
      });
    }
  }

  void _onGroupChanged(Map<String, String> group) {
    setState(() {
      currentGroupId = group['id']!;
      currentGroupName = group['name']!;
    });

    // Сохраняем выбор
    settingsStorage.saveGroup(group);
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SchedulePageContent(
            repo: repo,
            categoryRepo: categoryRepo,
            groupId: currentGroupId,
            title: currentGroupName.isNotEmpty
                ? currentGroupName
                : "Группа $currentGroupId",
          ),
          CategoriesPage(categoryRepo: categoryRepo),
          SettingsPage(
            groupId: currentGroupId,
            groupName: currentGroupName,
            onGroupChanged: _onGroupChanged,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Расписание"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Категории"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Настройки"),
        ],
      ),
    );
  }
}