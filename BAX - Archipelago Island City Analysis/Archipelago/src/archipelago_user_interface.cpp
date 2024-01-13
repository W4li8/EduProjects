#include "archipelago_user_interface.hpp"


// Layout parameters
#define NAV_BAR(posX) 	(posX), 0
#define BODY(posY)      0, (posY+1)
#define FULL_WIDTH 		4
#define DEFAULT_HEIGHT 	1



void ArchipelagoUI::SetupWidgets(void) {

	btn_info.set_image(img_info);

	filepath.set_size_request(240,0);
    filepath.set_placeholder_text("File path");
	btn_open.set_label("Open");
	btn_save.set_label("Save");

	spacer.set_hexpand(1);

	btn_view.set_image(img_view);


	rating.set_markup("<u>MTA</u> <u>ENJ</u> <u>CI</u>"); // make proper
    canvas.set_size_request(300, 300);
	canvas.set_hexpand(1);
	canvas.set_vexpand(1);


	editor_frame.set_label(" Archipelago Editor ");
	editor_frame.set_label_align(0.02, 0.5);

	info_desk.set_width_chars(24);
	info_desk.set_xalign(0.05);

	btn_zone	  .set_image(img_zone);
	btn_link	  .set_image(img_link);
	btn_add_choice.set_image(img_add_choice);
	btn_add_simple.set_image(img_add_simple);
	btn_edit	  .set_image(img_edit);
	btn_remove	  .set_image(img_remove);

	btn_add_choice.set_popup(add_menu);
	btn_add_choice.set_direction(Gtk::ARROW_UP);
	add_menu.append(ResidentialArea);
	add_menu.append(TransportHub);
	add_menu.append(ProductionZone);
	add_menu.show_all();
	ResidentialArea.set_label("Residential Area"); // RENAME
	TransportHub   .set_label("Transport Hub");
	ProductionZone .set_label("Production Zone");

	mouse_pos.set_width_chars(24);
	mouse_pos.set_xalign(0.95);
}

void ArchipelagoUI::PositionWidgets(void) {
	auto margin = [](Gtk::Widget& widget, int r, int t, int l, int b) {
		widget.set_margin_right(r);
		widget.set_margin_top(t);
		widget.set_margin_left(l);
		widget.set_margin_bottom(b);
	};

	layout.attach(btn_info,   NAV_BAR(0));
	layout.attach(filesystem, NAV_BAR(1));
	filesystem.pack_start(filepath, Gtk::PACK_SHRINK);
	filesystem.pack_start(btn_open, Gtk::PACK_SHRINK);
	filesystem.pack_start(btn_save, Gtk::PACK_SHRINK);
	layout.attach(spacer, 	  NAV_BAR(2));
	layout.attach(btn_view,   NAV_BAR(3));

	margin(btn_info,   2, 2, 2, 2);
	margin(filesystem, 0, 2, 0, 2);
	margin(filepath,   3, 0, 0, 0);
	margin(btn_open,   2, 0, 0, 0);
	margin(btn_save,   0, 0, 0, 0);
	margin(btn_view,   2, 2, 2, 2);


	layout.attach(rating,  BODY(0), FULL_WIDTH, DEFAULT_HEIGHT);
	layout.attach(canvas,  BODY(1), FULL_WIDTH, DEFAULT_HEIGHT);

	margin(rating, 2, 2, 2, 2);
	margin(canvas, 2, 0, 2, 0);


	layout.attach(editor_frame, BODY(2), FULL_WIDTH, DEFAULT_HEIGHT);
	editor_frame.add(editor);
	editor.pack_start(info_desk);
	editor.pack_start(btn_zone, 	  Gtk::PACK_SHRINK);
	editor.pack_start(btn_link, 	  Gtk::PACK_SHRINK);
	editor.pack_start(btn_add_choice, Gtk::PACK_SHRINK);
	editor.pack_start(btn_add_simple, Gtk::PACK_SHRINK);
	editor.pack_start(btn_edit, 	  Gtk::PACK_SHRINK);
	editor.pack_start(btn_remove,     Gtk::PACK_SHRINK);
	editor.pack_start(mouse_pos);

	margin(editor_frame,   2, 2, 2, 6);
	margin(info_desk,	   5, 0, 5, 6);
	margin(btn_zone, 	   1, 0, 1, 6);
	margin(btn_link, 	   2, 0, 1, 6);
	margin(btn_add_choice, 1, 0, 2, 6);
	margin(btn_add_simple, 1, 0, 2, 6);
	margin(btn_edit, 	   1, 0, 1, 6);
	margin(btn_remove, 	   1, 0, 1, 6);
	margin(mouse_pos, 	   5, 0, 5, 6);
}

