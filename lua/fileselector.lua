
function create_file_select(selector)
    -- construct objects to display a file selector and choose values
    local host_selector = ffi.new("struct VstFileSelect")
    
    
    local typemapping = {
                        load=ffi.C.kVstFileLoad, 
                        save=ffi.C.kVstFileSave, 
                        multiload=ffi.C.kVstMultipleFilesLoad,
                        directory=ffi.C.kVstDirectorySelect}
    table.debug(selector)                    
    host_selector.command = typemapping[selector.type or "load"]
    host_selector.type = ffi.C.kVstFileType
    host_selector.macCreator = 0
    host_selector.nbFileTypes = table.getn(selector.exts)
    
    host_selector.title = selector.title or "<file>"
    host_selector.initialPath = cstring(selector.initial_path or ".")
    host_selector.returnPath = ffi.null -- host allocates
    host_selector.returnMultiplePaths = ffi.null -- host allocates
    host_selector.sizeReturnPath = 0
    
    -- create the extension structures
    local ext_selector = ffi.new("struct VstFileType [?]", table.getn(selector.exts))
    for i, v in ipairs(selector.exts) do
        ffi.copy(ext_selector[i].name, v.name)
        ffi.copy(ext_selector[i].dosType, v.ext)        
    end
    host_selector.fileTypes = ext_selector
    
    return host_selector

end


function get_files_selected(host_selector)
    local files = {}
    if host_selector.command==ffi.C.kVstMultipleFilesLoad then
    
        -- multi files
        for i=1,host_selector.nbReturnPath do
            table.insert(files, ffi.string(host_selector.returnMultiplePaths[i-1]))
        end
    else
        -- single file
        if host_selector.sizeReturnPath>0 then 
            table.insert(files, ffi.string(host_selector.returnPath))
        end
    end
    return files
end