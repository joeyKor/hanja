import 'package:hanja/ending_dialog.dart';
import 'package:hanja/gosa.dart'; // New import
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
  Gosa? _currentGosa; // New: Current Gosa for quiz
  final TextEditingController _eumController = TextEditingController();
  bool _answerLocked = false;
  int _countdown = 10;
  Timer? _countdownTimer;
  final FocusNode _focusNode = FocusNode();

  final Map<String, List<Hanja>> _allHanjaByLevel = {};
  final List<Gosa> _allGosa = []; // New: List to hold all Gosa data
  final List<Map<String, dynamic>> _sessionIncorrectHanja = [];

  @override
  void initState() {
    super.initState();
    _score = widget.initialScore;
    _questionCount = widget.initialQuestionCount;
    _loadQuizData().then((_) {
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

  Future<void> _loadQuizData() async {
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
      } catch (e) {
        // Ignore errors for now
      }
    }

    // New: Load Gosa data
    try {
      final String response = await rootBundle.loadString('assets/gosa.json');
      final data = await json.decode(response) as List;
      _allGosa.addAll(data.map((e) => Gosa.fromJson(e)));
    } catch (e) {
      print('Error loading gosa.json: $e');
    }
  }

  void _startNewQuestion() {
    _questionCount++;
    setState(() {
      _eumController.clear();
      _answerLocked = false;

      if (_questionCount >= 61 && _questionCount <= 80) {
        // Hanja Eum Sseugi (existing logic)
        _currentHanja = _selectNextHanja();
        _currentGosa = null;
        _countdown = 10; // Existing countdown for Hanja Eum Sseugi
      } else if (_questionCount >= 81 && _questionCount <= 90) {
        // Gosa Seong-eo Sseugi (Request 1)
        _currentGosa = _selectNextGosa();
        _currentHanja = null;
        _countdown = 17; // New countdown for Gosa Seong-eo Sseugi
      } else if (_questionCount >= 91 && _questionCount <= 100) {
        // Gosa Seong-eo Eum Sseugi (Request 2)
        _currentGosa = _selectNextGosa();
        _currentHanja = null;
        _countdown = 19; // New countdown for Gosa Seong-eo Eum Sseugi
      } else if (_questionCount > 100) {
        // End of quiz after 100 questions
        _gameOver();
        return;
      } else {
        // This case should ideally not be reached if QuizPage transitions correctly
        _gameOver();
        return;
      }
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

  Gosa _selectNextGosa() {
    final random = Random();
    return _allGosa[random.nextInt(_allGosa.length)];
  }

  void _handleAnswer() {
    if (_answerLocked) return;

    _countdownTimer?.cancel();

    setState(() {
      _answerLocked = true;
    });

    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('입력 확인'),
          content: Text('입력하신 답: "${_eumController.text}"\n맞습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('다시쓸게요.'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _answerLocked = false; // Unlock for re-entry
                  _startCountdown(); // Restart countdown
                });
                _focusNode.requestFocus(); // Request focus back to TextField
              },
            ),
            TextButton(
              child: const Text('맞아요'),
              onPressed: () {
                Navigator.of(context).pop();
                _processAnswer(); // Proceed with answer checking
              },
            ),
          ],
        );
      },
    );
  }

  void _processAnswer() {
    bool isCorrect = false;
    double points = 0;

    if (_currentHanja != null) {
      // Hanja Eum Sseugi
      isCorrect = (_eumController.text == _currentHanja!.eum);
      points = _getScoreForLevel(_currentHanja!.level);
    } else if (_currentGosa != null) {
      if (_questionCount >= 81 && _questionCount <= 90) {
        // Gosa Seong-eo Sseugi (Request 1)
        isCorrect = (_eumController.text == _currentGosa!.idiom);
        points = 9;
      } else if (_questionCount >= 91 && _questionCount <= 100) {
        // Gosa Seong-eo Eum Sseugi (Request 2)
        isCorrect = (_eumController.text == _currentGosa!.eum);
        points = 15;
      }
    }

    if (isCorrect) {
      setState(() {
        _score += points;
        if (_questionCount == 100) { // Request 3: Bonus for problem #100
          _score += 50; // Bonus points
        }
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        _startNewQuestion();
      });
    } else {
      HapticFeedback.vibrate(); // Vibrate for incorrect answer

      String correctText = '';
      if (_currentHanja != null) {
        _saveIncorrectHanja(_currentHanja!); // Save incorrect Hanja
        correctText = '${_currentHanja!.hoon} ${_currentHanja!.eum}';
      } else if (_currentGosa != null) {
        if (_questionCount >= 81 && _questionCount <= 90) { // Gosa Seong-eo Sseugi
          correctText = '${_currentGosa!.eum} (뜻: ${_currentGosa!.meaning})';
        } else if (_questionCount >= 91 && _questionCount <= 100) { // Gosa Seong-eo Eum Sseugi
          correctText = '${_currentGosa!.eum} (뜻: ${_currentGosa!.meaning})';
        }
      }

      // Show dialog with correct answer if it's a Gosa question from 81 onwards
      if ((_questionCount >= 81 && _currentGosa != null) && correctText.isNotEmpty) {
        // Cancel the current countdown timer as we are showing a dialog
        _countdownTimer?.cancel();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('오답'),
              content: Text('정답은 "$correctText" 입니다.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('확인'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _gameOver(); // Proceed to game over after showing answer
                  },
                ),
              ],
            );
          },
        );
      } else {
        _gameOver(); // If not a Gosa question or no correctText, just game over
      }
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

  Future<void> _unlockAndShowReward() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedImages = prefs.getStringList('unlocked_images') ?? [];

    final allImageNumbers =
        List.generate(70, (index) => (index + 1).toString().padLeft(3, '0'));
    final lockedImages =
        allImageNumbers.where((img) => !unlockedImages.contains(img)).toList();

    if (lockedImages.isEmpty) {
      // All images are unlocked, maybe show a message
      return;
    }

    final random = Random();
    final imageToUnlock = lockedImages[random.nextInt(lockedImages.length)];

    unlockedImages.add(imageToUnlock);
    await prefs.setStringList('unlocked_images', unlockedImages);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('갤러리 해금!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/$imageToUnlock.png'),
              const SizedBox(height: 16),
              Text('$imageToUnlock번 그림을 획득했습니다!'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _gameOver() async {
    if (_questionCount > 100) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const EndingDialog();
        },
      );
    }

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

                    if (_score > 150) {
                      await _unlockAndShowReward();
                    }

                    if (!mounted) return;
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
      await showDialog(
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
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      if (_score > 150) {
        await _unlockAndShowReward();
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
    if (_currentHanja == null && _currentGosa == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String questionText = '';
    String levelText = '';
    Color levelColor = Colors.white;

    if (_currentHanja != null) {
      questionText = _currentHanja!.character;
      levelText = _currentHanja!.level;
      levelColor = _getLevelColor(_currentHanja!.level);
    } else if (_currentGosa != null) {
      if (_questionCount >= 81 && _questionCount <= 90) {
        // Gosa Seong-eo Sseugi
        questionText = _currentGosa!.idiom;
        levelText = '고사성어 쓰기';
        levelColor = Colors.teal;
      } else if (_questionCount >= 91 && _questionCount <= 100) {
        // Gosa Seong-eo Eum Sseugi
        questionText = _currentGosa!.meaning;
        levelText = '고사성어 음 쓰기';
        levelColor = Colors.indigo;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('랭킹 도전 - $_questionCount번째 문제 ($levelText)'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute space evenly
              children: [
                // 급수 (Level)
                Column(
                  children: [
                    const Text('급수', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    Text(
                      levelText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
                // 타이머 (Timer)
                Column(
                  children: [
                    const Text('남은 시간', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
                // 점수 (Score)
                Column(
                  children: [
                    const Text('점수', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    Text(
                      _score.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  questionText,
                  style: TextStyle(
                    fontSize: (_questionCount >= 91 && _questionCount <= 100) ? 24 : 120,
                    color: Colors.white,
                  ),
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
                    decoration: InputDecoration(
                      hintText: (_questionCount >= 81 && _questionCount <= 90)
                          ? '고사성어를 입력하세요'
                          : '음을 입력하세요', // Hint changes based on question type
                      border: const OutlineInputBorder(),
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
