-- Functions to make callbacks to the audioMaster (i.e. host) and request information and send events 
-- (e.g. midi  back to the host)
-- These functions just wrap the callbacks conveniently, so each function will have sensible argument and
-- use the correct opcode for the request

function add_master_callbacks(c)
    
    local master = function (opcode, index, value, ptr, opt)                 
        return c.internal.audio_master(c.internal.aeffect, opcode, index, value, ptr, opt)
    end
    
    -- audio master callbacks
    master_calls = 
    {        
        -- tell the host a paramter changed
        set_automate = function(index, opt) 
            master(ffi.C.audioMasterAutomate, index, 0, ffi.null, opt)
        end,
        
        -- tell the host a pin changed
        pin_connected = function(index, io) 
            return tonumber(master(ffi.C.audioMasterPinConnected, index, io, ffi.null, 0))
        end,
        
        -- get the host version
        version = function()
            return tonumber(master(ffi.C.audioMasterVersion,0, 0, ffi.null, 0))
        end,
        
        -- get the  host id
        current_id = function()
            return tonumber(master(ffi.C.audioMasterCurrentId,0, 0, ffi.null, 0))
        end,
        
        -- basic querying: sample rate, block size, latency
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
        
        -- ?
        get_process_level = function()
            return tonumber(master(ffi.C.audioMasterGetProcessLevel,0, 0, ffi.null, 0))
        end,
        
        get_automation_state = function()
            return tonumber(master(ffi.C.audioMasterGetAutomationState,0, 0, ffi.null, 0))
        end,
        
        -- get the current directory
        get_directory = function()
            ret = master(ffi.C.audioMasterGetDirectory,0, 0, ffi.null, 0)            
            return ffi.string(ffi.cast("char *", ret))
        end,
        
        -- capabilities (see vst.all_host_can_dos for a list)
        can_do = function(str)
            str_ptr = cstring(str)
            return tonumber(master(ffi.C.audioMasterCanDo, 0, 0, str_ptr, 0))
        end,
        
        -- language
        language = function()
            return tonumber(master(ffi.C.audioMasterGetLanguage, 0,0,ffi.null,0))
        end,
        
        -- time info. this is complicated structure and convert_time_info parses it
        -- into a sensible table
        get_time = function(flags)
            -- default to nanos and ppq
            flags = flags or {"nanos", "ppq"}
            return convert_time_info(master(ffi.C.audioMasterGetTime, 0, 
                                    lookup_flags(flags, vst.timeinfo_flags), ffi.null,0))
        end,
        
        -- send events to the host. These can be MIDI or sysex events, and should be
        -- passed as a table in the same format that receiving events produces
        send_events = function(events)
            cevents = create_host_events(events)
            master(ffi.C.audioMasterProcessEvents, 0, 0, cevents,0)
        end,
        
        -- parameter changes
        begin_edit = function(index)
            master(ffi.C.audioMasterBeginEdit, index, 0, ffi.null,0)
        end,
        
        end_edit = function(index)
            master(ffi.C.audioMasterEndEdit, index, 0, ffi.null,0)
        end,
        
        update_display = function()
            master(ffi.C.audioMasterUpdateDisplay,0, 0, ffi.null,0)
        end,
        
        -- file selectors; this requires a bit of setup, which fileselector.lua implements
        open_file_selector = function(selector)
            local host_selector = create_file_select(selector)
            master(ffi.C.audioMasterOpenFileSelector, 0, 0, host_selector, 0)
            return host_selector
        end,
        
        close_file_selector = function(host_selector)            
            return master(ffi.C.audioMasterCloseFileSelector, 0, 0, host_selector, 0)
        end,
        
        -- basic info strings
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
        
        -- window 
        resize_window = function( w, h)
            return tonumber(master(ffi.C.audioMasterSizeWindow, w, h, ffi.null, 0))
        end,
    }
    
    c.master = master_calls
end

-- test the open/save/etc. file selector on host
function test_file_selector(controller)
    test_file_selector = 
    {
        exts = {
            name="fxbs",
            ext=".fxb"
        },
        command="multiload",
        initial_path=".",    
    }    
    selector = controller.master.open_file_selector(test_file_selector)   
    selected = get_files_selected(selector)
    table.debug(selected)
    controller.master.close_file_selector(selector)
end

-- populate the host entry in the controller
function get_host_details(controller)
    controller.host = {
        host = controller.master.product(),
        vendor = controller.master.vendor(),
        version = controller.master.version(),
        language = vst.languages[controller.master.language()],
        current_id = controller.master.current_id(),
        directory = controller.master.get_directory(),
        can_do = {}
       
    }
    for i,v in ipairs(vst.all_host_can_dos) do
        if controller.master.can_do(v)==1 then
            table.insert(controller.host.can_do, v)        
        end
    end
        

end

function test_audio_master(controller)    
    
    table.debug(controller.host)
    
    _debug.log("---Time---")
    
    table.debug(controller.master.get_time())
        
   
end
