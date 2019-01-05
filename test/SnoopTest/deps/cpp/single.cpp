#include<iostream>
#include<random>
#include<time.h>
#include<sstream>
#include<sys/types.h>
#include<unistd.h>

// Declare global array size.
const int ARRAY_SIZE = 2000000;

// Basic function to populate a 2D iterator with uniformly distributed real
// numbers between -1.0 and 1.0.
template <class T>
void populate( T &x )
{
    for (int i = 0; i < ARRAY_SIZE; i++) {
        x[i] = x[i] + 1.0;
    }
}

template <class T>
bool timedout( T stoptime ) {
    return clock() > stoptime;
}

template <class T>
void access( T& array, int time ) {
    clock_t stoptime = clock() + time * CLOCKS_PER_SEC;
    // Initialize
    for (auto &i: array) {
        i = 0.0;
    }
    // Spin
    while ( !timedout(stoptime) ) {
        populate(array);
    } 
}

void wait(int time) {
    clock_t stoptime = clock() + time * CLOCKS_PER_SEC;
    while (!timedout(stoptime)) {}
}

static double A[ARRAY_SIZE];

int main(int argc, char *argv[])
{
    // Display the address of the first element of "A"
    std::cout <<  &A[0] << "\n";
    std::cout << &A[ARRAY_SIZE-1] << "\n";

    // Time for array accesses
    int initial_idletime = 2;
    int runtime = 10;

    // Spend time doing nothing
    wait(initial_idletime);

    // Repeatedly access "A" for "runtime" seconds
    std::cout << "Running" << "\n"; 
    access(A, runtime);
    std::cout << std::accumulate(A, A + ARRAY_SIZE, 0.0) << "\n";
    std::cout << "Stopping" << "\n";

    // Do nothing for a bit longer
    wait(runtime);

    return 0;
}