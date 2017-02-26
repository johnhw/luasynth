#include "simple_synth.h"
#include "user.h"
#include "sysfuncs.h"
#include "oversampler.h"
#include <math.h>
#include <string.h>
#include <stdio.h>
FILE *debug = NULL;

// reset an operator
void reset_operator(op *op)
{
    op_internal *opi = op->internal;
    opi->amp = 0;
    opi->phase = 0;
    opi->accum = 0;    
    opi->reset_ctr = op->reset_ctr;
}

void render_voice(synth_state *state, op_voice *voice, FLOAT_T *out1,  int n)
{
    FLOAT_T t;
    int i, o;
    FLOAT_T carrier, carrier_mul, carrier_a, carrier_n, ph, k;
    FLOAT_T amp_level;
    FLOAT_T freq, phase_inc;    
    int oversample = state->internal->oversampler->n;    
    
    for(o=0;o<1;o++)
    {
        op *operator = &(voice->operators[o]);
        op_internal *opi = operator->internal;
        
        freq = voice->freq * operator->fmul * operator->ftrack + operator->fadd;
        phase_inc = (2*M_PI*freq) / (state->sample_rate);        
        
        opi->phase = fmod(opi->phase, 2*M_PI);
        carrier_mul =  ((freq*operator->cmul*operator->ctrack+operator->cadd) / (freq * freq/voice->freq));
        carrier_n = floor(carrier_mul);
        carrier_a = carrier_mul - carrier_n;
        
        // if we have a mismatch in numbers, then we need to reset the note before continuing
        if(opi->reset_ctr!=operator->reset_ctr)
            reset_operator(operator);
        
        for(i=0;i<n;i++)
        {            
            amp_level = pow(10,opi->amp/20.0);            
            k = operator->K * amp_level;
            
            ph = opi->phase + operator->phase_offset;
            carrier = (1-carrier_a) * cos(ph*carrier_n) + (carrier_a) * cos(ph*(carrier_n+1));                
            t = exp(cos(ph)*k-k) * carrier * voice->amp * amp_level;                                       
            opi->phase += phase_inc / (double)oversample;                               
            out1[i] += t;
            opi->accum += t;                 
            opi->amp += voice->decay;
            
            if(opi->amp>0)
                opi->amp = 0;
        }        
        
    }
    
}


// allocate an internal state for an operator
op_internal *alloc_op_internal(void)
{
    op_internal *opi = malloc(sizeof(*opi));
    opi->amp  = 0;
    opi->phase = 0;
    opi->accum = 0;
    opi->reset_ctr = -1;
    return opi;
}

void init_synth(luasynthUser *user)
{
     synth_state *state = (synth_state *)(user->state);
     state->internal = (synth_internal*)malloc(sizeof(*state->internal));
     int i;
     for(i=0;i<state->n_voices;i++)
     {
        state->voices[i].operators[0].internal = alloc_op_internal();       
     }
     
     // should load these parameters from the synth state!
     state->internal->oversampler = create_oversampler(2, 10, 0);          
     
}


void process(luasynthUser *user, float **in, float **out, int n)
{
    int v;
    float *out1=out[0], *out2=out[1];    
    synth_state *state = (synth_state *)(user->state);
    synth_state state_copy_buf;
    synth_state *state_copy = &state_copy_buf;
    
    
    // get a zero-ed float buffer big enough 
    // to write an oversampled block to
    FLOAT_T *buf = alloc_oversampler(state->internal->oversampler, n);
    
    
    // copy the parameters; (note that internal parameters are *not* copied)
    lock_lua(user->param_lock);
    memcpy(state_copy, state, sizeof(*state));
    unlock_lua(user->param_lock);
    
      // don't do anything if we are turned off
    if(!state_copy->active)
        return;
        
    
    // accumulate all voices
    for(v=0;v<state_copy->n_voices;v++)
    {
        
        if(state_copy->voices[v].active)
            render_voice(state_copy, &(state_copy->voices[v]), buf,  state->internal->oversampler->n_buf);                      
        
    }
        
    // assume mono for just now
    process_oversampler(state->internal->oversampler, out1, n);
    memcpy(out2, out1, sizeof(*out1)*n);    
    // release parameter mutex
}
