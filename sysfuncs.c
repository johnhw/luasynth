#include <stdlib.h>
#include <stdio.h>
#include <lua.h>
#include <windows.h>
#include "sysfuncs.h"

LuaLock *create_lua_lock()
{
    LuaLock *lock = (LuaLock*)malloc(sizeof(*lock));
    lock->count = 0;
    lock->recursivecount=0;
    lock->threadID=0;
    lock->eventHandle = CreateEvent(NULL,FALSE,FALSE,NULL); 
    InitializeCriticalSection(&lock->cs);
    return lock;
}

    
int lock_lua(LuaLock *lock)
{
    if(lock->threadID == GetCurrentThreadId())
	{
		InterlockedIncrement(&lock->recursivecount);
		return 1;
	}
	if(InterlockedIncrement(&lock->count)==1)
		InterlockedExchange(&lock->recursivecount,0);
	else
        {
		int result = WaitForSingleObject(lock->eventHandle,1500);
            
            if(result!=WAIT_OBJECT_0)
            {
                RaiseException(0xbad10cc, 0, 0, NULL);
                return 0;                
            }                    
        }
	lock->threadID=GetCurrentThreadId();
    return 1;         
}
    
void unlock_lua(LuaLock *lock)
    {
       if(lock->threadID != GetCurrentThreadId())  
            return;

    	//some threads are waiting so release event
    	if(lock->recursivecount==0)
    	{
    		if(InterlockedDecrement(&lock->count)>0)
    		{
    			SetEvent(lock->eventHandle);
    		}
    	}
    	else
    	{
    		InterlockedDecrement(&lock->recursivecount);
    	}
    }
    
void destroy_lock(LuaLock *lock)
{
   CloseHandle(lock->eventHandle);
   free(lock);
}

    
void sys_sleep(int ms)
{
    Sleep(ms);
}

void addHandleToClose(lua_State *L, HANDLE ptr)
  {
        lua_pushstring(L, "_handleIndex");
        lua_gettable(L, LUA_REGISTRYINDEX);
        
        //create it if it doesn't exist
        if(!lua_istable(L,-1))
        {
            lua_pop(L,1); //pop the nil
            lua_pushstring(L, "_handleIndex");
            lua_newtable(L);
            lua_settable(L, LUA_REGISTRYINDEX);                
            lua_pushstring(L, "_handleIndex");
            lua_gettable(L, LUA_REGISTRYINDEX);            
        }
        
        //NB: ptr is stored in key!
        lua_pushlightuserdata(L, ptr);
        lua_pushnumber(L, 1);
        
        //call table.insert
        lua_settable(L,-3);
        
        lua_pop(L,1); // pop the table
  
  }
  
  
void freeHandles(lua_State *L)
{
 
    lua_pushstring(L, "_handleIndex");
    lua_gettable(L, LUA_REGISTRYINDEX);
    
    if(lua_istable(L,-1))
    {
        lua_pushnil(L);
        while (lua_next(L, -2) != 0) 
        {
            /* uses 'key' (at index -2) and 'value' (at index -1) */
            HANDLE ptr = (HANDLE)lua_touserdata(L,-2);
            CloseHandle(ptr);
          
            /* removes 'value'; keeps 'key' for next iteration */
            lua_pop(L, 1);
        }
    
    }
    
    lua_pop(L,1); //pop the table / nil    

}

   

    
//Get the module handle for this dll
HMODULE sysGetModule()
{
    HMODULE thisModule;
    /* DLL magic */
    MEMORY_BASIC_INFORMATION mbi;
    static int dummyVariable;
    VirtualQuery( &dummyVariable, &mbi, sizeof(mbi) );
    thisModule = (HMODULE)mbi.AllocationBase;    
    return thisModule;    
}

void sysGetCurrentPath(char *buf)
{

    HMODULE hMod = sysGetModule();
    char szModule[MAX_PATH];
    GetModuleFileName( (HMODULE)hMod, szModule, sizeof(szModule) ); 
    int n = strlen(szModule)-1;
    //Find last slash
    while(szModule[n]!='\\')
        n--;
    szModule[n] = '\0';            
    strncpy(buf, szModule, MAX_PATH-1);

    }

    
double sysGetTimeUs()
{
    //we could use QueryPerformanceCounter here, but variable clock speeds seem to make timing unreliable. Better to have 1ms accurate timing...
    DWORD time = timeGetTime();
    return time*1e3;  
}
    

//Show a help window
void sysCreateHelpWindow(char *msg)
{

    MessageBox(NULL, msg, "Help", MB_OK);    
}

#ifdef VS2005
// C99 function not implemented in Win32
int snprintf(char* str, size_t size, const char* format, ...)
{
    size_t count;
    va_list ap;
    va_start(ap, format);
    count = _vscprintf(format, ap);
    _vsnprintf_s(str, size, _TRUNCATE, format, ap);
    va_end(ap);
    return count;
}
#endif

