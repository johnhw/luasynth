function create_voices(max_voices)
    local voices = {voice_list={}, min_level=-80}
    for i=1,max_voices do
        table.insert(voices.voice_list, {active=false, active_time=0, released=0, level=0, voice_data={}})
    end
    
end

function add_voice(voices, voice_data)
    -- force out voice quieter than level (if levels available)
    for i,v in ipairs(voices.voice_list) do
        if level~=0 and level<voices.min_level then
            v.active = false
        end
    end
    
    -- sort tables by active, relased, active_time


end