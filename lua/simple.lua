
-- Defines the controller for a VST

local param_property = {
    short_label = "K",
    label = "Modulation depth",
    display_index = 0,
    
}

local controller = {
    n_programs = 128,
    n_inputs = 0,
    n_outputs = 2,
    
    midi = {
        in_channels = 1,
        out_channels = 0,
    },
    
    -- number of samples in tail (e.g. reverb)
    tail_size =0,
    delay = 0,
    
    -- event handlers for each possible type of event
    events = {
        midi = function(event) table.debug(event) end,
        sysex = function(event) table.debug(event) end,
    },
    
    pins = {
        inputs = 
        {
        
        },
        
        outputs = {
        
        },
    
    },
    
    -- settings for parameters that will be set if not overridden
    default_param = {label="", range={0,1}, init=0, auto=false, display=param_display},
    
    params = {
                {name="K", label="", short_label="MOD", range={0,1000}, init=0, auto=true, category="mod"},
                {name="C", label="Hz", range={0,20000}, init=0, auto=true, category="mod", float_step = {small=0.01, step=0.1, large=0.5}},
                {name="PW", label="%", range={0,0.5}, init=0.5, auto=true, category="mod"},
                {name="Decay", label="Rate", range={0,1}, init=0, auto=true, category="mod"},
            },
            
    flags = {ffi.C.effFlagsIsSynth, 
             ffi.C.effFlagsCanReplacing,
             ffi.C.effFlagsProgramChunks
             
             },
   
    info = {
            unique_id = 'BGSQ',
            version = 1,           
            vendor = 'JHW',
            product = 'Test',
            vendor_version = 1.0,
            effect_name = 'LuaTest',
            category = 'synth' -- one of vst.categories
        },
        
    can_do = {
        "receiveVstEvents",
        "receiveVstMidiEvent",
        "bypass",
        "sendVstEvents",
        "sendVstMidiEvent",
        "receiveVstTimeInfo",
    },
        
    -- internal state, e.g. pointer to audio_master
    internal = {},
    
    run = {
        block_size = -1,
        sample_rate = -1,
        mains = 0,
        open = false,
        program = 0,
        bypassed = false,
        program_changing = false,
        processing = false,
    },   
    
    programs =
    {
       {name="First", state={0,0,0,0}}    
    },
    
    default_program = {name="[default]", state={0,0,0,0}}    
    
    
}

function controller.create_default_program(controller)
    -- copy the default program into the current program
    return deepcopy(controller.default_program)    
end




return controller
