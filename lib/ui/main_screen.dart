import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/ui/categories_page.dart';
import 'package:flutter7/ui/schedule_page.dart';

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
    Widget getCurrentPage() {
      switch (_currentIndex) {
        case 0:
          return SchedulePageContent(
            repo: repo,
            categoryRepo: categoryRepo,
          ); // здесь чистый контент
        case 1:
          return CategoriesPage(categoryRepo: categoryRepo);
      // case 2:
      //   return SettingsPage();
        default:
          return const SizedBox();
      }
    }

    return Scaffold(
      body: getCurrentPage(),
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
