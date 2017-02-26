
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
#include "user.h"
#include "halfband.h"

void process(luasynthUser *user, float **in, float **out, int n);
void init_synth(luasynthUser *user);

// DLL loading

 
// End DLL loading





/* wrap the function with a mutex */
VstIntPtr VSTCALLBACK _dispatcher(struct AEffect* effect, VstInt32 opcode, VstInt32 index, VstIntPtr value, void* ptr, float opt)
{           
    VstIntPtr ret;  
    luasynthUser *user = (luasynthUser *)effect->user;
    AEffectDispatcherProc dispatcher_proc = (AEffectDispatcherProc) user->dispatcher;
    LuaLock *lock = user->lock;   
    lock_lua(lock);
    ret = dispatcher_proc(effect, opcode, index, value, ptr, opt);
    unlock_lua(lock);               
    return ret;
}


void VSTCALLBACK _processDoubleReplacing(struct AEffect* effect, double** inputs, double** outputs, VstInt32 sampleFrames)
{
    luasynthUser *user = (luasynthUser *)effect->user;    
    //processDouble(user->state, inputs, outputs, sampleFrames); 
}

void VSTCALLBACK _processReplacing(struct AEffect* effect, float** inputs, float** outputs, VstInt32 sampleFrames)
{
    luasynthUser *user = (luasynthUser *)effect->user;    
    user->process(user, inputs, outputs, sampleFrames);       
}

void VSTCALLBACK _setParameter (struct AEffect* effect, VstInt32 index, float parameter)
{
    luasynthUser *user = (luasynthUser *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    AEffectSetParameterProc set_proc = (AEffectSetParameterProc) user->setParameter;
    set_proc(effect, index, parameter);
    unlock_lua(lock);
}

float VSTCALLBACK _getParameter (struct AEffect* effect, VstInt32 index)
{   
    float ret;
    luasynthUser *user = (luasynthUser *)effect->user;
    LuaLock *lock = user->lock;
    lock_lua(lock);
    AEffectGetParameterProc get_proc = (AEffectGetParameterProc) user->getParameter;
    ret = get_proc(effect, index);
    unlock_lua(lock);
    return ret;
}

void wrap_mutexs(AEffect *aeffect)
{
    luasynthUser *user = (luasynthUser *)aeffect->user;
    // wrap functions
    user->dispatcher = (void*)aeffect->dispatcher;
    aeffect->dispatcher = _dispatcher;
    
    //aeffect->process = _process;
        
    //user->processReplacing = aeffect->processReplacing;
    aeffect->processReplacing = _processReplacing;
    
    //user->processDoubleReplacing = aeffect->processDoubleReplacing;
    aeffect->processDoubleReplacing = _processDoubleReplacing;
    
    user->getParameter = (void*)aeffect->getParameter;
    aeffect->getParameter = _getParameter;
       
    user->setParameter = (void*)aeffect->setParameter;
    aeffect->setParameter = _setParameter;    
}


// macro to push a c function along with its type onto a table 
#define LUA_FN(X,TYPE) lua_newtable(L);\
    lua_pushlightuserdata(L, (void*)X);\
    lua_setfield(L, -2, "fn");\
    lua_pushstring(L, TYPE);\
    lua_setfield(L, -2, "type");\
    lua_setfield(L, -2, #X);\
    

FILE *debugf;
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
    
    lua_newtable(L);
    LUA_FN(loadResource, "void (*)(char *, char *, uint32_t *, const char **)")    
    LUA_FN(lock_lua, "void (*)(void *)")    
    LUA_FN(unlock_lua, "void (*)(void *)")    
    
    lua_setglobal(L, "c_funcs");
    
    if(luaL_dofile(L, "lua\\luasynth.lua"))
        fprintf(debugf, lua_tostring(L,-1));        
    
    AEffect *effect = (AEffect*) malloc(sizeof(*effect));
    luasynthUser *user = (luasynthUser *)malloc(sizeof(*user));    
    user->lock = create_lua_lock();  
    user->param_lock = create_lua_lock();  
    
    // specify the processing function that will be called
    user->process = process;
    user->init_c = init_synth;
    effect->user = user;
    
    
    
    lua_getglobal(L, "vst_init");    
    lua_pushlightuserdata(L, effect);        
    lua_pushlightuserdata(L, (void*)audioMaster);                   
    
    
    if (lua_pcall(L, 2,0,0 ) != 0)
        fprintf(debugf, lua_tostring(L,-1));
    
    
    // call the c initialisation
    user->init_c(user);
    
    wrap_mutexs(effect);
         
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