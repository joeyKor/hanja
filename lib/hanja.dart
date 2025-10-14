
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
