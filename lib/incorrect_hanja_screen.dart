import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class IncorrectHanja {
  final String character;
  final String hoon;
  final String eum;
  final String level;
  final String date;

  IncorrectHanja({
    required this.character,
    required this.hoon,
    required this.eum,
    required this.level,
    required this.date,
  });

  factory IncorrectHanja.fromJson(Map<String, dynamic> json) {
    return IncorrectHanja(
      character: json['character'],
      hoon: json['hoon'],
      eum: json['eum'],
      level: json['level'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character': character,
      'hoon': hoon,
      'eum': eum,
      'level': level,
      'date': date,
    };
  }
}

class IncorrectHanjaScreen extends StatefulWidget {
  const IncorrectHanjaScreen({super.key});

  @override
  State<IncorrectHanjaScreen> createState() => _IncorrectHanjaScreenState();
}

class _IncorrectHanjaScreenState extends State<IncorrectHanjaScreen> {
  List<IncorrectHanja> _todaysIncorrectHanja = [];

  @override
  void initState() {
    super.initState();
    _loadIncorrectHanja();
  }

  Future<void> _loadIncorrectHanja() async {
    final prefs = await SharedPreferences.getInstance();
    final incorrectHanjaListJson = prefs.getStringList('incorrect_hanja') ?? [];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final allIncorrectHanja = incorrectHanjaListJson
        .map((jsonString) => IncorrectHanja.fromJson(json.decode(jsonString)))
        .toList();

    final todaysList = allIncorrectHanja.where((hanja) => hanja.date == today).toList();

    setState(() {
      _todaysIncorrectHanja = todaysList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘 틀린 한자'), centerTitle: true),
      body: _todaysIncorrectHanja.isEmpty
          ? const Center(
              child: Text(
                '오늘 틀린 한자가 없습니다.',
                style: TextStyle(fontSize: 20),
              ),
            )
          : ListView.builder(
              itemCount: _todaysIncorrectHanja.length,
              itemBuilder: (context, index) {
                final hanja = _todaysIncorrectHanja[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Text(
                      hanja.character,
                      style: TextStyle(fontSize: 33, color: Colors.yellow[100]),
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 17, color: Colors.white),
                        children: <TextSpan>[
                          TextSpan(text: '${hanja.hoon} '),
                          TextSpan(
                            text: hanja.eum,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Text('급수: ${hanja.level}'),
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
    );
  }
}

class HanjaDetailDialog extends StatelessWidget {
  final IncorrectHanja hanja;

  const HanjaDetailDialog({super.key, required this.hanja});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              hanja.character,
              style: const TextStyle(fontSize: 100, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 24),
            Text(
              '급수: ${hanja.level}',
              style: const TextStyle(fontSize: 22, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              '${hanja.hoon} ${hanja.eum}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}