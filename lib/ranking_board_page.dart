import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RankingBoardPage extends StatelessWidget {
  const RankingBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('랭킹 보기'), centerTitle: true),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rankings')
              .orderBy('score', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('아직 랭킹이 없습니다.'));
            }

            final rankings = snapshot.data!.docs;

            rankings.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final scoreComparison = (bData['score'] ?? 0).compareTo(
                aData['score'] ?? 0,
              );
              if (scoreComparison != 0) {
                return scoreComparison;
              }
              final aTimestamp = aData['timestamp'] as Timestamp?;
              final bTimestamp = bData['timestamp'] as Timestamp?;
              if (aTimestamp != null && bTimestamp != null) {
                return aTimestamp.compareTo(bTimestamp);
              }
              return 0;
            });

            return ListView.builder(
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final doc = rankings[index];
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] as Timestamp?;
                final date = timestamp != null
                    ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                    : '';

                Widget rankWidget;
                if (index < 3) {
                  rankWidget = Icon(
                    Icons.emoji_events,
                    color: index == 0
                        ? Colors.yellow[700]
                        : index == 1
                        ? Colors.grey[400]
                        : Colors.brown[400],
                    size: 40,
                  );
                } else {
                  rankWidget = Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return RankingDetailDialog(
                            rank: index + 1,
                            name: data['name'] ?? '',
                            score: data['score'] ?? 0,
                            time: date,
                            incorrectHanja:
                                data['incorrectHanja'] as List? ?? [],
                            level:
                                data['level'] ??
                                'N/A', // Assuming 'level' might be stored in ranking data
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          rankWidget,
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  (data['score'] ?? 0).toStringAsFixed(
                                        (data['score'] ?? 0)
                                                    .truncateToDouble() ==
                                                (data['score'] ?? 0)
                                            ? 0
                                            : 1,
                                      ) +
                                      '점',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (data['incorrectHanja'] != null &&
                                    (data['incorrectHanja'] as List).isNotEmpty)
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 4.0,
                                    runSpacing: 2.0,
                                    children: (data['incorrectHanja'] as List)
                                        .map((hanjaData) {
                                          return Chip(
                                            label: Text(
                                              hanjaData['character'],
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            date,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RankingDetailDialog extends StatelessWidget {
  final int rank;
  final String name;
  final num score;
  final String time;
  final List<dynamic> incorrectHanja;
  final String level;

  const RankingDetailDialog({
    super.key,
    required this.rank,
    required this.name,
    required this.score,
    required this.time,
    required this.incorrectHanja,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '랭킹 상세 정보',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('등수', '$rank위'),
            _buildDetailRow('이름', name),
            _buildDetailRow(
              '점수',
              '${score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1)}점',
            ),
            _buildDetailRow('시간', time),
            const SizedBox(height: 10),
            const Text(
              '틀린 한자',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 5),
            incorrectHanja.isEmpty
                ? const Text(
                    '없음',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  )
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: incorrectHanja.map((hanjaData) {
                      return Chip(
                        label: Text(
                          '${hanjaData['character']} (${hanjaData['hoon']} ${hanjaData['eum']})',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        backgroundColor: Colors.red.shade200,
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 20),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
