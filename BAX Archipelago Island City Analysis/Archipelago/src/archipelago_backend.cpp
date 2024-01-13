#include <iostream>
#include <gtkmm/drawingarea.h>
#include <gtkmm/gesturezoom.h>
// #include "zone.hpp"
#include <memory.h>
#include <sstream>
#include <cmath>
#include <fstream>
#include <vector>
#include "archipelago_backend.hpp"
#include "geometry.hpp"

ArchipelagoBackend::ArchipelagoBackend(void)
// : Ox{0}, Oy{0}, S{1}, Rz{0}, Tx{0}, Ty{0}
// , zone_edit{ZoneEdit::NONE}, link_edit{LinkEdit::NONE}
: selectedzone{0} {
    OpenFile("test2.txt");
}

bool ArchipelagoBackend::OpenFile(std::string filename) {
    std::ifstream file{filename};
    if(!file.is_open()) return 0;

    auto ParseLineFromFile = [&file](auto&... args) {
        std::string line; getline(file, line);
        line.erase(std::find(line.begin(), line.end(), '#'), line.end()); // strip comment

        std::istringstream iss{line};
        return (iss >> ... >> args) && !iss.fail(); // parse line for args
    };

    for(auto& [type, zonelist] : Zone::Types) {
        while(!file.eof()) {
            uint zones2read{0};
            if(ParseLineFromFile(zones2read)) {
                uint id, nb_people;
                float x, y;
                while(!file.eof() && zones2read) {
                    if(ParseLineFromFile(id, x, y, nb_people)) {
                        CreateZone(type, {x, y}, nb_people, id);
                        zones2read -= 1;
                    }
                }
                break;
            }
        }
    }
    while(!file.eof()) {
        uint links2read{0};
        if(ParseLineFromFile(links2read)) {
            uint id1, id2;
            while(!file.eof() && links2read) {
                if(ParseLineFromFile(id1, id2)) {
                    ConnectZones(id1, id2);
                    links2read -= 1;
                }
            }
            break;
        }
    }
    file.close();
    return 1;
}

bool ArchipelagoBackend::SaveFile(std::string filename) {
    std::ofstream file{filename};
    if(!file.is_open()) return 0;

    time_t clock = time(0);
    file <<"# "<< ctime(&clock);

    for(auto& [type, counter] : Zone::Types) {
        file <<"\n# "<< type <<"s\n"<< counter.size() <<'\n';
        for(auto id : counter) {
            file <<'\t'<< zones.at(id) <<'\n';
        }
    }
    file <<"\n# Links\n" << links.size() <<'\n';
    for(auto& [idx, link] : links) {
        file <<'\t'<< idx[A] <<' '<< idx[B] <<'\n';
    }
    file.close();
    return 1;
}

bool ArchipelagoBackend::SpacePermitsZone(Coord2D center, float radius, uint ignore) {

    for(auto& [id, zone] : zones) {
        if(id != ignore && DistancePoint2Point(zone.getCenter(), center) < (zone.getRadius() + radius)) {
            //std::cout <<"ERROR - Zones "<< key <<" and "<< center.x<<' '<<center.y <<" id "<< id <<" overlap.\n";
            return false;
        }
    }
    for(auto& [idx, link] : links) {
        if(not SpacePermitsLink(idx[A], idx[B])) {
            return false;
        }
    }
    return true;
}

bool ArchipelagoBackend::SpacePermitsZone(const Zone& z0) {
    return SpacePermitsZone(z0.getCenter(), z0.getRadius(), z0.id);
}

void ArchipelagoBackend::CreateZone(ZoneType zonetype, Coord2D pos, uint nb_people, uint id) {
    static uint max_id{0};
    //TODO: params validation check
    if(SpacePermitsZone(pos, sqrt(nb_people))) {
        id ? max_id = MAX(id, max_id) : id = ++max_id;

        zones.try_emplace(id, id, zonetype, pos, nb_people);
        // queue_draw();
    }
}



void ArchipelagoBackend::DestroyZone(ZoneId id) {

    for(auto zone : zones.at(id).getNeighbours()) {
        DisconnectZones(id, zone);
    }
    zones.erase(id);
    // queue_draw();
}


