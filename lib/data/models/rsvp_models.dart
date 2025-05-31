class RSVP {
  final String userId;
  final bool isAttending;

  RSVP({
    required this.userId,
    required this.isAttending,
  });

  factory RSVP.fromMap(String userId, bool isAttending) {
    return RSVP(userId: userId, isAttending: isAttending);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isAttending': isAttending,
    };
  }
}