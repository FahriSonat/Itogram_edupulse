enum AnnouncementType {
  general,
  exam,
  assignment,
  event,
  urgent,
}

extension AnnouncementTypeX on AnnouncementType {
  String toJson() => name;

  String get label {
    switch (this) {
      case AnnouncementType.general:
        return 'Genel';
      case AnnouncementType.exam:
        return 'Sınav';
      case AnnouncementType.assignment:
        return 'Ödev';
      case AnnouncementType.event:
        return 'Etkinlik';
      case AnnouncementType.urgent:
        return 'Acil';
    }
  }

  static AnnouncementType fromJson(String? value) {
    return AnnouncementType.values.firstWhere(
      (AnnouncementType type) => type.name == value,
      orElse: () => AnnouncementType.general,
    );
  }
}
