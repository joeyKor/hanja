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
import 'package:hanja/gosa_list_screen.dart';
import 'package:hanja/gallery_screen.dart';
import 'package:hanja/hanja.dart';
import 'package:hanja/quiz_page.dart'; // Will be created
import 'package:hanja/hanja_detail_dialog.dart'; // Will be created
import 'package:hanja/hanja_list_page.dart'; // Will be created
import 'package:hanja/hanja_search_page.dart'; // Will be created
import 'package:hanja/preparation_dialog.dart'; // Will be created


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
  int _rankingAttemptsRemaining = 20; // New: Remaining ranking attempts
  String _lastRankingAttemptDate = ''; // New: Date of last ranking attempt

  @override
  void initState() {
    print('HomePage initState');
    super.initState();
    _initializeDailyChallenge();
    _loadRankingAttempts(); // New: Load ranking attempts
  }

  Future<void> _loadRankingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _lastRankingAttemptDate = prefs.getString('last_ranking_attempt_date') ?? '';
    _rankingAttemptsRemaining = prefs.getInt('ranking_attempts_remaining') ?? 20;

    if (_lastRankingAttemptDate != today) {
      // New day, reset attempts
      _rankingAttemptsRemaining = 20;
      await prefs.setString('last_ranking_attempt_date', today);
      await prefs.setInt('ranking_attempts_remaining', _rankingAttemptsRemaining);
    }
    setState(() {}); // Update UI
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
                        title: const Text('문제 시작 지점 선택'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('원하는 문제 번호부터 시작할 수 있습니다.'),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close current dialog
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EumQuizPage(
                                      initialScore: 0,
                                      initialQuestionCount: 60, // Start from 61st question
                                    ),
                                  ),
                                );
                              },
                              child: const Text('61번부터'),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close current dialog
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EumQuizPage(
                                      initialScore: 0,
                                      initialQuestionCount: 80, // Start from 81st question
                                    ),
                                  ),
                                );
                              },
                              child: const Text('81번부터'),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close current dialog
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EumQuizPage(
                                      initialScore: 0,
                                      initialQuestionCount: 98, // Start from 99th question
                                    ),
                                  ),
                                );
                              },
                              child: const Text('99번부터'),
                            ),
                            const SizedBox(height: 20), // Add some space
                            // New button for adding attempts
                            ElevatedButton(
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                setState(() {
                                  _rankingAttemptsRemaining += 10;
                                });
                                await prefs.setInt('ranking_attempts_remaining', _rankingAttemptsRemaining);
                                Navigator.of(context).pop(); // Close dialog
                              },
                              child: const Text('랭킹 도전 10회 추가'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('취소'),
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

  Future<void> _unlockRandomGalleryImage() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedImages = prefs.getStringList('unlocked_images') ?? [];

    final allImageNumbers =
        List.generate(70, (index) => (index + 1).toString().padLeft(3, '0'));
    final lockedImages =
        allImageNumbers.where((img) => !unlockedImages.contains(img)).toList();

    if (lockedImages.isEmpty) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('모든 갤러리 이미지가 이미 해금되었습니다!'),
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

  void _showGalleryUnlockPasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('갤러리 해금 비밀번호'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '비밀번호를 입력하세요'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (passwordController.text == '9891') {
                  await _unlockRandomGalleryImage();
                } else {
                  if (!mounted) return;
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
              // Add this Text widget
              Text(
                '랭킹 도전 남은 횟수: $_rankingAttemptsRemaining회',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
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
                        ? () async { // Make onPressed async
                            if (_rankingAttemptsRemaining > 0) {
                              final prefs = await SharedPreferences.getInstance();
                              setState(() {
                                _rankingAttemptsRemaining--;
                              });
                              await prefs.setInt('ranking_attempts_remaining', _rankingAttemptsRemaining);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RankingQuizPage(),
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('알림'),
                                    content: const Text(
                                      '오늘은 랭킹 도전을 더 이상 할 수 없습니다. 내일 다시 시도해주세요.',
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
                  crossAxisCount: 5, // 5 buttons horizontally
                  crossAxisSpacing: 8, // Reduced spacing for more buttons
                  mainAxisSpacing: 8, // Reduced spacing
                  childAspectRatio:
                      1.0, // Adjusted aspect ratio for more compact buttons
                  children: levels.map((level) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced padding
                      ),
                      onPressed: () => _loadAndStartQuiz(context, level),
                      child: Text(level, style: const TextStyle(fontSize: 14)),
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
                  GestureDetector(
                    onLongPress: () => _showGalleryUnlockPasswordDialog(context),
                    child: ElevatedButton.icon(
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