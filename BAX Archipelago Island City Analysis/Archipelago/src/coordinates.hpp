#ifndef COORDINATES_H
#define COORDINATES_H

#include <iostream>
#include <cmath>
#include "utilities.hpp"

struct Coord3D {

    Coord3D(void): x{FLT_MAX}, y{FLT_MAX}, z{FLT_MAX} {}
    Coord3D(float x, float y, float z): x{x}, y{y}, z{z} {}
    float x, y, z;

    Coord3D operator+(const Coord3D& obj) { return {x + obj.x, y + obj.y, z + obj.z}; }
    Coord3D operator-(const Coord3D& obj) { return {x - obj.x, y - obj.y, z - obj.z}; }
    Coord3D operator*(const float& nb)   { return {x*nb, y*nb, z*nb}; }
    Coord3D operator/(const float& nb)   { return {x/nb, y/nb, z/nb}; }

    Coord3D& operator+=(const Coord3D& obj) { return *this = *this + obj; }
    Coord3D& operator-=(const Coord3D& obj) { return *this = *this - obj; }
    Coord3D& operator*=(const float& nb)   { return *this = *this*nb; }
    Coord3D& operator/=(const float& nb)   { return *this = *this/nb; }

    float  operator*(const Coord3D& obj) { return x*obj.x + y*obj.y + z*obj.z; }
    Coord3D operator^(const Coord3D& obj) { return {y*obj.z - z*obj.y, z*obj.x - x*obj.z, x*obj.y - y*obj.x}; }

    float norm(void) const { return sqrt(x*x + y*y + z*z); }

    friend bool operator==(const Coord3D& lhs, const Coord3D& rhs);
    friend std::ostream& operator<<(std::ostream& os, const Coord3D& me);
};
using Vector3D = Coord3D;


struct Coord2D {

    Coord2D(void): x{FLT_MAX}, y{FLT_MAX} {}
    Coord2D(float x, float y): x{x}, y{y} {}
    float x, y;

    std::string getInfoString(void) { return "X: "+ str(x) +" Y: "+ str(y); }


    Coord2D operator+(const Coord2D& obj) { return {x + obj.x, y + obj.y}; }
    Coord2D operator-(const Coord2D& obj) { return {x - obj.x, y - obj.y}; }
    Coord2D operator*(const float& nb)   { return {x*nb, y*nb}; }
    Coord2D operator/(const float& nb)   { return {x/nb, y/nb}; }

    Coord2D& operator+=(const Coord2D& obj) { return *this = *this + obj; }
    Coord2D& operator-=(const Coord2D& obj) { return *this = *this - obj; }
    Coord2D& operator*=(const float& nb)   { return *this = *this*nb; }
    Coord2D& operator/=(const float& nb)   { return *this = *this/nb; }

    float  operator*(const Coord2D& obj)  { return x*obj.x + y*obj.y; }
    Coord3D operator^(const Coord2D& obj)     { return {0.0, 0.0, x*obj.y - y*obj.x}; }

    float norm(void) const { return sqrt(x*x + y*y); }

    friend bool operator==(const Coord2D& lhs, const Coord2D& rhs);
    friend bool operator!=(const Coord2D& lhs, const Coord2D& rhs);
    std::string to_string() const;
    friend std::ostream& operator<<(std::ostream& os, const Coord2D& me);
};
using Vector2D = Coord2D;

#endif//COORDINATES_H