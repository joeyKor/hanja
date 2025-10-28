import 'package:flutter/material.dart';

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
