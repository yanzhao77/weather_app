import 'package:equatable/equatable.dart';

class LocationData extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? adminArea;
  final String? localName;

  const LocationData({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.adminArea,
    this.localName,
  });

  @override
  List<Object?> get props => [name, latitude, longitude, country, adminArea];

  factory LocationData.fromJson(Map<String, dynamic> json) {
    final localNames = json['local_names'] as Map<String, dynamic>?;
    return LocationData(
      name: json['name']?.toString() ?? '',
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      country: json['country']?.toString(),
      adminArea: json['state']?.toString(),
      localName: localNames?['zh'] ?? json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': latitude,
        'lon': longitude,
        'country': country,
        'state': adminArea,
      };

  String get displayName {
    if (country != null && adminArea != null) {
      return '$name, $adminArea';
    }
    if (country != null) {
      return '$name, $country';
    }
    return name;
  }
}
