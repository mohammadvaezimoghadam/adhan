/// Represents the lifecycle status of a study topic / reflection workspace.
enum TopicStatus {
  /// Topic is currently open, editable, and active for adding blocks/content.
  open,

  /// Topic has been completed, closed, or archived.
  closed;

  bool get isOpen => this == TopicStatus.open;
  bool get isClosed => this == TopicStatus.closed;

  String get titlePersian {
    switch (this) {
      case TopicStatus.open:
        return 'در حال تدوین';
      case TopicStatus.closed:
        return 'تکمیل‌شده';
    }
  }

  static TopicStatus fromString(String? value) {
    if (value == 'closed') return TopicStatus.closed;
    return TopicStatus.open;
  }
}
