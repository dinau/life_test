unit life_core;
{$IFDEF FPC}
  {$mode Delphi}
{$ENDIF}
interface

uses sysutils,strutils,types;

type
    TInfo = object
        genNum,lives:integer;
    end;
type
    TMap = array of array of integer;
type
    TLife = object
        VL,HL:integer;
        current,next:TMap;
        nGenNum,nLives:integer;
        fwalkThroughState:boolean;
    private
        procedure setWalkThroughState(val:boolean);
    public
        constructor init(xl,yl:integer);
        destructor done;
        procedure setVal(x, y,val: integer);
        procedure setValNext(x, y,val: integer);
        function getVal(x, y: integer): integer;
        function getValNext(x, y: integer): integer;
        procedure saveMap(fname:string;page:integer=0);
        procedure outMap;
        procedure update;
        procedure clearMap;
        procedure putObj( xt, yt: integer; shape:array of integer );
        function  putObj( xt, yt: integer; fname: string):string;
        function changed(x, y: integer): boolean;
        function getInfo():TInfo;
        function getVL():integer;
        function getHL():integer;
        property walkThroughState: boolean read fwalkThroughState write setWalkThroughState;
        procedure setPattern(num:integer);
    end;

const
    GliderDown:array[0..10] of integer= (3,3,
                                             0,1,0,
                                             1,0,0,
                                             1,1,1);
    GliderUp:array[0..10] of integer = (3,3,
                                            1,1,1,
                                            1,0,0,
                                            0,1,0);
    Pulser :array[0..16] of integer   =  (5,3, //# Hitode
                                            1,0,0,0,1,
                                            1,0,1,0,1,
                                            1,0,0,0,1);
    ShipLeft :array[0..21] of integer  = (5,4,
                                            0,1,0,0,1,
                                            1,0,0,0,0,
                                            1,0,0,0,1,
                                            1,1,1,1,0);
    ShipRight :array[0..21] of integer = (5,4,
                                            1,0,0,1,0,
                                            0,0,0,0,1,
                                            1,0,0,0,1,
                                            0,1,1,1,1);
    Train :array[0..82] of integer     = (9,9,
                                            0,0,0,0,0,1,1,1,1,
                                            0,0,0,0,1,0,0,0,1,
                                            0,0,0,0,0,0,0,0,1,
                                            1,1,0,0,1,0,0,1,0,
                                            1,1,1,0,0,0,0,0,0, //# center
                                            1,1,0,0,1,0,0,1,0,
                                            0,0,0,0,0,0,0,0,1,
                                            0,0,0,0,1,0,0,0,1,
                                            0,0,0,0,0,1,1,1,1);

implementation

constructor TLife.init(xl,yl:integer);
var delta:integer;
begin
    HL := xl;
    VL := yl;
    delta := 2;
    nGenNum := 0;
    nLives := 0;
    setLength(current,yl+delta,xl+delta);
    setLength(next,yl+delta,xl+delta);
    randomize;
    fwalkThroughState := true;
end;

destructor TLife.done;
begin
   setLength(current,0,0);
   setLength(next,0,0);
end;

procedure TLife.update;  // Start calculation of one gerneration
var
    val: integer;
    i,j,x1,y1,bres:integer;
    tmp:TMap;
begin
    nLives := 0;
    if fWalkThroughState then // To walk through the walls.
    begin
        // Refered to https://rosettacode.org/wiki/Category:Nim
        //            https://rosettacode.org/wiki/Conway%27s_Game_of_Life#Nim
        for i := 0 to Pred(VL) do
            for j := 0  to Pred(HL) do begin
                val := 0;
                for y1 := i-1 to i+1 do
                    for x1 := j-1 to j+1 do
                        if current[( (y1+VL) mod VL)+1][ ((x1+HL) mod HL)+1] = 1 then
                            inc(val);
                if current[i+1][j+1] = 1 then
                    dec(val);
                if ( (val = 3) or ((val = 2) and (current[i+1][j+1] = 1)) ) then bres := 1
                else bres := 0;
                next[i+1][j+1] := bres;
                if current[i+1][j+1] = 1 then
                    inc(nLives);
            end;
    end
    else begin // Cells that have a shape would be broken when they run into the wall.
        for i := 1 to Pred(VL+1) do
            for j := 1 to Pred(HL+1) do begin
                val  := current[i-1][j-1] + current[i-1][j] + current[i-1][j+1] +
                        current[i][j-1]   + current[i][j+1] +
                        current[i+1][j-1] + current[i+1][j] + current[i+1][j+1];
                // evaluate Dead or Live
                if val = 2 then
                    next[i][j] := current[i][j] // Same as prev state
                else if val = 3 then
                    next[i][j] := 1  // Live
                else
                    next[i][j] := 0; // Dead
                if current[i][j] = 1 then
                    inc(nLives);
            end;
    end;
    inc(nGenNum);
    tmp := current;
    current := next;
    next := tmp;
