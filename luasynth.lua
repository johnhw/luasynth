local bit = require('bit')
local vst = require('vst')
local ffi = require('ffi')


debug_on = true
if debug_on then
    local debug_file = io.open("luasynth.log", "a")    
    local debug_log = function(...)
        debug_file:write(string.format(...).."\n")
        debug_file:flush()
    end    
    _debug = {log=debug_log, file=debug_file}
    _debug.log("---")
end

function charcode_toint(charcode)
    -- convert 4 char string to int32 (for magic numbers)
    local a,b,c,d = string.byte(charcode,1,4)    
    return bit.bor(bit.bor(bit.lshift(a,24), bit.lshift(b,16)),  bit.bor(bit.lshift(c,8) ,bit.lshift(d,0)))
end

function param_display(controller, index)
    -- default display function    
    return tostring(controller.state[index])
end

default_param = {label="", range={0,1}, init=0, auto=false, display=param_display}

controller = {
    n_programs = 128,
    n_inputs = 0,
    n_outputs = 2,
    params = {
                {name="K", label="", range={0,1000}, init=0, auto=true},
                {name="C", label="Hz", range={0,20000}, init=0, auto=true},
                {name="PW", label="%", range={0,0.5}, init=0.5, auto=true},
                {name="Decay", label="Rate", range={0,1}, init=0, auto=true},
            },
    flags = {ffi.C.effFlagsIsSynth},
    delay = 0,
    info = {
            unique_id = 'BGSQ',
            version = 1,           
            vendor = 'JHW',
            product = 'Test',
            vendor_version = '1.0',
            effect_name = 'LuaTest'
        }
}

function merge_flags(flags)
    flag = 0
    for i,v in ipairs(flags) do
        flag = bit.bor(flag, v)
    end
    return flag
end

function get_parameter(controller, index)
    index = tonumber(index)+1
    
    if _debug then
       _debug.log("Get parameter: %s", controller.params[index].name)
    end
    return controller.state[index]
end

function set_parameter(controller, index, value)
    index = tonumber(index)+1
    value = tonumber(value)
    if _debug then
        _debug.log("Set parameter: %s = %f", controller.params[index].name, value)
    end
    controller.state[index] = value
end

function write_string(str, ptr, max_len)
    ffi.copy(ptr, str, max_len)
end

function init_params(controller)
    local values = {}
    local param_index = {}
    for i,v in ipairs(controller.params) do
    
        -- copy in defaults if omitted
        for j,t in pairs(default_param) do
            if v[j]==nil then
                v[j] = t
            end
        end
        values[i] = v.init        
        param_index[v.name] = i                
    end
    controller.param_index = param_index
    controller.state = values
end


opcode_handlers = {
    get_param_label = function(controller, opcode, index, value, ptr, opt)     
    write_string(controller.params[index+1].label, ptr, ffi.C.kVstMaxParamStrLen) end,
    
    get_param_name = function(controller, opcode, index, value, ptr, opt)     
    write_string(controller.params[index+1].name, ptr, ffi.C.kVstMaxParamStrLen) end,
    
    get_param_display = function(controller, opcode, index, value, ptr, opt)     
    write_string(tostring(controller.params[index+1].display(controller, index+1)), ptr, ffi.C.kVstMaxParamStrLen) end,

    can_be_automated = function(controller, opcode, index, value, ptr, opt)   
    if controller.params[index+1].auto then return 1 else return 0 end end,
    
    get_vendor_string = function(controller, opcode, index, value, ptr, opt)   
    write_string(controller.info.vendor, ptr, ffi.C.kVstMaxVendorStrLen) 
    end,
    
    get_product_string = function(controller, opcode, index, value, ptr, opt)   
    write_string(controller.info.product, ptr, ffi.C.kVstMaxProductStrLen)
    end,
    
    get_effect_name = function(controller, opcode, index, value, ptr, opt)   
    write_string(controller.info.effect_name, ptr, ffi.C.kVstMaxEffectNameLen) 
    end,



}

function dispatch(controller, opcode, index, value, ptr, opt)    
        if vst.opcode_index[tonumber(opcode)] then
            opcode_name = vst.opcode_index[tonumber(opcode)]
        else
            opcode_name = tonumber(opcode)
        end
    
    if opcode_handlers[opcode_name] then
        ret = opcode_handlers[opcode_name](controller, opcode, index, value, ptr, opt)    
    end
    
    if _debug then         
        _debug.log("Opcode: %s %d %f %f", opcode_name, tonumber(index), tonumber(value), tonumber(opt))
    end
    return ret
end

function process(controller, inputs, outputs, samples)
    if  _debug then
        _debug.log("Process: %d", tonumber(samples))
    end
end

init_params(controller)

function debug_error(error)
    _debug.log("\n%s\n%s", error, debug.traceback())
end

-- global instance
aeffect = ffi.new("struct AEffect")  

function vst_init(aeffect)     
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
    
    aeffect.future = ffi.new("char[56]", 0)
    aeffect.getParameter = function (effect, index) xpcall(get_parameter, debug_error, controller, index)  end 
    aeffect.setParameter = function (effect, index, value) xpcall(set_parameter, debug_error, controller, index, value) end
    aeffect.dispatcher = function (effect, opcode, index, value, ptr, opt) xpcall(dispatch, debug_error, controller, opcode, index, value, ptr, opt) end
    
        
    aeffect.processReplacing = function (effect, inputs, outputs, samples) process(controller, inputs, outputs, samples) end
    
    debug_log:flush()
end




