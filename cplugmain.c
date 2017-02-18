
#include <aeffect.h>

//------------------------------------------------------------------------
/** Must be implemented externally. */
extern AEffect* createAEffectInstance (audioMasterCallback audioMaster);

extern "C" {

#if defined (__GNUC__)
	#define VST_EXPORT	__attribute__ ((visibility ("default")))
#else
	#define VST_EXPORT
#endif

#include <lua.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdlib.h>



//------------------------------------------------------------------------
/** Prototype of the export function main */
//------------------------------------------------------------------------
VST_EXPORT AEffect* VSTPluginMain (audioMasterCallback audioMaster)
{
	// Get VST Version
	if (!audioMaster (0, audioMasterVersion, 0, 0, 0, 0))
		return 0;  // old version
    FILE *debug = fopen("debug.log", "w");
    lua_State *L = lua_open();    
    luaL_openlibs(L);
    luaL_dofile(L, "aeffect.lua");
    
    
    lua_getglobal(L, "vst_init"); 
    AEffect *effect = (AEffect*) malloc(sizeof(*effect));
    lua_pushlightuserdata(L, effect);
    
    if (lua_pcall(L, 1, 1,0 ) != 0)
        fprintf(debug, lua_tostring(L,-1));
    fclose(debug);
        
    //AEffect *effect = (AEffect *)lua_touserdata(L, -1);    
	return effect;
}

// support for old hosts not looking for VSTPluginMain
#if (TARGET_API_MAC_CARBON && __ppc__)
VST_EXPORT AEffect* main_macho (audioMasterCallback audioMaster) { return VSTPluginMain (audioMaster); }
#elif WIN32
VST_EXPORT AEffect* MAIN (audioMasterCallback audioMaster) { return VSTPluginMain (audioMaster); }
#elif BEOS
VST_EXPORT AEffect* main_plugin (audioMasterCallback audioMaster) { return VSTPluginMain (audioMaster); }
#endif

} // extern "C"

//------------------------------------------------------------------------
#if WIN32
#include <windows.h>
void* hInstance;
BOOL WINAPI DllMain (HINSTANCE hInst, DWORD dwReason, LPVOID lpvReserved)
{
	hInstance = hInst;
	return 1;
}
#endif