end;

function TLife.getVL():integer;
begin
    getVL := VL;
end;

function TLife.getHL():integer;
begin
    getHL := HL;
end;

procedure TLife.setWalkThroughState(val:boolean);
begin
    fWalkThroughState := val;
end;

function TLife.getInfo():TInfo;
begin
    getInfo.genNum := nGenNum;
    getInfo.lives := nLives;
end;

procedure TLife.setVal(x, y,val: integer);
begin
    current[y][x] := val;
end;

procedure TLife.setValNext(x, y,val: integer);
begin
    next[y][x] := val;
end;

function TLife.getVal(x, y: integer): integer;
begin
    getVal := current[y][x];
end;

function TLife.getValNext(x, y: integer): integer;
begin
    getValNext := next[y][x];
end;

procedure TLife.outMap;
var
    y,x:integer;
    strHL: string;
begin
    for y := 1 to VL do begin
        strHL :=  '';
        for x := 1 to HL do
            strHL := strHL + intToStr(getVal(x, y)) + ',';
        writeln(strHL);
    end;
    writeln('--- map:Current Gen: ', intToStr(nGenNum), '  Lives: ', intToStr(nLives));
    for y := 1 to VL do begin
        strHL :=  '';
        for x := 1 to HL do
            strHL := strHL + intToStr(getValNext(x, y)) + ',';
        writeln(strHL);
    end;
    writeln('--- map:Next Gen: ', intToStr(nGenNum), '  Lives: ', intToStr(nLives));

end;

procedure TLife.saveMap(fname:string;page:integer);
var
    fp:TextFile;
    strHL:string;
    x,y:integer;
begin
    assignFile(fp,fname);
    try
        rewrite(fp);
        // current
        writeln(fp,intToStr(VL),',',intToStr(HL),',');
        for y := 1 to VL do begin
            strHL := '';
            for x := 1 to HL do
                if page = 0 then
                    strHL := strHL + intToStr(getVal(x,y)) + ','
                else
                    strHL := strHL + intToStr(getValNext(x,y)) + ',';
            writeln(fp,strHL);
        end;
    //except
    //    on E: EInOutError do Writeln('File handling error occurred. Details: '+E.ClassName+'/'+E.Message);
    finally
        closeFile(fp)
    end;

end;

function TLife.putObj( xt, yt: integer; fname: string):string;
var
    fp:Textfile;
    str:string;
    hlx,i,j:integer;
    strArray:TStringDynArray;
begin
    assignFile(fp,fname);
    reset(fp);
    try
        readln(fp,str);
        hlx :=  strToInt(splitString(str,',')[0]);
        i := 0;
        while not eof(fp) do
        begin
            readln(fp, str);
            str := leftStr(str,length(str)-1);
            strArray := splitString(str,',');
            for j := 0 to length(strArray)-1 do begin
                current[yt + 1 + (i div hlx)][xt + 1 + (i mod hlx)] := strToInt(strArray[j]);
                inc(i);
            end;
        end;
    //except on E: EInOutError do writeln('File handling error occurred. Details: ', E.Message);
    finally
        close(fp);
    end;
    putObj := '';
end;

procedure TLife.putObj( xt, yt: integer; shape:array of integer );
var i:integer;
begin
    try
        for i := 0 to (shape[0] * shape[1])-1 do
            current[yt + 1  + (i div shape[0])][xt + 1 + (i mod shape[0])] := shape[i+2];
    except //RangeCheckError;
        writeln('ERROR!: putObj: x,y : ',intToStr(shape[0]),',',intToStr(shape[1]));

    end;
