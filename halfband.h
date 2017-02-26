/* Allpass cascade half band filtering. From http://www.musicdsp.org/showone.php?id=39, poretd to plain c */
#include <stdlib.h>
#include <string.h>

#define FLOAT_T float

typedef struct allpass
{
    double x0, x1, x2;
    double y0, y1, y2;
    double a;    
} allpass;

typedef struct allpass_cascade
{
    allpass **filters;
    int n;
} allpass_cascade;

typedef struct halfband
{
    allpass_cascade *a;
    allpass_cascade *b;    
    double oldout;
} halfband;

/* cascade of half band filters, for 2^n times oversampling */
typedef struct half_cascade
{
    halfband **halfs;
    FLOAT_T *buf;
    int n;    
} half_cascade;

allpass *create_allpass(double a);
void destroy_allpass(allpass *a);
double allpass_process(allpass *all, double input);
allpass_cascade *create_allpass_cascade(double *coefficients, int n);
void destroy_allpass_cascade(allpass_cascade *cascade);
double allpass_cascade_process(allpass_cascade *cascade, double input);
halfband *create_halfband(int order, int steep);
void destroy_halfband(halfband *half);
double process_halfband(halfband *half, double input);
half_cascade *create_half_cascade(int n, int order, int steep);
void destroy_half_cascade(half_cascade *cascade);
// should receive an array of 2**n inputs to process
FLOAT_T process_half_cascade(half_cascade *cascade, FLOAT_T *input);