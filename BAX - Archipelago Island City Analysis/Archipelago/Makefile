appname  := archipelago

CXX      :=  g++
CXXFLAGS := -std=c++17 -Wall
GFXPKG	 := `pkg-config gtkmm-3.0 --cflags --libs`

srcfiles :=  $(shell find . -maxdepth 5 -name "*.cpp")

default:
	@echo "### Making" $(appname)
	$(CXX) $(CXXFLAGS) $(srcfiles) -o $(appname) $(GFXPKG)

.SILENT: run
run: default
	@echo "### Running" $(appname)
	./$(appname)
