
#include <aeffect.h>
#include <aeffectx.h>



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
#include "simple_synth.h"

// DLL loading

 
// End DLL loading


typedef struct luasynthUser
{
    LuaLock *lock; // lock to prevent threads invalidating lua state 
    // pointers to the real functions
    AEffectDispatcherProc dispatcher;
    AEffectProcessProc process;
    AEffectProcessProc processReplacing;
	AEffectProcessDoubleProc processDoubleReplacing;	
    AEffectSetParameterProc setParameter;	
	AEffectGetParameterProc getParameter;
    synth_state *state; // will point to the state that Lua allocates
} luasynthUser;


/* wrap the function with a mutex */
VstIntPtr VSTCALLBACK _dispatcher(struct AEffect* effect, VstInt32 opcode, VstInt32 index, VstIntPtr value, void* ptr, float opt)
{           
    VstIntPtr ret;  
    luasynthUser *user = (luasynthUser *)effect->user;
    LuaLock *lock = user->lock;   
    lock_lua(lock);
    ret = user->dispatcher(effect, opcode, index, value, ptr, opt);
    unlock_lua(lock);               
    return ret;
}

void VSTCALLBACK _process(struct AEffect* effect, float** inputs, float** outputs, VstInt32 sampleFrames)
{
    luasynthUser *user = (luasynthUser *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    user->process(effect, inputs, outputs, sampleFrames);
    unlock_lua(lock);
}

void VSTCALLBACK _processDoubleReplacing(struct AEffect* effect, double** inputs, double** outputs, VstInt32 sampleFrames)
{
    luasynthUser *user = (luasynthUser *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    user->processDoubleReplacing(effect, inputs, outputs, sampleFrames);
    unlock_lua(lock);
}

void VSTCALLBACK _processReplacing(struct AEffect* effect, float** inputs, float** outputs, VstInt32 sampleFrames)
{
    luasynthUser *user = (luasynthUser *)effect->user;    
    process(user->state, inputs, outputs, sampleFrames);       
}

void VSTCALLBACK _setParameter (struct AEffect* effect, VstInt32 index, float parameter)
{
    luasynthUser *user = (luasynthUser *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    user->setParameter(effect, index, parameter);
    unlock_lua(lock);

}

float VSTCALLBACK _getParameter (struct AEffect* effect, VstInt32 index)
{   
    float ret;
    luasynthUser *user = (luasynthUser *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    ret = user->getParameter(effect, index);
    unlock_lua(lock);
    return ret;
}

void wrap_mutexs(AEffect *aeffect)
{
    luasynthUser *user = (luasynthUser *)aeffect->user;
    // wrap functions
    user->dispatcher = aeffect->dispatcher;
    aeffect->dispatcher = _dispatcher;
    
    //user->process = aeffect->process;
    //aeffect->process = _process;
        
    //user->processReplacing = aeffect->processReplacing;
    aeffect->processReplacing = _processReplacing;
    
    user->processDoubleReplacing = aeffect->processDoubleReplacing;
    aeffect->processDoubleReplacing = _processDoubleReplacing;
    
    user->getParameter = aeffect->getParameter;
    aeffect->getParameter = _getParameter;
       
    user->setParameter = aeffect->setParameter;
    aeffect->setParameter = _setParameter;    
}



//------------------------------------------------------------------------
/** Prototype of the export function main */
//------------------------------------------------------------------------
VST_EXPORT AEffect* VSTPluginMain (audioMasterCallback audioMaster)
{
	// Get VST Version
	if (!audioMaster (0, audioMasterVersion, 0, 0, 0, 0))
		return 0;  // old version
    debugf = fopen("debug.log", "w");
   
    
    lua_State *L = lua_open();    
    luaL_openlibs(L);
    
    /*DWORD size;
    const char *source;
    loadResource("test.lua", RT_RCDATA, &size, &source);
    fprintf(debug, "RC: %lu\n", size);
    */
    
    if(luaL_dofile(L, "lua\\luasynth.lua"))
        fprintf(debugf, lua_tostring(L,-1));        
    
    AEffect *effect = (AEffect*) malloc(sizeof(*effect));
    luasynthUser *user = (luasynthUser *)malloc(sizeof(*user));    
    user->lock = create_lua_lock();      
    effect->user = user;
    
    lua_getglobal(L, "vst_init");    
    lua_pushlightuserdata(L, effect);        
    lua_pushlightuserdata(L, (void*)audioMaster);        
    lua_pushlightuserdata(L, (void*)loadResource);        
    
    lua_pushlightuserdata(L, (void*)&(user->state));        
    
    
    if (lua_pcall(L, 4,1,0 ) != 0)
        fprintf(debugf, lua_tostring(L,-1));
    
        
    wrap_mutexs(effect);
    
    //unlock_lua(user->lock);
        
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