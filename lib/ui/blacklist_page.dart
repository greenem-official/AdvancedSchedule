import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/blacklist_repository.dart';
import 'package:flutter7/data/blacklist/blacklist_rule.dart';

class BlacklistPage extends StatefulWidget {
  final BlacklistRepository blacklistRepo;

  const BlacklistPage({super.key, required this.blacklistRepo});

  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  List<BlacklistRule> rules = [];

  @override
  void initState() {
    super.initState();
    loadRules();
  }

  Future<void> loadRules() async {
    rules = await widget.blacklistRepo.getAll();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Управление блеклистом")),
      body: rules.isEmpty
          ? const Center(child: Text("Блеклист пуст"))
          : ListView.builder(
        itemCount: rules.length,
        itemBuilder: (context, i) {
          final r = rules[i];
          return ListTile(
            title: Text("${r.path} = ${r.value}"),
            subtitle: Text(r.op.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await widget.blacklistRepo.removeRule(r.id);
                await loadRules(); // обновляем список
              },
            ),
          );
        },
      ),
    );
  }
}
