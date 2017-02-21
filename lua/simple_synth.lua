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


local function note_on(controller, event)

    --voice = activate_voice(controller)    
    voice = controller.synth_state.voices[0]
    voice.active = 1
        
    voice.freq = tuning.default_midi_notes[event.byte2]
    voice.amp = from_dB(-(1-event.byte3/127.0)*24.0)    
    voice.delta = event.delta
    
    voice.operators[0].K = controller.state.K
    voice.operators[0].C = controller.state.C
    voice.operators[0].phase_offset = 0 
    voice.operators[0].phase = 0 
    voice.operators[0].amp = 1
        
    _debug.log("-*-")   
        
end

local function note_off(controller, event)
    voice = controller.synth_state.voices[0]
    voice.active = 0       
end


function create_voices(n_voices)    
    -- construct the set of voices
    voices = ffi.new("struct op_voice[?]", n_voices)
    for i=1,n_voices do
        voices[i].active = 0
    
    end
    return voices
end

function init_synth(controller, aeffect, process)

    -- attach the actual call
    process = ffi.cast("void (*)(synth_state *, float **, float **, int)", process)       
    
    -- construct a new 
    synth_state = ffi.new("struct synth_state")
    aeffect.processReplacing = function (effect, inputs, outputs, samples) process(synth_state, inputs, outputs, samples) end    
            
            
    synth_state.sample_rate = 44100 -- until we get updated!
    synth_state.active = 0
    
    -- listen for updates, update the c struct directly
    add_listener(controller, "mains", function(k,v) synth_state.active=v end)
    add_listener(controller, "sample_rate", function(k,v) _debug.log("%s %s", k, v)
    synth_state.sample_rate=v end)
    
    -- callbacks for events
    add_event_handler(controller, "midi", midi.filter("note_on", function(event) note_on(controller, event) end))
    add_event_handler(controller, "midi", midi.filter("note_off",function(event) note_off(controller, event) end))
    --controller.add_event_handler("midi", midi.filter("cc", function(event) cc(controller, event) end))
    
    synth_state.n_voices = controller.synth.voices
    synth_state.voices = create_voices(controller.synth.voices)
    controller.synth_state = synth_state
    
    
end