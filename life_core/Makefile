
TARGET = life_core
TOOLCHAIN ?= clang

FPC = D:\lazarus220rc1\fpc\3.2.2\bin\i386-win32\fpc.exe

#OPT += --app:gui
OPT += --showAllMismatches:on
#OPT += --threads:on
#OPT += -d:useWinXP
OPT += --cc:$(TOOLCHAIN)

ifneq ($(TOOLCHAIN),tcc)
OPT += -d:danger -d:strip
OPT += --opt:size
OPT_GCC +=--passC:-ffunction-sections --passC:-fdata-sections
OPT_GCC +=--passL:-Wl,--gc-sections
OPT += $(OPT_GCC)
endif

ifeq ($(SIMPEL),1)
	$(TARGET) = $(TAREGT)_simple
endif

all:$(TARGET).exe core_test_pas.exe
	-@ls -al $^


.PHONY: run clean check format

#NIMCACHE= x:/.nimcache
NIMCACHE=.nimcache_$@_$(TOOLCHAIN)

%.exe: %.nim Makefile $(LIBS)
	-nim c $(OPT) --nimcache:$(NIMCACHE) $(<)
	-@size $(@)
	-@ls -al $@

check:
	nim check $(OPT) --nimcache:$(NIMCACHE) $(TARGET)

run: all
	$(TARGET).exe

clean:
	-@rm *.exe *.o *.ppu
	-@rm -fr .nimcache_*
	-@rm -fr .nimcache
	-@rm -fr $(NIMCACHE)

format:
	nimpretty  $(NIM_PRETTY_OPT) $(TARGET).nim

#FPC_OPT += -MDelphi
FPC_OPT += -Sx # enable exception keyword
core_test_pas.exe: core_test.pas life_core.pas Makefile
	$(FPC) -o$@ -Os $(FPC_OPT) $<
	@size $@

lib: life_core.nim Makefile
	@-nim c --app:staticlib $(OPT) --nimcache:$(NIMCACHE) $(<)
	-nim c --noMain --noLinking --nimcache:share\
		--header:life_core.h life_core.nim

test: test.pas
	$(FPC) -o$@.exe -Os $(FPC_OPT) $<


GIT_REPO = c:/.ccache/life_test/life_core
rel:
	cp *.nim        $(GIT_REPO)/
	cp *.pas        $(GIT_REPO)/
	cp setenv.bat   $(GIT_REPO)/
	cp Makefile     $(GIT_REPO)/
	cp fpc-help.txt $(GIT_REPO)/
	cp README.md    $(GIT_REPO)/

