
#ifndef GEOMETRY2D_H
#define GEOMETRY2D_H
#include <cmath>
#include <algorithm>
#include <iostream>

#include "coordinates.hpp"
#include "polygon.hpp"
#include "utilities.hpp"


class Point2D : public Coord2D {
  public:
    Point2D(void): Coord2D() {}
    Point2D(float x, float y): Coord2D(x, y) {}

};

float DistancePoint2Point(Coord2D P, Coord2D Q);
float fDistancePoint2Point(Coord2D P, Coord2D Q);
float DistancePoint2Segment(Coord2D P, Coord2D A, Coord2D B);
float DistancePoint2Ray(Coord2D P, Coord2D A, Coord2D B);
float DistancePoint2Line(Coord2D P, Coord2D A, Coord2D B);

class Segment2D {
public:
    Segment2D(Coord2D A, Coord2D B): A{A}, B{B} {}
    Coord2D A, B;

    float Distance(const Coord2D& P)  { return DistancePoint2Segment(P, A, B); }
    float Perimeter(void)  { return 0;}
    float Area(void)  { return 0; }

    Coord2D Center(void)  { return (A+B)/2; }
};

class Triangle2D : public Polygon2D {
public:
    Triangle2D(Coord2D A, Coord2D B, Coord2D C): Polygon2D({A, B, C}), A{A}, B{B}, C{C} {}
    Coord2D A, B, C;

    float Distance(const Coord2D& P) override { return min(DistancePoint2Segment(P, A, B),
                                                                DistancePoint2Segment(P, B, C),
                                                                DistancePoint2Segment(P, C, A)); }
    float Perimeter(void) override { return (A-B).norm() + (B-C).norm() + (C-A).norm(); }
    float Area(void) override { return 0.5*((A-B)^(A-C)).norm(); }

    Coord2D Center(void) override { return (A+B+C)/3; }
};

class Quadrilateral2D : public Polygon2D {
public:
    Quadrilateral2D(Coord2D A, Coord2D B, Coord2D C, Coord2D D): Polygon2D({A, B, C}), A{A}, B{B}, C{C}, D{D} {}
    Coord2D A, B, C, D;

    float Distance(const Coord2D& P) override { return min(DistancePoint2Segment(P, A, B),
                                                                DistancePoint2Segment(P, B, C),
                                                                DistancePoint2Segment(P, C, D),
                                                                DistancePoint2Segment(P, D, A)); }
    float Perimeter(void) override { return (A-B).norm() + (B-C).norm() + (C-D).norm() + (D-A).norm(); }
    float Area(void) override { return 0.5*((A-B)^(A-D)).norm() + 0.5*((C-B)^(C-D)).norm(); }

    Coord2D Center(void) override { return (A+C)/2; }
};

#endif//GEOMETRY2D_H