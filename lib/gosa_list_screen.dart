import 'package:flutter/material.dart';
import 'dart:convert';

class Gosa {
  final String hanja;
  final String korean;
  final String meaning;

  Gosa({
    required this.hanja,
    required this.korean,
    required this.meaning,
  });

  factory Gosa.fromJson(Map<String, dynamic> json) {
    return Gosa(
      hanja: json['hanja'],
      korean: json['korean'],
      meaning: json['meaning'],
    );
  }
}

class GosaListScreen extends StatefulWidget {
  const GosaListScreen({super.key});

  @override
  State<GosaListScreen> createState() => _GosaListScreenState();
}

class _GosaListScreenState extends State<GosaListScreen> {
  List<Gosa> _gosaList = [];

  @override
  void initState() {
    super.initState();
    _loadGosa();
  }

  Future<void> _loadGosa() async {
    try {
      String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/gosa.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);
      setState(() {
        _gosaList = jsonResponse.map((item) => Gosa.fromJson(item)).toList();
      });
    } catch (e) {
      print('Error loading gosa.json: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고사성어'),
        centerTitle: true,
      ),
      body: _gosaList.isEmpty
          ? const Center(
              child: Text(
                '고사성어를 불러오는 중입니다...',
                style: TextStyle(fontSize: 20),
              ),
            )
          : ListView.builder(
              itemCount: _gosaList.length,
              itemBuilder: (context, index) {
                final gosa = _gosaList[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Text(
                      gosa.hanja,
                      style: TextStyle(fontSize: 33, color: Colors.yellow[100]),
                    ),
                    title: Text(
                      gosa.korean,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CustomGosaDetailDialog(gosa: gosa);
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class CustomGosaDetailDialog extends StatelessWidget {
  final Gosa gosa;

  const CustomGosaDetailDialog({super.key, required this.gosa});

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
              gosa.hanja,
              style: const TextStyle(fontSize: 60, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 24),
            Text(
              gosa.korean,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              gosa.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Colors.white70),
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