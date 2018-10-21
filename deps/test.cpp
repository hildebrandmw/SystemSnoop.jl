#include<iostream>
#include<random>
#include<time.h>
#include<sstream>

// Declare global array size.
const int ARRAY_SIZE = 2000000;

// Basic function to populate a 2D iterator with uniformly distributed real
// numbers between -1.0 and 1.0.
template <class T>
void populate_array( T &x )
{
    // Initialize a random engine
    std::random_device rdev;
    std::default_random_engine u{rdev()};
    std::uniform_real_distribution<double> d(-1.0,1.0);

    // Randomize all entries
    for (auto &i : x) {
        i = d(u);
    }
}

template <class T>
bool timedout( T stoptime ) {
    return clock() > stoptime;
}

// Heap Initialize Arrays
static double a[ARRAY_SIZE];
static double b[ARRAY_SIZE];

int main(int argc, char *argv[])
{

    // Time for population
    int runtime = 5;

    // Spend time populating "A"
    std::cout << "Populating `a`\n"; 
    clock_t stoptime = clock() + runtime * CLOCKS_PER_SEC;
    while ( !timedout(stoptime) ) {
        populate_array(a);
    }
    std::cout << std::accumulate(a, a + ARRAY_SIZE, 0.0) << "\n";
 
    // Spend time populating "B"
    std::cout << "Populating `b`\n"; 
    stoptime = clock() + runtime * CLOCKS_PER_SEC;;
    while ( !timedout(stoptime) ) {
        populate_array(b);
    }
    std::cout << std::accumulate(b, b + ARRAY_SIZE, 0.0) << "\n";

    return 0;
}
