
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
    -- number of samples in tail (e.g. reverb)
    tail_size =0,
    delay = 0,
                    
    -- flags for the plugin (see vst.plugin_flags)
    flags = {"synth", "replacing", "chunks"},    
    
    midi = {
        in_channels = 1,
        out_channels = 0,
    },
    
    
    -- specification of the input and output pins (optional)
    pins = {
        inputs = 
        {
        
        },
        
        outputs = {
                    {active=true, stereo=true},
                    {active=true}        
        },
    
    },
    
    -- settings for parameters that will be set if not overridden
    default_param = {label="", range={0,1}, init=0, auto=false, display=param_display},
    
    -- the parameters accessible via setParameter/getParameter (i.e those that are automatable)
    params = {
                {name="K", label="", short_label="MOD", range={0,1000}, init=0, auto=true, category="mod"},
                {name="C", label="Hz", range={0,20000}, init=0, auto=true, category="mod", float_step = {small=0.01, step=0.1, large=0.5}},
                {name="PW", label="%", range={0,0.5}, init=0.5, auto=true, category="mod"},
                {name="Decay", label="Rate", range={0,1}, init=0, auto=true, category="mod"},
            },

   
   -- basic identifying info about the plugin
    info = {
            unique_id = 'BGSQ',
            version = 1,           
            vendor = 'JHW',
            product = 'Test',
            vendor_version = 1.0,
            effect_name = 'LuaTest',
            category = 'synth' -- one of vst.categories
        },
        
    -- some basic info for the voice manager
    synth = {
        monophonic=false,
        voices=8,
    },
    
    -- list of candos that this plugin supports
    can_do = {
        "receiveVstEvents",
        "receiveVstMidiEvent",
        "bypass",
        "sendVstEvents",
        "sendVstMidiEvent",
        "receiveVstTimeInfo",
    },
        
    
    -- these variables can change during running based on
    -- actions of the host
    -- listeners can be attached to observe state changes
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
    
    -- all of the programs
    programs =
    {
       {name="First", state={K=0,C=0,PW=0,Decay=0}}    
    },
    
    -- will be copied to a new program slot when it is accessed, if there
    -- is nothing there already. see create_default_program below, which
    -- is the function actually called when a program is missing
    default_program = {name="[default]", state={K=0,C=0,PW=0,Decay=0}},    
    
    -- called if switch to program that doesn't exist
    create_default_program = function(controller) 
        return deepcopy(controller.default_program)    
    end,
}


return controller
