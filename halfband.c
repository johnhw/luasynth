/* Allpass cascade half band filtering. 
From http://www.musicdsp.org/showone.php?id=39
poretd to plain C, and with a simple cascade
function to allow n times oversampling for n a power of 2
*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "halfband.h"

allpass *create_allpass(double a)
{
    allpass *all = (allpass *)malloc(sizeof(*all));
    all->a = a;
    all->x0 = all->x1 = all->x2 = 0;
    all->y0 = all->y1 = all->y2 = 0;
    return all;
}

void destroy_allpass(allpass *a)
{
   free(a);
}


double allpass_process(allpass *all, double input)
{
    double output;
    all->x2=all->x1;
    all->x1=all->x0;
    all->x0=input;

    all->y2=all->y1;    
    all->y1=all->y0;
    
    output = all->x2+((input-all->y2)*all->a);
    all->y0 = output;
    return output;
}


allpass_cascade *create_allpass_cascade(double *coefficients, int n)
{
    int i;
    allpass_cascade *cascade= (allpass_cascade *)malloc(sizeof(*cascade));
    cascade->filters = (allpass **)malloc(sizeof(*cascade->filters)*n);
    cascade->n = n;    
    for(i=0;i<n;i++)    
        cascade->filters[i] = create_allpass(coefficients[i]);
    return cascade;    
}

void destroy_allpass_cascade(allpass_cascade *cascade)
{
    int i;
    for(i=0;i<cascade->n;i++)            
        destroy_allpass(cascade->filters[i]);
    free(cascade->filters);
    free(cascade);           
}

double allpass_cascade_process(allpass_cascade *cascade, double input)
{
    double output = input;
    int i;    
    for(i=0;i<cascade->n;i++)    
        output = allpass_process(cascade->filters[i], output);
    return output;    
}



halfband *create_halfband(int order, int steep)
{
    halfband *half = (halfband *)malloc(sizeof(*half));
    
    if (steep)
    {
        if (order==12)    //rejection=104dB, transition band=0.01
        {
            double a_coefficients[6]=
            {0.036681502163648017
            ,0.2746317593794541
            ,0.56109896978791948
            ,0.769741833862266
            ,0.8922608180038789
            ,0.962094548378084
            };

            double b_coefficients[6]=
            {0.13654762463195771
            ,0.42313861743656667
            ,0.6775400499741616
            ,0.839889624849638
            ,0.9315419599631839
            ,0.9878163707328971
            };
            
            half->a = create_allpass_cascade(a_coefficients, 6);
            half->b = create_allpass_cascade(b_coefficients, 6);            
        }
        else if (order==10)    //rejection=86dB, transition band=0.01
        {
            double a_coefficients[5]=
            {0.051457617441190984
            ,0.35978656070567017
            ,0.6725475931034693
            ,0.8590884928249939
            ,0.9540209867860787
            };

            double b_coefficients[5]=
            {0.18621906251989334
            ,0.529951372847964
            ,0.7810257527489514
            ,0.9141815687605308
            ,0.985475023014907
            };
            
            half->a = create_allpass_cascade(a_coefficients, 5);
            half->b = create_allpass_cascade(b_coefficients, 5);            
            
        }
        else if (order==8)    //rejection=69dB, transition band=0.01
        {
            double a_coefficients[4]=
            {0.07711507983241622
            ,0.4820706250610472
            ,0.7968204713315797
            ,0.9412514277740471
            };

            double b_coefficients[4]=
            {0.2659685265210946
            ,0.6651041532634957
            ,0.8841015085506159
            ,0.9820054141886075
            };
    
            half->a = create_allpass_cascade(a_coefficients, 4);
            half->b = create_allpass_cascade(b_coefficients, 4);            
            
        }
        else if (order==6)    //rejection=51dB, transition band=0.01
        {
            double a_coefficients[3]=
            {0.1271414136264853
            ,0.6528245886369117
            ,0.9176942834328115
            };

            double b_coefficients[3]=
            {0.40056789819445626
            ,0.8204163891923343
            ,0.9763114515836773
            };
    
            half->a = create_allpass_cascade(a_coefficients, 3);
            half->b = create_allpass_cascade(b_coefficients, 3);            
        }
        else if (order==4)    //rejection=53dB,transition band=0.05
        {
            double a_coefficients[2]=
            {0.12073211751675449
            ,0.6632020224193995
            };

            double b_coefficients[2]=
            {0.3903621872345006
            ,0.890786832653497
            };
    
            half->a = create_allpass_cascade(a_coefficients, 2);
            half->b = create_allpass_cascade(b_coefficients, 2);            
        }
    
        else    //order=2, rejection=36dB, transition band=0.1
        {
            double a_coefficients[1]={0.23647102099689224};
            double b_coefficients[1]={0.7145421497126001};

            half->a = create_allpass_cascade(a_coefficients, 1);
            half->b = create_allpass_cascade(b_coefficients, 1);            
        }
    }
    else    //softer slopes, more attenuation and less stopband ripple
    {
        if (order==12)    //rejection=150dB, transition band=0.05
        {
            double a_coefficients[6]=
            {0.01677466677723562
            ,0.13902148819717805
            ,0.3325011117394731
            ,0.53766105314488
            ,0.7214184024215805
            ,0.8821858402078155
            };

            double b_coefficients[6]=
            {0.06501319274445962
            ,0.23094129990840923
            ,0.4364942348420355
            ,0.6329609551399348
            ,0.80378086794111226
            ,0.9599687404800694
            };
    
            half->a = create_allpass_cascade(a_coefficients, 6);
            half->b = create_allpass_cascade(b_coefficients, 6);            
        }
        else if (order==10)    //rejection=133dB, transition band=0.05
        {
            double a_coefficients[5]=
            {0.02366831419883467
            ,0.18989476227180174
            ,0.43157318062118555
            ,0.6632020224193995
            ,0.860015542499582
            };

            double b_coefficients[5]=
            {0.09056555904993387
            ,0.3078575723749043
            ,0.5516782402507934
            ,0.7652146863779808
            ,0.95247728378667541
            };
    
            half->a = create_allpass_cascade(a_coefficients, 5);
            half->b = create_allpass_cascade(b_coefficients, 5);            
        }
        else if (order==8)    //rejection=106dB, transition band=0.05
        {
            double a_coefficients[4]=
            {0.03583278843106211
            ,0.2720401433964576
            ,0.5720571972357003
            ,0.827124761997324
            };

            double b_coefficients[4]=
            {0.1340901419430669
            ,0.4243248712718685
            ,0.7062921421386394
            ,0.9415030941737551
            };
    
            half->a = create_allpass_cascade(a_coefficients, 4);
            half->b = create_allpass_cascade(b_coefficients, 4);            
        }
        else if (order==6)    //rejection=80dB, transition band=0.05
        {
            double a_coefficients[3]=
            {0.06029739095712437
            ,0.4125907203610563
            ,0.7727156537429234
            };

            double b_coefficients[3]=
            {0.21597144456092948
            ,0.6043586264658363
            ,0.9238861386532906
            };
    
            half->a = create_allpass_cascade(a_coefficients, 3);
            half->b = create_allpass_cascade(b_coefficients, 3);            
        }
        else if (order==4)    //rejection=70dB,transition band=0.1
        {
            double a_coefficients[2]=
            {0.07986642623635751
            ,0.5453536510711322
            };

            double b_coefficients[2]=
            {0.28382934487410993
            ,0.8344118914807379
            };
    
            half->a = create_allpass_cascade(a_coefficients, 2);
            half->b = create_allpass_cascade(b_coefficients, 2);            
        }
    
        else    //order=2, rejection=36dB, transition band=0.1
        {
            double a_coefficients[1]={0.23647102099689224};
            double b_coefficients[1]={0.7145421497126001};

            half->a = create_allpass_cascade(a_coefficients, 1);
            half->b = create_allpass_cascade(b_coefficients, 1);            
        }
    }
    half->oldout = 0;
    return half;    
}

void destroy_halfband(halfband *half)
{
    destroy_allpass_cascade(half->a);
    destroy_allpass_cascade(half->b);
    free(half);
}

double process_halfband(halfband *half, double input)
{
        double output;
        output = (allpass_cascade_process(half->a, input) + half->oldout)*0.5;
        half->oldout = allpass_cascade_process(half->b, input);
        return output;        
}


half_cascade *create_half_cascade(int n, int order, int steep)
{
    int i;
    half_cascade *cascade = (half_cascade *)malloc(sizeof(*cascade));
    cascade->halfs = (halfband **)malloc(sizeof(*cascade->halfs)*n);
    // buffer of size 2**n
    cascade->buf = (double *)malloc(sizeof(*cascade->buf)*(1<<n));
    cascade->n = n;
    for(i=0;i<n;i++)   
        cascade->halfs[i] = create_halfband(order, steep);
    return cascade;
}

void destroy_half_cascade(half_cascade *cascade)
{
    int i;
    for(i=0;i<cascade->n;i++)
        destroy_halfband(cascade->halfs[i]);
    free(cascade->halfs);
    free(cascade->buf);
    free(cascade);    
}


// should receive an array of 2**n inputs to process
// will return a single value following a cascade of filter->decimate steps
double process_half_cascade(half_cascade *cascade, double *input)
{
    int i, j, k;
    double b;
    int nbuf;
    nbuf = 1<<cascade->n;
    
   // cascade 1
   k = 0;
   for(j=0;j<nbuf;j+=2)
   {       
       b = process_halfband(cascade->halfs[0], input[j]);
       b = process_halfband(cascade->halfs[0], input[j+1]);
       // decimate and store
       cascade->buf[k++] = b;           
   }
   // next buf size
   nbuf >>= 1;        

    // subsequent cascades
    for(i=1;i<cascade->n;i++)
    {
       k = 0;
       for(j=0;j<nbuf;j+=2)
       {
           // note that we process the buffer in-place, writing
           // the decimated sample at the start of the buffer, always
           // behind the position read
           b = process_halfband(cascade->halfs[i], cascade->buf[j]);
           b = process_halfband(cascade->halfs[i], cascade->buf[j+1]);
           cascade->buf[k++] = b;           
       }
       // next buf size
       nbuf >>= 1;        
    }    
    
    // final fully decimated sample
    return cascade->buf[0];
}