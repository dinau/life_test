# 2021/09: Changed array to sequence
# First version:
#   2018/12 by audin(http://mpu.seesaa.net)
#   Nim Compiler Version 0.19.0
#
import random,os
import strutils,sequtils

const LoadPattern* = 100

#--- Life object (TLife)
type
    TLife* = ref object
        current,next:seq[seq[uint8]]
        nLives, nGenNum: int
        fWalkThroughTheWalls: bool
        VL, HL: int
        loadLifename:string

var tblPattern: seq[proc(self:TLife)]

proc init*(self: TLife, hl = 90, vl = 90) =
    self.nLives = 0; self.nGenNum = 1
    self.fWalkThroughTheWalls = true
    self.VL = vl; self.HL = hl

    let delta = 2
    let nVL = self.VL + delta
    let nHL = self.HL + delta
    self.current = newSeqWith(nHL, newSeq[uint8](nVL))
    self.next = newSeqWith(nHL, newSeq[uint8](nVL))

proc setVal*(self: TLife, x, y, val: int) =
    self.current[y][x] = val.uint8

proc getVal*(self: TLife, x, y: int): int =
    self.current[y][x].int

proc getValNext*(self: TLife, x, y: int): int =
    self.next[y][x].int

proc getInfo*(self: TLife, ): (int, int) =
    (self.nGenNum, self.nLives)

proc `walkThroughState=`*(self: TLife, state: bool) =
    self.fWalkThroughTheWalls = state

proc walkThroughState*(self: TLife): bool =
    self.fWalkThroughTheWalls

proc VL*(self: TLife): int =
    self.VL

proc HL*(self: TLife): int =
    self.HL

proc update*(self: TLife) = # Start calculation of one gerneration
    var val: uint8 = 0
    self.nLives = 0
    if self.fWalkThroughTheWalls: # To walk through the walls.
        # Refered to https://rosettacode.org/wiki/Category:Nim
        #            https://rosettacode.org/wiki/Conway%27s_Game_of_Life#Nim
        for y in 0..self.VL-1:
            for x in 0..self.HL-1:
                val = 0
                for y1 in y-1..y+1:
                    for x1 in x-1..x+1:
                        if self.current[( (y1+self.VL) mod self.VL)+1][ ((x1+self.HL) mod self.HL)+1] == 1:
                            inc(val)
                if self.current[y+1][x+1] == 1:
                    dec(val)
                self.next[y+1][x+1] = ((val == 3) or (val == 2 and self.current[y+1][x+1] == 1)).uint8
                if self.current[y+1][x+1] == 1:
                    self.nLives += 1
    else: # Cells that have a shape would be broken when they run into the wall.
        for y in 1..<self.VL+1:
            for x in 1..<self.HL+1:
                val = self.current[y-1][x-1] + self.current[y-1][x] + self.current[y-1][x+1] +
                      self.current[y][x-1]   + self.current[y][x+1] +
                      self.current[y+1][x-1] + self.current[y+1][x] + self.current[y+1][x+1]
                # evaluate Dead or Live
                if val == 2: self.next[y][x] = self.current[y][x] # Same as prev state
                elif val == 3: self.next[y][x] = 1 # Live
                else: self.next[y][x] = 0 # Dead
                if self.current[y][x] == 1:
                    self.nLives += 1
    self.nGenNum += 1
    swap(self.current, self.next)

proc setLoadLifename*(self:Tlife,fname:string) =
    self.loadLifename = fname

proc getLoadLifename*(self:TLife):string =
    return self.loadLifename

proc putObj*(self: TLife, x, y: int, shape: openArray[int]) =
    for i in 0..<(shape[0] * shape[1]):
        self.current[y + 1  + (i div shape[0])][x + 1 + (i mod shape[0])] = shape[i+2].uint8

