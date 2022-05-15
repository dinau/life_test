# 2018/12 by audin(http://mpu.seesaa.net)
# Nim Compiler Version 0.19.0

import wNim/[wApp, wIcon, wFrame, wFileDialog, wImage, wCursor,
        wPaintDC, wClientDC, wBitmap, wMemoryDC, wPanel,
        wStatusBar, wMessageDialog, wBrush, wPen
    ]
import winim
import ../life_core/life_core
import strformat,os

# Map size. Logical.
when defined(SIMPLE):
    const VL* = 88 # Row (Line). y
    const HL* = 88 # Column.     x
    const CellSize = 10 # Screen size is (HL*CellSize) * (VL*CellSize)
else:
    const VL* = 152 # Row (Line). y
    const HL* = 152 # Column.     x
    const CellSize = 6 # Screen size is (HL*CellSize) * (VL*CellSize)

#- forward definition
proc showInfo(self: wFrame)
proc drawCell(self: TLife)

const
    HMax = HL*CellSize
    VMax = VL*CellSize
    normalSpeed = 200
    Pattern7Speed = 80
    fgColor = 0x00_00ef00
    bgColor = 0x00_530000 # 0x00_BBGGRR
    gridColor = bgColor
    delayBetweenPattern = 1500
    IMG_DIR = "img"
var
    dcMem = MemoryDC()
    fInitLife = true
    fStop, fStep: bool
    pattern = 1
    wait = normalSpeed
    saveWait:int
    fStartDelayIsEnded: bool
    loadLifename:string
    fRecordingImg:bool

type timerID = enum
    idTimer1 = 10000, idTimer2, idTimer3

let life = TLife()
#- Main form
let fmMain = Frame()
fmMain.clientsize = (HMax,VMax)
#- Main panel
let pnMain = Panel(fmMain, (HMax, VMax))
pnMain.setBackgroundColor(0x00_0000ff)
#- Bitmap and memory buffer
let bmpImage = Bitmap(HMax, VMax)
dcMem.selectObject(bmpImage)
dcMem.clear(Brush(color = bgColor))
dcMem.setPen(Pen(color = gridColor))
#- Dialog
let dlg = FileDialog(fmMain)
#- Period timer
#
fmMain.startTimer(seconds = wait/1000,id = idTimer1.int)

proc timerRestart(msec:int) =
    let tid = idTimer1.int
    fmMain.stopTimer(id = tid )
    fmMain.startTimer( seconds = msec/1000,id = tid)

proc initLife() =
    fRecordingImg = false
    life.init(vl = VL, hl = HL)
    life.setPattern(pattern) # Set specified pattern
    life.drawCell()
    showInfo(fmMain)
    pnMain.refresh(eraseBackground = false)
    fStartDelayIsEnded = false
    saveWait = wait
    timerRestart(delayBetweenPattern)

proc layout() =
    fmMain.autolayout """
        h:|~[pnMain]~|
        v:|~[pnMain]~|
    """
proc showInfo(self: wFrame) =
    let (GenNum, nLives) = life.getInfo()
    var caption:string
    caption &= "Life Game by nim - "
    caption &= "Generations: " & $GenNum & "     "
    caption &= "Lives: " & $nLives & "     "
    caption &= "Delay: " & $wait & "     "
    caption &= "Pattern: " & $pattern & "     "
    if life.walkThroughState:
        caption &= "[ Walk through the walls ]"
    if fRecordingImg:
        caption &= "  << Recording !>>"
    self.title = caption

proc drawCell(self: TLife) = # Draw cells
    proc draw(x, y: int) =
        if self.getVal(x, y) == 1:
            dcMem.setBrush(Brush(color = fgColor))
            dcMem.drawRectangle( (x-1)*CellSize, (y-1)*CellSize, CellSize, CellSize) # fgColor
        else:
            dcMem.setBrush(Brush(color = bgColor))
            dcMem.drawRectangle( (x-1)*CellSize, (y-1)*CellSize, CellSize, CellSize) #, bgColor)
    for y in 1..self.VL:
        for x in 1..self.HL:
            if fInitLife or fStop:
                draw(x, y)
            else:
                if self.changed(x, y):
                    draw(x, y)

