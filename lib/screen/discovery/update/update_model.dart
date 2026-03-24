



class UpdateModel {
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrl;
  final String title;
  final String description;
  final List<String> changelog;

  const UpdateModel({
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateUrl,
    required this.title,
    required this.description,
    required this.changelog,
  });

  factory UpdateModel.fromMap(Map<String, dynamic> map) {
    return UpdateModel(
      latestVersion: (map['latest_version'] as String?) ?? '0.0.0',
      forceUpdate:   (map['force_update']   as bool?)   ?? false,
      updateUrl:     (map['update_url']      as String?) ?? '',
      title:         (map['title']           as String?) ?? 'Update Available',
      description:   (map['description']     as String?) ?? '',
      changelog: List<String>.from(
        (map['changelog'] as List<dynamic>?) ?? [],
      ),
    );
  }
}