import math
from typing import Dict, Tuple


def validate_gps_coordinates(latitude: float, longitude: float) -> Dict:
    """
    Validate GPS coordinates and detect potential spoofing
    
    Args:
        latitude: GPS latitude (-90 to 90)
        longitude: GPS longitude (-180 to 180)
        
    Returns:
        Dictionary with validation results
    """
    # Basic range validation
    if not (-90 <= latitude <= 90):
        return {
            'valid': False,
            'error': 'Invalid latitude (must be between -90 and 90)'
        }
    
    if not (-180 <= longitude <= 180):
        return {
            'valid': False,
            'error': 'Invalid longitude (must be between -180 and 180)'
        }
    
    # Check for exact 0,0 coordinates (common spoofing location)
    if latitude == 0 and longitude == 0:
        return {
            'valid': False,
            'error': 'Invalid coordinates (0, 0) - possible GPS spoofing'
        }
    
    # Check for Rajasthan bounds (approximately)
    # Rajasthan: Latitude 23.5° to 30.2° N, Longitude 69.5° to 78.3° E
    rajasthan_bounds = {
        'lat_min': 23.5,
        'lat_max': 30.2,
        'lon_min': 69.5,
        'lon_max': 78.3
    }
    
    in_rajasthan = (
        rajasthan_bounds['lat_min'] <= latitude <= rajasthan_bounds['lat_max'] and
        rajasthan_bounds['lon_min'] <= longitude <= rajasthan_bounds['lon_max']
    )
    
    possible_spoofing = False
    warnings = []
    
    # Check for suspiciously precise coordinates (common in spoofing)
    # Real GPS has some noise, exact values are suspicious
    lat_str = str(latitude)
    lon_str = str(longitude)
    
    if '.' in lat_str and '.' in lon_str:
        lat_decimals = len(lat_str.split('.')[1])
        lon_decimals = len(lon_str.split('.')[1])
        
        # More than 6 decimal places is suspicious for mobile GPS
        if lat_decimals > 8 or lon_decimals > 8:
            possible_spoofing = True
            warnings.append('Unusually precise coordinates')
    
    return {
        'valid': True,
        'in_rajasthan': in_rajasthan,
        'possible_spoofing': possible_spoofing,
        'warnings': warnings,
        'coordinates': {
            'latitude': latitude,
            'longitude': longitude
        }
    }


def calculate_distance(
    lat1: float, 
    lon1: float, 
    lat2: float, 
    lon2: float
) -> float:
    """
    Calculate distance between two GPS coordinates using Haversine formula
    
    Args:
        lat1: Latitude of first point
        lon1: Longitude of first point
        lat2: Latitude of second point
        lon2: Longitude of second point
        
    Returns:
        Distance in kilometers
    """
    # Earth's radius in kilometers
    R = 6371.0
    
    # Convert to radians
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)
    
    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = (
        math.sin(dlat / 2)**2 +
        math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    distance = R * c
    
    return distance


def is_within_geofence(
    latitude: float,
    longitude: float,
    center_lat: float,
    center_lon: float,
    radius_km: float
) -> Dict:
    """
    Check if coordinates are within a circular geofence
    
    Args:
        latitude: Point latitude
        longitude: Point longitude
        center_lat: Geofence center latitude
        center_lon: Geofence center longitude
        radius_km: Geofence radius in kilometers
        
    Returns:
        Dictionary with geofence check results
    """
    distance = calculate_distance(latitude, longitude, center_lat, center_lon)
    
    within_fence = distance <= radius_km
    
    return {
        'within_geofence': within_fence,
        'distance_km': round(distance, 3),
        'radius_km': radius_km,
        'distance_from_edge_km': round(radius_km - distance, 3)
    }
