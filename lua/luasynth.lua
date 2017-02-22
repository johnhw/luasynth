bit = require('bit')
vst = require('vst')
ffi = require('ffi')

    
require("utils")
require("logdebug")

require("params")
require("fileselector")
require("timeinfo")
require("master")
require("midievent")
require("pins")
require("opcodes")
require("chunks")
require("listeners")

require("simple_synth")
_debug.log("HEER")

function init_controller(name)
    local controller = require(name)
    init_params(controller)
    add_handlers(controller)
    controller.events = {}
    --testing
    add_listener(controller, "mains", function(k,v) _debug.log("mains is %d", v) end)
    -- populate the host details
    -- set the unique id
    controller.info.int_unique_id = charcode_toint(controller.info.unique_id)
    return controller
end


function real_init(aeffect, audio_master, state)
    
    -- register c functions
    for k,v in pairs(c_funcs) do
        _debug.log(v.type)
        _G[k] = ffi.cast(v.type, v.fn)                
    end
    
    
    controller = init_controller("simple")
    -- construct the effect
    aeffect = ffi.cast("struct AEffect *", aeffect)
    aeffect.magic = charcode_toint('VstP')    
    aeffect.numPrograms = controller.n_programs
    aeffect.numParams = table.getn(controller.params)
    aeffect.numInputs = controller.n_inputs
    aeffect.numOutputs = controller.n_outputs
    aeffect.flags = lookup_flags(controller.flags, vst.plugin_flags)    
    
    aeffect.initialDelay = controller.delay
    aeffect.uniqueID = charcode_toint(controller.info.unique_id)
    aeffect.version = controller.info.version
    -- attach master callback
    controller.internal = {aeffect=aeffect, audio_master = ffi.cast("audioMasterCallback", audio_master)}
    add_master_callbacks(controller)
    get_host_details(controller)    
    test_audio_master(controller)
                
    aeffect.future = ffi.new("char[56]", 0)
    
    -- parameter access callbacks
    aeffect.getParameter = function (effect, index)         
        local status, ret, err = xpcall(get_parameter, debug_error, controller, tonumber(index))        
        return tonumber(ret) or 0.0 -- vital!
    end 
    aeffect.setParameter = function (effect, index, value)
        xpcall(set_parameter, debug_error, controller, tonumber(index), tonumber(value))         
        end
    
    -- event dispatch callbacks
    aeffect.dispatcher = function (effect, opcode, index, value, ptr, opt)         
        local status, ret,err = xpcall(dispatch, debug_error, controller, tonumber(opcode), tonumber(index), tonumber(value), ptr, tonumber(opt))                      
        
        return tonumber(ret) or 0 -- vital!
    end
    
   
    -- attach the synthesizer
    init_synth(controller, state)
   
end






function vst_init(aeffect, audio_master,  process)             
    -- call the real init in a protected environment
    xpcall(real_init, debug_error, aeffect, audio_master, process)     
end



