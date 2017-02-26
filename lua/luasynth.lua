bit = require('bit')
vst = require('vst')
ffi = require('ffi')

    
require("utils")
require("logdebug")
require("scales")
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


function init_controller(name)
    local controller = require(name)
    init_params(controller)
    add_handlers(controller)
    controller.events = {}
    --testing
    add_listener(controller, "mains", function(k,v) _debug.log("mains is %d", v) end)
    -- set the unique id
    controller.info.int_unique_id = charcode_toint(controller.info.unique_id)
    
    return controller
end

function init_aeffect(aeffect)
 -- construct the effect
    
    aeffect.magic = charcode_toint('VstP')    
    aeffect.numPrograms = controller.n_programs
    aeffect.numParams = table.getn(controller.params)
    aeffect.numInputs = controller.n_inputs
    aeffect.numOutputs = controller.n_outputs
    aeffect.flags = lookup_flags(controller.flags, vst.plugin_flags)    
    
    aeffect.initialDelay = controller.delay
    aeffect.uniqueID = charcode_toint(controller.info.unique_id)
    aeffect.version = controller.info.version   
    aeffect.future = ffi.new("char[56]", 0)
    
    -- parameter access callbacks
    aeffect.getParameter = function (effect, index)         
        local status, ret, err = xpcall(get_parameter, debug_error, controller, tonumber(index))        
        return tonumber(ret) or 0.0 -- vital!
    end 
    aeffect.setParameter = function (effect, index, value)
        xpcall(set_parameter, debug_error, controller, tonumber(index), tonumber(value))     
        return nil
    end
    
    -- event dispatch callbacks
    aeffect.dispatcher = function (effect, opcode, index, value, ptr, opt)         
        local status, ret,err = xpcall(dispatch, debug_error, controller, tonumber(opcode), tonumber(index), tonumber(value), ptr, tonumber(opt))                              
        return tonumber(ret) or 0 -- vital!
    end    
end


ffi.cdef([[
typedef struct LuaLock LuaLock;
typedef struct synth_state synth_state;
typedef struct luasynthUser
{
    LuaLock *lock; // lock to prevent threads invalidating lua state 
    LuaLock *param_lock; // lock to lock parameter access
    // pointers to the real functions
    void *dispatcher;
    void *setParameter;	
	void *getParameter;
    void (*process)(struct luasynthUser *, float **, float **, int n);
    void (*init_c)(struct luasynthUser *); // called after lua initialisation; can read lua_state
    void *state; // will point to the state that lua allocates
} luasynthUser;
]])

global_handle = {}

function real_init(aeffect, audio_master)
    
    -- register c functions that are passed in
    for k,v in pairs(c_funcs) do
        _debug.log(v.type)
        _G[k] = ffi.cast(v.type, v.fn)                
    end
    
    aeffect = ffi.cast("struct AEffect *", aeffect)
    -- make sure we don't GC the controller 
    global_handle.controller = controller
    
    controller = init_controller("simple")
    init_aeffect(aeffect)
    local user=ffi.cast("luasynthUser *", aeffect.user)
    -- attach master callback
    controller.internal = {aeffect=aeffect, 
                           audio_master = ffi.cast("audioMasterCallback", audio_master), 
                           user=user
                          }
    
    -- populate the host details
    add_master_callbacks(controller)
    get_host_details(controller)    
    test_audio_master(controller)
    
    
    -- attach the synthesizer
    controller.synth.init(controller, user)       
end






function vst_init(aeffect, audio_master,  process)             
    -- call the real init in a protected environment
    xpcall(real_init, debug_error, aeffect, audio_master, process)     
end



