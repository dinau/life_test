import strutils

let SIMPLE = false

#--hint:"Conf:off"
--verbosity:1

const
    CC = "gcc"
    #CC = "tcc"
    #CC = "clang"

var opt = "size"

const OPT_DEF = "size"
#const OPT_DEF = "speed"

if OPT_DEF == "size":
    opt = "-Os"
    --opt:size
else:
    opt = "-O3"
    --opt:speed


#switch "gcc.options.always" , ""
switch "gcc.options.debug" ,""
switch "gcc.options.size" , opt
switch "gcc.options.speed" , opt

const
    TARGET    = "life_win"
    #@SRC_DIR   = "."
    # build path
    #BUILD_DIR = "."
    #OUT_NAME = getCurrentDir().splitFile.name
    #target_build_path = os.joinPath(BUILD_DIR,OUT_NAME)
    #target_src_path   = os.joinPath(SRC_DIR,TARGET)
    #
var OUTNAME = TARGET & "_simple"
var OUTOPT = ""
if SIMPLE:
    switch "d","SIMPLE"
    OUTOPT = "-o:" & OUTNAME

#--path:"timerWin"
--path:"life_core"

--d:danger
--gc:orc

switch "nimcache",".nimcache"

--passL:"-s"

if CC == "gcc" or CC == "clang":
    --passC:"-ffunction-sections -fdata-sections"
    --passL:"-Wl,--gc-sections"

when true:
    if CC == "gcc":
        --passC:"-flto"
        --passL:"-flto"

--app:gui
--threads:on
#--d:useWinXP
#

task make,"make":
    exec ("nim c $# " % [OUTOPT]) & TARGET
task clean,"clean":
    rmFile TARGET.toEXE()
    rmFile OUTNAME.toEXE()
    rmDir nimcacheDir()
task build,"build":
    makeTask()

