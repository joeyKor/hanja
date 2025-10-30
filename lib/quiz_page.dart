import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanja/hanja.dart';
import 'package:hanja/incorrect_hanja_screen.dart';
import 'package:hanja/preparation_dialog.dart'; // Assuming this will be moved too
import 'package:hanja/eum_quiz_page.dart';
import 'package:hanja/ending_dialog.dart';

class QuizPage extends StatefulWidget {
  final List<Hanja> quizHanja;
  final String level;
  final Function(String level)? onQuizPassed;
  const QuizPage({
    super.key,
    required this.quizHanja,
    required this.level,
    this.onQuizPassed,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentIndex = 0;
  int _score = 0;
  int _countdown = 3;
  Timer? _countdownTimer;
  Timer? _nextQuestionTimer;
  List<String> _options = [];
  String _correctAnswer = '';
  bool _showAnswer = false;
  String? _selectedAnswer;
  bool _answerLocked = false;

  @override
  void initState() {
    super.initState();
    _startNewQuestion();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nextQuestionTimer?.cancel();
    super.dispose();
  }

  void _startNewQuestion() {
    if (_currentIndex >= 100) {
      _showResult();
      return;
    }

    if (_currentIndex + 1 >= 61) { // If it's the 61st question or beyond
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EumQuizPage(
            initialScore: _score.toDouble(), // Pass current score
            initialQuestionCount: _currentIndex, // Pass current question count
          ),
        ),
      );
      return;
    }

    if (_currentIndex >= widget.quizHanja.length) {
      _showResult();
      return;
    }

    setState(() {
      _showAnswer = false;
      _selectedAnswer = null;
      _answerLocked = false;
      _countdown = (_currentIndex + 1 >= 31) ? 2 : 3; // Change countdown based on question number
      _generateOptions();
    });

    _startCountdown();
  }

  void _generateOptions() {
    final random = Random();
    final currentHanja = widget.quizHanja[_currentIndex];
    _correctAnswer = '${currentHanja.hoon} ${currentHanja.eum}';

    _options = [_correctAnswer];

    final allAnswers = widget.quizHanja
        .map((h) => '${h.hoon} ${h.eum}')
        .toSet()
        .toList();
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

  void _startCountdown() {
    if (_countdown > 0) {
      _countdownTimer = Timer(const Duration(seconds: 1), () {
        // Assign to _countdownTimer
        if (!mounted) return;
        setState(() {
          _countdown--;
        });
        _startCountdown();
      });
    } else {
      if (!_answerLocked) {
        // Only reveal answer if not already locked by user selection
        _revealAnswer();
      }
    }
  }

  void _handleAnswer(String answer) {
    if (_answerLocked) return;
    _countdownTimer?.cancel(); // Cancel timer immediately
    setState(() {
      _selectedAnswer = answer;
      _answerLocked = true;
    });
    _revealAnswer();
  }

  void _revealAnswer() {
    _countdownTimer?.cancel();
    if (!_answerLocked) {
      // Time is up
      _answerLocked = true;
    }

    if (_selectedAnswer == _correctAnswer) {
      _score++;
    } else {
      if (_currentIndex < widget.quizHanja.length) {
        final currentHanja = widget.quizHanja[_currentIndex];
        _saveIncorrectHanja(currentHanja);
      }
    }
    setState(() {
      _showAnswer = true;
      _countdown = 0;
    });
    _nextQuestionTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _currentIndex++;
        _startNewQuestion();
      });
    });
  }

  Future<void> _saveIncorrectHanja(Hanja hanja) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final incorrectHanja = IncorrectHanja(
      character: hanja.character,
      hoon: hanja.hoon,
      eum: hanja.eum,
      level: widget.level,
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

  void _showResult() {
    if (widget.quizHanja.length == 100) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const EndingDialog();
        },
      );
      return;
    }

    final passed = _score >= 8; // Passing threshold is 8 correct answers
    if (passed && widget.onQuizPassed != null) {
      widget.onQuizPassed!(widget.level);
    }
    final message = passed
        ? '축하합니다! ${widget.quizHanja.length}문제 중 $_score문제를 맞혀 통과했습니다!'
        : '아쉽지만 ${widget.quizHanja.length}문제 중 $_score문제를 맞혔습니다. 다시 도전해보세요!';

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(passed ? '통과!' : '재도전!'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // Navigate to home menu
              },
            ),
          ],
        );
      },
    );
  }

  Color _getButtonColor(String option) {
    if (!_showAnswer) {
      return _selectedAnswer == option
          ? Colors.yellow.shade700
          : const Color(0xFF1F1F1F);
    }

    if (option == _correctAnswer) {
      return Colors.green;
    }
    if (option == _selectedAnswer) {
      return Colors.red;
    }
    return Colors.grey.shade800;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.quizHanja.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentHanja = widget.quizHanja[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.level} 문제'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.quizHanja.length,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('점수: $_score', style: const TextStyle(fontSize: 20)),
                Text(
                  '${_currentIndex + 1} / ${widget.quizHanja.length}',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  currentHanja.character,
                  style: const TextStyle(fontSize: 120, color: Colors.white),
                ),
              ),
            ),
            if (_countdown > 0 && !_answerLocked)
              Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: _options.map((option) {
                return ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(option),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ).copyWith(
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                  onPressed: () => _handleAnswer(option),
                  child: Text(option, style: const TextStyle(fontSize: 20)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
