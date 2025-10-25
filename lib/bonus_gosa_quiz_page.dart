
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hanja/gosa_list_screen.dart';

enum BonusQuestionType {
  hanjaToKorean,
  koreanToHanja,
  meaningToHanja,
  meaningToKorean,
}

class BonusQuestion {
  final Gosa gosa;
  final BonusQuestionType type;

  BonusQuestion({required this.gosa, required this.type});
}

class BonusGosaQuizPage extends StatefulWidget {
  final double initialScore;

  const BonusGosaQuizPage({super.key, required this.initialScore});

  @override
  State<BonusGosaQuizPage> createState() => _BonusGosaQuizPageState();
}

class _BonusGosaQuizPageState extends State<BonusGosaQuizPage> {
  double _bonusScore = 0;
  int _currentQuestionIndex = 0;
  List<Gosa> _allGosa = [];
  List<BonusQuestion> _questions = [];
  List<String> _options = [];
  String _correctAnswer = '';
  bool _answerLocked = false;
  String? _selectedAnswer;
  String _questionText = '';
  int _countdown = 6;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadBonusQuestions();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBonusQuestions() async {
    try {
      String jsonString = await rootBundle.loadString('assets/gosa.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);
      _allGosa = jsonResponse.map((item) => Gosa.fromJson(item)).toList();
      _allGosa.shuffle();

      final random = Random();
      final questionTypes = BonusQuestionType.values;

      setState(() {
        _questions = _allGosa.take(5).map((gosa) {
          return BonusQuestion(
              gosa: gosa, type: questionTypes[random.nextInt(questionTypes.length)]);
        }).toList();
        _startNewQuestion();
      });
    } catch (e) {
      print('Error loading gosa.json: $e');
    }
  }

  void _startNewQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      _endBonusRound();
      return;
    }

    final questionData = _questions[_currentQuestionIndex];
    final gosa = questionData.gosa;
    final type = questionData.type;

    setState(() {
      _countdown = 6;
      switch (type) {
        case BonusQuestionType.hanjaToKorean:
          _questionText = gosa.hanja;
          _correctAnswer = gosa.korean;
          break;
        case BonusQuestionType.koreanToHanja:
          _questionText = gosa.korean;
          _correctAnswer = gosa.hanja;
          break;
        case BonusQuestionType.meaningToHanja:
          _questionText = gosa.meaning;
          _correctAnswer = gosa.hanja;
          break;
        case BonusQuestionType.meaningToKorean:
          _questionText = gosa.meaning;
          _correctAnswer = gosa.korean;
          break;
      }
      _answerLocked = false;
      _selectedAnswer = null;
      _generateOptions(type, gosa);
    });
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
          _endBonusRound();
          timer.cancel();
        }
      });
    });
  }

  void _generateOptions(BonusQuestionType type, Gosa currentGosa) {
    final random = Random();
    _options = [_correctAnswer];

    List<String> allAnswers;

    switch (type) {
      case BonusQuestionType.hanjaToKorean:
      case BonusQuestionType.meaningToKorean:
        allAnswers = _allGosa.map((g) => g.korean).toSet().toList();
        break;
      case BonusQuestionType.koreanToHanja:
      case BonusQuestionType.meaningToHanja:
        allAnswers = _allGosa.map((g) => g.hanja).toSet().toList();
        break;
    }

    allAnswers.remove(_correctAnswer);
    allAnswers.shuffle(random);

    for (var answer in allAnswers) {
      if (_options.length < 4) {
        _options.add(answer);
      }
    }

    while (_options.length < 4) {
      _options.add('오답');
    }

    _options.shuffle(random);
  }

  void _handleAnswer(String answer) {
    if (_answerLocked) return;

    _countdownTimer?.cancel();

    setState(() {
      _selectedAnswer = answer;
      _answerLocked = true;
    });

    if (_selectedAnswer == _correctAnswer) {
      setState(() {
        _bonusScore += 6;
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _currentQuestionIndex++;
        });
        _startNewQuestion();
      });
    } else {
      HapticFeedback.vibrate();
      _endBonusRound();
    }
  }

  void _endBonusRound() {
    _countdownTimer?.cancel();
    Navigator.pop(context, widget.initialScore + _bonusScore);
  }

  Color _getButtonColor(String option) {
    if (!_answerLocked) {
      return _selectedAnswer == option
          ? Colors.yellow.shade700
          : const Color(0xFF1F1F1F);
    }

    if (option == _correctAnswer) {
      return Colors.green;
    } else if (option == _selectedAnswer) {
      return Colors.red;
    }
    return Colors.grey.shade800;
  }

  double _getFontSizeForQuestion(String text) {
    if (text.length > 10) {
      return 30;
    } else if (text.length > 5) {
      return 60;
    }
    return 120;
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900, // Changed background color
      appBar: AppBar(
        title: const Text('보너스 문제'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: [
                Text(
                  '보너스 점수: ${_bonusScore.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  _questionText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _getFontSizeForQuestion(_questionText),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: _options.map((option) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(option),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ).copyWith(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: () => _handleAnswer(option),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