proc putObj*(self: TLife, x, y: int, fname: string="save.life"):string{.discardable.} =
    var fp = open(fname,FileMode.fmRead)
    try:
        let hl = fp.readLine.split(",")[0].parseInt
        var i = 2
        for line in fp.lines:
            for chVal in line.strip(leading = false, chars = {','}).split(","):
                self.current[y + 1 + (i div hl)][x + 1 + (i mod hl)] = chVal.parseInt.uint8
                inc(i)
    except ValueError:
        return getCurrentExceptionMsg()
    except IOError:
        return getCurrentExceptionMsg()
    finally: close(fp)
    return ""

proc changed*(self: TLife, x, y: int): bool =
    self.current[y][x] != self.next[y][x]

proc outMap*(self: TLife) {.used.} =
    for y in 1..self.VL:
        var strHL: string
        for x in 1..self.HL:
            strHL &= $self.getVal(x, y) & ","
        echo strHL
    echo "--- map:Current Gen: ", $self.nGenNum, "  Lives: ", $self.nLives
    for y in 1..self.VL:
        var strHL: string
        for x in 1..self.HL:
            strHL &= $self.getValNext(x, y) & ","
        echo strHL
    echo "--- map:Next Gen: ", $self.nGenNum, "  Lives: ", $self.nLives

proc saveMap*(self: TLife,fname:string="save.life") {.used.} =
    var fp = open(fname,FileMode.fmWrite)
    defer: close(fp)
    fp.writeLine $self.VL,",",$self.HL,","
    for y in 1..self.VL:
        var strHL: string
        for x in 1..self.HL:
            strHL &= $self.getVal(x, y) & ","
        fp.writeLine strHL

proc setPattern*(self:TLife;num:int) =
    case num
    of 1..7:
        tblPattern[num](self)
    of LoadPattern:
        self.putObj(0,0,self.getloadLifename())
    else:
        discard
#--- Life object (TLife)  end.

const
    GliderDown {.used.} = [3,3,
                             0,1,0,
                             1,0,0,
                             1,1,1,]
    GliderUp   = [3,3,
                    1,1,1,
                    1,0,0,
                    0,1,0,]
    Pulser    =  [5,3, # Hitode seed
                    1,0,0,0,1,
                    1,0,1,0,1,
                    1,0,0,0,1,]
    ShipLeft   = [5,4,
                    0,1,0,0,1,
                    1,0,0,0,0,
                    1,0,0,0,1,
                    1,1,1,1,0,]
    ShipRight  = [5,4,
                    1,0,0,1,0,
                    0,0,0,0,1,
                    1,0,0,0,1,
                    0,1,1,1,1,]
    Train      = [9,9,
                    0,0,0,0,0,1,1,1,1,
                    0,0,0,0,1,0,0,0,1,
                    0,0,0,0,0,0,0,0,1,
                    1,1,0,0,1,0,0,1,0,
                    1,1,1,0,0,0,0,0,0, # center
                    1,1,0,0,1,0,0,1,0,
                    0,0,0,0,0,0,0,0,1,
                    0,0,0,0,1,0,0,0,1,
                    0,0,0,0,0,1,1,1,1,]
    Torch       = [9,8,
                    0,0,0,0,0,1,0,0,0,
                    0,0,0,0,1,0,1,0,0,
                    0,0,0,0,1,1,0,1,0,
                    0,0,1,1,0,0,1,0,1,
                    0,1,0,1,0,0,1,1,0,
                    0,0,1,0,1,1,0,0,0,
                    0,0,0,1,0,1,0,0,0,
                    0,0,0,0,1,0,0,0,0,]

proc line(self:Tlife,xa,ya,xb,yb:int,val=1) =
        if (xb - xa) != 0:
            for x in xa..xb:
                let y = (((yb-ya)*(x-xa)) div (xb-xa)) + ya
                self.setVal(x,y,val)
        else:
            for y in ya..yb:
                self.setVal(xa,y,val)

