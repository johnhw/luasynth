-- functions to map parameters to 0,1 intervals

-- map to/from a linearly spaced range
function linear_scale(min, max)
    local range = max-min
    local map = {
        inverse = function(x)
            return (x-min) * (range)
        end,
        forward = function(x)
            return (x/range) + min
        end
    }        
    return map
end

-- map a value to/from a logarithmically spaced range
function log_scale(min, max)
    local range = max-min
    local map = {
        forward = function(x)
            return math.log((x - min + 1)) / math.log(range+1)
        end,
        inverse = function(x)
            return math.exp(x * math.log(range+1)) + min - 1
        end
    }        
    return map
end

-- map a value to/from a boolean
function switch_scale()
    local map = {
        forward = function(x) 
            if x then return 1 else return 0 end
        end,
        
        inverse = function(x) 
            return x>0.5
        end,        
    }    
    return map
end

-- map to from a list of possible options
function option_scale(options)
    local n_options = table.getn(options)
    local inverse_options = invert_table(options) -- cache indices
    local map = {
        forward = function(x) 
            return (inverse_options[x] - 1) / (n_options-1)
        end,
        
        inverse = function(x)             
            local n = min(math.floor(x*n_options)+1, n_options)
            return options[n]
        end,        
    }    
    return map
end

-- map a value to/from a logarithmically spaced range, which can (must) span across 0
function bilog_scale(min, max)
    local lrange = -min
    local rrange = max
    
    local left_log = log_scale(0, math.abs(min))
    local right_log = log_scale(0, max)
    
    local map = {
        forward = function(x)
            if x<0 then
                return 0.5 - left_log.forward(-x)*0.5           
            else
                return 0.5 + right_log.forward(x)*0.5
            end
        end,
        inverse = function(x)
            if x<0.5 then
                return -left_log.inverse((0.5-x)*2)
            else
                return right_log.inverse((x-0.5)*2)
            end
        end
    }        
    return map
end