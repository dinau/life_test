
TARGET ?= life_sdl
LIBS = ../life_core/life_core.nim

#TOOLCHAIN = clang
#TOOLCHAIN ?= tcc
TOOLCHAIN ?= gcc

ifneq ($(TOOLCHAIN),tcc)
OPT += -d:danger -d:strip
#OPT += --opt:speed
OPT += --opt:size
else
TOOLCHAIN = tcc
endif

OPT += --gc:orc
OPT += --app:gui
OPT += --showAllMismatches:on
OPT += --threads:on
#OPT += -d:useWinXP
OPT += --cc:$(TOOLCHAIN)

ifneq ($(TOOLCHAIN),tcc)
OPT_GCC +=--passC:-ffunction-sections --passC:-fdata-sections
OPT_GCC +=--passL:-Wl,--gc-sections
OPT_GCC += --passC:-flto --passL:-flto
OPT += $(OPT_GCC)
endif

TARGET_EXE = $(TARGET).exe $(TARGET)_simple.exe
all: $(TARGET_EXE)

.PHONY: run clean check format

#NIMCACHE= x:/.nimcache
NIMCACHE=.nimcache_$@_$(TOOLCHAIN)

$(TARGET).exe: $(TARGET).nim Makefile $(LIBS)
	nim c $(OPT) --nimcache:$(NIMCACHE) -o:$@ $(<)
	-@size $(@)
	-@ls -al $@

$(TARGET)_simple.exe: $(TARGET).nim Makefile $(LIBS)
	nim c $(OPT) --nimcache:$(NIMCACHE) -d:SIMPLE -o:$@ $(<)
	-@size $(@)
	-@ls -al $@

check:
	nim check $(OPT) --nimcache:$(NIMCACHE) $(TARGET)

clean:
	-@rm $(TARGET_EXE)
	-@rm -fr .nimcache_*
	-@rm -fr .nimcache
	-@rm -fr $(NIMCACHE)

include ../pretty.mak
format:
	nimpretty  $(NIM_PRETTY_OPT) $(TARGET).nim


GIT_REPO = c:/.ccache/life_test/life_sdl
rel:
	cp *.md         $(GIT_REPO)/
	cp *.dll        $(GIT_REPO)/
	cp *.nim        $(GIT_REPO)/
	-cp config.nims $(GIT_REPO)/
	cp Makefile     $(GIT_REPO)/
	cp setenv.bat   $(GIT_REPO)/
	-cp *.exe       $(GIT_REPO)/

