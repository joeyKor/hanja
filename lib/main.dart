import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hanja/incorrect_hanja_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

// 1. Modified Hanja class
class Hanja {
  final String character;
  final String hoon;
  final String eum;
  final String level;

  Hanja({required this.character, required this.hoon, required this.eum, required this.level});

  factory Hanja.fromJson(Map<String, dynamic> json, String level) {
    return Hanja(
      character: json['character'],
      hoon: json['hoon'],
      eum: json['eum'],
      level: level,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
  String _selectedUser = '조이준';
  int _remainingPlays = 30;

  @override
  void initState() {
    super.initState();
    _loadPlayCount();
  }

  Future<void> _loadPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastPlayDate = prefs.getString('last_play_date') ?? '';

    int playCount = 0;
    if (lastPlayDate == today) {
      playCount = prefs.getInt('play_count') ?? 0;
    }

    setState(() {
      _remainingPlays = 30 - playCount;
    });
  }

  Future<void> _loadAndStartQuiz(BuildContext context, String level) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    int playCount = prefs.getInt('play_count') ?? 0;
    String lastPlayDate = prefs.getString('last_play_date') ?? '';

    if (lastPlayDate != today) {
      playCount = 0;
    }

    if (playCount >= 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('하루에 30번만 플레이할 수 있습니다. 내일 다시 시도해주세요.')),
      );
      return;
    }

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
      final List<Hanja> allHanja = data.map((e) => Hanja.fromJson(e, level)).toList();
      allHanja.shuffle();
      final List<Hanja> quizHanja = allHanja.take(10).toList();

      if (quizHanja.isNotEmpty) {
        await prefs.setInt('play_count', playCount + 1);
        await prefs.setString('last_play_date', today);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPage(
              quizHanja: quizHanja,
              level: level,
              user: _selectedUser,
            ),
          ),
        );
        _loadPlayCount();
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

  @override
  Widget build(BuildContext context) {
    final levels = ['5급', '준4급', '4급', '준3급', '3급'];

    return Scaffold(
      appBar: AppBar(title: const Text('한자 퀴즈'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '오늘 남은 횟수: $_remainingPlays',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '사용자 선택',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: '조이준',
                    groupValue: _selectedUser,
                    onChanged: (value) {
                      setState(() {
                        _selectedUser = value!;
                      });
                    },
                  ),
                  const Text('조이준'),
                  Radio<String>(
                    value: '엄마',
                    groupValue: _selectedUser,
                    onChanged: (value) {
                      setState(() {
                        _selectedUser = value!;
                      });
                    },
                  ),
                  const Text('엄마'),
                  Radio<String>(
                    value: '아빠',
                    groupValue: _selectedUser,
                    onChanged: (value) {
                      setState(() {
                        _selectedUser = value!;
                      });
                    },
                  ),
                  const Text('아빠'),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '도전할 급수를 선택하세요',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: levels.map((level) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => _loadAndStartQuiz(context, level),
                      child: Text(level, style: const TextStyle(fontSize: 22)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // 6. Added Hanja Search button
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('결과보기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyanAccent,
                      side: const BorderSide(color: Colors.cyanAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResultsSummaryPage(),
                        ),
                      );
                    },
                  ),
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
                        vertical: 10,
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
                        vertical: 10,
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
                        vertical: 10,
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
  final String user;

  const QuizPage({
    super.key,
    required this.quizHanja,
    required this.level,
    required this.user,
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
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _revealAnswer();
      }
    });
  }

  void _handleAnswer(String answer) {
    if (_answerLocked) return;
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
    _nextQuestionTimer = Timer(const Duration(milliseconds: 1500), () {
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          score: _score,
          total: widget.quizHanja.length,
          user: widget.user,
          level: widget.level,
        ),
      ),
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
                  style: const TextStyle(fontSize: 150, color: Colors.white),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(option),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ).copyWith(
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: () => _handleAnswer(option),
                  child: Text(option, style: const TextStyle(fontSize: 22)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatefulWidget {
  final int score;
  final int total;
  final String user;
  final String level;

  const ResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.user,
    required this.level,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    _updateScoreFrequency();
  }

  Future<void> _updateScoreFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${widget.user}_${widget.level}';
    final scoreString = widget.score.toString();

    final existingData = prefs.getString(key);
    Map<String, dynamic> scoreMap =
        existingData != null ? json.decode(existingData) : {};

    int currentFrequency = scoreMap[scoreString] ?? 0;
    scoreMap[scoreString] = currentFrequency + 1;

    await prefs.setString(key, json.encode(scoreMap));
    await prefs.setInt('${widget.user}_${widget.level}_total', widget.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('퀴즈 결과'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '도전자 : ${widget.user}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Text(
              '총 ${widget.total}문제 중 ${widget.score}문제를 맞혔습니다.',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('처음으로 돌아가기', style: TextStyle(fontSize: 20)),
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
      child: contentBox(context),
    );
  }

  contentBox(context) {
    return Stack(
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
      final List<Hanja> hanja = data.map((e) => Hanja.fromJson(e, level)).toList();
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
                                  fontSize: 33, color: Colors.yellow[100]),
                            ),
                            title: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 17, color: Colors.white),
                                children: <TextSpan>[
                                  TextSpan(text: '${hanja.hoon} '),
                                  TextSpan(
                                    text: hanja.eum,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
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


class ResultsSummaryPage extends StatefulWidget {
  const ResultsSummaryPage({super.key});

  @override
  State<ResultsSummaryPage> createState() => _ResultsSummaryPageState();
}

class _ResultsSummaryPageState extends State<ResultsSummaryPage> {
  String _selectedUser = '조이준';
  String _selectedLevel = '4급';
  Map<String, dynamic> _levelResults = {};
  int _totalQuestions = 10;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_selectedUser}_$_selectedLevel';
    final totalKey = '${_selectedUser}_${_selectedLevel}_total';

    final data = prefs.getString(key);
    final total = prefs.getInt(totalKey) ?? 10; // Default to 10

    setState(() {
      _levelResults = data != null ? json.decode(data) : {};
      _totalQuestions = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final levels = ['5급', '준4급', '4급', '준3급', '3급'];
    const textStyle = TextStyle(color: Colors.white);
    const highlightedTextStyle = TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(title: const Text('결과 요약'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Text('사용자: ', style: textStyle),
                    DropdownButton<String>(
                      value: _selectedUser,
                      items: ['조이준', '엄마', '아빠'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: textStyle),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUser = newValue!;
                          _loadResults();
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('급수: ', style: textStyle),
                    DropdownButton<String>(
                      value: _selectedLevel,
                      items: levels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: textStyle),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLevel = newValue!;
                          _loadResults();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('점수', style: textStyle)),
                    DataColumn(label: Text('횟수', style: textStyle)),
                  ],
                  rows: List<DataRow>.generate(_totalQuestions + 1, (index) {
                    final score = _totalQuestions - index;
                    final frequency = _levelResults[score.toString()] ?? 0;
                    final style = frequency > 0 ? highlightedTextStyle : textStyle;
                    return DataRow(
                      cells: [
                        DataCell(Text('$score점', style: style)),
                        DataCell(Text('$frequency회', style: style)),
                      ],
                    );
                  }),
                ),
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
      child: contentBox(context),
    );
  }

  contentBox(context) {
    return Stack(
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
    );
  }
}
