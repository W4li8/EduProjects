#ifndef ARCHIPELAGO_UI
#define ARCHIPELAGO_UI

#include <gtkmm/box.h>
#include <gtkmm/button.h>
#include <gtkmm/entry.h>
#include <gtkmm/frame.h>
#include <gtkmm/gesturedrag.h>
#include <gtkmm/gesturerotate.h>
#include <gtkmm/gesturezoom.h>
#include <gtkmm/grid.h>
#include <gtkmm/label.h>
#include <gtkmm/menu.h>
#include <gtkmm/menubutton.h>
#include <gtkmm/menuitem.h>
#include <gtkmm/togglebutton.h>
#include <gtkmm/window.h>

#include "archipelago_backend.hpp"
#include "archipelago_drawing.hpp"

class ArchipelagoUI : public Gtk::Window {
  public:
	ArchipelagoUI(void);
   ~ArchipelagoUI(void) = default;
  private:
    ArchipelagoBackend city;

// #################################### WIDGETS ################################### //
  private: // UI Widgets
// ==================================== LAYOUT ==================================== //
	Gtk::Grid 		   layout;

// ==================================== HEADER ==================================== //
	Gtk::Button 	   btn_info;

	Gtk::HBox   	   filesystem;
    Gtk::Entry  	   filepath;
    Gtk::Button 	   btn_open;
    Gtk::Button 	   btn_save;

    Gtk::Label  	   spacer; // widget to fill space

	Gtk::Button 	   btn_view;

	Gtk::Image  	   img_info { Gdk::Pixbuf::create_from_file("./img/ui/info.png") };
	Gtk::Image  	   img_view { Gdk::Pixbuf::create_from_file("./img/ui/view.png") };

// =============================== ARCHIPELAGO CITY =============================== //
	Gtk::Label   	   rating;
    ArchipelagoDrawing canvas;

// ==================================== EDITOR ==================================== //
	Gtk::Frame 		   editor_frame;
	Gtk::HBox  		   editor;
    Gtk::Label 		   info_desk;
	Gtk::ToggleButton  btn_zone;
	Gtk::ToggleButton  btn_link;
	Gtk::ToggleButton  btn_add_simple;
	Gtk::MenuButton    btn_add_choice; // mostly hidden button
	Gtk::ToggleButton  btn_edit;
	Gtk::ToggleButton  btn_remove;
    Gtk::Label 		   mouse_pos;

	Gtk::Menu 	  	   add_menu;
	Gtk::MenuItem 	   ResidentialArea;
	Gtk::MenuItem 	   TransportHub;
	Gtk::MenuItem 	   ProductionZone;

	Gtk::Image 		   img_zone 	  { Gdk::Pixbuf::create_from_file("./img/ui/zone.png") };
	Gtk::Image 		   img_link       { Gdk::Pixbuf::create_from_file("./img/ui/link.png") };
	Gtk::Image 		   img_add_simple { Gdk::Pixbuf::create_from_file("./img/ui/add.png") };
	Gtk::Image 		   img_add_choice { Gdk::Pixbuf::create_from_file("./img/ui/add.png") };
	Gtk::Image 		   img_edit       { Gdk::Pixbuf::create_from_file("./img/ui/edit.png") };
	Gtk::Image 		   img_remove     { Gdk::Pixbuf::create_from_file("./img/ui/remove.png") };


// #################################### SIGNALS ################################### //
  private: // User Signals
// ==================================== HEADER ==================================== //
	void DisplayInfo_cb(void);

	void OpenFile_cb(void);
	void SaveFile_cb(void);

	void ResetView_cb(void);

// =============================== ARCHIPELAGO CITY =============================== //
	virtual bool on_motion_notify_event(GdkEventMotion* event) override;
	virtual bool on_scroll_event(GdkEventScroll* event) override;

	bool KeyboardShortcuts_cb(GdkEventKey* event);

  	Glib::RefPtr<Gtk::GestureDrag> gesture_drag;
	void Drag_cb(float dx, float dy, ArchipelagoBackend::EditState state);

	Glib::RefPtr<Gtk::GestureRotate> gesture_rotate;
	void Rotate_cb(float new_angle, float ignore);

	Glib::RefPtr<Gtk::GestureZoom> gesture_zoom;
	void Zoom_cb(float new_scale);

// ==================================== EDITOR ==================================== //
	void EditZone_cb(void);
	void EditLink_cb(void);

	void AddSimple_cb(void);
	void AddChoice_cb(void);
	void AddMenu_cb(ZoneType choice);
	void Edit_cb(void);
	void Remove_cb(void);


// ################################### UTILITIES ################################## //
  private:
	void SetupWidgets(void);
	void PositionWidgets(void);
	void ConnectSignals(void);

	void UpdateRating(void);
	void UpdateInfoDesk(void);
    void UpdateMouseCoordinates(void);

	void UpdateEditorAction(void); // to remove/modify?
	void ResetEditor(void);// to remove/modify?

};

#endif//ARCHIPELAGO_UI