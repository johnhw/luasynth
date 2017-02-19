json = require("extern/json")

-- get a chunk of memory filled with the JSON string
function get_chunk(controller, preset)
    local json_string, cjson
    
    if preset then
        local program = controller.programs[controller.run.program+1]
        json_string = json.stringify(program)
        cjson = cstring(json_string)        
    else    
        json_string = json.stringify(controller.programs)
        cjson = cstring(json_string)    
    end
    return ffi.cast("void *", cjson), string.len(json_string)       
end

-- restore a preset/bank from a JSON string
function set_chunk(controller, preset, ptr, len)
    local cjson_str = ffi.cast("char *", ptr)
    local json_str = ffi.string(ptr, len)
    if preset then
        -- just one preset
        controller.programs[controller.run.program+1] = json.parse(json_str)                
    else 
        controller.programs = json.parse(json_str)                        
    end
end

-- return 1 if this can be loaded as a bank, -1 otherwise
function valid_bank(controller, bank)
    bank = ffi.cast("struct VstPatchChunkInfo*", bank)
    if bank.version~=1 then return -1 end
    if bank.pluginUniqueID~=controller.info.int_unique_id then return -1 end
    if bank.pluginVersion~=controller.info.version then return -1  end
    -- ignore number of programs
    return 1
end

-- return 1 if this can be loaded as a bank, -1 otherwise
function valid_program(controller, program)
    program = ffi.cast("struct VstPatchChunkInfo*", program)
    if program.version~=1 then return -1 end
    if program.pluginUniqueID~=controller.info.int_unique_id then return -1 end
    if program.pluginVersion~=controller.info.version then return -1  end
    if program.numElements~=table.getn(controller.params) then return -1  end   
    return 1
end