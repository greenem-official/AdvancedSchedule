import 'package:flutter/material.dart';
import 'package:flutter7/api/api_client.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/data/schedule_scope.dart';
import 'package:flutter7/ui/categories_page.dart';
import 'package:flutter7/ui/schedule_page.dart';

class TeacherSearchPage extends StatefulWidget {
  const TeacherSearchPage({super.key});

  @override
  State<TeacherSearchPage> createState() => _TeacherSearchPageState();
}

class _TeacherSearchPageState extends State<TeacherSearchPage> {
  final _searchController = TextEditingController();
  final _api = ScheduleApi();
  bool _isLoading = false;
  List<Map<String, String>> _searchResults = [];
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
    });

    try {
      final results = await _api.searchTeachers(query);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Поиск преподавателя"),
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Введите ФИО преподавателя",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text("Найти"),
                ),
              ],
            ),
          ),

          // Ошибка
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Ошибка: $_error",
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Результаты поиска
          Expanded(
            child: _searchResults.isEmpty && !_isLoading
                ? Center(
              child: Text(
                _error != null
                    ? "Попробуйте другой запрос"
                    : "Введите запрос и нажмите Найти",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final teacher = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  title: Text(teacher['name'] ?? ''),
                  subtitle: Text(
                    teacher['department'] ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleScope(
                          groupId: teacher['id']!,
                          title: teacher['name'],
                          builder: (repo, catRepo) => Scaffold(
                            appBar: AppBar(
                              title: Text(teacher['name'] ?? 'Преподаватель'),
                            ),
                            body: SchedulePageContent(
                              repo: repo,
                              categoryRepo: catRepo,
                              groupId: teacher['id']!,
                              showAppBar: false,
                              scheduleType: ScheduleType.person,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}