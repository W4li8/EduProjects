#ifndef SHAPE_H
#define SHAPE_H

#include "coordinates.hpp"

float DistancePoint2Point(Coord2D P, Coord2D Q);
float DistancePoint2Segment(Coord2D P, Coord2D A, Coord2D B);
float DistancePoint2Ray(Coord2D P, Coord2D A, Coord2D B);
float DistancePoint2Line(Coord2D P, Coord2D A, Coord2D B);

class Shape2D {
  public:
    virtual float Distance(const Coord2D& P) = 0;
    virtual float Perimeter(void) = 0;
    virtual float Area(void) = 0;

    virtual Coord2D Center(void) = 0; //centroid for triangle
};


class Circle2D : public Shape2D {
public:
    Circle2D(Coord2D center, float radius): center{center}, radius{radius} {}
    Coord2D center;
    float  radius;

    float Distance(const Coord2D& P) override { return DistancePoint2Point(center, P) - radius; }
    float Perimeter(void) override { return 2*M_PI*radius; }
    float Area(void) override { return M_PI*radius*radius; }

    Coord2D Center(void) override { return center; }
};



#endif//SHAPE_H