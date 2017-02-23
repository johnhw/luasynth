local tuning=require("tuning")
local midi=require("midi")

ffi.cdef([[
typedef struct op {
    // parameters, fixed at note on
    float fmul, fadd;
    float cmul, cadd;
    float K;    
    float phase_offset;    
   
    
    // changing values
    float phase;   
    
    float amp;
    void *oversampler;
    
    
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

typedef struct synth_state
{
    op_voice *voices;
    int n_voices;      // number of voices
    int sample_rate;
    int active;   
} synth_state;

void process(synth_state *state, float **in, float **out, int n);
]])


local synth = {
    voices=8,
    monophonic=false,
}

-- coefficients for the curve specifying the maximum value of log(K) for a given midi
-- note number

-- quadratic approx for 1x oversampling   
local mod_fm_coeffs = {
-3.45895623354351190465588716804746e-04,
  -9.67043666721787292805956326446903e-02,
   1.39763653421096893936237393063493e+01,
}

-- quartic approx for 4x oversampling
   local mod_fm_coeffs_4x = {
  -1.63979090133852279948667988356339e-08,
  -4.50447131686858268681365735641720e-06,
   1.97610091218673690136031773079139e-03,
  -3.16087267966017215758967040528660e-01,
   2.25334983292233097529333463171497e+01,
}
   
-- return the maximum permissble k value for the given frequency
local function max_k(midinote)
    local m1 = midinote
    local m2 = m1 * m1
    local m3 = m2 * midinote
    local m4 = m2 * m2    
    
    return math.exp(mod_fm_coeffs_4x[1]*m4 + mod_fm_coeffs_4x[2]*m3 + mod_fm_coeffs_4x[3]*m2 + mod_fm_coeffs_4x[4]*m1 + mod_fm_coeffs_4x[5])
    -- return math.exp(mod_fm_coeffs[1]*m2 + mod_fm_coeffs[2]*m1 + mod_fm_coeffs[3])
end   

local function note_on(controller, state, event)

    --voice = activate_voice(controller)    
    voice = state.voices[0]
    voice.active = 1
            
    voice.freq = tuning.default_midi_notes[event.byte2]
    voice.amp = from_dB(-(1-event.byte3/127.0)*24.0)    
    voice.delta = event.delta
    voice.decay = 0.1
    voice.level = -80    
    mk = max_k(event.byte2)
    voice.operators[0].K = min(mk, controller.state.K ) * from_dB(-(1-event.byte3/127.0)*48.0)    
    voice.operators[0].phase_offset = 0 
    voice.operators[0].phase = 0 
    voice.operators[0].amp = 1
    voice.operators[0].oversampler = create_half_cascade(2, 10, 0)
        
    _debug.log("%f", mk)   
        
end

local function note_off(controller, state, event)
    voice = state.voices[0]
    voice.decay = -0.001
    --voice.active = 0       
end


local function create_voices(n_voices)    
    -- construct the set of voices
    voices = ffi.new("struct op_voice[?]", n_voices)
    for i=1,n_voices do
        voices[i].active = 0
    
    end
    return voices
end

function synth.init(controller, state_ptr)

    -- point the C pointer to the state we allocate    
    state_ptr = ffi.cast("synth_state **", state_ptr)
    
    -- construct a new 
    synth_state = ffi.new("struct synth_state")
    state_ptr[0] = synth_state
            
    synth_state.sample_rate = 44100 -- until we get updated!
    synth_state.active = 0
    
    -- this access to synth state should be mutexed!
    -- listen for updates, update the c struct directly
    add_listener(controller, "mains", function(k,v) synth_state.active=v end)
    add_listener(controller, "sample_rate", function(k,v) synth_state.sample_rate=v end)
    
    -- callbacks for events
    add_event_handler(controller, "midi", midi.filter("note_on", function(event) note_on(controller, synth_state, event) end))
    add_event_handler(controller, "midi", midi.filter("note_off",function(event) note_off(controller, synth_state, event) end))
    
    --controller.add_event_handler("midi", midi.filter("cc", function(event) cc(controller, event) end))
    
    synth_state.n_voices = controller.synth.voices
    synth_state.voices = create_voices(controller.synth.voices)
    synth.state = synth_state
       
end



return synth