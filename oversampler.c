#include "oversampler.h"
#include <math.h>

oversampler *create_oversampler(int n, int order, int steep)
{
    oversampler *over = (oversampler *)malloc(sizeof(*over));
    over->n = n;
    if(n<2)
    {
        over->oversampler = NULL;
        over->n=1;
    }    
    else
    {
        over->oversampler = create_half_cascade(floor(log(n)/log(2)), order, steep);
    }
    over->max_buf = 65536;
    over->buf = (FLOAT_T *) malloc((sizeof(*over->buf))*over->max_buf);
    return over;    
}

void destroy_oversampler(oversampler *over)
{
    free(over->buf);
    free(over);   
}

FLOAT_T *alloc_oversampler(oversampler *over, int block_size)
{
    int buf_reqd = block_size * over->n;    
    if(buf_reqd > over->max_buf)
    {
        over->max_buf = buf_reqd;
        free(over->buf);
        over->buf = (FLOAT_T*)(malloc(sizeof(FLOAT_T) * over->max_buf));
    }
    over->n_buf = buf_reqd;
    memset(over->buf, 0.0, sizeof(FLOAT_T)*over->n_buf);
    return over->buf;
    
}

void process_oversampler(oversampler *over, FLOAT_T *out, int block_size)
{
    int buf_reqd = block_size * over->n; 
    int i, k;
    k = 0;
    if(over->oversampler)
    {
        for(i=0;i<buf_reqd;i+=over->n)    
            out[k++] = process_half_cascade(over->oversampler, &(over->buf[i]));            
    }
    else
    {
        for(i=0;i<buf_reqd;i++)    
            out[k++] = over->buf[i];
    }
}