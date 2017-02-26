#include "halfband.h"

typedef struct oversampler
{
    int n;
    int n_buf;
    int max_buf;
    FLOAT_T *buf;
    int oversample;
    half_cascade *oversampler;
} oversampler;


oversampler *create_oversampler(int n, int order, int steep);
void destroy_oversampler(oversampler *over);
FLOAT_T *alloc_oversampler(oversampler *over, int block_size);
void process_oversampler(oversampler *over, float *out, int block_size);