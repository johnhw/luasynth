ffi.cdef([[
typedef struct voice_set
{
    int n_voices;      // number of voices
    void **voices;      // array of voices
    int *active;       // voice active states
    float *max_level;  // max amplitude of this voice in last process pass
} voice_set;

typedef struct synth_state
{
    voice_set *voices;
    int sample_rate;
    int active;   
} synth_state;

typedef struct op {
    // parameters, fixed at note on
    float K;
    float C;
    float PW;
    float decay;       
    float phase_offset;    
    float phase_inc;
    
    // changing values
    float phase;   
    float amp;
    
} op; 

typedef struct op_voice
{
    op operators[4];    
    float freq;
} op_voice;

void process(synth_state *state, float **in, float **out, int n);
]])

function create_voices(voices)

    local shadow_voices = {}
    for i=1,n_voices do
        table.insert(shadow_voices, {active=false, max_level=0, last_active=-1, released=false})
    end
    
    voice_set = ffi.new("struct voice_set[1]")
    voice_set.n_voices = n_voices
    voice_set.voices = ffi.new("void *[?]", n_voices)
    voice_set.active = ffi.new("int [?]", n_voices)
    voice_set.max_level = ffi.new("float [?]", n_voices)
    
    shadow_voices.cvoices = voice_set
end

function init_synth(controller)
    synth_state = ffi.new("struct synth_state[1]")
    synth_state.sample_rate = 44100 -- until we get updated!
    synth.active = 0
    
    -- listen for updates
    add_listener(controller, "mains", function(k,v) synth.active=1 end)
    add_listener(controller, "sample_rate", function(k,v) synth.sample_rate=sample_rate end)
    
    create_voices(8)
    
    
end