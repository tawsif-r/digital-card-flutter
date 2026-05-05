class UserSettings {
  const UserSettings({
    this.showOnlineStatus = true,
    this.allowAudioCalls = true,
    this.allowVideoCalls = true,
  });

  final bool showOnlineStatus;
  final bool allowAudioCalls;
  final bool allowVideoCalls;

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
        allowAudioCalls: json['allowAudioCalls'] as bool? ?? true,
        allowVideoCalls: json['allowVideoCalls'] as bool? ?? true,
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
}
