#ifndef LINK_HPP
#define LINK_HPP

#include "utilities.hpp"
#include "zone.hpp"

class Link {
  public: /* --- DEFINITIONS --------------------------------------- */
    enum Extremity { A, B };

    struct LinkId {
      public: /* --- PUBLIC ACCESS --------------------------------- */
        LinkId(ZoneId id1, ZoneId id2)
        : id1{MIN(id1, id2)}, id2{MAX(id1, id2)} {}
        // easy access: [A] -> id1 & [B] -> id2
        ZoneId operator[](Extremity x) const { return x ? id2 : id1; }

      private: /* -- DATA ------------------------------------------ */
        const ZoneId id1;
        const ZoneId id2;

      public: /* --- UTILITY --------------------------------------- */
        // copy of operator< expression for std::pair, used by std::map for comparisons
        friend bool operator<(const LinkId& lhs, const LinkId& rhs) {
            return lhs.id1 < rhs.id1 || (!(rhs.id1 < lhs.id1) && lhs.id2 < rhs.id2);
        }
        operator bool() const { return id1 && id2; }
    };
  private:
	// static inline std::map< ZoneId, std::vector<ZoneId> > neighbours;

  public: /* --- PUBLIC ACCESS ------------------------------------- */
    Link(const Zone& z1, const Zone& z2)
    : marked{0}, z1{z1}, z2{z2} {
        Update();
    }
    Link(const Link& copy) = delete;
    // easy access: [A] -> z1 & [B] -> z2
    const Zone& operator[](Extremity x) const { return x ? z2 : z1; }

  public: // Flags
    bool marked; // set when link is on selected path

  public: // Getters & Setters
	float getSpeedLimit(void) const { return speed; }
	float getDistance(void)   const { return distance; }
	float getTravelTime(void) const { return time; }

	// static std::vector<ZoneId> getNeighbours(ZoneId id) {
	// 	return neighbours.count(id) ? neighbours.at(id) : std::vector<ZoneId>{};
	// }

	void Update(void) {
		speed = (z1.HasSpeedLimit() or z2.HasSpeedLimit()) ? S_SPEED : F_SPEED;
		distance = z1.Distance(z2);
		time = distance/speed;
	}
  private: /* -- DATA ---------------------------------------------- */
    const Zone& z1;
    const Zone& z2;

    float speed;    // defined by infrastructure
    float distance; // connection length
    float time;     // travel time

  public: /* --- UTILITY ------------------------------------------- */
    friend std::ostream& operator<<(std::ostream& os, const Link& obj) {
        return os << obj.z1.id <<' '<< obj.z2.id;
    }
    std::string getInfoString(void) {
        return "Link between "+ str(z2.id) +" and "+ str(z1.id) +"\nSpeed: "+ str(speed);
    }
    bool Connects(ZoneId id) { return id == z1.id or id == z2.id; }
};

using LinkId = Link::LinkId;
// Simplify access syntax
constexpr Link::Extremity A{Link::Extremity::A};
constexpr Link::Extremity B{Link::Extremity::B};

#endif//LINK_HPP

