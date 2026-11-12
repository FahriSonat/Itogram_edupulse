// ignore_for_file: constant_identifier_names

/// 4.00'lük sistemde harf notları.
enum LetterGrade {
  AA(4.0),
  BA(3.5),
  BB(3.0),
  CB(2.5),
  CC(2.0),
  DC(1.5),
  DD(1.0),
  FD(0.5),
  FF(0.0),
  NA(0.0);

  const LetterGrade(this.coefficient);

  /// 4.00 üzerinden katsayı karşılığı.
  final double coefficient;

  String toJson() => name;

  bool get isPassing => this != LetterGrade.FF && this != LetterGrade.NA;

  static LetterGrade fromJson(String? value) {
    return LetterGrade.values.firstWhere(
      (LetterGrade grade) => grade.name == value,
      orElse: () => LetterGrade.FF,
    );
  }
}
