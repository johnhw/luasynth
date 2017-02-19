function param_display(controller, index)
    -- default display function    
    local name = controller.param_index[index]
    return tostring(controller.state[name])
end

function get_parameter(controller, index)   
    if _debug then
       _debug.log("Get parameter: %s", controller.params[index+1].name)
    end
    local name = controller.param_index[index+1]
    return controller.state[name]
end

function set_parameter(controller, index, value)
    if _debug then
        _debug.log("Set parameter: %s = %f", controller.params[index+1].name, value)
    end
    local name = controller.param_index[index+1]
    controller.state[name] = value    
    -- synchronise the program
    controller.programs[controller.run.program+1].state[name] = value
end


-- return parameter properties
function parameter_properties(controller, index, ptr)
    local param_ptr = ffi.cast("struct VstParameterProperties *", ptr)
    local param = controller.params[index+1]    
    
    param_ptr.flags = param.flags
    write_string(param.short_label, param_ptr.shortLabel,  ffi.C.kVstMaxShortLabelLen)
    write_string(param.label, param_ptr.label,  ffi.C.kVstMaxLabelLen)
    param_ptr.displayIndex = param.display_index
    
    -- support display categories
    if param.category then
        param_ptr.category = param.category_index
        param_ptr.numParametersInCategory = controller.categories[param.category].n_params
        write_string(param.category, param_ptr.categoryLabel, ffi.C.kVstMaxCategLabelLen)
    end
    
    -- int ranges
    if param.int_range then
        param_ptr.inInteger = param.int_range[1]
        param_ptr.maxInteger = param.int_range[2]
    end
    
    -- float step
    if param.float_step then
        param_ptr.smallStepFloat = param.float_step['small']
        param_ptr.stepFloat = param.float_step['normal']
        param_ptr.largeStepFloat = param.float_step['large']
    end
    
    -- int steps
    if param.int_step then        
        param_ptr.stepInt = param.int_step['normal']
        param_ptr.largeStepInt = param.int_step['large']
    end
    
    return 1
end

-- initialise the parameters for the controller
function init_params(controller)
    local values = {}
    local param_index = {}
    controller.categories = {}
    controller.n_categories = 0
    
    for i,v in ipairs(controller.params) do
    
        -- parameter properties
        v.display_index = i-1
        v.short_label = v.short_label or ""
        v.flags = 0
        if v.switch then v.flags = bit.bor(v.flags, ffi.C.kVstParameterIsSwitch) end
        if v.ramp then v.flags = bit.bor(v.flags, ffi.C.kVstParameterCanRamp) end
        v.flags = bit.bor(v.flags, ffi.C.kVstParameterSupportsDisplayIndex)
        
        if v.int_range then v.flags = bit.bor(v.flags, ffi.C.kVstParameterUsesIntegerMinMax) end
        if v.float_step then v.flags = bit.bor(v.flags, ffi.C.kVstParameterUsesFloatStep) end
        if v.int_step then v.flags = bit.bor(v.flags, ffi.C.kVstParameterUsesIntStep) end
        
        
        if v.category then
            v.flags = bit.bor(v.flags, ffi.C.kVstParameterSupportsDisplayCategory)
            
            -- create a new category if needed
            if not controller.categories[v.category] then
                controller.categories[v.category] = {label=v.category, n_params=0, index=controller.n_categories+1}
                controller.n_categories = controller.n_categories  + 1
            end
            
            local cat = controller.categories[v.category]
            v.category_index = cat.index
            cat.n_params = cat.n_params + 1                
                        
        end
    
        -- copy in defaults if omitted
        for j,t in pairs(controller.default_param) do
            if v[j]==nil then
                v[j] = t
            end
        end
        values[i] = v.init        
        param_index[i] = v.name
    end
    controller.param_index = param_index
    controller.state = {params=values}
end
