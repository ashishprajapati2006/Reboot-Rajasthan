import 'package:flutter_test/flutter_test.dart';
import 'package:saaf_surksha/utils/geo_utils.dart';

void main() {
  test('GeoUtils.distanceKm is ~0 for identical points', () {
    final d = GeoUtils.distanceKm(lat1: 26.9124, lng1: 75.7873, lat2: 26.9124, lng2: 75.7873);
    expect(d, closeTo(0.0, 1e-6));
  });

  test('GeoUtils.boundingBox contains center', () {
    final box = GeoUtils.boundingBox(lat: 26.9124, lng: 75.7873, radiusKm: 5);
    expect(26.9124, inInclusiveRange(box.minLat, box.maxLat));
    expect(75.7873, inInclusiveRange(box.minLng, box.maxLng));
  });
}
