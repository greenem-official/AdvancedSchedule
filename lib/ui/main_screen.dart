import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/ui/categories_page.dart';
import 'package:flutter7/ui/schedule_page.dart';
import 'package:flutter7/ui/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Репозитории создаём один раз
  final ScheduleRepository repo = ScheduleRepository();
  final CategoryRepository categoryRepo = CategoryRepository();

  String currentGroupId = "154481";

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await categoryRepo.addCategory(title: "blacklist");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // SchedulePageContent теперь переиспользуемый
          SchedulePageContent(
            repo: repo,
            categoryRepo: categoryRepo,
            groupId: currentGroupId,
            title: "Расписание группы $currentGroupId",
          ),
          CategoriesPage(categoryRepo: categoryRepo),
          SettingsPage(
            // groupId: currentGroupId,
            // onGroupChanged: (newGroupId) {
            //   setState(() => currentGroupId = newGroupId);
            // },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Расписание"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Категории"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Настройки"),
        ],
      ),
    );
  }
}
