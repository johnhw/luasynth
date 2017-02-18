local vst = require('vst')
local ffi = require('ffi')

-- Defines the controller for a VST

controller = {
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
    
    
    -- settings for parameters that will be set if not overridden
    default_param = {label="", range={0,1}, init=0, auto=false, display=param_display},
    
    params = {
                {name="K", label="", range={0,1000}, init=0, auto=true},
                {name="C", label="Hz", range={0,20000}, init=0, auto=true},
                {name="PW", label="%", range={0,0.5}, init=0.5, auto=true},
                {name="Decay", label="Rate", range={0,1}, init=0, auto=true},
            },
            
    flags = {ffi.C.effFlagsIsSynth},
   
    info = {
            unique_id = 'BGSQ',
            version = 1,           
            vendor = 'JHW',
            product = 'Test',
            vendor_version = 1.0,
            effect_name = 'LuaTest'
        },
        
    run = {
        block_size = -1,
        sample_rate = -1,
        mains = 0,
        open = false,
        program = 0,
        bypassed = false,
    },   
    
    programs =
    {
       {name="First", param_state={0,0,0,0}}    
    },
    
    default_program = {name="[default]", param_state={0,0,0,0}}    
    
    
}

function controller.create_default_program(controller)
    -- copy the default program into the current program
    return deepcopy(controller.default_program)    
end

return controller