bool ArchipelagoBackend::SpacePermitsLink(ZoneId id1, ZoneId id2) {

    for(auto& [id, zone] : zones) {
        if(id != id1 && id != id2 && DistancePoint2Segment(zone.getCenter(), zones.at(id1).getCenter(), zones.at(id2).getCenter()) < zone.getRadius()) {
            // std::cerr <<"ERROR - Link between zones "<< id1 <<"("<<citymap.at(id1)->getCenter().x<<','<<citymap.at(id1)->getCenter().y<<")"<<" and "<< id2<<"("<<citymap.at(id2)->getCenter().x<<','<<citymap.at(id2)->getCenter().y<<")"
            //           <<" passes through zone "<< zone->id<<"("<<zone->getCenter().x<<','<<zone->getCenter().y<<") dist: " <<DistancePoint2Segment(zone->getCenter(), citymap.at(id1)->getCenter(), citymap.at(id2)->getCenter())<<" vs "<<zone->getRadius()<<".\n";
            return false;
        }
    }
    return true;
}
bool ArchipelagoBackend::LinkAllowed(ZoneId id1, ZoneId id2) {
    return zones.count(id1) && zones.count(id2)
        && (not zones.at(id1).IsOftenCongested()) and (not zones.at(id2).IsOftenCongested());
}


void ArchipelagoBackend::ConnectZones(ZoneId id1, ZoneId id2) {

    if(LinkAllowed(id1, id2) and SpacePermitsLink(id1, id2)) {

        zones.at(id1).AddNeighbour(id2);
        zones.at(id2).AddNeighbour(id1);

        links.try_emplace({id1, id2}, zones.at(id1), zones.at(id2));
        // queue_draw();
    }
}

void ArchipelagoBackend::DisconnectZones(ZoneId id1, ZoneId id2) {

    zones.at(id1).RemoveNeighbour(id2);
    zones.at(id2).RemoveNeighbour(id1);

    links.erase({id1, id2});
    // queue_draw();
}




// void ArchipelagoBackend::Scale(float sign) {
//     static float zoom{1};
//     if(S == 1) zoom = 1; // for smooth view reset

//     zoom = CLAMP(zoom*(1 + sign*0.02), 0.1326, 7.2446);
//     // slightly adapt view to windows size
//     S = CLAMP(zoom*MIN(width, height)/500, 0.3, 3);
//     // queue_draw();
// }

// void ArchipelagoBackend::Rotate(float sign) {
//     static float deg{0};
//     if(Rz == 0) deg = 0; // for smooth view reset

//     deg = std::fmod(deg + sign, 360);
//     // convert to radians for direct use
//     Rz = 2*deg*M_PI/180;
//     // queue_draw();
// }

// void ArchipelagoBackend::Translate(float dx, float dy) {
//     Tx -= dx;
//     Ty -= dy;
//     // queue_draw();
// }

// void ArchipelagoBackend::Origin(void) {
//     Gtk::Allocation allocation = get_allocation();
//     width = allocation.get_width();
//     height = allocation.get_height();

//     Ox = width/2;
//     Oy = height/2;
//     // queue_draw();
// }

// void ArchipelagoBackend::UpdateViewModifiers(void) {
//     // Ox, Oy and S depend on window size
//     Origin();
//     Scale();
//     // Tx, Ty and Rz are unchanged
// }

// void ArchipelagoBackend::ResetView(void) {
//     Origin();
//     S  = 1;
//     Rz = 0;
//     Tx = 0;
//     Ty = 0;
//     // queue_draw();
// }

//##########################   EDITOR    #################################

ZoneId ArchipelagoBackend::IdentifyZone(Coord2D xy) {
    for(auto& [id, zone] : zones) {
        if(DistancePoint2Point(xy, zone.getCenter()) < zone.getRadius()) {
            return id;
        }
    }
    return 0;
}

LinkId ArchipelagoBackend::IdentifyLink(Coord2D xy) {
    for(auto& [idx, link] : links) {
        if(DistancePoint2Segment(xy, link[A].getCenter(), link[B].getCenter()) < EPS) {
            return idx;
        }
    }
    return {0, 0};
}


