-- tuning, with support for microtuning via Scala files

local tuning = {}

--compute midi note frequencies    
local midibase = 8.1758 --hz
tuning.default_midi_notes = {}
for i=0,127 do
    tuning.default_midi_notes[i] = midibase*2^(i/12.0)            
end

--convert a ratio (as a string in the form x/y) to a cent value
function tuning.ratio_to_cents(str)
    slash = string.find(str, "/")
    first = string.sub(str, 1, slash-1)
    second = string.sub(str, slash+1)
    x = (math.log(first/second)/math.log(2)) * 1200 
    return x    
end


function tuning.cents_to_ratio(x)
    return math.pow(2, x/1200.0)
    
end



--compute the map for each key, given the current detune level and the current scale
function tuning.compute_keyboard_map(scale)
    local n = scale.notes
    local ctr = 1    
    local base = 8.1758 --hz    
    local hz_notes = {}
    
    --start at lowest C as a reference (midi note 0)    
    for i=0,127 do    
        if ctr>n then
            ctr = 1
            base = hz
        end        
        hz = base * 2^(scale[ctr]/1200.0)        
        hz_notes[i] = hz
        ctr = ctr + 1                        
    end
    
    -- return a midi number => frequency mapping
    return hz_notes
end



--parse a scala file, converting all ratios into cent values
function tuning.parse_scala(filename)
    io.input(filename)    
    
    local line
    local state = 0
    local scale = {}
    
    repeat
        line = io.read() -- first line is always description/comment               
        
        if line then
            if string.find(line, '!')  then
                --ignore comments
                
            else
                --first non comment is the description
                if state==0 then
                    scale.description =line
                end
                
                --second is the number of notes
                if state==1 then
                    scale.notes = line+0
                end
                                
                --the remainder are scale lines
                if state>1 then
                    --is it a cent value (MUST have a period, as per Scala specs)
                    if string.find(line, "%.") then                        
                        scale[state-1] = line+0
                    else
                        scale[state-1] = ratioToCents(line)
                    end                   
                end                
                state = state + 1
            end        
        end    
    until not line
     
    return compute_keyboard_map(scale)
end

return tuning