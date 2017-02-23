function add_handlers(controller)
    -- attach run state change listeners
    controller.listeners = {}
    
    controller.event = function(etype, event)
           
        if controller.events[etype] then 
            for i,v in ipairs(controller.events[etype]) do                
                
            
                v(etype, event)
            end
        end
    end
    
    local proxy = controller.run
    controller.run = {}    
    mt = {__newindex = function(t,k,v)             
            proxy[k] = v            
            controller.event(k,v)
        end,
        __index = function(t,k)
            return proxy[k]        
        end
    }    
    setmetatable(controller.run, mt)   
    
    proxy = controller.state
    controller.state = {}
    mt = {__newindex = function(t,k,v)             
            proxy[k] = v            
            _debug.log("%s %s", k, v)
            controller.event(k, v)
        end,
        __index = function(t,k)
            return proxy[k]        
        end
    }    
    setmetatable(controller.state, mt)   

    
end


function add_listener(controller, event_type, callback)
    -- add a handler for a specific event type
    if controller.events[event_type]==nil then
        controller.events[event_type] = {callback}
    else
        table.insert(controller.events[event_type], callback)
    end
    
end
