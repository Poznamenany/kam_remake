unit KM_Utils;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows}
  Windows,
  {$ENDIF}
  {$IFDEF Unix}
  unix, baseunix, UnixUtil,
  {$ENDIF}
  {$IFDEF FPC} FileUtil, {$ENDIF}
  {$IFDEF WDC} IOUtils, {$ENDIF}
	SysUtils, StrUtils, Classes, Controls,
  KM_Terrain,
  KM_Defaults, KM_CommonTypes, KM_CommonClasses, KM_Points;

  function KMPathLength(aNodeList: TKMPointList): Single;

  function GetHintWHotKey(aTextId, aHotkeyId: Integer): String;

	function GetShiftState(aButton: TMouseButton): TShiftState;
  function GetMultiplicator(aButton: TMouseButton): Word; overload;
  function GetMultiplicator(aShift: TShiftState): Word; overload;

  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer); overload;
  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aIsKaMFormat: Boolean); overload;
  procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aIsKaMFormat: Boolean; var aMapDataSize: Cardinal); overload;

  function GetGameObjectOwnerIndex(aObject: TObject): TKMHandIndex;

  function GetTerrainTileBasic(aTile: TKMTerrainTile): TKMTerrainTileBasic;

  function ApplyColorCoef(aColor: Cardinal; aRed, aGreen, aBlue: Single): Cardinal;


implementation
uses
  Math, KM_CommonUtils, KM_ResTexts, KM_ResKeys, KM_Houses, KM_Units, KM_UnitGroups;


function KMPathLength(aNodeList: TKMPointList): Single;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to aNodeList.Count - 1 do
    Result := Result + KMLengthDiag(aNodeList[I-1], aNodeList[I]);
end;


procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer);
var
  UseKaMFormat: Boolean;
begin
  LoadMapHeader(aStream, aMapX, aMapY, UseKaMFormat);
end;


procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aIsKaMFormat: Boolean);
var
  MapDataSize: Cardinal;
begin
  LoadMapHeader(aStream, aMapX, aMapY, aIsKaMFormat, MapDataSize);
end;


procedure LoadMapHeader(aStream: TKMemoryStream; var aMapX: Integer; var aMapY: Integer; var aIsKaMFormat: Boolean; var aMapDataSize: Cardinal);
var
  GameRevision: UnicodeString;
begin
  aStream.Read(aMapX); //We read header to new variables to avoid damage to existing map if header is wrong

  aIsKaMFormat := True;
  if aMapX = 0 then //Means we have not standart KaM format map, but our own KaM_Remake format
  begin
    aStream.ReadW(GameRevision);
    aIsKaMFormat := False;
    aStream.Read(aMapDataSize);
    aStream.Read(aMapX);
  end;

  aStream.Read(aMapY);
  Assert(InRange(aMapX, 1, MAX_MAP_SIZE) and InRange(aMapY, 1, MAX_MAP_SIZE),
         Format('Can''t open the map cos it has wrong dimensions: [%d:%d]', [aMapX, aMapY]));
end;


procedure IterateThroughTiles(const aStartCell: TKMPoint; Size: Integer; aIsSquare: Boolean; aOnCell: TPointEvent);
var
  I,K,Rad: Integer;
begin
  if Size = 0 then
    // Brush size smaller than one cell
//    aOnCell(aStartCell.X, aStartCell.Y);
//    gRenderAux.DotOnTerrain(Round(F.X), Round(F.Y), $FF80FF80)
  else
  begin
    // There are two brush types here, even and odd size
    if Size mod 2 = 1 then
    begin
      // First comes odd sizes 1,3,5..
      Rad := Size div 2;
      for I := -Rad to Rad do
        for K := -Rad to Rad do
        // Rounding corners in a nice way
//        if (gGameCursor.MapEdShape = hsSquare) or (Sqr(I) + Sqr(K) < Sqr(Rad+0.5)) then
//          RenderTile(Combo[TKMTerrainKind(gGameCursor.Tag1), TKMTerrainKind(gGameCursor.Tag1),1],P.X+K,P.Y+I,0);
    end
    else
    begin
      // Even sizes 2,4,6..
      Rad := Size div 2;
      for I := -Rad to Rad - 1 do
        for K := -Rad to Rad - 1 do
        // Rounding corners in a nice way
//        if (gGameCursor.MapEdShape = hsSquare) or (Sqr(I+0.5)+Sqr(K+0.5) < Sqr(Rad)) then
//          RenderTile(Combo[TKMTerrainKind(gGameCursor.Tag1), TKMTerrainKind(gGameCursor.Tag1),1],P.X+K,P.Y+I,0);
    end;
  end;
end;


function GetTerrainTileBasic(aTile: TKMTerrainTile): TKMTerrainTileBasic;
var
  L: Integer;
begin
  Result.BaseLayer := aTile.BaseLayer;
  Result.LayersCnt := aTile.LayersCnt;
  Result.Height := aTile.Height;
  Result.Obj := aTile.Obj;
  for L := 0 to 2 do
    Result.Layer[L] := aTile.Layer[L];
end;


function GetGameObjectOwnerIndex(aObject: TObject): TKMHandIndex;
begin
  Result := -1;
  if aObject is TKMHouse then
  begin
    Result := TKMHouse(aObject).Owner;
    Exit;
  end;
  if aObject is TKMUnit then
  begin
    Result := TKMUnit(aObject).Owner;
    Exit;
  end;
  if aObject is TKMUnitGroup then
  begin
    Result := TKMUnitGroup(aObject).Owner;
    Exit;
  end;
end;


function GetShiftState(aButton: TMouseButton): TShiftState;
begin
  Result := [];
  case aButton of
    mbLeft:   Include(Result, ssLeft);
    mbRight:  Include(Result, ssRight);
  end;

  if GetKeyState(VK_SHIFT) < 0 then
    Include(Result, ssShift);
end;


function GetMultiplicator(aButton: TMouseButton): Word;
begin
  Result := GetMultiplicator(GetShiftState(aButton));
end;


function GetMultiplicator(aShift: TShiftState): Word;
begin
  Result := Byte(aShift = [ssLeft]) + Byte(aShift = [ssRight]) * 10 + Byte(aShift = [ssShift, ssLeft]) * 100 + Byte(aShift = [ssShift, ssRight]) * 1000;
end;


function GetHintWHotKey(aTextId, aHotkeyId: Integer): String;
var
  HotKeyStr: String;
begin
  Result := gResTexts[aTextId];
  HotKeyStr := gResKeys.GetKeyNameById(aHotkeyId);
  if HotKeyStr <> '' then
    Result := Result + Format(' (''%s'')', [HotKeyStr]);

end;


//Multiply color by channels
function ApplyColorCoef(aColor: Cardinal; aRed, aGreen, aBlue: Single): Cardinal;
var
  R, G, B, R2, G2, B2: Byte;
begin
  //We split color to RGB values
  R := aColor and $FF;
  G := aColor shr 8 and $FF;
  B := aColor shr 16 and $FF;

  R2 := Min(Round(aRed * R), 255);
  G2 := Min(Round(aGreen * G), 255);
  B2 := Min(Round(aBlue * B), 255);

  Result := (R2 + G2 shl 8 + B2 shl 16) or $FF000000;
end;


end.

