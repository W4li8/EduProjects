
#include <gtkmm/application.h>

#include "archipelago_user_interface.hpp"

auto main(int argc, char *argv[]) -> int {
    auto app = Gtk::Application::create(argc, argv);
    ArchipelagoUI window;
	return app->run(window);
}

/* some ideas

add, sub, mul, div, dot, vec


*/

