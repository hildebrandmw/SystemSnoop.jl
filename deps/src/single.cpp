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
    for (int i = 0; i < ARRAY_SIZE; i++) {
        x[i] = x[i] + 1.0;
    }
    // // Initialize a random engine
    // std::random_device rdev;
    // std::default_random_engine u{rdev()};
    // std::uniform_real_distribution<double> d(-1.0,1.0);

    // // Randomize all entries
    // for (auto &i : x) {
    //     i = d(u);
    // }
}

template <class T>
bool timedout( T stoptime ) {
    return clock() > stoptime;
}

static double A[ARRAY_SIZE];

int main(int argc, char *argv[])
{


    std::cout << &A[0] << "\n";

    // Time for population
    int runtime = 4;

    // Spend time doing nothing
    clock_t stoptime = clock() + runtime * CLOCKS_PER_SEC;
    while ( !timedout(stoptime) ) {}

    // Spend time populating "A"
    std::cout << "Populating `a`\n"; 

    for (int i = 0; i < ARRAY_SIZE; i++) {
        A[i] = 0.0;
    }

    stoptime = clock() + runtime * CLOCKS_PER_SEC;
    while ( !timedout(stoptime) ) {
        populate_array(A);
    }
    std::cout << std::accumulate(A, A + ARRAY_SIZE, 0.0) << "\n";

    // Do nothing for a bit longer
    stoptime = clock() + 2 * runtime * CLOCKS_PER_SEC;
    while ( !timedout(stoptime) ) {}

    return 0;
}
