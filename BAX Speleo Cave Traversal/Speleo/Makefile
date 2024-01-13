appname  := speleo

CXX      :=  g++
CXXFLAGS := -std=c++17 -Wall

srcfiles :=  $(shell find . -maxdepth 5 -name "*.cpp")

default:
	@echo "### Making" $(appname)
	$(CXX) $(CXXFLAGS) $(srcfiles) -o $(appname)

.SILENT: run
run: default
	@echo "### Running" $(appname)
	./$(appname)
