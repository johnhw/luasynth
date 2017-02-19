
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
#include "sysfuncs.h"

typedef struct luasynthUserdata
{
    LuaLock *lock; // lock to prevent threads invalidating lua state 
    // pointers to the real functions
    AEffectDispatcherProc *dispatcher;
    AEffectProcessProc *process;
    AEffectProcessProc processReplacing;
	AEffectProcessDoubleProc processDoubleReplacing;	
    AEffectSetParameterProc setParameter;	
	AEffectGetParameterProc getParameter;

} luasynth_userdata;


/* wrap the function with a mutex */
VstIntPtr _dispatcher(struct AEffect* effect, VstInt32 opcode, VstInt32 index, VstIntPtr value, void* ptr, float opt)
{       
    VstIntPtr ret;
    luasynthUser *user = (luasynthUserdata *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    ret = user->dispatcher(effect, opcode, index, value, ptr, opt);
    unlock_lua(lock);
    return ret;
}

void _process(struct AEffect* effect, float** inputs, float** outputs, VstInt32 sampleFrames)
{
    luasynthUser *user = (luasynthUserdata *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    user->process(effect, inputs, outputs, sampleFrames);
    unlock_lua(lock);
}

void _processDoubleReplacing(struct AEffect* effect, double** inputs, double** outputs, VstInt32 sampleFrames)
{
    luasynthUser *user = (luasynthUserdata *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    user->doubleProcess(effect, inputs, outputs, sampleFrames);
    unlock_lua(lock);
}

void _processReplacing(struct AEffect* effect, float** inputs, float** outputs, VstInt32 sampleFrames)
{
    luasynthUser *user = (luasynthUserdata *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    user->processReplacing(effect, inputs, outputs, sampleFrames);
    unlock_lua(lock);
}

void _setParameter (struct AEffect* effect, VstInt32 index, float parameter)
{
    luasynthUser *user = (luasynthUserdata *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    user->setParameter(effect, index, parameter);
    unlock_lua(lock);

}

 float _getParameter (struct AEffect* effect, VstInt32 index)
{   
    float ret;
    luasynthUser *user = (luasynthUserdata *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    ret = user->getParameter(effect, index);
    unlock_lua(lock);
    return ret;
}



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
    luaL_dofile(L, "luasynth.lua");
    
    AEffect *effect = (AEffect*) malloc(sizeof(*effect));
    luasynthUserdata *user = (luasynthUserdata *)malloc(sizeof(*user));    
    user->lock = create_lua_lock();
    effect->user = user;
    
    lua_getglobal(L, "vst_init");    
    lua_pushlightuserdata(L, effect);        
    lua_pushlightuserdata(L, (void*)audioMaster);        
    if (lua_pcall(L, 2,1,0 ) != 0)
        fprintf(debug, lua_tostring(L,-1));
    fclose(debug);
        
    // wrap functions
    user->dispatcher = aeffect->dispatcher;
    aeffect->dispatcher = _dispatcher;
    
    user->process = aeffect->process;
    aeffect->process = _process;
        
    user->processReplacing = aeffect->processReplacing;
    aeffect->processReplacing = _processReplacing;
    
    user->processDoubleReplacing = aeffect->processDoubleReplacing;
    aeffect->processDoubleReplacing = _processDoubleReplacing;
    
    user->getParameter = aeffect->getParameter;
    aeffect->getParameter = _getParameter;
       
    user->setParameter = aeffect->setParameter;
    aeffect->setParameter = _setParameter;    
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