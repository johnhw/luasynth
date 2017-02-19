
#ifndef __SysFuncs__
#define __SysFuncs__




#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>


#ifdef WINDOWS

#include <windows.h>


typedef struct LuaLock
{
    long count;
	DWORD threadID;
	HANDLE eventHandle;
	long recursivecount;
    CRITICAL_SECTION cs;
    HANDLE mutex;
} LuaLock;

LuaLock *create_lua_lock();    
int lock_lua(LuaLock *lock);  
void unlock_lua(LuaLock *lock);   
void destroy_lock(LuaLock *lock);

DWORD WINAPI receivePoll(LPVOID parameter);


void sysSleep(int ms);
double sysGetTimeUs();
HMODULE sysGetModule();
void sysCreateHelpWindow(char *msg);
void sysGetCurrentPath(char *buf);
void addHandleToClose(lua_State *L, HANDLE h);
void freeHandles(lua_State *L);


#endif


#ifdef VS2005 // C99 function not implemented in Win32
extern int snprintf(char* str, size_t size, const char* format, ...);
#endif



#endif
