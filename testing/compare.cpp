#include <chrono>
#include <random>
#include <iostream>
#include <set>

#include <stdint.h>

#define OUTER_ITER 30000
#define INNTER_ITER 300

class Set1
{
private:

    std::set<uint64_t> mSet;

public:

    Set1() {}

    void insert(uint64_t p) {mSet.insert(p);}
    void clear() {mSet.clear();}

    // inclusive of a and b
    bool isEmptyInterval(uint64_t a, uint64_t b)
    {
        auto low = mSet.lower_bound(a);
        return low == mSet.end() || *low > b;
    }
};

class Set2
{
private:

    std::vector<uint64_t> mVec;

public:

    Set2() {}

    void insert(uint64_t p) {mVec.push_back(p);}
    void clear() {mVec.clear();}

    // inclusive of a and b
    bool isEmptyInterval(uint64_t a, uint64_t b)
    {
        for (auto& p : mVec)
        {
            if (p >= a && p <= b)
            {
                return false;
            }
        }
        return true;
    }
};

volatile bool cond = false;

int main()
{
    std::uniform_int_distribution<uint64_t> dist(0,
        std::numeric_limits<uint64_t>::max());
    std::uniform_int_distribution<uint64_t> intervalDist(0, 2767011611056432);

    std::mt19937 rng;
    rng.seed(123);
    unsigned rNdx = 0;

    std::vector<uint64_t> atoms, intervals;
    for (unsigned i = 0; i < 4096; ++i)
    {
        atoms.push_back(dist(rng));
        intervals.push_back(dist(rng));
    }

////////////////////////////////////////////////////////////////////////////////

/*    Set1 s1;
    rNdx = 0;
    auto start1 = std::chrono::high_resolution_clock::now();
    for (unsigned i = 0; i < OUTER_ITER; ++i)
    {
        s1.clear();
        for (unsigned j = 0; j < INNTER_ITER; ++j)
        {
            s1.insert(atoms[rNdx]);
            rNdx = (rNdx + 1) % 4096;

            uint64_t a = atoms[rNdx];
            rNdx = (rNdx + 1) % 4096;

            uint64_t interval = std::min(intervals[rNdx],
                std::numeric_limits<uint64_t>::max() - a - 1);
            rNdx = (rNdx + 1) % 4096;
            
            cond = s1.isEmptyInterval(a, a + interval);
        }
    }
    auto end1 = std::chrono::high_resolution_clock::now();
    std::cout << "s1 elapsed time: "
        << std::chrono::duration_cast<std::chrono::milliseconds>(end1-start1).count()
        << " milliseconds\n";
*/

////////////////////////////////////////////////////////////////////////////////

    rng.seed(123);
    Set2 s2;
    rNdx = 0;
    auto start2 = std::chrono::high_resolution_clock::now();
    for (unsigned i = 0; i < OUTER_ITER; ++i)
    {
        s2.clear();
        for (unsigned j = 0; j < INNTER_ITER; ++j)
        {
            s2.insert(atoms[rNdx]);
            rNdx = (rNdx + 1) % 4096;

            uint64_t a = atoms[rNdx];
            rNdx = (rNdx + 1) % 4096;

            uint64_t interval = std::min(intervals[rNdx],
                std::numeric_limits<uint64_t>::max() - a - 1);
            rNdx = (rNdx + 1) % 4096;
            
            cond = s2.isEmptyInterval(a, a + interval);
        }
    }
    auto end2 = std::chrono::high_resolution_clock::now();
    std::cout << "s2 elapsed time: "
            << std::chrono::duration_cast<std::chrono::milliseconds>(end2-start2).count()
        << " milliseconds\n";
}