fmMain.wEvent_timer do (event: wEvent):# drawLife
    if fStartDelayIsEnded:
        if fStop or fStep:
            if fStep:
                fStep = false
                life.update() # [Step]: Calculate life
        else:
            life.update() # [Run ]: Calculate life
    else:
        fStartDelayIsEnded = true
        timerRestart(saveWait)
        wait = saveWait

    life.drawCell()
    if fRecordingImg:
        let (genNum,_) = life.getInfo()
        Image(bmpImage).saveFile(fmt"{IMG_DIR}/{genNum:04}.png")
    showInfo(fmMain)
    pnMain.refresh(eraseBackground = false)

fmMain.wIdExit do ():
    fmMain.close()

pnMain.wEvent_Paint do (event: wEvent):
    var dcDest = PaintDC(event.window)
    defer: dcDest.delete
    let size = event.window.clientsize
    dcDest.blit(0, 0, size.width, size.height, dcMem, 0, 0)
    event.skip()

fmMain.wEvent_Size do ():
    layout()

fmMain.wEvent_Char do (event: wEvent):
    let keyCode = event.getKeyCode
    let tmpWait = wait
    case keyCode
    of '['.int:
        fRecordingImg =true
        discard existsOrCreateDir(IMG_DIR)
    of ']'.int:
        fRecordingImg =false
    of '+'.int, '='.int, 'x'.int,'d'.int: # Speed down
        if wait < 500:
            wait += 10
        fStop = false
    of '-'.int, 'z'.int, 'u'.int: # Speed up
        if wait > 10:
            wait -= 10
        else: wait = 10
        fStop = false
    of ' '.int: # [Space key]: Calculate next gerneration
        if fStop:
            fStep = true
        fStop = true
    of '0'.int: # [0] Set normal speed
        wait = normalSpeed
        fStop = false
        if pattern == 7:
            wait = Pattern7speed
    of '1'.int..'7'.int: # [1..7] Select pattern
        when not defined(SIMPLE):
            pattern = keyCode - '0'.int
            if pattern == 7:
                wait = Pattern7speed
            fInitLife = true
    of '9'.int: # [9] Set high speed
        wait = 30
        fStop = false
    of 'c'.int:
        pattern = 0
        fInitLife = true
        fStop = true
    of 'l'.int: # Load pattern from file
        dlg.setWildcard("Life data(*.life)|*.life")
        dlg.setDirectory(".")
        let files = dlg.display
        if files != @[]:
            fmMain.stoptimer(id = idTimer1.int)
            loadLifename = files[0]
            life.setLoadLifename(loadLifename)
            fInitLife = true
            pattern = LoadPattern
    of 'p'.int: # Save current window image and map data(text file)
        Image(bmpImage).saveFile("save.png")
        life.saveMap("save.life")
    of 'q'.int: # Quit application
        fmMain.close()
    of 'r'.int: # Reset start
        fInitLife = true
        fStop = false
    of 's'.int: # Start/Stop drawing
        fStop = not fStop
    of 'w'.int:
        life.walkThroughState = not life.walkThroughState
    else:
        return

    if tmpWait != wait:
        timerRestart(wait)
    if fInitLife:
        initLife()
        fInitLife = false

pnMain.wEvent_LeftDown do (event: wEvent):
    let xp = (event.getX() div CellSize) + 1
    let yp = (event.getY() div CellSize) + 1
    when true:
        life.setVal(xp, yp, life.getVal(xp, yp) xor 1)
    else: # for debug
        echo "---"
        echo "Pos-org: " & $event.getX() & " , " & $event.getY()
        echo "Pos-xp,yp: " & $xp & " , " & $yp," (",$(xp-1),",",$(yp-1),")"
        echo  "org:",$life.getVal(xp,yp),"  xor 1:",life.getVal(xp,yp) xor 1
        life.outMap()
        life.setVal(xp, yp, life.getVal(xp, yp) xor 1)
        life.outMap()

#-----------------
# main()
#-----------------
when isMainModule:
    let app = App(wSystemDpiAware)
    #- start
    initLife()
    fInitLife = false
    layout()
    fmMain.startTimer(id = idTimer1.int ,seconds=2)
    fmMain.center()
    fmMain.show()
    app.mainLoop()

