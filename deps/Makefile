tests = build/single.out build/double.out

all: $(tests)

build/%.out: src/%.cpp
	c++ -std=c++1y -O0 $< -o $@
