RPI_VERSION ?= 4

TARGET_EXEC = mandelbrot

ARMGNU ?= aarch64-linux-gnu

# Define required environment variables
#------------------------------------------------------------------------------------------------
# Define target platform: PLATFORM_DESKTOP, PLATFORM_RPI, PLATFORM_DRM, PLATFORM_ANDROID, PLATFORM_WEB
PLATFORM              ?= PLATFORM_DESKTOP

# Define required raylib variables
PROJECT_NAME          ?= raylib_examples
RAYLIB_VERSION        ?= 4.5.0
RAYLIB_PATH           ?= ..

# Locations of raylib.h and libraylib.a/libraylib.so
# NOTE: Those variables are only used for PLATFORM_OS: LINUX, BSD
RAYLIB_INCLUDE_PATH   ?= /usr/local/include
RAYLIB_LIB_PATH       ?= /usr/local/lib
#RAYLIB_LIB_PATH       ?= /usr/local/lib/aarch64-linux-gnu

# Library type compilation: STATIC (.a) or SHARED (.so/.dll)
RAYLIB_LIBTYPE        ?= STATIC

# Build mode for project: DEBUG or RELEASE
BUILD_MODE            ?= RELEASE

# Use external GLFW library instead of rglfw module 
USE_EXTERNAL_GLFW     ?= TRUE 

# Use Wayland display server protocol on Linux desktop (by default it uses X11 windowing system)
# NOTE: This variable is only used for PLATFORM_OS: LINUX
USE_WAYLAND_DISPLAY   ?= FALSE

# PLATFORM_WEB: Default properties
BUILD_WEB_ASYNCIFY    ?= TRUE
BUILD_WEB_SHELL       ?= $(RAYLIB_PATH)/src/minshell.html
BUILD_WEB_HEAP_SIZE   ?= 134217728
BUILD_WEB_RESOURCES   ?= TRUE
BUILD_WEB_RESOURCES_PATH  ?= $(dir $<)resources@resources

# Use cross-compiler for PLATFORM_RPI
ifeq ($(PLATFORM),PLATFORM_RPI)
    USE_RPI_CROSS_COMPILER ?= FALSE
    ifeq ($(USE_RPI_CROSS_COMPILER),TRUE)
        RPI_TOOLCHAIN ?= C:/SysGCC/Raspberry
        RPI_TOOLCHAIN_SYSROOT ?= $(RPI_TOOLCHAIN)/arm-linux-gnueabihf/sysroot
    endif
endif

# Determine PLATFORM_OS in case PLATFORM_DESKTOP or PLATFORM_WEB selected
ifeq ($(PLATFORM),$(filter $(PLATFORM),PLATFORM_DESKTOP PLATFORM_WEB))
    # No uname.exe on MinGW!, but OS=Windows_NT on Windows!
    # ifeq ($(UNAME),Msys) -> Windows
    ifeq ($(OS),Windows_NT)
        PLATFORM_OS = WINDOWS
    else
        UNAMEOS = $(shell uname)
        ifeq ($(UNAMEOS),Linux)
            PLATFORM_OS = LINUX
        endif
        ifeq ($(UNAMEOS),FreeBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),OpenBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),NetBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),DragonFly)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),Darwin)
            PLATFORM_OS = OSX
        endif
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    UNAMEOS = $(shell uname)
    ifeq ($(UNAMEOS),Linux)
        PLATFORM_OS = LINUX
    endif
endif
ifeq ($(PLATFORM),PLATFORM_DRM)
    UNAMEOS = $(shell uname)
    ifeq ($(UNAMEOS),Linux)
        PLATFORM_OS = LINUX
    endif
endif

# RAYLIB_PATH adjustment for LINUX platform
# TODO: Do we really need this?
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),LINUX)
        RAYLIB_PREFIX  ?= ..
        RAYLIB_PATH     = $(realpath $(RAYLIB_PREFIX))
    endif
endif

# Default path for raylib on Raspberry Pi
ifeq ($(PLATFORM),PLATFORM_RPI)
    RAYLIB_PATH        ?= /home/pi/raylib
endif
ifeq ($(PLATFORM),PLATFORM_DRM)
    RAYLIB_PATH        ?= /home/pi/raylib
endif

# Define raylib release directory for compiled library
RAYLIB_RELEASE_PATH    ?= $(RAYLIB_PATH)/src

