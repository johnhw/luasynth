
-- convert the time info from the host into a simple table
function convert_time_info(info)
    local info = ffi.cast("struct VstTimeInfo *", info)
    
    -- unpack the structure
    local  time_info = {
        samples = info.samplePos,
        sample_rate = info.sampleRate,
        nanos = info.nanoSeconds,
        ppq = info.ppqPos,
        tempo = info.tempo,
        bars = info.barStartPos,
        cycle = {info.cycleStartPos, info.cycleEndPos},    
        timesig = {info.timeSigNumerator, info.timeSigDenominator},
        smpte = {info.smpteOffset, info.smpteFrameRate},     
        clock = info.samplesToNextClock,    
        flags = info.flags
    }
    
    
    -- remove invalid entries
    for k,v in pairs(vst.timeinfo_flags) do
        if not bit.band(time_info.flags, v) then time_info[v] = nil end
    end
    
    return time_info    
end