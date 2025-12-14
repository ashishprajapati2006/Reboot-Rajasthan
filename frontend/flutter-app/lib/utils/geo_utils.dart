import 'dart:math';

class GeoBox {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const GeoBox({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}

class GeoUtils {
  static const double earthRadiusKm = 6371.0;

  static double _degToRad(double deg) => deg * (pi / 180.0);

  /// Haversine distance in kilometers.
  static double distanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// A quick bounding box for a radius query.
  /// Use as Firestore pre-filter, then exact-filter with [distanceKm].
  static GeoBox boundingBox({
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    final latRad = _degToRad(lat);

    final latDelta = radiusKm / earthRadiusKm;
    final lngDelta = radiusKm / (earthRadiusKm * cos(latRad));

    final minLat = lat - (latDelta * (180 / pi));
    final maxLat = lat + (latDelta * (180 / pi));
    final minLng = lng - (lngDelta * (180 / pi));
    final maxLng = lng + (lngDelta * (180 / pi));

    return GeoBox(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }
}
