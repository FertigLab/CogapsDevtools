#include <immintrin.h>

#include <boost/align/aligned_allocator.hpp>
#include <vector>
#include <iostream>
#include <limits>
#include <stdint.h>

// need to align data for SIMD
namespace bal = boost::alignment;
typedef std::vector<float, bal::aligned_allocator<float,32> > aligned_vector;

// boost time helpers
#include <boost/date_time/posix_time/posix_time.hpp>
namespace bpt = boost::posix_time;
#define bpt_now() bpt::microsec_clock::local_time()

static const float maxU32AsFloat = static_cast<float>(std::numeric_limits<uint32_t>::max());

class CustomRng
{
public:

    CustomRng(uint32_t seed)
    {
        mState = seed;
        next();
        next();
    }

    float uniform()
    {
        next();
        return static_cast<float>(mState) / maxU32AsFloat;
    }

private:

    uint32_t mState;

    void next()
    {
        mState ^= mState << 13;
        mState ^= mState >> 17;
        mState ^= mState << 5;
    }
};

static float getScalar(__m256 pf)
{
    pf = _mm256_hadd_ps(pf, pf);
    pf = _mm256_hadd_ps(pf, pf);
    float* ra = reinterpret_cast<float*>(&pf);
    return ra[0] + ra[4];
}

static float fast_dot(const float *v1, const float *v2, unsigned size)
{
    unsigned nChunks = 1 + (size - 1) / 8;
    __m256 packedDot(_mm256_set1_ps(0.f)), p1, p2;
    switch(nChunks)
    {
        case 12:
            p1 = _mm256_load_ps(v1 + 11 * 8);
            p2 = _mm256_load_ps(v2 + 11 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 11:
            p1 = _mm256_load_ps(v1 + 10 * 8);
        p2 = _mm256_load_ps(v2 + 10 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 10:
            p1 = _mm256_load_ps(v1 + 9 * 8);
            p2 = _mm256_load_ps(v2 + 9 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 9:
            p1 = _mm256_load_ps(v1 + 8 * 8);
            p2 = _mm256_load_ps(v2 + 8 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 8:
            p1 = _mm256_load_ps(v1 + 7 * 8);
            p2 = _mm256_load_ps(v2 + 7 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 7:
            p1 = _mm256_load_ps(v1 + 6 * 8);
            p2 = _mm256_load_ps(v2 + 6 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 6:
            p1 = _mm256_load_ps(v1 + 5 * 8);
            p2 = _mm256_load_ps(v2 + 5 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 5:
            p1 = _mm256_load_ps(v1 + 4 * 8);
            p2 = _mm256_load_ps(v2 + 4 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 4:
            p1 = _mm256_load_ps(v1 + 3 * 8);
            p2 = _mm256_load_ps(v2 + 3 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 3:
            p1 = _mm256_load_ps(v1 + 2 * 8);
            p2 = _mm256_load_ps(v2 + 2 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 2:
            p1 = _mm256_load_ps(v1 + 1 * 8);
            p2 = _mm256_load_ps(v2 + 1 * 8);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
        case 1:
            p1 = _mm256_load_ps(v1);
            p2 = _mm256_load_ps(v2);
            packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
            break;
        default:
            for (unsigned i = 0; i < size; i += 8)
            {
                p1 = _mm256_load_ps(v1 + i);
                p2 = _mm256_load_ps(v2 + i);
                packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
            }
    }
    return getScalar(packedDot);
}

static float slow_dot(const float *v1, const float *v2, unsigned size)
{
    __m256 packedDot(_mm256_set1_ps(0.f)), p1, p2;
    for (unsigned i = 0; i < size; i += 8)
    {
        p1 = _mm256_load_ps(v1 + i);
        p2 = _mm256_load_ps(v2 + i);
        packedDot = _mm256_add_ps(packedDot, _mm256_mul_ps(p1, p2));
    }
    return getScalar(packedDot);
}

static float default_dot(const float *v1, const float *v2, unsigned size)
{
    float dot = 0.f;
    for (unsigned i = 0; i < size; ++i)
    {
        dot += v1[i] * v2[i];
    }
    return dot;
}

#define N_ROW 80
#define N_COL 20000

int main()
{
    std::vector<aligned_vector> matrix;
    CustomRng rng(123);

    for (unsigned i = 0; i < N_COL; ++i)
    {
        matrix.push_back(aligned_vector(N_ROW, 0.f));
        for (unsigned j = 0; j < N_ROW; ++j)
        {
            matrix[i][j] = 1000.f * rng.uniform();
        }
    }

    float total = 0.f;
    bpt::ptime startTime = bpt_now();
    for (unsigned i = 0; i < N_COL; ++i)
    {
        for (unsigned j = 0; j < N_COL; ++j)
        {
        #if defined(TIME_FAST)
            total += fast_dot(&(matrix[i][0]), &(matrix[j][0]), N_ROW);
        #elif defined(TIME_SLOW)
            total += slow_dot(&(matrix[i][0]), &(matrix[j][0]), N_ROW);
        #else
            total += default_dot(&(matrix[i][0]), &(matrix[j][0]), N_ROW);
        #endif
        }
    }
    bpt::time_duration diff = bpt_now() - startTime;
    std::cout << diff << std::endl;

    std::cout << "total: " << total << std::endl;
}
