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

function cstring(str)
    return ffi.new("char [?]", string.len(str)+1, str)
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
    -- synchronise the program
    controller.programs[controller.run.program+1].state[index+1] = value
end


-- initialise the parameters for the controller
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

-- parse a midi event
function midi_event(event)
    local event = ffi.cast("struct VstMidiEvent *", event)    
    local midi = {}    
    midi.flags = tonumber(event.flags)
    midi.delta = tonumber(event.deltaFrames)
    midi.note_len = tonumber(event.noteLength)
    midi.note_offset = tonumber(event.noteOffset)
    midi.detune = tonumber(event.noteOffset)
    midi.note_off_velocity= tonumber(event.noteOffVelocity)
    midi.byte1 = tonumber(ffi.cast("unsigned char", event.midiData[0]))
    midi.byte2 = tonumber(ffi.cast("unsigned char", event.midiData[1]))
    midi.byte3 = tonumber(ffi.cast("unsigned char", event.midiData[2]))    
    return midi
end

-- parse a sysex event
function sysex_event(event)
    local event = ffi.cast("struct VstMidiSysexEvent *", event)    
    local sysex = {}    
    sysex.flags = tonumber(event.flags)
    sysex.delta = tonumber(event.deltaFrames)
    sysex.bytes = ffi.string(event.sysexDump, sysex.dumpBytes)    
    return sysex   
end

-- handle events coming in as a cdata * VstEvents
function process_events(controller, ptr)
    local events = ffi.cast("struct VstEvents *", ptr)
    local n = tonumber(events.numEvents)    
    -- iterate over events
    for i=1,n do
        local event = events.events[i-1]    
        -- dispatch according to type (either midi or sysex)
        if event.type==ffi.C.kVstMidiType then
            local mevent = midi_event(event)
            controller.events.midi(mevent)
        elseif event.type==ffi.C.kVstSysExType then
            local sevent = sysex_event(event)
            controller.events.midi(sevent)
        end                 
    end
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
    
    can_do = function(controller, opcode, index, value, ptr, opt)   
        local cando = ffi.string(ffi.cast("char *", ptr))
        for i,v in ipairs(controller.can_do) do
            if v==cando then return 1 end
        end
        return 0
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
        controller.run.sample_rate = value           
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
    
    start_process = function(controller, opcode, index, value, ptr, opt)   
        controller.run.processing = true
    end,
    
    stop_process = function(controller, opcode, index, value, ptr, opt)   
        controller.run.processing = false
    end,
    
    
    -- event processing 
    process_events = function(controller, opcode, index, value, ptr, opt)           
        process_events(controller, ptr)
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
        controller.state = deepcopy(current_program.state)
        
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
        if opcode_name~="process_events" then 
            _debug.log("Handled opcode: %s %d %f %f", opcode_name, tonumber(index), tonumber(value), tonumber(opt))
        end
    else        
        _debug.log("Unhandled opcode: %s %d %f %f", opcode_name, tonumber(index), tonumber(value), tonumber(opt))
    end
   
    return ret
end

function process(controller, inputs, outputs, samples)
    -- if  _debug then
        -- _debug.log("Process: %d", tonumber(samples))
    -- end
end

function add_handlers(controller)
    -- attach run state change listeners
    controller.listeners = {}
    local proxy = controller.run
    controller.run = {}
    mt = {__newindex = function(t,k,v)             
            proxy[k] = v
            -- call any attached listeners for this state change
            if controller.listeners[k] then
                for i,callback in ipairs(controller.listeners[k]) do
                    callback(k,v)
                end
            end
        end,
        __index = function(t,k)
            return proxy[k]        
        end
    }    
    setmetatable(controller.run, mt)   
    
end

function add_listener(controller, run, callback)
    if controller.listeners[run]==nil then
        controller.listeners[run] = {callback}
    else
        table.insert(controller.listeners[run], callback)
    end       
end

function remove_listener(controller, run, callback)
    if controller.listeners[run]~=nil then        
        table.remove(controller.listeners[run], callback)
    end       
end


