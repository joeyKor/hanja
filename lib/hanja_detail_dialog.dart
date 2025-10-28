import 'package:flutter/material.dart';
import 'package:hanja/hanja.dart';

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
