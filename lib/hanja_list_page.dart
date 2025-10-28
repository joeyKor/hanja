import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hanja/hanja.dart';
import 'package:hanja/hanja_detail_dialog.dart';

class HanjaListPage extends StatefulWidget {
  const HanjaListPage({super.key});

  @override
  State<HanjaListPage> createState() => _HanjaListPageState();
}

class _HanjaListPageState extends State<HanjaListPage> {
  String _selectedLevel = '4급';
  List<Hanja> _hanjaList = [];

  @override
  void initState() {
    super.initState();
    _loadHanja(_selectedLevel);
  }

  Future<void> _loadHanja(String level) async {
    String fileName;
    switch (level) {
      case '5급':
        fileName = 'assets/hanja_5.json';
        break;
      case '준4급':
        fileName = 'assets/hanja_jun4.json';
        break;
      case '4급':
        fileName = 'assets/hanja_4.json';
        break;
      case '준3급':
        fileName = 'assets/hanja_jun3.json';
        break;
      case '3급':
        fileName = 'assets/hanja_3.json';
        break;
      default:
        return;
    }

    try {
      final String response = await rootBundle.loadString(fileName);
      final data = await json.decode(response) as List;
      // 3. Updated Hanja.fromJson call
      final List<Hanja> hanja = data
          .map((e) => Hanja.fromJson(e, level))
          .toList();
      setState(() {
        _hanjaList = hanja;
      });
    } catch (e) {
      setState(() {
        _hanjaList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = ['5급', '준4급', '4급', '준3급', '3급'];

    return Scaffold(
      appBar: AppBar(title: const Text('급수별 한자'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedLevel,
              isExpanded: true,
              items: levels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLevel = newValue!;
                  _loadHanja(_selectedLevel);
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _hanjaList.isEmpty
                  ? const Center(child: Text('해당 급수는 준비중입니다.'))
                  : ListView.builder(
                      itemCount: _hanjaList.length,
                      itemBuilder: (context, index) {
                        final hanja = _hanjaList[index];
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
