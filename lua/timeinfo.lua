
-- convert the time info from the host into a simple table
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