function convert_time_info(info)
    local info = ffi.cast("struct VstTimeInfo *", info)
    
    local  time_info = {
        sample_pos = info.samplePos,
        sample_rate = info.sampleRate,
        nano_seconds = info.nanoSeconds,
        ppq_pos = info.ppqPos,
        tempo = info.tempo,
        bar_start = info.barStartPos,
        cycle = {info.cycleStartPos, info.cycleEndPos},    
        time_sig = {info.timeSigNumerator, info.timeSigDenominator},
        smpte_offset = info.smpteOffset,
        smpte_frame_rate = info.smpteFrameRate,
        sample_to_next_clock = info.samplesToNextClock,    
        flags = info.flags
    }
    
    flag_map = {
        nano_seconds = ffi.C.kVstNanosValid,
        ppq_pos = ffi.C.kVstPpqPosValid,
        tempo =  ffi.C.kVstTempoValid,
        bar_start = ffi.C.kVstBarsValid,
        cycle = ffi.C.kVstCyclePosValid,
        time_sig = ffi.C.kVstTimeSigValid,
        smpte = ffi.C.kVstSmpteValid,
        clock = kVstClockValid
    }
    
    -- remove invalid entries
    for k,v in pairs(flag_map) do
        if not bit.band(time_info.flags, v) then time_info[v] = nil end
    end
    
    return time_info    
end

function add_master_callbacks(c)
    
    local master = function (opcode, index, value, ptr, opt)                 
        return c.internal.audio_master(c.internal.aeffect, opcode, index, value, ptr, opt)
    end
    
    -- audio master callbacks
    master_calls = 
    {
        set_automate = function(index, opt) 
            master(ffi.C.audioMasterAutomate, index, 0, ffi.null, opt)
        end,
        
        pin_connected = function(index, io) 
            return tonumber(master(ffi.C.audioMasterPinConnected, index, io, ffi.null, 0))
        end,
        
        version = function()
            return tonumber(master(ffi.C.audioMasterVersion,0, 0, ffi.null, 0))
        end,
        
        current_id = function()
            return tonumber(master(ffi.C.audioMasterCurrentId,0, 0, ffi.null, 0))
        end,
        
        get_sample_rate = function()
            return tonumber(master(ffi.C.audioMasterGetSampleRate,0, 0, ffi.null, 0))
        end,
        
        get_block_size = function()
            return tonumber(master(ffi.C.audioMasterGetBlockSize,0, 0, ffi.null, 0))
        end,
        
        get_input_latency = function()
            return tonumber(master(ffi.C.audioMasterGetInputLatency,0, 0, ffi.null, 0))
        end,
        
        get_output_latency = function()
            return tonumber(master(ffi.C.audioMasterGetOutputLatency,0, 0, ffi.null, 0))
        end,
        
        get_process_level = function()
            return tonumber(master(ffi.C.audioMasterGetProcessLevel,0, 0, ffi.null, 0))
        end,
        
        get_automation_state = function()
            return tonumber(master(ffi.C.audioMasterGetAutomationState,0, 0, ffi.null, 0))
        end,
        
        can_do = function(str)
            str_ptr = cstring(str)
            return tonumber(master(ffi.C.audioMasterCanDo, 0, 0, str_ptr, 0))
        end,
        
        language = function()
            return tonumber(master(ffi.C.audioMasterGetLanguage, 0,0,ffi.null,0))
        end,
        
        get_time = function(filter)
            return convert_time_info(master(ffi.C.audioMasterGetTime, 0, filter, ffi.null,0))
        end,
        
        send_events = function(events)
            cevents = create_events(events)
            master(ffi.C.audioMasterProcessEvents, 0, 0, cevents,0)
        end,
        
        
        vendor = function()
            buf = ffi.new("char[?]", ffi.C.kVstMaxVendorStrLen)
            master(ffi.C.audioMasterGetVendorString, 0, 0, buf, 0)    
            return ffi.string(buf)
        end,
        
        product = function()
            buf = ffi.new("char[?]", ffi.C.kVstMaxProductStrLen)
            master(ffi.C.audioMasterGetProductString, 0, 0, buf, 0)    
            return ffi.string(buf)
        end,
        
        
        resize_window = function( w, h)
            return tonumber(master(ffi.C.audioMasterSizeWindow, w, h, ffi.null, 0))
        end,
    }
    
    c.master = master_calls
end


function test_audio_master(controller)    
    _debug.log(controller.master.product())
    _debug.log(controller.master.vendor())
    _debug.log("%d", controller.master.version())
    _debug.log("%d", controller.master.current_id())
    table.debug(controller.master.get_time(255))
    
    for i,v in ipairs(vst.all_host_can_dos) do
        _debug.log("%s: %d", v, controller.master.can_do(v))
    end
end

-- global instance
aeffect = ffi.new("struct AEffect")  
local controller = require('simple')
init_params(controller)
add_handlers(controller)

add_listener(controller, "mains", function(k,v) _debug.log("mains is %d", v) end)

function real_init(aeffect, audio_master)
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
    xpcall(real_init, debug_error, aeffect, audio_master)     
end




