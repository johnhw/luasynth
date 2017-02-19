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


function process(controller, inputs, outputs, samples)
    -- if  _debug then
        -- _debug.log("Process: %d", tonumber(samples))
    -- end
end

function init_controller(name)
    local controller = require(name)
    init_params(controller)
    add_handlers(controller)
    --testing
    add_listener(controller, "mains", function(k,v) _debug.log("mains is %d", v) end)
    -- populate the host details
    -- set the unique id
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
    aeffect.flags = lookup_flags(controller.flags, vst.plugin_flags)    
    
    aeffect.initialDelay = controller.delay
    aeffect.uniqueID = charcode_toint(controller.info.unique_id)
    aeffect.version = controller.info.version
    -- attach master callback
    controller.internal.aeffect = aeffect
    controller.internal.audio_master = ffi.cast("audioMasterCallback", audio_master)
    add_master_callbacks(controller)
    get_host_details(controller)    
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
    
    -- process callbacks (these should never be done in Lua, but in an external C module!)
    aeffect.processReplacing = function (effect, inputs, outputs, samples) process(controller, inputs, outputs, tonumber(samples)) end    
   
end




-- define a package searcher to find modules in the .rc file
function add_loader(load_resource)
    LUA_RESOURCE_TYPE = 1
    load_resource = ffi.cast("void (*) (char * , int, uint32_t *, char **)", load_resource)
    
    -- query for the resource, and return a loader if found
    function resource_loader(pkg)
        len = ffi.new("int [1]")
        name = ffi.new("char *[1]")
        load_resource(cstring(pkg..".lua"), LUA_RESOURCE_TYPE, len, name)
        if name[0]~=ffi.null then 
            -- loader just executes the string
            function loader()
                return loadstring(ffi.string(name[0]))
            end
            return loader
        else
            return 'Could not load resource: ' .. pkg..'.lua'
        end
    end
    -- add to the default loader list
    table.insert(package.loaders, resource_loader)
end

function vst_init(aeffect, audio_master, load_resource)             
    -- call the real init in a protected environment
    xpcall(real_init, debug_error, aeffect, audio_master)     
end



