#ifndef GRAPHICS_H
#define GRAPHICS_H

#include "geometry.hpp"
#include <gtkmm/drawingarea.h>


using Pencil = const Cairo::RefPtr<Cairo::Context>;

struct Color {
    Color(int red, int green, int blue, float alpha = 1.0)
    : red{float(red)/255}, green{float(green)/255}, blue{float(blue)/255}, alpha{alpha} {}
    Color(Color old, float alpha)
    : red{old.red}, green{old.green}, blue{old.blue}, alpha{alpha} {}


    constexpr Color(uint8_t r, uint8_t g, uint8_t b, float a)
        : red(r/255), green(g/255), blue(b/255), alpha(a) {}

    float red, green, blue, alpha;
};

const Color black {  0,  0,  0};
const Color white {255,255,255};
const Color red   {255,  0,  0};
const Color orange{255,123,  0};
const Color lgreen{  0,255,  0};
const Color green {  0,147,  0};
const Color blue  {  0,  0,255};
const Color pink  {135, 35, 135};
const Color macdefault {246,245,244};

void DrawPoint(Pencil& cr, const Point2D& P, Color line = black);
void DrawSegment(Pencil& cr, const Segment2D& S, Color line = black);
void DrawCircle(Pencil& cr, const Circle2D& C, Color line = black, Color fill = white);
void DrawTriangle(Pencil& cr, const Triangle2D& T, Color line = black, Color fill = white);
void DrawQuadrilateral(Pencil& cr, const Quadrilateral2D& R, Color line = black, Color fill = white);
void Draw(Pencil& cr, const Polygon2D& Poly, Color line = black, Color fill = white);

#endif//GRAPHICS_H