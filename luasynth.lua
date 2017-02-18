local bit = require('bit')
local vst = require('vst')
local ffi = require('ffi')

-- debugging ------------
debug_on = true
if debug_on then
    local debug_file = io.open("luasynth.log", "a")    
    local debug_log = function(...)
        debug_file:write(string.format(...).."\n")
        debug_file:flush()
    end    
    local debug_raw_log = function(s)
        debug_file:write(tostring(s).."\n")
        debug_file:flush()
    end        
    _debug = {log=debug_log, file=debug_file, raw_log=debug_raw_log}
    _debug.log("---")
end

function debug_error(error)
    _debug.log("\n%s\n%s", error, debug.traceback())
end

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            _debug.raw_log(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    pos = tostring(pos)
                    if (type(val)=="table") then
                    
                        _debug.raw_log(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        _debug.raw_log(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        _debug.raw_log(indent.."["..pos..'] => "'..val..'"')
                    else
                        _debug.raw_log(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                _debug.raw_log(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        _debug.raw_log(tostring(t).." {")
        sub_print_r(t,"  ")
        _debug.raw_log("}")
    else
        sub_print_r(t,"  ")
    end
    _debug.raw_log()
end

table.debug = print_r
------------------------------

-- utils ---------------------
function charcode_toint(charcode)
    -- convert 4 char string to int32 (for magic numbers)
    local a,b,c,d = string.byte(charcode,1,4)    
    return bit.bor(bit.bor(bit.lshift(a,24), bit.lshift(b,16)),  bit.bor(bit.lshift(c,8) ,bit.lshift(d,0)))
end

function merge_flags(flags)
    flag = 0
    for i,v in ipairs(flags) do
        flag = bit.bor(flag, v)
    end
    return flag
end

function min(x,y)
    if x>y then return y else return x end
end

function write_string(str, ptr, max_len)
    str = string.sub(str, 1, max_len)
    ffi.copy(ptr, str)
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
---------------------------------------


function param_display(controller, index)
    -- default display function    
    return tostring(controller.state[index])
end


function get_parameter(controller, index)   
    if _debug then
       _debug.log("Get parameter: %s", controller.params[index+1].name)
    end
    return controller.state[index+1]
end

function set_parameter(controller, index, value)
    if _debug then
        _debug.log("Set parameter: %s = %f", controller.params[index+1].name, value)
    end
    controller.state[index+1] = value    
end


function init_params(controller)
    local values = {}
    local param_index = {}
    for i,v in ipairs(controller.params) do
    
        -- copy in defaults if omitted
        for j,t in pairs(controller.default_param) do
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
    -- parameters: label, name, display and automation enabled
    get_param_label = function(controller, opcode, index, value, ptr, opt)     
    write_string(controller.params[index+1].label, ptr, ffi.C.kVstMaxParamStrLen) end,
    
    get_param_name = function(controller, opcode, index, value, ptr, opt)     
    write_string(controller.params[index+1].name, ptr, ffi.C.kVstMaxParamStrLen) end,
    
    get_param_display = function(controller, opcode, index, value, ptr, opt)     
    write_string(tostring(controller.params[index+1].display(controller, index+1)), ptr, ffi.C.kVstMaxParamStrLen) end,

    can_be_automated = function(controller, opcode, index, value, ptr, opt)   
    if controller.params[index+1].auto then return 1 else return 0 end end,
    
    -- basic info about the plugin 
    get_vendor_string = function(controller, opcode, index, value, ptr, opt)   
    write_string(controller.info.vendor, ptr, ffi.C.kVstMaxVendorStrLen) 
    end,
    
    get_vendor_version = function(controller, opcode, index, value, ptr, opt)   
        return controller.info.version    
    end,
    
    get_product_string = function(controller, opcode, index, value, ptr, opt)   
    write_string(controller.info.product, ptr, ffi.C.kVstMaxProductStrLen)
    end,
    
    get_effect_name = function(controller, opcode, index, value, ptr, opt)   
    write_string(controller.info.effect_name, ptr, ffi.C.kVstMaxEffectNameLen) 
    end,
    
    get_tail_size = function(controller, opcode, index, value, ptr, opt)   
        return controller.tail_size
    end,
    
    -- hardcoded to VST 2.4 standard
    get_vst_version = function(controller, opcode, index, value, ptr, opt)   
        return 2400
    end,
    
    -- midi
    
    get_num_midi_input_channels = function(controller, opcode, index, value, ptr, opt)   
        return controller.midi.in_channels
    end,
    
    get_num_midi_output_channels = function(controller, opcode, index, value, ptr, opt)   
        return controller.midi.out_channels
    end,
        
    
    -- state changes (sample rate, mains, block size, opened, closed)
    mains_changed = function(controller, opcode, index, value, ptr, opt)   
        controller.run.mains = value           
    end,
    
    set_sample_rate = function(controller, opcode, index, value, ptr, opt)   
        controller.run.sample_state = value           
    end,
        
    set_block_size = function(controller, opcode, index, value, ptr, opt)   
        controller.run.block_size = value           
    end,
    
    open = function(controller, opcode, index, value, ptr, opt)   
        controller.run.open = true
    end,
    
    close = function(controller, opcode, index, value, ptr, opt)   
        controller.run.open = false
    end,
    
    set_bypass = function(controller, opcode, index, value, ptr, opt)   
        controller.run.bypass = value>0
    end,
    
    
    -- programs
    get_program = function(controller, opcode, index, value, ptr, opt)   
        return controller.run.program
    end,
    
    
    set_program = function(controller, opcode, index, value, ptr, opt)           
    
        controller.run.program = value
        if controller.programs[value+1]==nil then
            controller.programs[value+1] = controller:create_default_program()            
        end
        
        -- set the parameters from the program state
        current_program  = controller.programs[value+1]
        for i,v in pairs(controller.state) do
            controller.state[i] = current_program.param_state[i]
        end
        
    end,
    
    get_program_name = function(controller, opcode, index, value, ptr, opt)   
        local current = controller.run.program+1
        if controller.programs[current]==nil then
            write_string("[none]", ptr, ffi.C.kVstMaxProgNameLen)
            return
        end        
        write_string(controller.programs[current].name, ptr, ffi.C.kVstMaxProgNameLen)
    end,
    
    set_program_name = function(controller, opcode, index, value, ptr, opt)   
        local current = controller.run.program+1
        controller.programs[current].name = ffi.string(ffi.cast("char *", ptr))
    end,    
        
    get_program_name_indexed = function(controller, opcode, index, value, ptr, opt)           
        local program = controller.programs[index+1]
        if program then
            return program.name
        else
            return "<unknown>"
        end        
    end,
    

}

function dispatch(controller, opcode, index, value, ptr, opt)    
    local ret = 0
    
    if vst.opcode_index[tonumber(opcode)] then
        opcode_name = vst.opcode_index[tonumber(opcode)]
    else
        opcode_name = tonumber(opcode)
    end
    
    if opcode_handlers[opcode_name] then
        ret = opcode_handlers[opcode_name](controller, opcode, index, value, ptr, opt)    
        _debug.log("Handled opcode: %s %d %f %f", opcode_name, tonumber(index), tonumber(value), tonumber(opt))
    elseif    opcode_name~='process_events' then
        -- ignore process_events flood!      
        _debug.log("Unhandled oppcode: %s %d %f %f", opcode_name, tonumber(index), tonumber(value), tonumber(opt))
    end
   
    return ret
end

function process(controller, inputs, outputs, samples)
    if  _debug then
        _debug.log("Process: %d", tonumber(samples))
    end
end



-- global instance
aeffect = ffi.new("struct AEffect")  
local controller = require('simple')
init_params(controller)


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
    aeffect.getParameter = function (effect, index) 
        local status, ret, err = xpcall(get_parameter, debug_error, controller, tonumber(index)    )
        return ret
    end 
    aeffect.setParameter = function (effect, index, value) xpcall(set_parameter, debug_error, controller, tonumber(index), tonumber(value)) end
    aeffect.dispatcher = function (effect, opcode, index, value, ptr, opt) 
        local status, ret,err = xpcall(dispatch, debug_error, controller, tonumber(opcode), tonumber(index), tonumber(value), ptr, tonumber(opt))      
        return ret 
    end
    aeffect.processReplacing = function (effect, inputs, outputs, samples) process(controller, inputs, outputs, tonumber(samples)) end
    debug_log:flush()
end