void ArchipelagoBackend::AddZone(ZoneType type, Coord2D xy, uint capacity, uint id) {
    CreateZone(type, xy, capacity, id);
}
void ArchipelagoBackend::ModifyZone(Coord2D xy, EditState state) {
    static Vector2D offset; // visual selection gap

    static Coord2D c_backup; // static Circle2D() ? in shape.hpp
    static float r_backup;

    if(state != EditState::INIT && zone_edit == ZoneEdit::NONE) return ;
    switch(state) {
      case EditState::INIT:
        for(auto& [id, zone] : zones) {
            float distance = zone.Distance(xy);
            if(abs(distance) < EPS) {
                selectedzone = id;
                r_backup = zone.getRadius();
                zone_edit = ZoneEdit::RESIZE;
                break;
            } else if(distance < 0) {
                selectedzone = id;
                c_backup = zone.getCenter();
                offset = xy - zone.getCenter();
                zone_edit = ZoneEdit::MOVE;
                break;
            }
        }
        return ;
      case EditState::UPDATE:
        if(zone_edit == ZoneEdit::RESIZE) {
            zones.at(selectedzone).setRadius(CLAMP(zones.at(selectedzone).DistanceFromCenter(xy), 10, 300));
            edit_text = "Resizing zone "+ str(selectedzone) +" to fit "+ str(zones.at(selectedzone).getCapacity()) +" people ";
        }
        if(zone_edit == ZoneEdit::MOVE) {
            zones.at(selectedzone).setCenter(xy - offset);
            edit_text = "Moving zone "+ str(selectedzone) +" \nto "+ zones.at(selectedzone).getCenter().getInfoString();
        }
        break;
      case EditState::END:
        if(not SpacePermitsZone(zones.at(selectedzone))) {
            if(zone_edit == ZoneEdit::RESIZE) {
                zones.at(selectedzone).setRadius(r_backup);
            }
            if(zone_edit == ZoneEdit::MOVE) {
                zones.at(selectedzone).setCenter(c_backup);
            }
        }
        selectedzone = 0;
        zone_edit = ZoneEdit::NONE;
        break;
    }
    ShortestPath(EditState::UPDATE);
    // queue_draw();
}
void ArchipelagoBackend::RemoveZone(Coord2D xy) {
    ZoneId id = IdentifyZone(xy);
    if(id) {
        DestroyZone(id);
    }
}


void ArchipelagoBackend::AddLink(Coord2D xy, EditState state) {
    if(state != EditState::INIT && link_edit == LinkEdit::NONE) return ;

    ZoneId id = IdentifyZone(xy);
    switch(state) {
      case EditState::INIT:
        if(id) {
            selectedzone = id;
            cursor = xy;
            link_edit = LinkEdit::ADD;
        }
        return ;
      case EditState::UPDATE:
        cursor = xy;
        edit_text = "Connecting zone "+ str(selectedzone) +" to "+ ((id && id != selectedzone) ? str(id) : "??");
        break;
      case EditState::END:
        if(id) {
            ConnectZones(selectedzone, id);
        }
        selectedzone = 0;
        link_edit = LinkEdit::NONE;
        break;
    }
    // queue_draw();
}
void ArchipelagoBackend::RemoveLink(Coord2D xy) {
    if(!IdentifyZone(xy)) {
        LinkId idx = IdentifyLink(xy);
        if(idx) {
            DisconnectZones(idx[A], idx[B]);
        }
    }
}

// bool ArchipelagoBackend::on_draw(const Cairo::RefPtr<Cairo::Context>& cr) {

//     UpdateViewModifiers();

//     cr->save();
//     // Fill background (default: black border, white background)
//     DrawQuadrilateral(cr, {{0, 0}, {width, 0}, {width, height}, {0, height}});
//     // Setup drawing for ArchipelagoBackend coordinates
//     cr->translate(Ox + Tx, Oy + Ty);
//     cr->rotate(Rz);
//     cr->scale(S, -S);

//     for(auto& [idx, link] : links) {
//         DrawLink(cr, link);
//     }
//     if(link_edit == LinkEdit::ADD) {
//         DrawSegment(cr, {zones.at(selectedzone).getCenter(), cursor});
//     }

//     for(auto& [id, zone] : zones) {
//         DrawZone(cr, zone);
//     }
//     if(zone_edit == ZoneEdit::RESIZE) {
//         // cr->set_line_width(2);
//         DrawCircle(cr, {zones.at(selectedzone).getCenter(), zones.at(selectedzone).getRadius()}, black, {white, 0.0});
//     }
//     if(zone_edit == ZoneEdit::MOVE) {
//         Coord2D c{zones.at(selectedzone).getCenter()}; float r015{0.15f*zones.at(selectedzone).getRadius()};
//         // cr->set_line_width(2);
//         DrawSegment(cr, {{c + Coord2D(-r015, -r015)}, {c + Coord2D(r015, r015)}});
//         DrawSegment(cr, {{c + Coord2D(-r015, r015)}, {c + Coord2D(r015, -r015)}});
//     }
//     cr->restore();
//     return 1; // return 1 stops event propagation
// }

// void ArchipelagoBackend::DrawLink(const Cairo::RefPtr<Cairo::Context>& cr, const Link& link) {

//     // cr->save();
//     cr->set_line_width(link.getSpeedLimit()*1.2);
//     DrawSegment(cr, {link[A].getCenter(), link[B].getCenter()},
//                     (link.getSpeedLimit() == F_SPEED) ? (link.marked ? red : green)
//                                                       : (link.marked ? orange : black));
//     cr->set_line_width(1);
//     // cr->restore();
// }

