#ifndef ARCHIPELAGO_DRAWING
#define ARCHIPELAGO_DRAWING

#include <gtkmm/drawingarea.h>

#include "archipelago_backend.hpp"

class ArchipelagoDrawing : public Gtk::DrawingArea {
  public:
    ArchipelagoDrawing(const ArchipelagoBackend& data);
   ~ArchipelagoDrawing(void) = default;
  public:
	void Scale(float sign = 0);
	void Rotate(float sign = 0);
	void Translate(float dx = 0, float dy = 0);
	void ResetView(void);

	void MouseToArchipelagoXY(float& mx, float& my);

  private:
	const ArchipelagoBackend& city;

    float width, height;  // canvas dimensions

	float Ox, Oy; // origin of the coordinates system
    float S;      // scale of x,y-axis
    float Rz;     // rotation around z-axis
    float Tx, Ty; // translation of the coordinates system
  private:
	void Origin(void);
	void UpdateViewModifiers(void);

	virtual bool on_draw(const Cairo::RefPtr<Cairo::Context>& pencil) override;
	void DrawLink(const Cairo::RefPtr<Cairo::Context>& cr, const Link& link);
	void DrawZone(const Cairo::RefPtr<Cairo::Context>& cr, const Zone& zone);

};

#endif//ARCHIPELAGO_DRAWING