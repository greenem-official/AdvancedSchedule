import 'package:flutter/material.dart';
import 'package:flutter7/api/api_client.dart';

class GroupSearchPage extends StatefulWidget {
  const GroupSearchPage({super.key});

  @override
  State<GroupSearchPage> createState() => _GroupSearchPageState();
}

class _GroupSearchPageState extends State<GroupSearchPage> {
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
      final results = await _api.searchGroups(query);

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
        title: const Text("Выбор группы"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Номер или название группы",
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

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Ошибка: $_error",
                style: const TextStyle(color: Colors.red),
              ),
            ),

          Expanded(
            child: _searchResults.isEmpty && !_isLoading
                ? Center(
              child: Text(
                _error != null
                    ? "Попробуйте другой запрос"
                    : "Введите номер группы и нажмите Найти",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final group = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.group,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  title: Text(group['name'] ?? ''),
                  subtitle: group['description']!.isNotEmpty
                      ? Text(
                    group['description'] ?? '',
                    style: const TextStyle(fontSize: 13),
                  )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Возвращаем выбранную группу
                    Navigator.pop(context, group);
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
