local tuning=require("tuning")
local midi=require("midi")

ffi.cdef([[
typedef struct op {
    // parameters, fixed at note on
    float fmul, fadd;
    float K;
    float C;        
    float phase_offset;    
   
    
    // changing values
    float phase;   
    
    float amp;
    
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


-- coefficients for the curve specifying the maximum value of log(K) for a given midi
-- note number
local mod_fm_coeffs = {
   4.31252797843203016885772023078505e-07,
  -1.44061433628169736735624706369663e-04,
   1.61320473592682332719672189114135e-02,
  -8.22886236553297401030704349977896e-01,
   2.33231396521359783946536481380463e+01}
   
local mod_fm_coeffs = {
    -4.63664607657288878155010802828428e-04,
  -7.63642157190617121287345980817918e-02,
   1.34240280326354337603333988226950e+01
}
   
-- return the maximum permissble k value for the given frequency
function max_k(midinote)
    local m1 = midinote
    local m2 = m1 * m1
    local m3 = m2 * midinote
    local m4 = m2 * m2    
    -- return math.exp(mod_fm_coeffs[1]*m4 + mod_fm_coeffs[2]*m3 + mod_fm_coeffs[3]*m2 + mod_fm_coeffs[4]*m1 + mod_fm_coeffs[5])
    return math.exp(mod_fm_coeffs[1]*m2 + mod_fm_coeffs[2]*m1 + mod_fm_coeffs[3])
end   

local function note_on(controller, event)

    --voice = activate_voice(controller)    
    voice = controller.synth_state.voices[0]
    voice.active = 1
        
    
    voice.freq = tuning.default_midi_notes[event.byte2]
    voice.amp = from_dB(-(1-event.byte3/127.0)*24.0)    
    voice.delta = event.delta
    voice.decay = 0.1
    voice.level = -80
    
    mk = max_k(event.byte2)
    voice.operators[0].K = min(mk, controller.state.K ) * from_dB(-(1-event.byte3/127.0)*48.0)
    voice.operators[0].C = voice.freq --controller.state.C
    voice.operators[0].phase_offset = 0 
    voice.operators[0].phase = 0 
    voice.operators[0].amp = 1
        
    _debug.log("%f", mk)   
        
end

local function note_off(controller, event)
    voice = controller.synth_state.voices[0]
    voice.decay = -0.001
    --voice.active = 0       
end


function create_voices(n_voices)    
    -- construct the set of voices
    voices = ffi.new("struct op_voice[?]", n_voices)
    for i=1,n_voices do
        voices[i].active = 0
    
    end
    return voices
end

function init_synth(controller, state)

    -- attach the actual call
    
    state = ffi.cast("synth_state **", state)
    
    -- construct a new 
    synth_state = ffi.new("struct synth_state")
    state[0] = synth_state
            
    synth_state.sample_rate = 44100 -- until we get updated!
    synth_state.active = 0
    
    -- this access to synth state should be mutexed!
    -- listen for updates, update the c struct directly
    add_listener(controller, "mains", function(k,v) synth_state.active=v end)
    add_listener(controller, "sample_rate", function(k,v) synth_state.sample_rate=v end)
    
    -- callbacks for events
    add_event_handler(controller, "midi", midi.filter("note_on", function(event) note_on(controller, event) end))
    add_event_handler(controller, "midi", midi.filter("note_off",function(event) note_off(controller, event) end))
    --controller.add_event_handler("midi", midi.filter("cc", function(event) cc(controller, event) end))
    
    synth_state.n_voices = controller.synth.voices
    synth_state.voices = create_voices(controller.synth.voices)
    controller.synth_state = synth_state
    
    
end