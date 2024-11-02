#include <vector>
#include <cmath>
#include <algorithm>
#include <array>
#include <limits>

class LatLong {
public:
    double latitude;
    double longitude;
    
    constexpr LatLong(double lat, double lon) : latitude(lat), longitude(lon) {}
};

class Polygon {
private:
    static constexpr double EARTH_RADIUS = 6371000.0; // Earth's radius in meters
    static constexpr double PI = 3.14159265358979323846;
    static constexpr double DEG_TO_RAD = PI / 180.0;
    static constexpr double RAD_TO_DEG = 180.0 / PI;

public:
    std::vector<LatLong> vertices;
    std::vecotr<LatLong> enlargedVertices;
	
    void enlarge(double distance = 0) {
        if (vertices.size() < 3) return;

        this->enlargedVertices.reserve(vertices.size() * 2); // Reserve space for potential new vertices
		if(distance == 0.0)
		{
			this->enlargedVertices = std::move(vertices);
		}
        for (size_t i = 0; i < vertices.size(); ++i) {
		
			// Create a Triangle between 3 adjacent vertices.
			// the current index (demarcated by curr) is what we're focusing on in each index in the for-loop
            size_t prev = (i + vertices.size() - 1) % vertices.size();
			auto& curr = vertices[i];
            size_t next = (i + 1) % vertices.size();
			
			// Calculate the direction (bearing) from one point to another
			// Used to determine the direction in which to "offset" each vertex
			LatLong bisector = calculateAngleBisector(vertices[prev], curr, vertices[next]);
            LatLong enlargedVertex = movePoint(curr, bisector, distance);
            this->enlargedVertices.push_back(enlargedVertex);
        }
    }

private:
	LatLong calculateAngleBisector(const LatLong& prev, const LatLong& current, const LatLong& next) {
        double bearing1 = calculateBearing(current, prev);
        double bearing2 = calculateBearing(current, next);
        
        // Calculate the bisector
        double bisectorBearing = (bearing1 + bearing2) / 2;
        
        // If the interior angle is reflex/concave (> 180 degrees), adjust the bisector
		// e.g, the interior angle around G
		/* 
		   A---B
		   |   |
		F--G   C
		|      |
		E------D
		*/
		// If this is negative, then want to shift to see if it's larger than PI/180
        double angleDifference = bearing2 - bearing1; 
		if (angleDifference < 0) {
			angleDifference += 2 * PI;
		}
		
		// If this is larger than PI/180, then we've found a concave vertex.
		if (angleDifference > PI) {
			bisectorBearing += PI;
		}
		bisectorBearing = std::fmod(bisectorBearing, 2 * PI);
        
        return LatLong(std::cos(bisectorBearing), std::sin(bisectorBearing));
    }
	
    static double calculateBearing(const LatLong& from, const LatLong& to) {
        double dLon = (to.longitude - from.longitude) * DEG_TO_RAD;
        double lat1 = from.latitude * DEG_TO_RAD;
        double lat2 = to.latitude * DEG_TO_RAD;
        
        double y = std::sin(dLon) * std::cos(lat2);
        double x = std::cos(lat1) * std::sin(lat2) - std::sin(lat1) * std::cos(lat2) * std::cos(dLon);
        
		// Updating 
		// return std::atan2(y, x); This was OG, but im imagning an edge case at 180/-180 with my bearing..
		
		// New approach shifts to [0, 2PI) which also helps with talking in terms of 0 to 360
		// If you choose to go back, have to handle the edge case and update the angle difference logic
		return std::fmod(std::atan2(y, x) + 2 * PI, 2 * PI);
    }

    static LatLong movePoint(const LatLong& point, double bearing, double distance) {
        double d = distance / EARTH_RADIUS;
        double lat1 = point.latitude * DEG_TO_RAD;
        double lon1 = point.longitude * DEG_TO_RAD;
        
        double lat2 = std::asin(std::sin(lat1) * std::cos(d) + 
                                std::cos(lat1) * std::sin(d) * std::cos(bearing));
        double lon2 = lon1 + std::atan2(std::sin(bearing) * std::sin(d) * std::cos(lat1),
                                        std::cos(d) - std::sin(lat1) * std::sin(lat2));
        
        return LatLong(lat2 * RAD_TO_DEG, lon2 * RAD_TO_DEG);
    }
};