void ArchipelagoUI::ConnectSignals(void) {

    canvas.add_events(Gdk::POINTER_MOTION_MASK | Gdk::BUTTON_PRESS_MASK | Gdk::SMOOTH_SCROLL_MASK | Gdk::KEY_PRESS_MASK);
 	signal_key_press_event().connect(sigc::mem_fun(*this, &ArchipelagoUI::KeyboardShortcuts_cb));

	btn_info.signal_clicked().connect(sigc::mem_fun(*this, &ArchipelagoUI::DisplayInfo_cb));

	btn_open.signal_clicked().connect(sigc::mem_fun(*this, &ArchipelagoUI::OpenFile_cb));
	btn_save.signal_clicked().connect(sigc::mem_fun(*this, &ArchipelagoUI::SaveFile_cb));

	btn_view.signal_clicked().connect(sigc::mem_fun(*this, &ArchipelagoUI::ResetView_cb));

	btn_zone	  .signal_toggled().connect(sigc::mem_fun(*this, &ArchipelagoUI::EditZone_cb));
	btn_link	  .signal_toggled().connect(sigc::mem_fun(*this, &ArchipelagoUI::EditLink_cb));
	btn_add_simple.signal_toggled().connect(sigc::mem_fun(*this, &ArchipelagoUI::AddSimple_cb));
	btn_add_choice.signal_toggled().connect(sigc::mem_fun(*this, &ArchipelagoUI::AddChoice_cb));
	btn_edit	  .signal_toggled().connect(sigc::mem_fun(*this, &ArchipelagoUI::Edit_cb));
	btn_remove	  .signal_toggled().connect(sigc::mem_fun(*this, &ArchipelagoUI::Remove_cb));

    ResidentialArea.signal_activate().connect(sigc::bind(sigc::mem_fun(*this, &ArchipelagoUI::AddMenu_cb), ZoneType::RESIDENTIAL));
    TransportHub   .signal_activate().connect(sigc::bind(sigc::mem_fun(*this, &ArchipelagoUI::AddMenu_cb), ZoneType::TRANSPORT));
    ProductionZone .signal_activate().connect(sigc::bind(sigc::mem_fun(*this, &ArchipelagoUI::AddMenu_cb), ZoneType::PRODUCTION));

	gesture_zoom = Gtk::GestureZoom::create(canvas);
	gesture_zoom->signal_scale_changed().connect(sigc::mem_fun(*this, &ArchipelagoUI::Zoom_cb));

	gesture_rotate = Gtk::GestureRotate::create(canvas);
	gesture_rotate->signal_angle_changed().connect(sigc::mem_fun(*this, &ArchipelagoUI::Rotate_cb));

	gesture_drag = Gtk::GestureDrag::create(canvas);
	gesture_drag->signal_drag_begin() .connect(sigc::bind(sigc::mem_fun(*this, &ArchipelagoUI::Drag_cb), ArchipelagoBackend::EditState::INIT));
	gesture_drag->signal_drag_update().connect(sigc::bind(sigc::mem_fun(*this, &ArchipelagoUI::Drag_cb), ArchipelagoBackend::EditState::UPDATE));
	gesture_drag->signal_drag_end()   .connect(sigc::bind(sigc::mem_fun(*this, &ArchipelagoUI::Drag_cb), ArchipelagoBackend::EditState::END));
}


ArchipelagoUI::ArchipelagoUI()
: canvas{city} {

    Gtk::Window::set_title("Archipelago City");
    Gtk::Window::resize(400,400);

	SetupWidgets();
	PositionWidgets();
	ConnectSignals();

	Gtk::Window::add(layout);
	Gtk::Window::show_all();
	btn_add_choice.hide();

	// city.editor_action = ArchipelagoBackend::EditorOptions::NONE; // why was this needed?
}

#define GDK_COMMAND_MASK GDK_MOD2_MASK

