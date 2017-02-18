local ffi=require("ffi")


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
        
        -- basic querying
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
        
        get_directory = function()
            ret = master(ffi.C.audioMasterGetDirectory,0, 0, ffi.null, 0)            
            return ffi.string(ffi.cast("char *", ret))
        end,
        
        -- capabilities
        can_do = function(str)
            str_ptr = cstring(str)
            return tonumber(master(ffi.C.audioMasterCanDo, 0, 0, str_ptr, 0))
        end,
        
        language = function()
            return tonumber(master(ffi.C.audioMasterGetLanguage, 0,0,ffi.null,0))
        end,
        
        -- time and events
        get_time = function(filter)
            return convert_time_info(master(ffi.C.audioMasterGetTime, 0, filter, ffi.null,0))
        end,
        
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
        
        -- file selectors
        open_file_selector = function(selector)
            local host_selector = create_file_select(selector)
            master(ffi.C.audioMasterOpenFileSelector, 0, 0, host_selector, 0)
            return host_selector
        end,
        
        close_file_selector = function(host_selector)            
            return master(ffi.C.audioMasterCloseFileSelector, 0, 0, host_selector, 0)
        end,
        
        -- vendor strings
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


function test_audio_master(controller)    
    _debug.log("Host: %s", controller.master.product())
    _debug.log("Vendor: %s", controller.master.vendor())
    _debug.log("Version: %d", controller.master.version())
    _debug.log("ID: %d", controller.master.current_id())
    _debug.log("Directory: %s", controller.master.get_directory())
    _debug.log("---Time---")
    
    table.debug(controller.master.get_time(255))
    
    for i,v in ipairs(vst.all_host_can_dos) do
        _debug.log("Can do %s: %d", v, controller.master.can_do(v))
    end
    
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
