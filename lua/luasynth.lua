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

require("listeners")


function process(controller, inputs, outputs, samples)
    -- if  _debug then
        -- _debug.log("Process: %d", tonumber(samples))
    -- end
end

function init_controller(name)
    local controller = require('simple')
    init_params(controller)
    add_handlers(controller)
    --testing
    add_listener(controller, "mains", function(k,v) _debug.log("mains is %d", v) end)

    controller.info.int_unique_id = charcode_toint(controller.info.unique_id)
    return controller
end


function real_init(aeffect, audio_master)
    controller = init_controller("simple")
    -- construct the effect
    aeffect = ffi.cast("struct AEffect *", aeffect)
    aeffect.magic = charcode_toint('VstP')    
    aeffect.numPrograms = controller.n_programs
    aeffect.numParams = table.getn(controller.params)
    aeffect.numInputs = controller.n_inputs
    aeffect.numOutputs = controller.n_outputs
    aeffect.flags = merge_flags(controller.flags)
    
    aeffect.initialDelay = controller.delay
    aeffect.uniqueID = charcode_toint(controller.info.unique_id)
    aeffect.version = controller.info.version
    -- attach master callback
    controller.internal.audio_master = ffi.cast("audioMasterCallback", audio_master)
    controller.internal.aeffect = aeffect
    add_master_callbacks(controller)
    test_audio_master(controller)
    
    
    aeffect.future = ffi.new("char[56]", 0)
    
    -- parameter access callbacks
    aeffect.getParameter = function (effect, index) 
        local status, ret, err = xpcall(get_parameter, debug_error, controller, tonumber(index))
        return ret
    end 
    aeffect.setParameter = function (effect, index, value) xpcall(set_parameter, debug_error, controller, tonumber(index), tonumber(value)) end
    
    -- event dispatch callbacks
    aeffect.dispatcher = function (effect, opcode, index, value, ptr, opt) 
        local status, ret,err = xpcall(dispatch, debug_error, controller, tonumber(opcode), tonumber(index), tonumber(value), ptr, tonumber(opt))              
        return ret 
    end
    
    -- process callbacks
    aeffect.processReplacing = function (effect, inputs, outputs, samples) process(controller, inputs, outputs, tonumber(samples)) end    
   
end

function vst_init(aeffect, audio_master)     
    -- call the real init in a protected environment
    xpcall(real_init, debug_error, aeffect, audio_master)     
end



