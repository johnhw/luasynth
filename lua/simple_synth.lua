local tuning=require("tuning")
local midi=require("midi")

ffi.cdef([[
typedef struct op {
    // parameters, fixed at note on
    float fmul, fadd;
    float cmul, cadd;
    float ctrack, ftrack;
    float K;    
    float phase_offset;    
   float accum;
    
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
    op_voice voices[8];
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

-- quartic approx for 8x oversampling
local mod_fm_coeffs_8x = {
  -6.93453558813240906925784716625938e-08,
   1.93395186369337897952253718658611e-05,
  -1.46668198954703747106942390843187e-03,
  -1.31686292999671966663655098273011e-01,
   2.13872733169352962079301505582407e+01,
}
   
-- return the maximum permissble k value for the given frequency
local function max_k(midinote)
    local m1 = midinote
    local m2 = m1 * m1
    local m3 = m2 * midinote
    local m4 = m2 * m2    
    c = mod_fm_coeffs_8x
    
    return math.exp(c[1]*m4 + c[2]*m3 + c[3]*m2 + c[4]*m1 + c[5])
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
    
    
    voice.operators[0].accum = 0
    
    voice.operators[0].oversampler = create_half_cascade(3, 10, 0)
        
        
end

local function note_off(controller, state, event)
       
    voice = state.voices[0]
    voice.decay = -0.001
    --voice.active = 0       
end


-- return a new function that is only called if the midi type matches
function midi_filter(midi_type, fn)
    
    local midi_code = midi.types[midi_type]
    return function (etype, event) table.debug(event); if event.type==midi_code then fn(event) end end
end

-- lock callbacks that touch the parameter state
function add_locked_listener(controller, etype, fn)
    local lock = controller.internal.user.param_lock
    add_listener(controller, etype, function(param, event) 
    lock_lua(lock)
        fn(param, event)
    unlock_lua(lock)
    end)
end


function synth.init(controller, user)

    -- point the C pointer to the state we allocate    
    -- construct a new 
    synth_state = ffi.new("struct synth_state")
    vstate = synth_state
    
    user.state = synth_state
            
    synth_state.sample_rate = 44100 -- until we get updated!
    synth_state.active = 0
    
    -- this access to synth state should be mutexed!
    -- listen for updates, update the c struct directly
    add_listener(controller, "mains", function(k,v) synth_state.active=v end)
    add_listener(controller, "sample_rate", function(k,v) synth_state.sample_rate=v end)
    
    -- callbacks for events
    add_locked_listener(controller, "midi", midi_filter("note_on", function(event) note_on(controller, synth_state, event) end))
    add_locked_listener(controller, "midi", midi_filter("note_off",function(event) note_off(controller, synth_state, event) end))
    add_locked_listener(controller, "K", function (param, event)  synth_state.voices[0].operators[0].K=event end)
    add_locked_listener(controller, "fM", function (param, event)  synth_state.voices[0].operators[0].fmul=tuning.cents_to_ratio(event) end)
    add_locked_listener(controller, "cM", function (param, event) synth_state.voices[0].operators[0].cmul=tuning.cents_to_ratio(event)*(controller.state.ctrack or 1) end)
    add_locked_listener(controller, "fA", function (param, event) synth_state.voices[0].operators[0].fadd=event end)
    add_locked_listener(controller, "cA", function (param, event) synth_state.voices[0].operators[0].cadd=event  end)
    add_locked_listener(controller, "ftrack", function (param, event) synth_state.voices[0].operators[0].ftrack = event
    end)
    add_locked_listener(controller, "ctrack", function (param, event)  synth_state.voices[0].operators[0].ctrack = event
    end)
    
    
    
    --controller.add_event_handler("midi", midi.filter("cc", function(event) cc(controller, event) end))
    
    synth_state.n_voices = controller.synth.voices
    
    for i=1,synth_state.n_voices do
            synth_state.voices[i].active = 0    
    end
    
    synth.state = synth_state        
end



return synth