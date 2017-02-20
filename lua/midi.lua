local bit = require("bit")
local chords = require("chords")
require "utils"
--these are updated inside the callback wrappers
local midi_filters = {}
local midi = {}

--type definitions
midi.types = {noteOn=9, noteOff=8, poly, at=10, cc=11, pc=12, channel_at=13, pb=14, sysex=15}

midi.type_names = invert_table(midi.types)


-- CC definitions
midi.cc = {
    bank_select=0,
    modulation=1,
    breath=2,
    foot=4,
    porta_time=5,
    data_m_s_b=6,
    volume=7,
    balance=8,
    pan=10,
    expression=11,
    effect1=12,
    effect2=13,
    gp1=16,
    gp2=16,
    gp3=16,
    gp4=16,
    sustain=64,
    portamento=65,
    sustenuto=66,
    soft_pedal=67,
    legato=68,
    hold2=69,
    sound_controller1=70,
    sound_controller2=71,
    sound_controller3=72,
    sound_controller4=73,
    sound_controller5=74,
    sound_controller6=75,
    sound_controller7=76,
    sound_controller8=77,
    sound_controller9=78,
    sound_controller10=79,
    gp5=80,
    gp6=81,
    gp7=82,
    gp8=83,
    porta_control=84,
    effect1_depth=91,
    effect2_depth=92,
    effect3_depth=93,
    effect4depth= 94,
    effect5_depth=95,
    data_increment=96,
    data_decrement=97,
    nrpn_lsb=98,
    nrpn_msb=99,
    rpn_lsb=100,
    nrpn_msb=101,
    all_sound_off=120,
    reset_all_controllers=121,
    local_on_off=122,
    all_notes_off=123,
    omni_off=124,
    omni_on=125,
    mono_on=126,
    poly_on=127
}


midi.ccnames = invert_table(midi.cc)


--aliases various accessors to midi events
function midi.add_midi_meta_table(event)
    --define midi aliases
    local mt =
    {
    __index = function(t,k)
        if k=='note' then return t.byte2
        elseif k=='controller' then return t.byte2
        elseif k=='value' then return t.byte3
        elseif k=='velocity' then return t.byte3
        elseif k=='bend' then return bit.bor((bit.band(t.byte2,127)), bit.lshift((bit.band(t.byte3,127))))
        elseif k=='aftertouch' then return t.byte2
        elseif k=='program' then return byte2
        else return rawget(t,k)
        end
    end,
    
    __newindex = function(t,k,v)
        if k=='note' then t.byte2 = v
        elseif k=='controller' then t.byte2 = v
        elseif k=='value' then t.byte3 = v
        elseif k=='velocity' then t.byte3 = v
        elseif k=='bend' then t.byte3 = (bit.band(bit.rshift(v,7), 127)) 
        t.byte2 = bit.band(v,127)
        elseif k=='aftertouch' then t.byte2=v
        elseif k=='program' then t.byte2=v
        else rawset(t,k,v)
        end
    end
    }
    setmetatable(event, mt)
    return event
end


--return a copy of a midievent
function midi.copy_midi_event(event)
    local nevent = {}
    nevent.sysex = event.sysex
    nevent.byte2= event.byte2
    nevent.byte3= event.byte3
    nevent.byte4= event.byte4
    nevent.type= event.type
    nevent.channel= event.channel
    nevent.delta= event.delta
    nevent.noteLength= event.noteLength
    nevent.noteOffset = event.noteOffset
    nevent.detune = event.detune
    nevent.noteOffVelocity = event.noteOffVelocity
    midi.add_midi_meta_table(nevent)
    return nevent
end


--fill in all missing fields of an event
function midi.complete_midi_fields(event)
    local nevent = {}
    nevent.sysex = event.sysex or ""
    nevent.byte2= event.byte2 or 0
    nevent.byte3= event.byte3 or 0
    nevent.byte4= event.byte4 or 0
    nevent.type= event.type or 0
    nevent.channel= event.channel or 0
    nevent.delta= event.delta or 0 
    nevent.noteLength= event.noteLength or 0
    nevent.noteOffset = event.noteOffset or 0
    nevent.detune = event.detune or 0
    nevent.noteOffVelocity = event.noteOffVelocity or 0
    midi.add_midi_meta_table(nevent)
    return nevent
end

--midi utilities
function midi.sysex_msg(sysex)
    return midi.complete_midi_fields({type=midi.types.sysex, sysex=sysex})
end

function midi.note_on(note, velocity, channel)
    return midi.complete_midi_fields({type=midi.types.noteOn, channel=channel, byte2=note, byte3=velocity})
end

function midi.note_off(note, channel)
    return midi.complete_midi_fields({type=midi.types.noteOff, channel=channel, byte2=note, byte3=0})
end

function midi.set_cc(cc, value, channel)
    return midi.complete_midi_fields({type=midi.types.cc, channel=channel, byte2=cc, byte3=value})
end

function midi.program_change(pc, channel)
    return midi.complete_midi_fields({type=midi.types.pc, channel=channel, byte2=pc})
end

function midi.pitch_bend(bend, channel)
    return midi.complete_midi_fields({type=midi.types.pb, channel=channel, byte2=bit.band(bend,127), byte3=bit.band(bit.rshift(bend,7),127)})
end

function midi.channel_aftertouch(touch, channel)
    return midi.complete_midi_fields({type=midi.types.channel_at, channel=channel, byte2=touch})
end

function midi.poly_aftertouch(note, touch, channel)
    return midi.complete_midi_fields({type=midi.types.channel_at, channel=channel, byte2=note, byte3=touch})
end


