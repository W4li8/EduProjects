#include "graphics.hpp"

void DrawPoint(Pencil& cr, const Point2D& P, Color dot) {
    cr->save();
	cr->arc(P.x, P.y, 1, 0.0, 2*M_PI);
    cr->set_source_rgba(dot.red, dot.green, dot.blue, dot.alpha);
    cr->fill();
    cr->restore();
    // Draw(cr, {P, 1.0}, line, line);
}
void DrawSegment(Pencil& cr, const Segment2D& S, Color line) {
	cr->save();
	cr->move_to(S.A.x, S.A.y);
    cr->line_to(S.B.x, S.B.y);
    cr->set_source_rgba(line.red, line.green, line.blue, line.alpha);
    cr->stroke();
    cr->restore();
}

void DrawCircle(Pencil& cr, const Circle2D& C, Color line, Color fill) {
    cr->save();
	cr->arc(C.center.x, C.center.y, C.radius, 0.0, 2*M_PI);
    cr->set_source_rgba(fill.red, fill.green, fill.blue, fill.alpha);
    cr->fill_preserve();
    cr->set_source_rgba(line.red, line.green, line.blue, line.alpha);
    cr->stroke();
    cr->restore();
}

void DrawTriangle(Pencil& cr, const Triangle2D& T, Color line, Color fill) {
    cr->save();
    cr->move_to(T.A.x, T.A.y);
    cr->line_to(T.B.x, T.B.y);
    cr->line_to(T.C.x, T.C.y);
    cr->line_to(T.A.x, T.A.y);
    cr->set_source_rgba(fill.red, fill.green, fill.blue, fill.alpha);
    cr->fill_preserve();
    cr->set_source_rgba(line.red, line.green, line.blue, line.alpha);
    cr->stroke();
    cr->restore();
}
void DrawQuadrilateral(Pencil& cr, const Quadrilateral2D& R, Color line, Color fill) {

	cr->save();
    cr->move_to(R.A.x, R.A.y);
    cr->line_to(R.B.x, R.B.y);
    cr->line_to(R.C.x, R.C.y);
    cr->line_to(R.D.x, R.D.y);
    cr->line_to(R.A.x, R.A.y);
    cr->set_source_rgba(fill.red, fill.green, fill.blue, fill.alpha);
    cr->fill_preserve();
    cr->set_source_rgba(line.red, line.green, line.blue, line.alpha);
    cr->stroke();
    cr->restore();
}

void Draw(Pencil& cr, const Polygon2D& Poly, Color line, Color fill) {
	cr->save();
    cr->move_to(Poly.vertices[Poly.n].x, Poly.vertices[Poly.n].y);
    for(auto& vertex : Poly.vertices) {
        cr->line_to(vertex.x, vertex.y);
    }
    cr->set_source_rgba(fill.red, fill.green, fill.blue, fill.alpha);
    cr->fill_preserve();
    cr->set_source_rgba(line.red, line.green, line.blue, line.alpha);
    cr->stroke();
    cr->restore();
}