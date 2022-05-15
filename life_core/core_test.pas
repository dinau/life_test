program core_test;

uses sysutils,life_core;

const VLY = 10;
const HLX = 10;
var
    life:TLife;
    i:integer;
begin
    with life do begin
        init(HLX,VLY);
        putObj(3,3,GliderUp);
        for i:=0 to 30 do begin
            outMap;
            update;
            sleep(700);
        end;
        {$if false}
        saveMap('gliderUp.life');
        init(88,88);
        putObj(0,0,'save.life');
        outMap;
        {$ifend}
    end;
end.

