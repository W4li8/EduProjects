#ifndef ZONE_HPP
#define ZONE_HPP

#include <map>
#include <vector>

#include "geometry.hpp"
#include "utilities.hpp"


using ZoneId = uint;

class Zone {
  public: /* --- DEFINITIONS --------------------------------------- */
    // order defines position in map which defines reading order from file
    enum class ZoneType { RESIDENTIAL, TRANSPORT, PRODUCTION };
    static inline std::map< ZoneType, std::vector<ZoneId> > Types = {
		{ZoneType::RESIDENTIAL, {}},
		{ZoneType::TRANSPORT,   {}},
		{ZoneType::PRODUCTION,  {}}
    };

  public: /* --- PUBLIC ACCESS ----------------------------------------------- */
    Zone(ZoneId id, ZoneType type, Coord2D xy, uint nb_people)
    : id{id}, type{type}, location{xy}, capacity{nb_people}, neighbours{} {
       	Counter.at(type).push_back(id);
    }
    Zone(const Zone& obj) = delete;
   ~Zone(void) {
		Counter.at(type).erase(std::find(Counter.at(type).begin(), Counter.at(type).end(), id));
    }
  public: // Methods
    bool CanTraverse(void)      const { return type != ZoneType::PRODUCTION; }
    bool IsOftenCongested(void) const { return (type != ZoneType::RESIDENTIAL) ? false : (neighbours.size() > 3); }
    bool HasSpeedLimit(void)    const { return type != ZoneType::TRANSPORT; }

    void AddNeighbour(ZoneId id)    { neighbours.emplace_back(id); }
    void RemoveNeighbour(ZoneId id) { neighbours.erase(std::find(neighbours.begin(), neighbours.end(), id)); }
  public: // Getters & Setters
    std::vector< ZoneId > getNeighbours(void) { return neighbours; }

    Coord2D getCenter(void) const { return location; }
    float   getRadius(void) const { return sqrt(capacity); }

    void setCenter(Coord2D c) { location = c; }
    void setRadius(float r)   { capacity = r*r; }

    Coord2D getLocation(void) const { return location; }
    float   getCapacity(void) const { return capacity; }
  public: // other :/ TODO
    float Distance(const Coord2D& xy) { return DistanceFromCenter(xy) - getRadius(); }
    float DistanceFromCenter(const Coord2D& xy) { return DistancePoint2Point(location, xy); }
    float Distance(const Zone& zone) const {
		return DistancePoint2Point(this->location, zone.location)
             - this->getRadius() - zone.getRadius();
	}
  public: /* --- DATA ---------------------------------------------- */
    const ZoneId id;     // unique identifier
    const ZoneType type; // zone classifier
  private:
    Coord2D location; // map coordinates (x,y) of the zone's center
    uint capacity;    // max population, determines the zone's radius
    std::vector< ZoneId > neighbours; // ids of neighbouring zones

	std::map< ZoneType, std::vector<ZoneId> >& Counter = Types;

  private: /* -- UTILITY ------------------------------------------- */
	static std::string enumZoneType2str(ZoneType type) {
		switch(type) {
			case ZoneType::PRODUCTION:  return "Production Zone";
			case ZoneType::TRANSPORT:   return "Transport Hub";
			case ZoneType::RESIDENTIAL: return "Residential Area" ;
		}
	}
  public:
    friend std::ostream& operator<<(std::ostream& os, const ZoneType& type) {
        return os << enumZoneType2str(type);
    }
  public:
	std::string getInfoString(void) const {
        return enumZoneType2str(type) +' '+ str(id) + "\nCapacity: "+ str(capacity);
    }
    friend std::ostream& operator<<(std::ostream& os, const Zone& obj) {
        return os << obj.id <<' '<< obj.location.x <<' '<< obj.location.y <<' '<< obj.capacity;
    }
};

using ZoneType = Zone::ZoneType;


#endif//ZONE_HPP