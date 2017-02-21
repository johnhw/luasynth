function add_handlers(controller)
    -- attach run state change listeners
    controller.listeners = {}
    local proxy = controller.run
    controller.run = {}
    mt = {__newindex = function(t,k,v)             
            proxy[k] = v
            -- call any attached listeners for this state change
            if controller.listeners[k] then
                for i,callback in ipairs(controller.listeners[k]) do
                    callback(k,v)
                end
            end
        end,
        __index = function(t,k)
            return proxy[k]        
        end
    }    
    setmetatable(controller.run, mt)   
    
end

function add_listener(controller, run, callback)
    if controller.listeners[run]==nil then
        controller.listeners[run] = {callback}
    else
        table.insert(controller.listeners[run], callback)
    end       
end

function remove_listener(controller, run, callback)
    if controller.listeners[run]~=nil then        
        table.remove(controller.listeners[run], callback)
    end       
end


function add_event_handler(controller, event_type, callback)
    -- add a handler for a specific event type
    if controller.events[event_type]==nil then
        controller.events[event_type] = {callback}
    else
        table.insert(controller.events[event_type], callback)
    end
    
end
