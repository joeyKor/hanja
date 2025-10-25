import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hanja/incorrect_hanja_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanja/ranking_quiz_page.dart';
import 'package:hanja/ranking_board_page.dart';
import 'package:hanja/eum_quiz_page.dart';
import 'package:hanja/gosa_list_screen.dart'; // Import the new GosaListScreen
import 'package:hanja/gallery_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:hanja/hanja.dart';

void main() async {
  print('main started');
  WidgetsFlutterBinding.ensureInitialized();
  print('WidgetsFlutterBinding ensured');
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Firebase initialized');
  print('Calling runApp');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('MyApp build method called');
    return MaterialApp(
      title: '한자 학습',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.cyan,
        ).copyWith(secondary: Colors.cyanAccent),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontStyle: FontStyle.italic),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.cyanAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _rankingChallengeUnlocked = false;
  String _hanjaDate = '';
  List<String> _dailyChallengeLevels =
      []; // Levels to be passed for ranking challenge
  List<String> _passedChallengeLevels = []; // Levels already passed today

  @override
  void initState() {
    print('HomePage initState');
    super.initState();
    _initializeDailyChallenge();
  }

  String _getHanjaDate(DateTime date) {
    final Map<int, String> hanjaNumbers = {
      0: '〇',
      1: '一',
      2: '二',
      3: '三',
      4: '四',
      5: '五',
      6: '六',
      7: '七',
      8: '八',
      9: '九',
    };

    String convertNumberToHanja(int num) {
      if (num == 0) return hanjaNumbers[0]!;
      String result = '';
      if (num >= 1000) {
        result += '${convertNumberToHanja(num ~/ 1000)}千';
        num %= 1000;
      }
      if (num >= 100) {
        result += '${convertNumberToHanja(num ~/ 100)}百';
        num %= 100;
      }
      if (num >= 10) {
        result += '${num ~/ 10 == 1 ? '' : hanjaNumbers[num ~/ 10]!}十';
        num %= 10;
      }
      if (num > 0) {
        result += hanjaNumbers[num]!;
      }
      return result;
    }

    String convertMonthDayToHanja(int num) {
      if (num == 0) return hanjaNumbers[0]!;
      String result = '';
      if (num >= 20) {
        result += '${hanjaNumbers[num ~/ 10]!}十';
        num %= 10;
      } else if (num >= 10) {
        result += '十';
        num %= 10;
      }
      if (num > 0) {
        result += hanjaNumbers[num]!;
      }
      return result;
    }

    String yearHanja = '${convertNumberToHanja(date.year)}年';
    String monthHanja = '${convertMonthDayToHanja(date.month)}月';
    String dayHanja = '${convertMonthDayToHanja(date.day)}日';

    return '$yearHanja $monthHanja $dayHanja';
  }

  Future<void> _initializeDailyChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      _hanjaDate = _getHanjaDate(DateTime.now());
    });

    final savedChallengeDate = prefs.getString('daily_challenge_date');
    final savedChallengeLevels = prefs.getStringList('daily_challenge_levels');
    final savedPassedLevels = prefs.getStringList('daily_passed_levels');

    if (savedChallengeDate == today && savedChallengeLevels != null) {
      setState(() {
        _dailyChallengeLevels = savedChallengeLevels;
        _passedChallengeLevels = savedPassedLevels ?? [];
      });
    } else {
      // New day or no levels saved, generate new ones
      final allPossibleLevels = ['5급', '준4급', '4급', '준3급', '3급'];
      allPossibleLevels.shuffle(Random());
      final selectedLevels = allPossibleLevels.take(3).toList();

      await prefs.setString('daily_challenge_date', today);
      await prefs.setStringList('daily_challenge_levels', selectedLevels);
      await prefs.setStringList(
        'daily_passed_levels',
        [],
      ); // Reset passed levels for new day

      setState(() {
        _dailyChallengeLevels = selectedLevels;
        _passedChallengeLevels = [];
      });
    }
  }

  Future<void> _handleChallengeLevelPassed(String level) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (!_passedChallengeLevels.contains(level)) {
      _passedChallengeLevels.add(level);
      await prefs.setStringList('daily_passed_levels', _passedChallengeLevels);
      // Re-initialize to update UI with filtered levels and message
      _initializeDailyChallenge();
    }
  }


  Future<void> _loadAndStartQuiz(BuildContext context, String level) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('유효하지 않은 급수입니다.')));
        return;
    }

    try {
      final String response = await rootBundle.loadString(fileName);
      final data = await json.decode(response) as List;
      // 2. Updated Hanja.fromJson call
      final List<Hanja> allHanja = data
          .map((e) => Hanja.fromJson(e, level))
          .toList();
      allHanja.shuffle();
      final List<Hanja> quizHanja = allHanja.take(10).toList();

      if (quizHanja.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPage(
              quizHanja: quizHanja,
              level: level,
              onQuizPassed: _handleChallengeLevelPassed,
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return PreparationDialog(level: level);
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return PreparationDialog(level: level);
        },
      );
    }
  }

  void _showPasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 입력'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: '비밀번호'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text == '0000') {
                  setState(() {
                    _rankingChallengeUnlocked = true;
                  });
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('성공'),
                        content: const Text('랭킹 도전이 해제되었습니다.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('확인'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EumQuizPage(
                                    initialScore: 0,
                                    initialQuestionCount: 100,
                                  ),
                                ),
                              );
                            },
                            child: const Text('101번부터 테스트'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('오류'),
                        content: const Text('비밀번호가 틀렸습니다.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('확인'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = ['5급', '준4급', '4급', '준3급', '3급'];

    final List<String> displayedChallengeLevels = _dailyChallengeLevels
        .where((level) => !_passedChallengeLevels.contains(level))
        .toList();

    final int remainingLevelsToPass = displayedChallengeLevels.length;

    String challengeMessage;
    if (_passedChallengeLevels.length >= 2) {
      challengeMessage = '랭킹 도전을 할 수 있습니다.';
    } else {
      final int neededToPass = 2 - _passedChallengeLevels.length;
      challengeMessage = '랭킹 도전을 하려면 다음 중 $neededToPass개의 급수를 통과해야합니다.';
    }

    final bool canChallengeRanking =
        _passedChallengeLevels.length >= 2 || _rankingChallengeUnlocked;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _hanjaDate,
                style: const TextStyle(fontSize: 20, color: Colors.white70),
              ),
              const SizedBox(height: 10),

              Text(
                challengeMessage,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0, // gap between adjacent chips
                runSpacing: 4.0, // gap between lines
                alignment: WrapAlignment.center,
                children: _dailyChallengeLevels.map((level) {
                  final bool isPassed = _passedChallengeLevels.contains(level);
                  return Chip(
                    label: Text(level),
                    backgroundColor: isPassed
                        ? Colors.green.shade700
                        : Colors.yellowAccent.shade700,
                    labelStyle: TextStyle(
                      color: isPassed ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('랭킹 도전'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: canChallengeRanking
                          ? Colors.purple
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40, // Increased padding for larger button
                        vertical: 20, // Increased padding for larger button
                      ),
                    ),
                    onPressed: canChallengeRanking
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RankingQuizPage(),
                              ),
                            );
                          }
                        : () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('안내'),
                                  content: const Text(
                                    '랭킹 도전을 하려면 2개의 급수를 통과해야 합니다.',
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
                          },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.leaderboard),
                    label: const Text('랭킹 보기'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40, // Increased padding for larger button
                        vertical: 20, // Increased padding for larger button
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RankingBoardPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                '도전할 급수를 선택하세요',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180, // Set a fixed height for the GridView container
                child: GridView.count(
                  crossAxisCount: 3, // 3 buttons horizontally
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio:
                      1.5, // Adjusted aspect ratio for increased height
                  children: levels.map((level) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => _loadAndStartQuiz(context, level),
                      child: Text(level, style: const TextStyle(fontSize: 18)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // 6. Added Hanja Search button
              // 6. Added Hanja Search button
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('오늘틀린한자'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IncorrectHanjaScreen(),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book),
                    label: const Text('고사성어'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GosaListScreen(),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onLongPress: () => _showPasswordDialog(context),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.book),
                      label: const Text('급수한자보기'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HanjaListPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('한자 검색'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HanjaSearchPage(),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_album),
                    label: const Text('갤러리'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GalleryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... (QuizPage, ResultPage are unchanged in their logic, but depend on the new Hanja class)
// I will just copy them as they are, but the Hanja class they receive is the new one.

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
    if (_currentIndex >= widget.quizHanja.length) {
      _showResult();
      return;
    }

    setState(() {
      _showAnswer = false;
      _selectedAnswer = null;
      _answerLocked = false;
      _countdown = 3;
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

class HanjaDetailDialog extends StatelessWidget {
  final Hanja hanja;

  const HanjaDetailDialog({super.key, required this.hanja});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              top: 45,
              right: 20,
              bottom: 20,
            ),
            margin: const EdgeInsets.only(top: 45),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: const Color(0xFF2d2d2d),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 10),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  hanja.character,
                  style: const TextStyle(fontSize: 100, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(
                  '${hanja.hoon} ${hanja.eum}',
                  style: const TextStyle(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      '닫기',
                      style: TextStyle(fontSize: 18, color: Colors.cyanAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

// 4. Added HanjaSearchPage
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

class PreparationDialog extends StatelessWidget {
  final String level;

  const PreparationDialog({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              top: 65,
              right: 20,
              bottom: 20,
            ),
            margin: const EdgeInsets.only(top: 45),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: const Color(0xFF2d2d2d),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 10),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '알림',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '$level은(는) 준비중입니다.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      '확인',
                      style: TextStyle(fontSize: 18, color: Colors.cyanAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 45,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(45)),
                child: Icon(
                  Icons.info_outline,
                  size: 90,
                  color: Colors.cyanAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
