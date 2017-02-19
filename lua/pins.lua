-- I/O pin details
function copy_pin_details(ptr, pin)
    ptr = ffi.cast("struct VstPinProperties *", ptr)
    write_string(pin.label or "none", ptr.label, ffi.C.kVstMaxLabelLen)
    
    -- should be one of the integer constants kSpeakerArr*
    ptr.arrangementType = pin.arrangement or ffi.C.kSpeakerArrStereo
    
    -- default to being active, stereo pin
    if pin.active==true or pin.active==nil then
        ptr.flags = bit.bor(ptr.flags, ffi.C.kVstPinIsActive)
    end
    
    if pin.stereo==true or pin.stereo==nil then
        ptr.flags = bit.bor(ptr.flags, ffi.C.kVstPinIsActive)
    end
    
    if pin.arrangement~=nil then
        ptr.flags = bit.bor(ptr.flags, ffi.C.kVstPinUseSpeaker)
    end        

end