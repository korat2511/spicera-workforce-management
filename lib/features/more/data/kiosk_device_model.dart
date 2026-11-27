class KioskDevice {
  const KioskDevice({
    required this.id,
    required this.name,
    this.platform,
    this.model,
    this.lastSeenAt,
    this.revokedAt,
    this.createdAt,
  });

  factory KioskDevice.fromJson(Map<String, dynamic> json) {
    return KioskDevice(
      id: json['id'] as int,
      name: json['name'] as String,
      platform: json['platform'] as String?,
      model: json['model'] as String?,
      lastSeenAt: json['last_seen_at'] as String?,
      revokedAt: json['revoked_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  final int id;
  final String name;
  final String? platform;
  final String? model;
  final String? lastSeenAt;
  final String? revokedAt;
  final String? createdAt;

  bool get isRevoked => revokedAt != null;
}