// void ArchipelagoBackend::DrawZone(const Cairo::RefPtr<Cairo::Context>& cr, const Zone& zone) {
//     Coord2D c{zone.getCenter()}; float r{zone.getRadius()};

//     // cr->save();
//     switch(zone.type) {
//       case ZoneType::PRODUCTION: {
//         float r012 = 0.12*r; float r070 = 0.70*r;
//         DrawCircle(cr, {c, r}, black, red);

//         DrawQuadrilateral(cr, {{c.x - r070, c.y - r012}, {c.x + r070, c.y - r012},
//                                {c.x + r070, c.y + r012}, {c.x - r070, c.y + r012}}, white);
//       } break;
//       case ZoneType::RESIDENTIAL: {
//         float r038 = 0.5*0.75*r; float r065 = 0.5*sqrt(3)*0.75*r; float r075 = 0.75*r;
//         float r030 = 0.5*0.60*r; float r052 = 0.5*sqrt(3)*0.60*r; float r060 = 0.60*r;
//         DrawCircle(cr, {c, r}, white);
//         DrawCircle(cr, {c, r}, blue, {0,0,255,0.5});

//         DrawTriangle(cr, {{c.x, c.y - r075}, {c.x - r065, c.y + r038}, {c.x + r065, c.y + r038}}, white);
//         DrawTriangle(cr, {{c.x, c.y + r075}, {c.x - r065, c.y - r038}, {c.x + r065, c.y - r038}}, white);
//         DrawTriangle(cr, {{c.x, c.y - r060}, {c.x - r052, c.y + r030}, {c.x + r052, c.y + r030}}, pink, pink);
//         DrawTriangle(cr, {{c.x, c.y + r060}, {c.x - r052, c.y - r030}, {c.x + r052, c.y - r030}}, pink, pink);
//       } break;
//       case ZoneType::TRANSPORT: {
//         float r071 = M_SQRT1_2*r;
//         DrawCircle(cr, {c, r}, white);
//         cr->set_line_width(4);
//         DrawCircle(cr, {c, r}, lgreen, {lgreen,0.2});
//         cr->set_line_width(1);

//         DrawSegment(cr, {{c.x + r, c.y}, {c.x - r, c.y}}, lgreen);
//         DrawSegment(cr, {{c.x + r071, c.y + r071}, {c.x - r071, c.y - r071}}, lgreen);
//         DrawSegment(cr, {{c.x, c.y + r}, {c.x, c.y - r}}, lgreen);
//         DrawSegment(cr, {{c.x - r071, c.y + r071}, {c.x + r071, c.y - r071}}, lgreen);
//       } break;
//       default:;
//     }
//     // cr->restore();
// }

void ArchipelagoBackend::ClearCity(void) {
    links.clear();
    zones.clear();
}





std::string ArchipelagoBackend::InfoFromCoordinates(Coord2D xy) {

    ZoneId id = IdentifyZone(xy);
    if(id) return zones.at(id).getInfoString();

    LinkId idx = IdentifyLink(xy);
    if(idx) return links.at(idx).getInfoString();

    return "";
}

// Coord2D ArchipelagoBackend::MouseToArchipelagoXY(double mx, double my) {
//     return {float( 1/S*(cos(Rz)*(mx - Ox - Tx) + sin(Rz)*(my - Oy - Ty))),
//             float(-1/S*(cos(Rz)*(my - Oy - Ty) - sin(Rz)*(mx - Ox - Tx)))};
// }


void ArchipelagoBackend::ComputePerformance(void) {
    static int i{0};
    std::cout<<i++<<" UPDATE PERFORMANCE\n";

    float ENJ = ComputeENJ();
    float CI = ComputeCI();
    float MTA = ComputeMTA();
    performance = "<b>ENJ:</b> "+ str(ENJ) +" <b>CI:</b> "+ str(CI) +" <b>MTA:</b> "+ str(MTA);
    // std::cout <<"ENJ "<<ENJ<<'\n';
    // std::cout <<"CI "<<CI<<'\n';
    // std::cout <<"MTA "<<MTA<<'\n';
}

float ArchipelagoBackend::ComputeENJ(void) {
    int result{0}, normalize{0};
    for(auto [type, zonelist] : Zone::Types) {
        uint tmp{0};
        for(auto id : zonelist) {
            tmp += zones.at(id).getCapacity();
        }
        switch(type) {
          case ZoneType::PRODUCTION:
            result += tmp;
            normalize += tmp;
            break;
          case ZoneType::RESIDENTIAL:
            result += tmp;
            normalize += tmp;
            break;
          case ZoneType::TRANSPORT:
            result -= tmp;
            normalize += tmp;
            break;
        }
    }
    std::cout<<"DONE ENJ\n";
    return float(result)/float(normalize);
}

