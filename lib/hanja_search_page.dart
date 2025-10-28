import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hanja/hanja.dart';
import 'package:hanja/hanja_detail_dialog.dart';

class HanjaSearchPage extends StatefulWidget {
  const HanjaSearchPage({super.key});

  @override
  State<HanjaSearchPage> createState() => _HanjaSearchPageState();
}

class _HanjaSearchPageState extends State<HanjaSearchPage> {
  List<Hanja> _allHanja = [];
  List<Hanja> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllHanja();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHanja() async {
    final levels = {
      '5급': 'assets/hanja_5.json',
      '준4급': 'assets/hanja_jun4.json',
      '4급': 'assets/hanja_4.json',
      '준3급': 'assets/hanja_jun3.json',
      '3급': 'assets/hanja_3.json',
    };

    List<Hanja> allHanja = [];
    for (var level in levels.keys) {
      try {
        final String response = await rootBundle.loadString(levels[level]!);
        final data = await json.decode(response) as List;
        allHanja.addAll(data.map((e) => Hanja.fromJson(e, level)));
      } catch (e) {
        // Ignore errors for now
      }
    }

    setState(() {
      _allHanja = allHanja;
      _searchResults = allHanja;
    });
  }

  void _searchHanja(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allHanja;
      });
      return;
    }

    final results = _allHanja.where((hanja) {
      return hanja.eum.contains(query);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('한자 검색'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _searchHanja,
              decoration: InputDecoration(
                hintText: '음으로 검색 (예: 가)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchHanja('');
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final hanja = _searchResults[index];
                  return Card(
                    child: ListTile(
                      leading: Text(
                        hanja.character,
                        style: TextStyle(
                          fontSize: 33,
                          color: Colors.yellow[100],
                        ),
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                          ),
                          children: <TextSpan>[
                            TextSpan(text: '${hanja.hoon} '),
                            TextSpan(
                              text: hanja.eum,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Text(hanja.level),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return HanjaDetailDialog(hanja: hanja);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
