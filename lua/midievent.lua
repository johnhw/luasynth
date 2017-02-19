---------- midi events

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
-- returns a table of events (type, event)
function process_events(controller, ptr)
    local events = ffi.cast("struct VstEvents *", ptr)
    local n = tonumber(events.numEvents)    
    local all_events = {}
    
    -- iterate over events
    for i=1,n do
        local event = events.events[i-1]    
        -- dispatch according to type (either midi or sysex)
        if event.type==ffi.C.kVstMidiType then
            local mevent = midi_event(event)
            table.insert(all_events, {"midi", controller.events.midi(mevent)})            
        elseif event.type==ffi.C.kVstSysExType then
            local sevent = sysex_event(event)
            table.insert(all_events, {"sysex", controller.events.midi(mevent)})
        end                 
    end
    
    return all_events
end


-- create a sysex event to send to the host    
function create_sysex_event(sysex_event) 
    local host_event = ffi.new("struct VstMidiSysexEvent []", 1)
    host_event.type = ffi.C.kVstSysexType
    host_event.byteSize = ffi.sizeof("struct VstMidiSysexEvent")    
    host_event.deltaFrames = sysex_event.delta or 0
    host_event.flags = 0 -- no important flags
    host_event.dumpBytes = string.len(sysex_event.bytes)
    host_event.resvd1= 0
    host_event.sysexDump = cstring(sysex_event.bytes)
    host_event.resvd2=0
    return ffi.cast("struct VstEvent*", host_event)
end
    
    
-- create a midi event to send to the host
function create_midi_event(midi_event) 
    local host_event = ffi.new("struct VstMidiEvent []", 1)
    host_event.type = ffi.C.kVstMidiType
    host_event.byteSize = ffi.sizeof("struct VstMidiEvent")
    host_event.deltaFrames = midi_event.delta or 0
    host_event.flags = 0 -- no important flags
    host_event.noteLength = midi_event.note_len or 0
    host_event.detune = midi_event.detune or 0
    host_event.noteOffVelocity = midi_event.note_off_velocity or 0
    host_event.midiData[0] = midi_event.byte1 or 0
    host_event.midiData[1] = midi_event.byte2 or 0
    host_event.midiData[2] = midi_event.byte3 or 0
    host_event.midiData[3] = 0
    host_event.reserved1 = 0
    host_event.reserved2 = 0       
    return ffi.cast("struct VstEvent*", host_event)
end

-- prepare events to send to the host
function create_host_events(events)
    local host_events = ffi.new("struct VstEvents []", 1)
    
    host_events.numEvents = table.getn(events)    
    
    for i,v in ipairs(events) do
        local event_type = events[0]
        local event_data = events[1]
        if event_type=='midi' then
            local host_event = create_midi_host_event(event_data)            
        elseif event_type=='sysex' then
            local host_event = create_sysex_host_event(event_data)            
        end
        host_events.events[i] = host_event
    end
    return host_events    
end

----------------