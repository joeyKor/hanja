
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
      appBar: AppBar(
        title: const Text('랭킹 보기'),
        centerTitle: true,
      ),
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
            final scoreComparison = (bData['score'] ?? 0).compareTo(aData['score'] ?? 0);
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
                rankWidget = Text('${index + 1}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (data['score'] ?? 0).toStringAsFixed((data['score'] ?? 0).truncateToDouble() == (data['score'] ?? 0) ? 0 : 1) + '점',
                              style: const TextStyle(fontSize: 24, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Text(date, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ));
  }
}
