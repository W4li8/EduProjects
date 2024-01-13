#include "archipelago_drawing.hpp"
#include "graphics.hpp"


ArchipelagoDrawing::ArchipelagoDrawing(const ArchipelagoBackend& data)
: city{data}, Ox{0}, Oy{0}, S{1}, Rz{0}, Tx{0}, Ty{0} {}


void ArchipelagoDrawing::Scale(float sign) {
    static float zoom{1};
    if(S == 1) zoom = 1; // for smooth view reset

    zoom = CLAMP(zoom*(1 + sign*0.02), 0.0483, 19.4996);
    // slightly adapt view to windows size
    S = CLAMP(zoom*MIN(width, height)/500, 0.3, 3);
    queue_draw();
}

void ArchipelagoDrawing::Rotate(float sign) {
    static float deg{0};
    if(Rz == 0) deg = 0; // for smooth view reset

    deg = std::fmod(deg + sign, 360);
    // convert to radians for direct use
    Rz = 2*deg*M_PI/180;
    queue_draw();
}

void ArchipelagoDrawing::Translate(float dx, float dy) {
    Tx -= dx;
    Ty -= dy;
    queue_draw();
}

void ArchipelagoDrawing::ResetView(void) {
    Origin();
    S  = 1;
    Rz = 0;
    Tx = 0;
    Ty = 0;
    queue_draw();
}


void ArchipelagoDrawing::Origin(void) {
    Gtk::Allocation allocation = get_allocation();
    width = allocation.get_width();
    height = allocation.get_height();

    Ox = width/2;
    Oy = height/2;
    queue_draw();
}

void ArchipelagoDrawing::UpdateViewModifiers(void) {
    // Ox, Oy and S depend on window size
    Origin();
    Scale();
    // Tx, Ty and Rz are unchanged
}


void ArchipelagoDrawing::MouseToArchipelagoXY(float& mx, float& my) {
    float tmpx{mx - Ox - Tx};
    float tmpy{my - Oy - Ty};

    mx = (cos(Rz)*tmpx + sin(Rz)*tmpy)/S;
    my = (sin(Rz)*tmpx - cos(Rz)*tmpy)/S;
}
// return { 1/S*(cos(Rz)*(mx - Ox - Tx) + sin(Rz)*(my - Oy - Ty)),
//          1/S*(sin(Rz)*(mx - Ox - Tx) - cos(Rz)*(my - Oy - Ty)) };


bool ArchipelagoDrawing::on_draw(const Cairo::RefPtr<Cairo::Context>& cr) {

    UpdateViewModifiers();

    cr->save();
    // Fill background (default: black border, white background)
    DrawQuadrilateral(cr, {{0, 0}, {width, 0}, {width, height}, {0, height}});
    // Setup drawing for Archipelago coordinates
    cr->translate(Ox + Tx, Oy + Ty);
    cr->rotate(Rz);
    cr->scale(S, -S);

    for(auto& [idx, link] : city.links) {
        DrawLink(cr, link);
    }
    switch(city.link_edit) {
      case ArchipelagoBackend::LinkEdit::ADD: {
        int x, y; get_pointer(x, y);
        Coord2D cursor {float(x), float(y)};
        MouseToArchipelagoXY(cursor.x, cursor.y);
        DrawSegment(cr, {city.zones.at(city.selectedzone).getCenter(), cursor});
      } break;
      default:;
    }

    for(auto& [id, zone] : city.zones) {
        DrawZone(cr, zone);
    }
    switch(city.zone_edit) {
      case ArchipelagoBackend::ZoneEdit::MOVE: { // change cursor?
        Coord2D c{city.zones.at(city.selectedzone).getCenter()}; float r015{0.15f*city.zones.at(city.selectedzone).getRadius()};
        DrawSegment(cr, {{c + Coord2D(-r015, -r015)}, {c + Coord2D(r015, r015)}});
        DrawSegment(cr, {{c + Coord2D(-r015, r015)}, {c + Coord2D(r015, -r015)}});
      } break;
      case ArchipelagoBackend::ZoneEdit::RESIZE: { // change cursor?
        DrawCircle(cr, {city.zones.at(city.selectedzone).getCenter(), city.zones.at(city.selectedzone).getRadius()}, black, {white, 0.0});
      } break;
      default:;
    }
    cr->restore();
    return 1; // stop event propagation
}

void ArchipelagoDrawing::DrawLink(const Cairo::RefPtr<Cairo::Context>& cr, const Link& link) {

    cr->set_line_width(link.getSpeedLimit()*1.2);
    DrawSegment(cr, {link[A].getCenter(), link[B].getCenter()},
                    (link.getSpeedLimit() == F_SPEED) ? (link.marked ? red : green)
                                                      : (link.marked ? orange : black));
    cr->set_line_width(1);
}

void ArchipelagoDrawing::DrawZone(const Cairo::RefPtr<Cairo::Context>& cr, const Zone& zone) {
    Coord2D c{zone.getCenter()}; float r{zone.getRadius()};

    switch(zone.type) {
      case ZoneType::PRODUCTION: {
        float r012 = 0.12*r; float r070 = 0.70*r;
        DrawCircle(cr, {c, r}, black, red);

        DrawQuadrilateral(cr, {{c.x - r070, c.y - r012}, {c.x + r070, c.y - r012},
                               {c.x + r070, c.y + r012}, {c.x - r070, c.y + r012}}, white);
      } break;
      case ZoneType::RESIDENTIAL: {
        float r038 = 0.5*0.75*r; float r065 = 0.5*sqrt(3)*0.75*r; float r075 = 0.75*r;
        float r030 = 0.5*0.60*r; float r052 = 0.5*sqrt(3)*0.60*r; float r060 = 0.60*r;
        DrawCircle(cr, {c, r}, white);
        DrawCircle(cr, {c, r}, blue, {0,0,255,0.5});

        DrawTriangle(cr, {{c.x, c.y - r075}, {c.x - r065, c.y + r038}, {c.x + r065, c.y + r038}}, white);
        DrawTriangle(cr, {{c.x, c.y + r075}, {c.x - r065, c.y - r038}, {c.x + r065, c.y - r038}}, white);
        DrawTriangle(cr, {{c.x, c.y - r060}, {c.x - r052, c.y + r030}, {c.x + r052, c.y + r030}}, pink, pink);
        DrawTriangle(cr, {{c.x, c.y + r060}, {c.x - r052, c.y - r030}, {c.x + r052, c.y - r030}}, pink, pink);
      } break;
      case ZoneType::TRANSPORT: {
        float r071 = 0.71*r; // M_SQRT1_2
        DrawCircle(cr, {c, r}, white);
        cr->set_line_width(4);
        DrawCircle(cr, {c, r}, lgreen, {lgreen,0.2});
        cr->set_line_width(1);

        DrawSegment(cr, {{c.x + r, c.y}, {c.x - r, c.y}}, lgreen);
        DrawSegment(cr, {{c.x + r071, c.y + r071}, {c.x - r071, c.y - r071}}, lgreen);
        DrawSegment(cr, {{c.x, c.y + r}, {c.x, c.y - r}}, lgreen);
        DrawSegment(cr, {{c.x - r071, c.y + r071}, {c.x + r071, c.y - r071}}, lgreen);
      } break;
      default:;
    }
}