float ArchipelagoBackend::ComputeCI(void) {
    float result{0};
    for(auto& [idx, link] : links) {
        result += link.getDistance()*min(link[A].getCapacity(), link[B].getCapacity())*link.getSpeedLimit();
    }
    std::cout<<"DONE CI\n";
    return result;
}

float ArchipelagoBackend::ComputeMTA(void) {
    float result{0};
    for(auto id : Zone::Types.at(ZoneType::RESIDENTIAL)) {
        for(auto [type, zonelist] : Zone::Types) {
            if(type != ZoneType::RESIDENTIAL) {
                for(auto idx : Dijkstra(id, zonelist)) {
                    result += links.at(idx).getTravelTime();
                }
            }
        }
    }
    std::cout<<"DONE MTA\n";
    return result/Zone::Types.at(ZoneType::RESIDENTIAL).size();
}


std::vector<LinkId> ArchipelagoBackend::Dijkstra(const ZoneId zi, const std::vector<ZoneId> zf) {

    struct DijkstraNode {
        bool  visited; // has it the zone been visited by the algorithm
        bool  stop;    // should outgoing connections be considered
        float time;    // shortest access time
        uint  prev;    // id of the node that provides best access time
        DijkstraNode(bool yn): visited{0}, stop{yn}, time{FLT_MAX}, prev{0} {}
    };
    std::map< uint, DijkstraNode > DijkstraGraph;
    // Generates a graph of all zones accessible from a zone
    // NB: need to specify type, trick with auto doesn't work for recursive lambdas
    std::function< void(ZoneId) > ZoneAccessGraph = [this, &ZoneAccessGraph, &DijkstraGraph](ZoneId id) {
        DijkstraGraph.try_emplace(id, !zones.at(id).CanTraverse());
        for(auto zone : zones.at(id).getNeighbours()) {
            if(!DijkstraGraph.count(zone)) {
                ZoneAccessGraph(zone);
            }
        }
    };
    // Utility function to find out which node to visit next
    auto FastestAccessUnvisitedNode = [&DijkstraGraph](void) {
        uint ans{0}; float best_time{FLT_MAX};
        for(auto& [id, node] : DijkstraGraph) {
            if(not node.visited and node.time < best_time) {
                best_time = node.time;
                ans = id;
            }
        }
        return ans;
    };
    // Make sure all link data is up to date
    for(auto& [idx, link] : links) {
        link.Update();
    }
    // Init graph of interest and starting node
    ZoneAccessGraph(zi);
    DijkstraGraph.at(zi).stop = 0;
    DijkstraGraph.at(zi).time = 0;
    // Look for shortest path
    for(uint id{0}; (id = FastestAccessUnvisitedNode()); ) {
        DijkstraNode& self = DijkstraGraph.at(id);
        self.visited = true;
        // Solution exists
        if(std::find(zf.begin(), zf.end(), id) != zf.end()) {
            std::vector<LinkId> shortest_path;
            for( ; id != zi; (id = DijkstraGraph.at(id).prev)) {
                shortest_path.push_back({id, DijkstraGraph.at(id).prev});
            }
            return shortest_path;
        }
        if(self.stop) continue;
        // Evaluate access to neighbours
        for(auto zone : zones.at(id).getNeighbours()) {
            DijkstraNode& other = DijkstraGraph.at(zone);
            if(not other.visited) {
                float time = self.time + links.at({id, zone}).getTravelTime();
                if(time < other.time) {
                    other.time = time;
                    other.prev = id;
                }
            }
        }
    }
    return std::vector<LinkId>{};
}

void ArchipelagoBackend::ShortestPath(EditState state, Coord2D position) {
    static ZoneId z1{0}, z2{0};

    switch(state) {
      case EditState::INIT:
        for(auto& [idx, link] : links) {
            link.marked = false;
        }
        z1 = IdentifyZone(position);
        z2 = 0;
        break;
      case EditState::UPDATE:
        if(z1 && z2) {
            for(auto& [idx, link] : links) {
                link.marked = false;
            }
            for(auto idx : Dijkstra(z1, {z2})) {
                links.at(idx).marked = true;
            }
        }
        break;
      case EditState::END:
        if(z1 && (z2 = IdentifyZone(position)) && z1 != z2)  {
            for(auto& idx : Dijkstra(z1, {z2})) {
                links.at(idx).marked = true;
            }
        }
        break;
    }
    // queue_draw();
}