bool ArchipelagoUI::KeyboardShortcuts_cb(GdkEventKey* event) {

	if(event->state & GDK_SHIFT_MASK) {
		btn_zone.set_active(1);
		switch(gdk_keyval_to_upper(event->keyval)) {
		  case GDK_KEY_P:
			AddMenu_cb(ZoneType::PRODUCTION); break;
		  case GDK_KEY_R:
			AddMenu_cb(ZoneType::RESIDENTIAL); break;
		  case GDK_KEY_T:
		  	AddMenu_cb(ZoneType::TRANSPORT); break;
		  case GDK_KEY_Return:
		    btn_edit.set_active(1); break;
		  case GDK_KEY_BackSpace:
		    btn_remove.set_active(1); break;
		  default:
		  	btn_zone.set_active(0);
		}
		return 1;
	}
	if(event->state & GDK_CONTROL_MASK) {
		btn_link.set_active(1);
		switch(gdk_keyval_to_upper(event->keyval)) {
		  case GDK_KEY_L:
			btn_add_simple.set_active(1); break;
		  case GDK_KEY_BackSpace:
			btn_remove.set_active(1); break;
		  default:
		  	btn_link.set_active(0);
		}
		return 1;
	}
	if(event->state & GDK_COMMAND_MASK) {
		switch(gdk_keyval_to_upper(event->keyval)) {
		  case GDK_KEY_I:
		  	DisplayInfo_cb();
			break;
		  case GDK_KEY_O:
		  	OpenFile_cb();
			break;
		  case GDK_KEY_S:
		  	SaveFile_cb();
			break;
		  case GDK_KEY_W:
		  case GDK_KEY_Q:
		  	Gtk::Window::hide(); // to close window w\o segfault
			break;
		}
		return 1;
	}
	if(event->keyval == GDK_KEY_Escape) {
		ResetEditor();
	}
	if(event->keyval == GDK_KEY_space) {
		ResetView_cb();
	}
    return 0;
}

void ArchipelagoUI::DisplayInfo_cb(void) {
	std::cout<<"This button is currently a stub, maybe later.\n";
}

void ArchipelagoUI::OpenFile_cb(void) {
	if(city.OpenFile(filepath.get_text())) {
	    Gtk::Window::set_title("Archipelago City - " + StripPathFromFilePath(filepath.get_text()));
    } else {
        Gtk::Window::set_title("Archipelago City");
        spacer.set_label("Could not open file "+ filepath.get_text() + " !");
    }
}

void ArchipelagoUI::SaveFile_cb(void) {
	city.SaveFile(filepath.get_text());
	spacer.set_text("file saved");
}

void ArchipelagoUI::ResetView_cb(void) {
	canvas.ResetView();
}



void ArchipelagoUI::EditZone_cb(void) {

	if(btn_zone.get_active()) {
		btn_link.set_active(0);

		if(btn_add_simple.get_active()) {
			btn_add_simple.set_active();
		}
	} else {
		btn_edit.set_active(0);
	}
	UpdateEditorAction();
}

void ArchipelagoUI::EditLink_cb(void) {

	if(btn_link.get_active()) {
		btn_zone.set_active(0);
	}
	UpdateEditorAction();
}

void ArchipelagoUI::AddSimple_cb(void) {

	if(btn_add_simple.get_active()) {
		btn_edit.set_active(0);
		btn_remove.set_active(0);

		// if(btn_zone.get_active() && !btn_add_choice.get_active()) {//city.editor_action != ArchipelagoBackend::EditorOptions::ADD_ZONE) {
		// 	btn_add_choice.set_active(1);
		// } else {
		// 	btn_add_choice.set_active(0);
		if(btn_zone.get_active()) {
			if(!btn_add_choice.get_active()) {
				btn_add_choice.set_active(1);
			} else {
				btn_add_choice.set_active(0);
			}
		}
	}
	UpdateEditorAction();
}
void ArchipelagoUI::AddChoice_cb(void) {

	if(btn_add_choice.get_active()) {
		btn_add_simple.hide();
		btn_add_choice.show();
	} else {
		btn_add_choice.hide();
		btn_add_simple.show();
	}
}
void ArchipelagoUI::AddMenu_cb(ZoneType choice) {
	city.add_menu_choice = choice;
	// btn_add_choice.set_active(0);
	btn_add_simple.set_active(1); std::cout<<"selection\n";
	// UpdateEditorAction();
}


void ArchipelagoUI::Edit_cb(void) {

	if(btn_edit.get_active()) {
		if(btn_link.get_active()) {
			btn_edit.set_active(0);
		} else {
			btn_zone.set_active(1);
			btn_add_simple.set_active(0);
			btn_remove.set_active(0);
		}
	}
	UpdateEditorAction();
}

void ArchipelagoUI::Remove_cb(void) {

	if(btn_remove.get_active()) {
		btn_add_simple.set_active(0);
		btn_edit.set_active(0);
	}
	UpdateEditorAction();
}



bool ArchipelagoUI::on_motion_notify_event(GdkEventMotion* event) {
    UpdateMouseCoordinates();
    return 1;
}

bool ArchipelagoUI::on_scroll_event(GdkEventScroll* event) {
	canvas.Translate(event->delta_x, event->delta_y);
    UpdateMouseCoordinates();
    return 1;
}