ifeq ($(PLATFORM),PLATFORM_WEB)
    ifeq ($(PLATFORM_OS),WINDOWS)
        # Emscripten required variables
		EMSDK_PATH         ?= C:/emsdk
		EMSCRIPTEN_PATH    ?= $(EMSDK_PATH)/upstream/emscripten
		CLANG_PATH          = $(EMSDK_PATH)/upstream/bin
		PYTHON_PATH         = $(EMSDK_PATH)/python/3.9.2-1_64bit
		NODE_PATH           = $(EMSDK_PATH)/node/14.15.5_64bit/bin
		export PATH         = $(EMSDK_PATH);$(EMSCRIPTEN_PATH);$(CLANG_PATH);$(NODE_PATH);$(PYTHON_PATH):$$(PATH)
    endif
endif

# INCLUDES = -I/usr/local/include -Ia -Ib -Ic -I($(HOME)/include  thisisanexample
# LIBINCLUDES = -L/usr/local/lib -Lbuild/lib  -L $(HOME)/lib  thisisanexample

 
#INC = -I/snap/ogre/190/include/OGRE 
#LIBINC = /snap/ogre/190/lib/libOgreMain.so.13.5 
INC = $(RAYLIB_INCLUDE_PATH)
LIBINC = -L. -L$(RAYLIB_LIB_PATH) -lraylib -lGL -lm -lpthread -ldl -lrt
# /snap/ogre/190/lib/OGRE/RenderSystem_Vulkan.so.13.5 /snap/ogre/190/lib/libOgreBites.so.13.5

CPPOPS = -Wall -Iinclude -D_DEFAULT_SOURCE -Wno-missing-braces -Wunused-result -O2 -c \
	   -I$(INC)
# -nostartfiles -ffreestanding 

# Avoid linker error - firmware.elf: hidden symbol `__dso_handle’ isn’t defined   
# If I’m not mistaken, it is related to a combination of complex C++ object destruction of static objects and the nostdlib compiler option.
# n an embedded system, you likely don’t need the destruction of static objects. So try this compiler option: -fno-use-cxa-atexit.

COPS = 	-Wall -D_DEFAULT_SOURCE -Wno-missing-braces -Wunused-result -O2 -D_DEFAULT_SOURCE \
		-Iinclude -I$(INC) -std=c99 
		# -nostartfiles -ffreestanding Idm enlevé
		# -fpermissive for using the more strict G++ compiler
		
ASMOPS = -Iinclude


BUILD_DIR = build
SRC_DIR = src
LDFLAGS = -lstdc++ -fno-pie -no-pie
# -lX11 -latomic -DPLATFORM_DESKTOP 

all : compileandlink

clean:
	rm -rf $(BUILD_DIR) *.img *.bin
	rm $(TARGET_EXEC)
	@echo "cleaned"

$(BUILD_DIR)/%_cpp.o: $(SRC_DIR)/%.cpp
	mkdir -p $(@D)
	$(ARMGNU)-g++ $(CPPOPS) $< -o $@

$(BUILD_DIR)/%_c.o: $(SRC_DIR)/%.c
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

$(BUILD_DIR)/%_s.o: $(SRC_DIR)/%.S
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

C_FILES = $(wildcard $(SRC_DIR)/*.c)
CPP_FILES = $(wildcard $(SRC_DIR)/*.cpp)
ASM_FILES = $(wildcard $(SRC_DIR)/*.S)
OBJ_FILES = $(CPP_FILES:$(SRC_DIR)/%.cpp=$(BUILD_DIR)/%_cpp.o)
OBJ_FILES += $(C_FILES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%_c.o)
OBJ_FILES += $(ASM_FILES:$(SRC_DIR)/%.S=$(BUILD_DIR)/%_s.o)

DEP_FILES = $(OBJ_FILES:%.o=%.d)
-include $(DEP_FILES)

compileandlink: $(OBJ_FILES)
	@echo "linking"
	$(ARMGNU)-gcc $(OBJ_FILES) -o $(TARGET_EXEC) $(LIBINC) $(LDFLAGS) 



#aarch64-linux-gnu-g++ -Wall -D_DEFAULT_SOURCE -Wno-missing-braces -c -Wunused-result -O2 -I. -I/usr/local/include src/models_geometric_shapes.cpp -o build/models_geometric_shapes.o 
#aarch64-linux-gnu-gcc -o line build/models_geometric_shapes.o -L. -L/home/pi/raylib/src -L/usr/local/lib -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -latomic -DPLATFORM_DESKTOP

#gcc -o models/models_geometric_shapes models/models_geometric_shapes.c -Wall -std=c99 -D_DEFAULT_SOURCE -Wno-missing-braces -Wunused-result -O2 -D_DEFAULT_SOURCE 
#-I. -I/home/pi/raylib/src -I/home/pi/raylib/src/external -I/usr/local/include 
#-L. -L/home/pi/raylib/src -L/home/pi/raylib/src -L/usr/local/lib -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -latomic -DPLATFORM_DESKTOP
