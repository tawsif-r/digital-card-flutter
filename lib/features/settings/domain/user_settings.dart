class UserSettings {
  const UserSettings({
    required this.showOnlineStatus,
    required this.allowAudioCalls,
    required this.allowVideoCalls,
  });

  final bool showOnlineStatus;
  final bool allowAudioCalls;
  final bool allowVideoCalls;

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        showOnlineStatus: json['showOnlineStatus'] as bool,
        allowAudioCalls: json['allowAudioCalls'] as bool,
        allowVideoCalls: json['allowVideoCalls'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'showOnlineStatus': showOnlineStatus,
        'allowAudioCalls': allowAudioCalls,
        'allowVideoCalls': allowVideoCalls,
      };

  UserSettings copyWith({
    bool? showOnlineStatus,
    bool? allowAudioCalls,
    bool? allowVideoCalls,
  }) =>
      UserSettings(
        showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
        allowAudioCalls: allowAudioCalls ?? this.allowAudioCalls,
        allowVideoCalls: allowVideoCalls ?? this.allowVideoCalls,
      );

  static const UserSettings defaults = UserSettings(
    showOnlineStatus: true,
    allowAudioCalls: true,
    allowVideoCalls: false,
  );
}