void ArchipelagoUI::Rotate_cb(float new_angle, float ignore) { // ignore is delta angle
    static float old_angle{0};
    if(abs(new_angle) > 0.02) {
        canvas.Rotate(SIGN(new_angle - old_angle));
        UpdateMouseCoordinates();
    }
    old_angle = new_angle;
}

void ArchipelagoUI::Zoom_cb(float new_scale) {
    static float old_scale{1};
    if(abs(new_scale - 1) > 0.02) {
    	canvas.Scale(SIGN(new_scale - old_scale));
        UpdateMouseCoordinates();
    }
	old_scale = new_scale;
}

void ArchipelagoUI::Drag_cb(float dx, float dy, ArchipelagoBackend::EditState state) {
    if(filepath.has_focus()) btn_open.grab_focus(); // one way to take focus off filepath entry

	int x, y; canvas.get_pointer(x, y);
	Coord2D position {float(x), float(y)};
    canvas.MouseToArchipelagoXY(position.x, position.y);

	if(city.editor_action != ArchipelagoBackend::EditorOptions::NONE) {
		switch(city.editor_action) {
		  case ArchipelagoBackend::EditorOptions::MODIFY_ZONE:
			city.ModifyZone(position, state);
			break;
		  case ArchipelagoBackend::EditorOptions::ADD_LINK:
			city.AddLink(position, state);
			break;
		  default: // act as button release and cancel action if release is far from original press
			if(state == ArchipelagoBackend::EditState::END && abs(dx) < 5 && abs(dy) < 5) {
				switch(city.editor_action) {
				  case ArchipelagoBackend::EditorOptions::ADD_ZONE:
					city.AddZone(city.add_menu_choice, position);
					break;
				  case ArchipelagoBackend::EditorOptions::REMOVE_ZONE:
					city.RemoveZone(position);
					break;
				  case ArchipelagoBackend::EditorOptions::REMOVE_LINK:
					city.RemoveLink(position);
					break;
			      default: ;
				}
			}
		}
		UpdateRating();
	} else {
		city.ShortestPath(state, position);
	}
}


void ArchipelagoUI::UpdateEditorAction(void) {

	city.editor_action = ArchipelagoBackend::EditorOptions::NONE;
	if(btn_zone.get_active()) {
		if(btn_add_simple.get_active()) { std::cout<<"here\n";city.editor_action = ArchipelagoBackend::EditorOptions::ADD_ZONE;		return ; }
		if(btn_edit.get_active()) 	{ city.editor_action = ArchipelagoBackend::EditorOptions::MODIFY_ZONE;	return ; }
		if(btn_remove.get_active()) { city.editor_action = ArchipelagoBackend::EditorOptions::REMOVE_ZONE;	return ; }
	}
	if(btn_link.get_active()) {
		if(btn_add_simple.get_active()) 	{ city.editor_action = ArchipelagoBackend::EditorOptions::ADD_LINK;		return ; }
		if(btn_remove.get_active()) { city.editor_action = ArchipelagoBackend::EditorOptions::REMOVE_LINK;	return ; }
	}
}

void ArchipelagoUI::ResetEditor(void) {

	city.editor_action = ArchipelagoBackend::EditorOptions::NONE;
	btn_zone.set_active(0);
	btn_link.set_active(0);
	btn_add_simple.set_active(0);
	btn_edit.set_active(0);
	btn_remove.set_active(0);
}



void ArchipelagoUI::UpdateMouseCoordinates() {
	auto flt2txt = [](float a, int decimals) {
		std::ostringstream out;
		out.precision(decimals);
		for(float copy{abs(a)}; copy < 1000; copy *= 10) out << " ";
		// out << (abs(a) < 10 ? "   " : abs(a) < 100 ? "  " : abs(a) < 1000 ? " " : "");
		out << /*std::fixed <<*/ (a < 0 ? "-" : "+") << abs(a);
		return out.str();
	};

	int x, y; canvas.get_pointer(x, y);
    Coord2D mouse {float(x), float(y)};
	canvas.MouseToArchipelagoXY(mouse.x, mouse.y);

	// display coordinates of zone center during edit
    mouse_pos.set_markup("<span font_family=\'Fira Code\' size=\"smaller\"><b>X:</b>"
						 + flt2txt(mouse.x, 2) +" <b>Y:</b>"+ flt2txt(mouse.y, 2) +"</span> ");

	info_desk.set_markup("<span font_family=\'Fira Code\' size=\"smaller\">" + city.InfoFromCoordinates(mouse) + "</span>");
}

void ArchipelagoUI::UpdateRating(void) {
	city.ComputePerformance();
	rating.set_markup(city.performance);
}