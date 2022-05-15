# 2018/12 by audin(http://mpu.seesaa.net)
# Nim Compiler Version 0.19.0
# Needed files:
#     For Windows: SDL.dll, (SDL_ttf.dll)
# Needed command:
#     $ nimble install graphics,sdl
# Compile:
#    $ nim c -d:release --opt:size --passL:-s

import ../life_core/life_core
import graphics
import sdl
import colors
import random



# Map size. Logical.
when defined(SIMPLE):
    const VL* = 88 # Row (Line). y
    const HL* = 88 # Column.     x
    const CellSize = 10 # Screen size is (HL*CellSize) * (VL*CellSize)
else:
    const VL* = 152 # Row (Line). y
    const HL* = 152 # Column.     x
    const CellSize = 6 # Screen size is (HL*CellSize) * (VL*CellSize)

let life = TLife()
const
    HMax = HL*CellSize
    VMax = VL*CellSize
    normalSpeed = 200
    Pattern7Speed = 80
    bgColor = colors.Color(0x000053)
    fgColor = colors.Color(0x32cd32)
    gridColor = colors.Color(0x212121)
    updatePeriod = 10
var
    event: sdl.Event
    prevTime, prevSyncTime = 0
    fInitLife = true
    fStop, fStep: bool
    startDelay: int
    pattern = 1
    wait = normalSpeed

when false:
    import winim/lean
    # get window handle for win32api
    var wmInfo:SysWMinfo
    discard getWMInfo(cast[PSysWMinfo](wmInfo.addr))
    let hwdc =  wmInfo.window
    let dcClient = GetDC(hwdc)

proc showInfo() =
    let (GenNum, nLives) = life.getInfo()
    var caption = "Life Game by nim - "
    caption &= "Generations: " & $GenNum & "     "
    caption &= "Lives: " & $nLives & "     "
    caption &= "Delay: " & $wait & "     "
    caption &= "Pattern: " & $pattern & "     "
    if life.walkThroughState:
        caption &= "[ Walk through the walls ]"
    sdl.wmSetCaption(cstring(caption), nil)

proc drawCell(surf: graphics.PSurface) = # Draw cells
    proc draw(x, y: int) =
        if life.getVal(x, y) == 1:
            surf.fillRect(( (x-1)*CellSize, (y-1)*CellSize, CellSize, CellSize), fgColor)
        else:
            surf.fillRect(( (x-1)*CellSize, (y-1)*CellSize, CellSize, CellSize), bgColor)
        surf.drawRect(( (x-1)*CellSize, (y-1)*CellSize, CellSize, CellSize), gridColor)
    for y in 1..VL:
        for x in 1..HL:
            if fInitLife:
                draw(x, y)
            else:
                if life.changed(x, y):
                    draw(x, y)

proc updateScreen(surf: graphics.PSurface){.inline.} =
    showInfo()
    drawCell(surf)
    sdl.updateRect(surf.s, 0, 0, HMax, VMax)
    discard sdl.flip(surf.s)

# --- Initialize SDL
if sdl.init(sdl.INIT_VIDEO) < 0: # or sdl_ttf.init() < 0:
    sdl.quit()
var surf = newScreenSurface(HMax, VMax)
surf.fillSurface(bgColor)

# ------- Main_loop --------
while true:
    sdl.delay(1) # Reduce CPU load by waiting 1msec.
    if sdl.pollEvent(addr(event)) == 1: # Key/Mouse Event_polling -- None blocking
        var eventp = addr(event)
        case event.kind
        of sdl.KEYDOWN:
            let evk = sdl.evKeyboard(addr(event))
            case evk.keysym.sym
            of sdl.K_W: # Walk through the walls
                life.walkThroughState = not life.walkThroughState
            of sdl.K_C: # Clear window
                pattern = 0
                fInitLife = true
                fStop = true
            of sdl.K_ESCAPE, sdl.K_Q: # Quit application
                break
            of sdl.K_R: # Reset start
                fInitLife = true; fStop = false
            of sdl.K_P: # Save current window
                let (GenNum, nLives) = life.getInfo()
                surf.writeToBMP("life_G" & $GenNum & "_L" & $nLives & ".bmp")
            of sdl.K_SPACE: # Step up one gerneration
                if fStop:
                    fStep = true
                fStop = true
            of sdl.K_S: # Start/Stop drawing
                fStop = not fStop
            of sdl.K_PLUS, sdl.K_X, sdl.K_EQUALS:
                if wait < 500:
                    wait += 10
                fStop = false
            of sdl.K_MINUS, sdl.K_Z:
                if wait > updatePeriod:
                    wait -= 10
                else: wait = updatePeriod
                fStop = false
            of sdl.K_0: # Set normal speed
                wait = normalSpeed; fStop = false
                when not defined(SIMPLE):
                    if pattern == 7:
                        wait = Pattern7speed
            of sdl.K_9: # Set max speed
                wait = 80; fStop = false
            of sdl.K_1, sdl.K_2, sdl.K_3, sdl.K_4, sdl.K_5,
                sdl.K_6, sdl.K_7:
                when not defined(SIMPLE):
                    pattern = evk.keysym.sym - sdl.K_0
                    if pattern == 7:
                        wait = Pattern7speed
                    fInitLife = true
            else: discard
        of sdl.MOUSEBUTTONDOWN:
            var mPos = sdl.evMouseButton(eventp)
            if mPos.button == sdl.BUTTON_LEFT:
                let xp = int((mPos.x div CellSize)+1)
                let yp = int((mPos.y div CellSize)+1)
                life.setVal(xp, yp, life.getVal(xp, yp) xor 1)
        of sdl.QUITEV:
            break # quit Main_loop
        else: discard

    # --- Main_Process ---
    if fInitLife: # Init
        life.init(vl = VL, hl = HL)
        randomize() # For patterns
        life.setPattern(pattern) # Set specified pattern
        startDelay = 500 # Wait for a while when restart
        drawCell(surf)
        fInitLife = false

    var currentSyncTime = sdl.getTicks() # miliseconds
    if currentSyncTime > prevSyncTime + updatePeriod: # Update every fixed period: 30msec
        updateScreen(surf)
        prevSyncTime = currentSyncTime

    if startDelay == 0:
        var currentTime = sdl.getTicks() # miliseconds
        if fStop or fStep:
            if fStep:
                fStep = false
                life.update() # [Step]: Calculate life
        else:
            if currentTime > (prevTime + wait): # Update arbitrary period
                prevTime = currentTime
                life.update() # [Run ]: Calculate life
    else:
        dec(startDelay)
        if fStop:
            startDelay = 0

# ------- Main_loop end --------
surf.writeToBMP("life.bmp")
sdl.quit()