--Pretty print a midi event
function midi.midi_event_to_string(event)

    --sysex handler
    if event.type==midi.types.sysex then
        retval="Sysex: "+midi.sysex_to_hex(event.sysex)
        return retval
    end
   
	
	retval = "Ch: "..(event.channel+1).." "..midi_type_names[event.type].." "
	if event.type==midi.types.note_on or event.type==midi.types.note_off then
		retval = retval..(chords.number_to_note(event.byte2).." "..event.byte3.." ")
	end
	
	if event.type==midi.types.cc  then
		name = " ("..midi.cc_names[event.byte2]..")" or ""
	
		retval = retval..(event.byte2..name.." = "..event.byte3.." ")
	end
	
	if event.type==midi.types.pb then
		retval = retval..((bit.lshift(event.byte3) + event.byte2).." ")
	end
	
	if event.type==midi.types.at then
		retval = retval..(number_to_note(event.byte2).."  "..event.byte3.." ")
	end
	
	if event.type==midi.types.channel_at then
		retval = retval..(event.byte2.." ")
	end
	
	if event.type==midi.types.pc then
		retval = retval..(event.byte2.." ")
	end
	
	
	if event.note_offset~=0 then
		retval = retval..("Note offset: "..event.note_offset.." ")
	end
	
	if event.note_off_velocity~=0 then
		retval = retval..("Off. vel.: "..event.note_off_velocity.." ")
	end
	
	
	if event.note_length~=0 then
		retval = retval..("Note len.: "..event.note_length.." ")
	end
	
	if event.detune~=0 then
		retval = retval..("Detune: "..event.detune.." ")
	end
		
	
	retval = retval..("    [Delta: "..event.delta.."]\n")
	
	return retval

end



--add a new filter.
--Filters have format:
-- callback. Function to be called. Same format as midiEventCb()
--numbers can be a single number,  a range of numbers, or a list of these. Ranges are strings with - separator, e.g. "4-13" or "6--15", "8 - 9"
-- type 
-- channel
-- byte2 
-- byte3
-- byte4
-- delta
-- noteLen
-- noteOffset
--noteOffVelocity
-- detune
--NB: no support for filtering sysex events

local midi_filters = {}
function add_midi_filter(filter)
    table.insert(midi_filters, filter)
end


function midi.handle_filters(event)
    local fields = {'type', 'byte2', 'byte3', 'byte4', 'channel', 'delta', 'note_len', 
        'note_offset', 'note_off_velocity', 'detune', 'note', 'value', 'velocity', 
        'controller', 'bend', 'aftertouch', 'program'}
    
    --check each filter
    for i,v in ipairs(midi_filters) do
        if v.callback then
            local match = true
                        
            --check for matches
            for j,k in ipairs(fields) do
                if v[k] and event[k] then match = match and in_range(event[k], v[k]) end
            end
            
            --call the filter function
            if match then
                v.callback(event)
            end
                       
        end    
    end    
end

--parses ranges as used in midifilter
function in_range(test, range)

    
    --simple number
    if type(range)=='number' then
        return test==range             
    end
    
    --string range
    if type(range)=='string' then
        --extract digits
        local match = "(%d+)%s*%-+%s*(%d+)"
        local first, last
        _,_,first,last = string.find(range, match)
        if first and last then
            return test>=(first+0) and test<=(last+0)
        else
            return false
        end
        
    end
    
    --check tables
    if type(range)=='table' then
        local inr = false
        for i,v in ipairs(range) do
            if inRange(test, v) then
                inr = true
            end
        end
        return inr
    end
        
end



--Compute time to next beat, and the index of that beat. BeatLength 
function midi.compute_next_q_beat(sample_pos, tempo, sample_rate, beat_length)
     local one_beat_length = sample_rate * (60/(tempo)) * beat_length
     local beat_time = sample_pos/one_beat_length
     local off_beat = beat_time - math.floor(beat_time)
     local timeto_next_beat = 1.0 - off_beat
     local timein_frames = (timeto_next_beat*one_beat_length)
     return math.floor(beat_time), timein_frames 
 end


--Compute time to next beat, and the index of that beat.  
function midi.compute_beat_time(sample_pos, tempo, sample_rate, beat_length)
     local one_beat_length = sample_rate * (60/(tempo)) * beat_length     
     local beat_time = sample_pos/one_beat_length     
     local off_beat = beat_time - math.floor(beat_time)     
     local timeto_next_beat = 1.0 - off_beat                     
     local timein_frames = (timeto_next_beat*one_beat_length)            
     return one_beat_length, math.floor(beat_time), timein_frames 
 end


--convert a sysex string to a table
function midi.sysex_to_table(dump)
    local len = string.len(dump)
    local tab = {}
    for i=1,len do
        table.insert(tab,string.byte(dump, i))
    end    
    return tab  
end

--convert a sysex string to a hexdump
function midi.sysex_to_hex(dump)
    local len = string.len(dump)
    local thex = {}
    for i=1,len do
        table.insert(thex, string.format("%02X ",string.byte(dump, i)))
    end    
    return table.concat(thex)    
end



--convert a hex string to a binary string
function midi.from_hex(str)
    local match="(%x%x)[%s%p]*"
    local digits = {}

    function insert_digit(digit)
        table.insert(digits, string.char(('0x'..digit)+0))
        return ""
    end
    string.gsub(str, match, insert_digit)
        
    
    return table.concat(digits)
end

--convert a hex string, integer or table of these into a string
function midi.hex_to_sysex(dump)

    --simple number
    if type(dump)=='number' then
        return string.char(dump)
    end
    
    --hex block
    if type(dump)=='string' then
        return from_hex(dump)
    end
    
    --table 
    if type(dump)=='table' then
        local dtable = {}
        for i,v in ipairs(dump) do
            --recursively dump elements
            table.insert(dtable, hex_to_sysex(v))        
        end
        return table.concat(dtable)
    end

end

return midi