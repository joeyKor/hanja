class Gosa {
  final String idiom;
  final String meaning;
  final String eum; // Korean pronunciation

  Gosa({required this.idiom, required this.meaning, required this.eum});

  factory Gosa.fromJson(Map<String, dynamic> json) {
    return Gosa(
      idiom: json['hanja'],
      meaning: json['meaning'],
      eum: json['korean'],
    );
  }
}