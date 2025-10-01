class UpdateInfo {
  final String latestVersion;
  final String apkUrl;
  final String updateNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.updateNotes,
    required this.forceUpdate,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latestVersion'] as String,
      apkUrl: json['apkUrl'] as String,
      updateNotes: json['updateNotes'] as String,
      forceUpdate: json['forceUpdate'] as bool,
    );
  }
}
