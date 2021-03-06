
-- utils ---------------------
function charcode_toint(charcode)
    -- convert 4 char string to int32 (for magic numbers)
    local a,b,c,d = string.byte(charcode,1,4)    
    return bit.bor(bit.bor(bit.lshift(a,24), bit.lshift(b,16)),  bit.bor(bit.lshift(c,8) ,bit.lshift(d,0)))
end

-- allocate a new char* pointing at the given string
function cstring(str)
    return ffi.new("char [?]", string.len(str)+1, str)
end

-- invert a mapping (assumes values are all unique!)
function invert_table(t)
    local inv = {}
    for k,v in pairs(t) do
        inv[v] = k
    end
    return inv
end

-- take a list of flags and table mapping flag names to flags
-- and return a merged flag value
function lookup_flags(flags, flag_table)
    flag = 0
    for k,v in pairs(flags) do        
        flag = bit.bor(flag, flag_table[v])        
    end
    return flag
end

function merge_flags(flags)
    flag = 0
    for i,v in ipairs(flags) do
        flag = bit.bor(flag, v)
    end
    return flag
end

function min(x,y)
    if x>y then return y else return x end
end

-- copy str into ptr, only copying up to max_len characters
function write_string(str, ptr, max_len)
    str = string.sub(str, 1, max_len)
    ffi.copy(ptr, str)
end

-- deep copy a table
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function from_dB(x)
    return math.pow(10, x/20.0)
end

function to_dB(x)
    return 20 * math.log(x)/math.log(10)
end

---------------------------------------
