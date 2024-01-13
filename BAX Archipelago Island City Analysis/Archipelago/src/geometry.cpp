#include "geometry.hpp"
#include <cmath>
#include <algorithm>


float fDistancePoint2Point(Coord2D P, Coord2D Q) {return float(DistancePoint2Point(P,Q));}

std::string Coord2D::to_string() const {
	return '('+ bsfn(x) +", "+ bsfn(y) +')';
}

std::ostream& operator<<(std::ostream& os, const Coord2D& me) { return os <<"("<< me.x <<", "<< me.y <<")"; }
std::ostream& operator<<(std::ostream& os, const Coord3D& me) { return os <<"("<< me.x <<", "<< me.y <<", "<< me.z <<")"; }
bool operator==(const Coord2D& lhs, const Coord2D& rhs) { return lhs.x == rhs.x && lhs.y == rhs.y; }
bool operator!=(const Coord2D& lhs, const Coord2D& rhs) { return !(lhs == rhs); }
bool operator==(const Coord3D& lhs, const Coord3D& rhs) { return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z; }


//line from eq. ax + by + c = 0
static float DistancePoint2Line(Coord2D P, float a, float b, float c) {
	return abs(a*P.x + b*P.y + c)/sqrt(a*a + b*b);
}
static float Norm(Vector2D v) {
	return sqrt(v.x*v.x + v.y*v.y);
}


//dist(P,Q)
float DistancePoint2Point(Coord2D P, Coord2D Q) {
	// float dx{P.x - Q.x}, dy{P.y - Q.y};
	// return sqrt(dx*dx + dy*dy);
	return Norm(Q-P);
}

//dist(P, [A,B])
float DistancePoint2Segment(Coord2D P, Coord2D A, Coord2D B) {
    Vector2D PA = A-P;
    Vector2D AB = B-A;
    Vector2D BP = P-B;

	return PA*AB > 0 ? DistancePoint2Point(P, A)
		 : AB*BP > 0 ? DistancePoint2Point(B, P)
		 :             DistancePoint2Line(P, A, B);
}
//dist(P, [A,B))
float DistancePoint2Ray(Coord2D P, Coord2D A, Coord2D B) {
    Vector2D PA = A-P;
    Vector2D AB = B-A;

	return PA*AB > 0 ? DistancePoint2Point(P, A)
	     :             DistancePoint2Line(P, A, B);
}
// dist(P, (A,B))
float DistancePoint2Line(Coord2D P, Coord2D A, Coord2D B) {
	// line equation between two points: y-y1 = (y2-y1)/(x2-x1) * (x-x1)
    return DistancePoint2Line(P, (A.y - B.y), (B.x - A.x), (A.x*B.y - B.x*A.y));
}