end;

function TLife.changed(x, y: integer): boolean;
begin
    changed :=  (current[y][x] <> next[y][x]);
end;

function randomx(val:integer):integer;
begin
    randomx := random(val+1); // get 0 or 1
end;

procedure TLife.ClearMap;
var y,x:integer;
begin
    for y := 0 to VL+1 do
        for x := 0 to HL+1 do begin
            setVal(x, y, 0);
            setValNext(x, y, 0);
        end;
end;

procedure Pattern0(self:TLife); // do nothing
begin
    // just reserve
end;

procedure Pattern1(self:TLife);
var y,x:integer;
begin
    with self do begin
        for y := 1 to VL do
            for x := 1 to HL do
                setVal(x, y, randomx(1));
    end;
end;

procedure Pattern2(self:TLife);
var y,x: integer;
begin
    with self do begin
        for y := 1 to (VL div 2) do
            for x := 1 to (HL div 2) do
                setVal(x, y, 1);
        for y :=  ((VL div 2)+1) to VL do
            for x := ((HL div 2)+1) to HL do
                setVal(x, y, 1);
    end;
end;

procedure Pattern3(self:TLife);
var y,x,dd: integer;
begin
    dd := 9 ;// 9:4000g 6:3600g 30:2700g 8:2400g 5:1800g 4:1800g 7:1700g 18,3:1600g 40,20:1500g 15:1000g 60:1000g(inf) 50:900g 70:200g
    with self do begin
        for x  := 1+dd to HL-dd do
            setVal(x, 1+dd, 1);
        for y :=  1+dd to VL-dd do
            setVal(HL-dd, y, 1);
    end;
end;

procedure Pattern4(self:TLife);
var y,x: integer;
begin
    with self do begin
        for y := 1 to VL do begin
            setVal(HL div 2, y, 1);
            setVal((HL div 2)+1, y, 1);
        end;
        for x := 1 to HL do begin
            setVal(x, VL div 2, 1);
            setVal(x, (VL div 2)+1, 1);
        end;
    end;
end;

procedure Pattern5(self:TLife);
var y: integer;
begin
    with self do begin
        for y := 1 to VL do begin
            setVal(1, y, 1); setVal(HL, y, 1);
            setVal(1, y, 1); setVal(VL, y, 1);
        end;
        for y := 2 to VL-1 do begin
            setVal(2, y, 1); setVal(HL-1, y, 1);
            setVal(2, y, 1); setVal(VL-1, y, 1);
        end;
    end;
end;

procedure Pattern6(self:TLife);
var y,x,dd: integer;
begin
    dd := 9 ;// 9:4000g 6:3600g 30:2700g 8:2400g 5:1800g 4:1800g 7:1700g 18,3:1600g 40,20:1500g 15:1000g 60:1000g(inf) 50:900g 70:200g
    with self do begin
        for x  := 1+dd to HL-dd do setVal(x, VL div 2, 1);
        for y :=  1+dd to VL-dd do setVal(HL div 2, y, 1);
    end;
end;

procedure Pattern7(self:TLife); // like a game.
var x:integer;
begin
    with self do begin
        putObj(randomx(HL-10)+10, 10, Train);
        for x := 1 to 4 do putObj(x*20, 2*20, Pulser);
        for x := 6 to 6 do putObj(x*20, 2*20, Pulser);
        for x := 1 to 4 do putObj(x*20+10, 3*20, Pulser);
        for x := 6 to 6 do putObj(x*20+10, 3*20, Pulser);
        putObj(randomx(HL-10)+10, VL-60, ShipLeft);
        putObj(randomx(HL-10)+10, VL-70, ShipRight);
        putObj(randomx(HL-10)+10, VL-10, GliderUp);
    end;
end;

procedure TLife.setPattern(num:integer);
type TProcArray = array of procedure(self:TLife);
var procArray:TProcArray = [pattern0,
                            pattern1,
                            pattern2,
                            pattern3,
                            pattern4,
                            pattern5,
                            pattern6,
                            pattern7];
begin
    procArray[num](self);
end;

end.
