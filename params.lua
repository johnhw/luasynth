local ffi=require("ffi")

function param_display(controller, index)
    -- default display function    
    return tostring(controller.state[index])
end


function get_parameter(controller, index)   
    if _debug then
       _debug.log("Get parameter: %s", controller.params[index+1].name)
    end
    return controller.state[index+1]
end

function set_parameter(controller, index, value)
    if _debug then
        _debug.log("Set parameter: %s = %f", controller.params[index+1].name, value)
    end
    controller.state[index+1] = value    
    -- synchronise the program
    controller.programs[controller.run.program+1].state[index+1] = value
end


-- initialise the parameters for the controller
function init_params(controller)
    local values = {}
    local param_index = {}
    for i,v in ipairs(controller.params) do
    
        -- copy in defaults if omitted
        for j,t in pairs(controller.default_param) do
            if v[j]==nil then
                v[j] = t
            end
        end
        values[i] = v.init        
        param_index[v.name] = i                
    end
    controller.param_index = param_index
    controller.state = values
end
