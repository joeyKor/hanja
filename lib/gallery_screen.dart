import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<String> _unlockedImages = [];

  @override
  void initState() {
    super.initState();
    _loadUnlockedImages();
  }

  Future<void> _loadUnlockedImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockedImages = prefs.getStringList('unlocked_images') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('갤러리'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemCount: 70,
        itemBuilder: (context, index) {
          final imageNumber = (index + 1).toString().padLeft(3, '0');
          final isUnlocked = _unlockedImages.contains(imageNumber);

          return Card(
            child: isUnlocked
                ? GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Image.asset(
                            'assets/images/$imageNumber.png',
                            fit: BoxFit.contain, // Ensure the image fits within the dialog
                          ),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/$imageNumber.png',
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      imageNumber,
                    ),
                  ),
          );
        },
      ),
    );
  }
}
