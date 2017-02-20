-- define a package searcher to find modules in the .rc file
function add_loader(load_resource)
    LUA_RESOURCE_TYPE = 1
    load_resource = ffi.cast("void (*) (char * , int, uint32_t *, char **)", load_resource)
    
    -- query for the resource, and return a loader if found
    function resource_loader(pkg)
        len = ffi.new("int [1]")
        name = ffi.new("char *[1]")
        load_resource(cstring(pkg..".lua"), LUA_RESOURCE_TYPE, len, name)
        if name[0]~=ffi.null then 
            -- loader just executes the string
            function loader()
                return loadstring(ffi.string(name[0]))
            end
            return loader
        else
            return 'Could not load resource: ' .. pkg..'.lua'
        end
    end
    -- add to the default loader list
    table.insert(package.loaders, resource_loader)
end