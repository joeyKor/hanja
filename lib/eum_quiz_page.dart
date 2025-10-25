import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hanja/hanja.dart';
import 'package:hanja/ranking_board_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanja/incorrect_hanja_screen.dart';
import 'package:intl/intl.dart';

class EumQuizPage extends StatefulWidget {
  final double initialScore;
  final int initialQuestionCount;

  const EumQuizPage(
      {super.key, required this.initialScore, required this.initialQuestionCount});

  @override
  State<EumQuizPage> createState() => _EumQuizPageState();
}

class _EumQuizPageState extends State<EumQuizPage> {
  double _score = 0;
  int _questionCount = 0;
  Hanja? _currentHanja;
  final TextEditingController _eumController = TextEditingController();
  bool _answerLocked = false;
  int _countdown = 10;
  Timer? _countdownTimer;
  final FocusNode _focusNode = FocusNode();

  final Map<String, List<Hanja>> _allHanjaByLevel = {};
  final List<Hanja> _allHanja = [];
  final List<Map<String, dynamic>> _sessionIncorrectHanja = [];

  @override
  void initState() {
    super.initState();
    _score = widget.initialScore;
    _questionCount = widget.initialQuestionCount;
    _loadAllHanja().then((_) {
      _startNewQuestion();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _eumController.dispose();
    _focusNode.dispose();
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

    for (var level in levels.keys) {
      try {
        final String response = await rootBundle.loadString(levels[level]!);
        final data = await json.decode(response) as List;
        final hanjaList = data.map((e) => Hanja.fromJson(e, level)).toList();
        _allHanjaByLevel[level] = hanjaList;
        _allHanja.addAll(hanjaList);
      } catch (e) {
        // Ignore errors for now
      }
    }
  }

  void _startNewQuestion() {
    _questionCount++;
    setState(() {
      _currentHanja = _selectNextHanja();
      _eumController.clear();
      _answerLocked = false;
      _countdown = 10;
    });
    _focusNode.requestFocus();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _gameOver();
          timer.cancel();
        }
      });
    });
  }

  Hanja _selectNextHanja() {
    final random = Random();
    final double probability = random.nextDouble();

    String selectedLevel;
    if (probability < 0.1) {
      selectedLevel = '5급';
    } else if (probability < 0.35) {
      selectedLevel = '준4급';
    } else if (probability < 0.60) {
      selectedLevel = '4급';
    } else if (probability < 0.80) {
      selectedLevel = '준3급';
    } else {
      selectedLevel = '3급';
    }

    final hanjaList = _allHanjaByLevel[selectedLevel]!;
    return hanjaList[random.nextInt(hanjaList.length)];
  }

  void _handleAnswer() {
    if (_answerLocked) return;

    _countdownTimer?.cancel();

    setState(() {
      _answerLocked = true;
    });

    if (_eumController.text == _currentHanja!.eum) {
      setState(() {
        _score += _getScoreForLevel(_currentHanja!.level);
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        _startNewQuestion();
      });
    } else {
      HapticFeedback.vibrate();
      if (_currentHanja != null) {
        _saveIncorrectHanja(_currentHanja!);
      }
      _gameOver();
    }
  }

  double _getScoreForLevel(String level) {
    switch (level) {
      case '5급':
        return 3;
      case '준4급':
        return 4;
      case '4급':
        return 5;
      case '준3급':
        return 6;
      case '3급':
        return 7;
      default:
        return 1;
    }
  }

  Future<void> _saveIncorrectHanja(Hanja hanja) async {
    final incorrectHanjaData = {
      'character': hanja.character,
      'hoon': hanja.hoon,
      'eum': hanja.eum,
      'level': hanja.level,
    };
    if (!_sessionIncorrectHanja.any(
      (item) => item['character'] == hanja.character,
    )) {
      _sessionIncorrectHanja.add(incorrectHanjaData);
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final incorrectHanja = IncorrectHanja(
      character: hanja.character,
      hoon: hanja.hoon,
      eum: hanja.eum,
      level: hanja.level,
      date: today,
    );

    final incorrectHanjaListJson = prefs.getStringList('incorrect_hanja') ?? [];

    final isAlreadySaved = incorrectHanjaListJson.any((jsonString) {
      try {
        final savedHanja = IncorrectHanja.fromJson(json.decode(jsonString));
        return savedHanja.character == incorrectHanja.character &&
            savedHanja.date == today;
      } catch (e) {
        return false;
      }
    });

    if (!isAlreadySaved) {
      incorrectHanjaListJson.add(json.encode(incorrectHanja.toJson()));
      await prefs.setStringList('incorrect_hanja', incorrectHanjaListJson);
    }
  }

  Future<void> _saveScore(double score) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final scoresJson = prefs.getString('daily_scores');
    Map<String, dynamic> scores =
        scoresJson != null ? json.decode(scoresJson) : {};

    List<double> todayScores =
        scores.containsKey(today) ? List<double>.from(scores[today]) : [];
    todayScores.add(score);
    scores[today] = todayScores;

    await prefs.setString('daily_scores', json.encode(scores));
  }

  Future<void> _gameOver() async {
    await _saveScore(_score);
    final rankingsRef = FirebaseFirestore.instance.collection('rankings');
    final querySnapshot = await rankingsRef
        .orderBy('score', descending: true)
        .limit(50)
        .get();
    final rankings = querySnapshot.docs;

    bool isTop50 = false;
    if (_score > 0 &&
        (rankings.length < 50 || _score > rankings.last.get('score'))) {
      isTop50 = true;
    }

    if (isTop50) {
      final nameController = TextEditingController();
      int rank = 1;
      for (final doc in rankings) {
        final data = doc.data();
        if ((data['score'] ?? 0) > _score) {
          rank++;
        }
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('축하합니다! 50위 안에 드셨습니다!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentHanja != null) ...[
                  Text(
                    _currentHanja!.character,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentHanja!.hoon} ${_currentHanja!.eum} (${_currentHanja!.level})',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('최종 점수: ${_score.toStringAsFixed(1)}'),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '이름을 입력하세요'),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('등록'),
                onPressed: () async {
                  final name = nameController.text;
                  if (name.isNotEmpty) {
                    await rankingsRef.add({
                      'name': name,
                      'score': _score,
                      'timestamp': FieldValue.serverTimestamp(),
                      'incorrectHanja': _sessionIncorrectHanja,
                    });

                    if (rankings.length == 50) {
                      await rankingsRef.doc(rankings.last.id).delete();
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RankingBoardPage(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('이름을 입력해주세요.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('게임 종료'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentHanja != null) ...[
                  Text(
                    _currentHanja!.character,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentHanja!.hoon} ${_currentHanja!.eum} (${_currentHanja!.level})',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('최종 점수: ${_score.toStringAsFixed(1)}'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('확인'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case '5급':
        return Colors.green;
      case '준4급':
        return Colors.blue;
      case '4급':
        return Colors.orange;
      case '준3급':
        return Colors.purple;
      case '3급':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentHanja == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('랭킹 도전 - $_questionCount번째 문제 (음쓰기)'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: [
                Text(
                  '점수: ${_score.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentHanja!.level,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getLevelColor(_currentHanja!.level),
                  ),
                ),
              ],
            ),
            Text(
              '$_countdown',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _currentHanja!.character,
                  style: const TextStyle(fontSize: 120, color: Colors.white),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _eumController,
                    focusNode: _focusNode,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30),
                    decoration: const InputDecoration(
                      hintText: '음을 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _handleAnswer,
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
