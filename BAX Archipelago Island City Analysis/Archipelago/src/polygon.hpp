#ifndef POLYGON_H
#define POLYGON_H

#include<iostream>
#include<vector>
#include<float.h>
#include <algorithm>
#include "coordinates.hpp"
#include "shape.hpp"
#include "geometry.hpp"

float DistancePoint2Point(Coord2D P, Coord2D Q);
float DistancePoint2Segment(Coord2D P, Coord2D A, Coord2D B);
float DistancePoint2Ray(Coord2D P, Coord2D A, Coord2D B);
float DistancePoint2Line(Coord2D P, Coord2D A, Coord2D B);

class Polygon2D : public Shape2D {
public:
    Polygon2D(std::vector<Coord2D> vertices): vertices{vertices}, n{vertices.size()-1} {}
    std::vector<Coord2D> vertices;
    size_t n; // last element access of n-gone

    float Distance(const Coord2D& P) override {
        if(vertices.size() < 2) {
            std::cout<<"\tD: "<< DistancePoint2Point(P, vertices[0]);
            return DistancePoint2Point(P, vertices[0]);
        }
        float ans{FLT_MAX};
        for(size_t i{0}, j{n}; i <= n; j = i++) {
            ans = std::min(ans, DistancePoint2Segment(P, vertices[i], vertices[j]));
        }
        for(auto& v : vertices)std::cout<<v;std::cout<<"\tD"<<P<<": "<<ans<<'\n';
        return ans;
    }

    float Perimeter(void) override {
        if(vertices.size() < 3) // degenerate polygon
            return (vertices[0]-vertices[n]).norm();

        float ans{0};
        for(size_t i{0}, j{n}; i <= n; j = i++) {
            ans += (vertices[i]-vertices[j]).norm();
        }
        return ans;
    }

    // http://geomalgorithms.com/a01-_area.html
    float Area(void) override {
        if(vertices.size() < 3) // degenerate polygon
            return 0.0;

        float ans{vertices[0].x*(vertices[1].y - vertices[n].y)};
        for(int i{2}; i <= n; ++i) {
            ans += vertices[i-1].x*(vertices[i].y - vertices[i-2].y);
        }
        ans += vertices[n].x*(vertices[0].y - vertices[n-1].y);
        return 0.5*ans;
    }

    Coord2D Center(void) override {
        Coord2D ans{0,0};
        for(int i{0}; i <= n; ++i) {
            ans = ans + vertices[i];
        }
        return ans/vertices.size();
    }
    float eps = std::numeric_limits<float>::epsilon();
    // https://wrf.ecse.rpi.edu/Research/Short_Notes/pnpoly.html
    bool Contains(const Coord2D& P) {
        if(Distance(P) == 0) // on the edge
            return true;
        //determine polygon extremes
        float minX = vertices[0].x;
        float maxX = vertices[0].x;
        float minY = vertices[0].y;
        float maxY = vertices[0].y;
        for(int i = 1 ; i <= n ; i++) {
            Coord2D q = vertices[i];
            minX = std::min( q.x, minX );
            maxX = std::max( q.x, maxX );
            minY = std::min( q.y, minY );
            maxY = std::max( q.y, maxY );
        }
        //return false if outside extremes
        if(P.x < minX || P.x > maxX || P.y < minY || P.y > maxY) {
            return false;
        }
        // simplified exprssion counting nb of polygon sides' crossings, return even = outside/odd = inside
        bool inside = false;
        for(size_t i{0}, j{n}; i <= n; j = i++) {
            if((vertices[i].y > P.y ) != (vertices[j].y > P.y)
               && P.x < (vertices[j].x - vertices[i].x)*(P.y - vertices[i].y)/(vertices[j].y - vertices[i].y) + vertices[i].x) {
                inside = !inside;
            }
        }
        return inside;
    }
};

#endif//POLYGON_H