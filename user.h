typedef struct LuaLock LuaLock;

typedef struct luasynthUser
{
    LuaLock *lock; // lock to prevent threads invalidating lua state 
    LuaLock *param_lock; // lock to lock parameter access
    // pointers to the real functions
    void *dispatcher;
    void *setParameter;	
	void *getParameter;
    void (*process)(struct luasynthUser *, float **, float **, int n);
    void (*init_c)(struct luasynthUser *); // called after lua initialisation; can read lua_state
    void *state; // will point to the state that Lua allocates    
    
} luasynthUser;
