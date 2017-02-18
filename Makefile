
#you need to change these to match your system
VSTSDK_BASE = c:\devel\vstsdk2.4
VSTGUI_PATH = $(VSTSDK_BASE)\vstgui.sf\vstgui
VSTSDK_PATH = $(VSTSDK_BASE)\public.sdk\source\vst2.x
VSTPLUG_PATH = $(VSTSDK_BASE)\pluginterfaces\vst2.x
LUAJIT_PATH = luajit-2.0.4\src

VPATH=$(VSTSDK_PATH):$(VSTGUI_PATH):source
CC = g++ 
CFLAGS = -g3 -shared -Wall -mwindows -static -DWINDOWS

LIBS = -lluajit
#-llua51

LIBDIRS = -L. -Lluajit-2.0.4/src

INCDIRS = -I. -I$(VSTSDK_BASE)  -I$(VSTSDK_PATH) -I$(LUAJIT_PATH) -I$(VSTPLUG_PATH)


CPPOBJECTS = cplugmain.c
OBJECTS =  $(CPPOBJECTS)  
.c.o:
	gcc $(CFLAGS) -c $< $(INCDIRS)

.cpp.o:
	g++ $(CFLAGS) -c $< $(INCDIRS)
	
	
all: $(OBJECTS)$ 
	g++ $(CFLAGS)  $(OBJECTS)  -o luasynth.dll $(INCDIRS) $(LIBDIRS) vstplug.def  $(LIBS)


#Compile the resources
#resource.o: resource/luasynth.rc
#	windres resource/luasynth.rc -o luasynth.o
	

