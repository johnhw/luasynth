-- debugging ------------
debug_on = true

if debug_on then
    local debug_file = io.open("luasynth.log", "a")    
    local debug_log = function(...)
        debug_file:write(string.format(...).."\n")
        debug_file:flush()
    end    
    local debug_raw_log = function(s)
        debug_file:write(tostring(s).."\n")
        debug_file:flush()
    end        
    _debug = {log=debug_log, file=debug_file, raw_log=debug_raw_log}
    _debug.log("---")
else
    _debug = {log=function(...) end, file={}, raw_log=function(...) end}
end

function debug_error(error)
    _debug.log("\n%s\n%s", error, debug.traceback())
end

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            _debug.raw_log(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    pos = tostring(pos)
                    if (type(val)=="table") then
                    
                        _debug.raw_log(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        _debug.raw_log(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        _debug.raw_log(indent.."["..pos..'] => "'..val..'"')
                    else
                        _debug.raw_log(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                _debug.raw_log(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        _debug.raw_log(tostring(t).." {")
        sub_print_r(t,"  ")
        _debug.raw_log("}")
    else
        sub_print_r(t,"  ")
    end
    _debug.raw_log()
end

table.debug = print_r
------------------------------