

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
        
        get_plug_category = function(controller, opcode, index, value, ptr, opt)
            return vst.categories[controller.info.category or "unknown"] or ffi.C.kPlugCategUnknown
        end,
        
        can_do = function(controller, opcode, index, value, ptr, opt)   
            local cando = ffi.string(ffi.cast("char *", ptr))
            for i,v in ipairs(controller.can_do) do
                if v==cando then return 1 end
            end
            return 0
        end,
        
        -- default to VST 2.4 standard
        get_vst_version = function(controller, opcode, index, value, ptr, opt)   
            return controller.info.vst_version or 2400
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
        
      
        
        
        input_properties = function(controller, opcode, index, value, ptr, opt)   
            if controller.pins and controller.pins.inputs and controller.pins.inputs[index] then
                copy_pin_details(ptr, controller.pins.inputs[index])                
                return 1
            end
            return 0
        end,
        
        output_properties = function(controller, opcode, index, value, ptr, opt)   
            if controller.pins and controller.pins.outputs and controller.pins.outputs[index] then
                copy_pin_details(ptr, controller.pins.inputs[index])                
                return 1
            end
            return 0
        end,
        
        
        start_process = function(controller, opcode, index, value, ptr, opt)   
            controller.run.processing = true
        end,
        
        stop_process = function(controller, opcode, index, value, ptr, opt)   
            controller.run.processing = false
        end,
        
    
    -- event processing 
        process_events = function(controller, opcode, index, value, ptr, opt)           
            local all_events = process_events(controller, ptr)
            -- send to the handler
            if controller.event_handler then 
                controller.event_handler(all_events)
            end
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
        
        begin_set_program =  function(controller, opcode, index, value, ptr, opt)   
            controller.run.program_changing = true
        end,
        
        end_set_program =  function(controller, opcode, index, value, ptr, opt)   
            controller.run.program_changing = false
        end,

    -- chunks
        get_chunk = function(controller, opcode, index, value, ptr, opt)   
            len, void_ptr = get_chunk(controller, index)
            ptr = ffi.cast("void **", ptr)
            ptr[0] = void_ptr
            return len
        end,
        
        set_chunk = function(controller, opcode, index, value, ptr, opt)   
            len, void_ptr = set_chunk(controller, index, ptr, value)            
        end,

        begin_load_bank = function(controller, opcode, index, value, ptr, opt)   
            return valid_bank(ptr)
        end,
        
        begin_load_program = function(controller, opcode, index, value, ptr, opt)   
            return valid_program(ptr)
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
