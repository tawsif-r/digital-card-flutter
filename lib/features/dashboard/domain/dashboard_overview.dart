class DashboardOverview {
  const DashboardOverview({
    required this.pendingTaskCount,
    required this.totalCards,
    required this.totalContacts,
    required this.cardViewsThisWeek,
  });

  final int pendingTaskCount;
  final int totalCards;
  final int totalContacts;
  final int cardViewsThisWeek;

  factory DashboardOverview.fromJson(Map<String, dynamic> json) =>
      DashboardOverview(
        pendingTaskCount: (json['pendingTaskCount'] as num?)?.toInt() ?? 0,
        totalCards: (json['totalCards'] as num?)?.toInt() ?? 0,
        totalContacts: (json['totalContacts'] as num?)?.toInt() ?? 0,
        cardViewsThisWeek: (json['cardViewsThisWeek'] as num?)?.toInt() ?? 0,
      );
}
