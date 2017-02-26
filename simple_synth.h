typedef struct oversampler oversampler;

typedef struct op_internal
{
    float amp;
    float phase;
    float accum;
    int reset_ctr;
} op_internal;

typedef struct op {
    // parameters, fixed at note on
    float fmul, fadd;
    float cmul, cadd;
    float ctrack, ftrack;
    float K;    
    float phase_offset;       
    
    int reset_ctr;
    // lua never writes here
    op_internal *internal;
    
    
} op; 

typedef struct op_voice
{
    op operators[1];    
    float freq;  // base frequency, Hz
    float amp;   // amplitude
    int delta;   // samples until actuation happens
    float decay;
    float level; // level
    int active;       // voice active states
    int last_time;    // last time this voice was activated
    int released;     // if this voice has been released
} op_voice;



typedef struct synth_internal
{
    oversampler *oversampler;
} synth_internal;

typedef struct synth_state
{
    op_voice voices[8];
    int n_voices;      // number of voices
    int sample_rate;
    int active;   
    // hidden from Lua
    synth_internal *internal;    
} synth_state;
