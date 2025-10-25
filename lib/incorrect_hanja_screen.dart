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

class _IncorrectHanjaScreenState extends State<IncorrectHanjaScreen>
    with SingleTickerProviderStateMixin {
  List<IncorrectHanja> _todaysIncorrectHanja = [];
  late TabController _tabController;
  Map<String, double> _dailyAverages = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadIncorrectHanja();
    await _loadDailyAverages();
  }

  Future<void> _loadIncorrectHanja() async {
    final prefs = await SharedPreferences.getInstance();
    final incorrectHanjaListJson = prefs.getStringList('incorrect_hanja') ?? [];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final allIncorrectHanja = incorrectHanjaListJson
        .map((jsonString) => IncorrectHanja.fromJson(json.decode(jsonString)))
        .toList();

    final todaysList =
        allIncorrectHanja.where((hanja) => hanja.date == today).toList();

    setState(() {
      _todaysIncorrectHanja = todaysList;
    });
  }

  Future<void> _loadDailyAverages() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString('daily_scores');
    if (scoresJson == null) return;

    final Map<String, dynamic> scores = json.decode(scoresJson);
    final Map<String, double> averages = {};

    scores.forEach((date, scoresList) {
      final scores = List<double>.from(scoresList);
      if (scores.isNotEmpty) {
        averages[date] = scores.reduce((a, b) => a + b) / scores.length;
      }
    });

    // Sort dates in descending order
    final sortedDates = averages.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final sortedAverages = {for (var k in sortedDates) k: averages[k]!};

    setState(() {
      _dailyAverages = sortedAverages;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오답노트 및 통계'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '오늘 틀린 한자'),
            Tab(text: '일별 평균'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodaysIncorrectHanjaTab(),
          _buildDailyAverageTab(),
        ],
      ),
    );
  }

  Widget _buildTodaysIncorrectHanjaTab() {
    return _todaysIncorrectHanja.isEmpty
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
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Text(
                    hanja.character,
                    style: TextStyle(fontSize: 33, color: Colors.yellow[100]),
                  ),
                  title: RichText(
                    text: TextSpan(
                      style:
                          const TextStyle(fontSize: 17, color: Colors.white),
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
                        return IncorrectHanjaDetailDialog(hanja: hanja);
                      },
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildDailyAverageTab() {
    if (_dailyAverages.isEmpty) {
      return const Center(
        child: Text(
          '아직 랭킹 도전 기록이 없습니다.',
          style: TextStyle(fontSize: 20),
        ),
      );
    }

    return ListView.builder(
      itemCount: _dailyAverages.length,
      itemBuilder: (context, index) {
        final date = _dailyAverages.keys.elementAt(index);
        final average = _dailyAverages[date]!;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              date,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '평균: ${average.toStringAsFixed(1)}점',
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class IncorrectHanjaDetailDialog extends StatelessWidget {
  final IncorrectHanja hanja;

  const IncorrectHanjaDetailDialog({super.key, required this.hanja});

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