proc box(self:TLife,x,y,len:int) =
    self.line(x,y,x+len,y)
    self.line(x,y,x,y+len)
    self.line(x,y+len,x+len,y+len)
    self.line(x+len,y,x+len,y+len)

proc Pattern0(self: TLife) = # do nothing
    discard

proc Pattern1(self: TLife) = # Set random data
    for y in 1..self.VL:
        for x in 1..self.HL:
            {.cast(noSideEffect).}:
                if (y and 0x01) == 1:
                    self.setVal(x, y, rand(1))

proc Pattern2(self: TLife) = #
    let len = 120
    let x = (self.HL - len) div 2
    let y = (self.VL - len) div 2
    self.box(x,y,len)
    self.line(x+len,y+1,x+len,y+len-1,0)

proc Pattern3(self: TLife) = #
    for y in 1..self.VL:
        for x in 1..self.HL:
            self.setVal(x, y, 1)
    for y in (self.VL div 4)+1..(self.VL div 4)*3:
        for x in (self.HL div 4)+1..(self.HL div 4)*3:
            self.setVal(x, y, 0)

proc Pattern4(self: TLife) = #
    for y in 1..self.VL:
        self.setVal(self.HL div 2, y, 1)
        self.setVal((self.HL div 2)+1, y, 1)
    for x in 1..self.HL:
        self.setVal(x, self.VL div 2, 1)
        self.setVal(x, (self.VL div 2)+1, 1)

proc Pattern5(self: TLife) = #
    for y in 1..self.VL:
        self.setVal(1, y, 1); self.setVal(self.HL, y, 1)
        self.setVal(1, y, 1); self.setVal(self.VL, y, 1)
    for y in 2..<self.VL:
        self.setVal(2, y, 1); self.setVal(self.HL-1, y, 1)
        self.setVal(2, y, 1); self.setVal(self.VL-1, y, 1)

    for x in 4..self.HL-3:
        self.setVal(x, 1, 1)
        self.setVal(x,self.HL, 1)

proc Pattern6(self: TLife) =
    Pattern3(self)
    Pattern4(self)

proc Pattern7(self: TLife) = # like a game.
    {.cast(noSideEffect).}:
        self.putObj(rand(10..self.HL-20), 10, Train)
        for x in 1..4: self.putObj(x*20, 2*20, Pulser)
        for x in 6..6: self.putObj(x*20, 2*20, Pulser)
        for x in 1..4: self.putObj(x*20+10, 3*20, Pulser)
        for x in 6..6: self.putObj(x*20+10, 3*20, Pulser)
        self.putObj(rand(10..self.HL-10), self.VL-60, ShipLeft)
        self.putObj(rand(10..self.HL-10), self.VL-70, ShipRight)
        self.putObj(rand(10..self.HL-10), self.VL-10, GliderUp)
        self.putObj(rand(10..(self.HL-10)), self.VL-50, Torch)

# define function table
tblPattern.add Pattern0
tblPattern.add Pattern1
tblPattern.add Pattern2
tblPattern.add Pattern3
tblPattern.add Pattern4
tblPattern.add Pattern5
tblPattern.add Pattern6
tblPattern.add Pattern7
#tblPattern = @[Pattern0, Pattern1, Pattern2, Pattern3, Pattern4, Pattern5, Pattern6, Pattern7]

proc testModule(){.used.}  =
    let life = TLife()
    # create a map
    life.init(vl = 20, hl = 20)
    life.putObj(x=8, y=8, Pulser)
    for _ in 0..<40:
        life.outMap()
        life.update() # calclate generation
        sleep(700)

    # create another map
    life.init(vl = 88, hl = 88)
    let res = life.putObj(0,0,"save.life")
    if  "" != res:
        echo  "ERROR: ",res,"  in putObj()"
        quit 0
    life.outMap()
    life.update()
    life.outMap()

when isMainModule:
    testModule()

