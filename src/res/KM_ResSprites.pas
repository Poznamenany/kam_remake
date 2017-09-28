unit KM_ResSprites;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Graphics, Math, SysUtils,
  KM_CommonTypes, KM_Defaults, KM_Pics, KM_PNG, KM_Render, KM_ResTexts, KM_ResTileset
  {$IFDEF FPC}, zstream {$ENDIF}
  {$IFDEF WDC}, ZLib {$ENDIF};


const
  //Colors to paint beneath player color areas (flags)
  //The blacker/whighter - the more contrast player color will be
  FLAG_COLOR_DARK = $FF101010;   //Dark-grey (Black)
  FLAG_COLOR_LITE = $FFFFFFFF;   //White

type
  TRXUsage = (ruMenu, ruGame, ruCustom); //Where sprites are used

  TRXInfo = record
    FileName: string; //Used for logging and filenames
    TeamColors: Boolean; //sprites should be generated with color masks
    Usage: TRXUsage; //Menu and Game sprites are loaded separately
    LoadingTextID: Word;
  end;


var
  RXInfo: array [TRXType] of TRXInfo = (
    (FileName: 'Trees';      TeamColors: False; Usage: ruGame;   LoadingTextID: TX_MENU_LOADING_TREES;),
    (FileName: 'Houses';     TeamColors: True;  Usage: ruGame;   LoadingTextID: TX_MENU_LOADING_HOUSES;),
    (FileName: 'Units';      TeamColors: True;  Usage: ruGame;   LoadingTextID: TX_MENU_LOADING_UNITS;),
    (FileName: 'GUI';        TeamColors: True;  Usage: ruMenu;   LoadingTextID: 0;),
    (FileName: 'GUIMain';    TeamColors: False; Usage: ruMenu;   LoadingTextID: 0;),
    (FileName: 'Custom';     TeamColors: False; Usage: ruCustom; LoadingTextID: 0;),
    (FileName: 'Tileset';    TeamColors: False; Usage: ruMenu;   LoadingTextID: TX_MENU_LOADING_TILESET;));

type
  TRXData = record
    Count: Integer;
    Flag: array of Byte; //Sprite is valid
    Size: array of record X,Y: Word; end;
    Pivot: array of record x,y: Integer; end;
    Data: array of array of Byte;
    RGBA: array of array of Cardinal; //Expanded image
    Mask: array of array of Byte; //Mask for team colors
    HasMask: array of Boolean; //Flag if Mask for team colors is used
  end;
  PRXData = ^TRXData;

  //Base class for Sprite loading
  TKMSpritePack = class
  private
    fPad: Byte; //Force padding between sprites to avoid neighbour edge visibility
    procedure MakeGFX_BinPacking(aTexType: TTexFormat; aStartingIndex: Word; var BaseRAM, ColorRAM, TexCount: Cardinal);
    procedure SaveTextureToPNG(aWidth, aHeight: Word; aFilename: string; const Data: TKMCardinalArray);
  protected
    fRT: TRXType;
    fRXData: TRXData;
    procedure Allocate(aCount: Integer); virtual; //Allocate space for data that is being loaded
  public
    constructor Create(aRT: TRXType);

    procedure AddImage(aFolder, aFilename: string; aIndex: Integer);
    property RXData: TRXData read fRXData;
    property Padding: Byte read fPad write fPad;

    procedure LoadFromRXXFile(const aFileName: string; aStartingIndex: Integer = 1);
    procedure OverloadFromFolder(const aFolder: string);
    procedure MakeGFX(aAlphaShadows: Boolean; aStartingIndex: Integer = 1); overload;
    procedure DeleteSpriteTexture(aIndex: Integer);

    function GetSpriteColors(aCount: Word): TRGBArray;

    procedure ExportAll(const aFolder: string);
    procedure ExportImage(const aFile: string; aIndex: Integer);
    procedure ExportMask(const aFile: string; aIndex: Integer);

    procedure ClearTemp; virtual;//Release non-required data
  end;


  TKMResSprites = class
  private
    fAlphaShadows: Boolean; //Remember which state we loaded
    fSprites: array[TRXType] of TKMSpritePack;
    fStepProgress: TEvent;
    fStepCaption: TUnicodeStringEvent;
    fGenTexIdStartI: Integer;
    fGenTerrainToTerKind: array of TKMTerrainKind;

    function GetRXFileName(aRX: TRXType): string;
    function GetSprites(aRT: TRXType): TKMSpritePack;
  public
    constructor Create(aStepProgress: TEvent; aStepCaption: TUnicodeStringEvent);
    destructor Destroy; override;

    procedure LoadMenuResources;
    procedure LoadGameResources(aAlphaShadows: Boolean);
    procedure ClearTemp;
    class procedure SetMaxAtlasSize(aMaxSupportedTxSize: Integer);
    class function AllTilesOnOneAtlas: Boolean;

    procedure GenerateTerrainTransitions(aSprites: TKMSpritePack);

    function GetGenTerrainKindByTerrain(aTerrain: Integer): TKMTerrainKind;

    property Sprites[aRT: TRXType]: TKMSpritePack read GetSprites; default;

    //Used externally to access raw RGBA data (e.g. by ExportAnim)
    function LoadSprites(aRT: TRXType; aAlphaShadows: Boolean): Boolean;
    procedure ExportToPNG(aRT: TRXType);

    property AlphaShadows: Boolean read fAlphaShadows;
    property FileName[aRX: TRXType]: string read GetRXFileName;
  end;


  TKMTexCoords = record
                  ID: Cardinal;
                  u1,v1,u2,v2: Single; //Top-Left, Bottom-Right uv coords
                end;

var
  gGFXData: array [TRXType] of array of record
    Tex, Alt: TKMTexCoords; //AltID used for team colors and house building steps
    PxWidth, PxHeight: Word;
  end;

   gGenTerrainTransitions: array[TKMTerrainKind]
                            of array[TKMTileMaskType]
                              of array[0..1] //mask components (subtypes)
//                                of array[0..3] //Terrain Rotation
                                  of Word;
implementation
uses
  TypInfo, KromUtils, KM_Log, KM_BinPacking, KM_CommonUtils;

const
  MAX_GAME_ATLAS_SIZE = 2048; //Max atlas size for KaM. No need for bigger atlases

var
  LOG_EXTRA_GFX: Boolean = True;
  ALL_TILES_IN_ONE_TEXTURE: Boolean = False;
  MaxAtlasSize: Integer;


{ TKMSpritePack }
constructor TKMSpritePack.Create(aRT: TRXType);
begin
  inherited Create;

  fRT := aRT;

  //Terrain tiles need padding to avoid edge bleeding
  if fRT = rxTiles then
    fPad := 1;
end;


//This is a crude solution to allow Campaigns to delete sprites they add
procedure TKMSpritePack.DeleteSpriteTexture(aIndex: Integer);
begin
  if gGFXData[fRT, aIndex].Tex.ID <> 0 then
    TRender.DeleteTexture(gGFXData[fRT, aIndex].Tex.ID);
  if gGFXData[fRT, aIndex].Alt.ID <> 0 then
    TRender.DeleteTexture(gGFXData[fRT, aIndex].Alt.ID);

  gGFXData[fRT, aIndex].Tex.ID := 0;
  gGFXData[fRT, aIndex].Alt.ID := 0;
end;


procedure TKMSpritePack.Allocate(aCount: Integer);
begin
  fRXData.Count := aCount;

  aCount := fRXData.Count + 1;
  SetLength(gGFXData[fRT],     aCount);
  SetLength(fRXData.Flag,     aCount);
  SetLength(fRXData.Size,     aCount);
  SetLength(fRXData.Pivot,    aCount);
  SetLength(fRXData.RGBA,     aCount);
  SetLength(fRXData.Mask,     aCount);
  SetLength(fRXData.HasMask,  aCount);
end;


//Release RAM that is no longer needed
procedure TKMSpritePack.ClearTemp;
var I: Integer;
begin
  for I := 1 to fRXData.Count do
  begin
    SetLength(fRXData.RGBA[I], 0);
    SetLength(fRXData.Mask[I], 0);
  end;
end;


//Add PNG images to spritepack if user has any addons in Sprites folder
procedure TKMSpritePack.AddImage(aFolder, aFilename: string; aIndex: Integer);
type TMaskType = (mtNone, mtPlain, mtSmart);
var
  I,K:integer;
  Tr, Tg, Tb, T: Byte;
  Thue, Tsat, Tbri: Single;
  ft: TextFile;
  MaskFile: array [TMaskType] of string;
  MaskTyp: TMaskType;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
begin
  Assert(SameText(ExtractFileExt(aFilename), '.png'));

  if aIndex > fRXData.Count then
    Allocate(aIndex);

  LoadFromPng(aFolder + aFilename, pngWidth, pngHeight, pngData);
  Assert((pngWidth <= 1024) and (pngHeight <= 1024), 'Image size should be less than 1024x1024 pixels');

  fRXData.Flag[aIndex] := Byte(pngWidth * pngHeight <> 0); //Mark as used (required for saving RXX)
  fRXData.Size[aIndex].X := pngWidth;
  fRXData.Size[aIndex].Y := pngHeight;

  SetLength(fRXData.RGBA[aIndex], pngWidth * pngHeight);
  SetLength(fRXData.Mask[aIndex], pngWidth * pngHeight); //Should allocate space for it's always comes along

  for K := 0 to pngHeight - 1 do
  for I := 0 to pngWidth - 1 do
    fRXData.RGBA[aIndex, K * pngWidth + I] := pngData[K * pngWidth + I];

  MaskFile[mtPlain] := aFolder + StringReplace(aFilename, '.png', 'm.png', [rfReplaceAll, rfIgnoreCase]);
  MaskFile[mtSmart] := aFolder + StringReplace(aFilename, '.png', 'a.png', [rfReplaceAll, rfIgnoreCase]);

  //Determine mask processing mode
  if FileExists(MaskFile[mtPlain]) then
    MaskTyp := mtPlain
  else
  if FileExists(MaskFile[mtSmart]) then
    MaskTyp := mtSmart
  else
    MaskTyp := mtNone;

  fRXData.HasMask[aIndex] := MaskTyp in [mtPlain, mtSmart];

  //Load and process the mask if it exists
  if fRXData.HasMask[aIndex] then
  begin
    //Plain masks are used 'as is'
    //Smart masks are designed for the artist, they convert color brightness into a mask

    LoadFromPng(MaskFile[MaskTyp], pngWidth, pngHeight, pngData);

    if (fRXData.Size[aIndex].X = pngWidth)
    and (fRXData.Size[aIndex].Y = pngHeight) then
    begin
      //We don't handle transparency in Masks
      for K := 0 to pngHeight - 1 do
      for I := 0 to pngWidth - 1 do
      case MaskTyp of
        mtPlain:  begin
                    //For now process just red (assume pic is greyscale)
                    fRXData.Mask[aIndex, K*pngWidth+I] := pngData[K*pngWidth+I] and $FF;
                  end;
        mtSmart:  begin
                    if Cardinal(pngData[K*pngWidth+I] and $FFFFFF) <> 0 then
                    begin
                      Tr := fRXData.RGBA[aIndex, K*pngWidth+I] and $FF;
                      Tg := fRXData.RGBA[aIndex, K*pngWidth+I] shr 8 and $FF;
                      Tb := fRXData.RGBA[aIndex, K*pngWidth+I] shr 16 and $FF;

                      //Determine color brightness
                      ConvertRGB2HSB(Tr, Tg, Tb, Thue, Tsat, Tbri);

                      //Make background RGBA black or white for more saturated colors
                      if Tbri < 0.5 then
                        fRXData.RGBA[aIndex, K*pngWidth+I] := FLAG_COLOR_DARK
                      else
                        fRXData.RGBA[aIndex, K*pngWidth+I] := FLAG_COLOR_LITE;

                      //Map brightness from 0..1 to 0..255..0
                      T := Trunc((0.5 - Abs(Tbri - 0.5)) * 510);
                      fRXData.Mask[aIndex, K*pngWidth+I] := T;
                    end
                    else
                      fRXData.Mask[aIndex, K*pngWidth+I] := 0;
                 end;
        end;
    end;
  end;

  //Read pivot info
  if FileExists(aFolder + Copy(aFilename, 1, 6) + '.txt') then
  begin
    AssignFile(ft, aFolder + Copy(aFilename, 1, 6) + '.txt');
    Reset(ft);
    ReadLn(ft, fRXData.Pivot[aIndex].X);
    ReadLn(ft, fRXData.Pivot[aIndex].Y);
    CloseFile(ft);
  end;
end;


procedure TKMSpritePack.LoadFromRXXFile(const aFileName: string; aStartingIndex: Integer = 1);
var
  I: Integer;
  RXXCount: Integer;
  InputStream: TFileStream;
  DecompressionStream: TDecompressionStream;
begin
  if SKIP_RENDER then Exit;
  if not FileExists(aFileName) then Exit;

  InputStream := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  DecompressionStream := TDecompressionStream.Create(InputStream);

  try
    DecompressionStream.Read(RXXCount, 4);
    if gLog <> nil then
      gLog.AddTime(RXInfo[fRT].FileName + ' -', RXXCount);

    if RXXCount = 0 then
      Exit;

    Allocate(aStartingIndex + RXXCount - 1);

    DecompressionStream.Read(fRXData.Flag[aStartingIndex], RXXCount);

    for I := aStartingIndex to aStartingIndex + RXXCount - 1 do
      if fRXData.Flag[I] = 1 then
      begin
        DecompressionStream.Read(fRXData.Size[I].X, 4);
        DecompressionStream.Read(fRXData.Pivot[I].X, 8);
        //Data part of each sprite is 32BPP RGBA in Remake RXX files
        SetLength(fRXData.RGBA[I], fRXData.Size[I].X * fRXData.Size[I].Y);
        SetLength(fRXData.Mask[I], fRXData.Size[I].X * fRXData.Size[I].Y);
        DecompressionStream.Read(fRXData.RGBA[I, 0], 4 * fRXData.Size[I].X * fRXData.Size[I].Y);
        DecompressionStream.Read(fRXData.HasMask[I], 1);
        if fRXData.HasMask[I] then
          DecompressionStream.Read(fRXData.Mask[I, 0], fRXData.Size[I].X * fRXData.Size[I].Y);
      end;
  finally
    DecompressionStream.Free;
    InputStream.Free;
  end;
end;


//Parse all valid files in Sprites folder and load them additionaly to or replacing original sprites
procedure TKMSpritePack.OverloadFromFolder(const aFolder: string);
  procedure ProcessFolder(const aProcFolder: string);
  var
    FileList: TStringList;
    SearchRec: TSearchRec;
    I, ID: Integer;
  begin
    if not DirectoryExists(aFolder) then Exit;
    FileList := TStringList.Create;
    try
      //PNGs
      if FindFirst(aProcFolder + IntToStr(Byte(fRT) + 1) + '_????.png', faAnyFile - faDirectory, SearchRec) = 0 then
      repeat
        FileList.Add(SearchRec.Name);
      until (FindNext(SearchRec) <> 0);
      FindClose(SearchRec);

      //PNG may be accompanied by some more files
      //#_####.png - Base texture
      //#_####a.png - Flag color mask
      //#_####.txt - Pivot info (optional)
      for I := 0 to FileList.Count - 1 do
        if TryStrToInt(Copy(FileList.Strings[I], 3, 4), ID) then
          AddImage(aProcFolder, FileList.Strings[I], ID);

      //Delete following sprites
      if FindFirst(aProcFolder + IntToStr(Byte(fRT) + 1) + '_????', faAnyFile - faDirectory, SearchRec) = 0 then
      repeat
        if TryStrToInt(Copy(SearchRec.Name, 3, 4), ID) then
          fRXData.Flag[ID] := 0;
      until (FindNext(SearchRec) <> 0);
      FindClose(SearchRec);
    finally
      FileList.Free;
    end;
  end;
begin
  if SKIP_RENDER then Exit;

  ProcessFolder(aFolder);
  ProcessFolder(aFolder + IntToStr(Byte(fRT) + 1) + PathDelim);
end;


//Export RX to Bitmaps without need to have GraphicsEditor, also this way we preserve image indexes
procedure TKMSpritePack.ExportAll(const aFolder: string);
var
  I: Integer;
  SL: TStringList;
begin
  ForceDirectories(aFolder);

  SL := TStringList.Create;

  for I := 1 to fRXData.Count do
  if fRXData.Flag[I] = 1 then
  begin
    ExportImage(aFolder + Format('%d_%.4d.png', [Byte(fRT)+1, I]), I);

    if fRXData.HasMask[I] then
      ExportMask(aFolder + Format('%d_%.4da.png', [Byte(fRT)+1, I]), I);

    //Export pivot
    SL.Clear;
    SL.Append(IntToStr(fRXData.Pivot[I].x));
    SL.Append(IntToStr(fRXData.Pivot[I].y));
    SL.SaveToFile(aFolder + Format('%d_%.4d.txt', [Byte(fRT)+1, I]));
  end;

  SL.Free;
end;


procedure TKMSpritePack.ExportImage(const aFile: string; aIndex: Integer);
var
  I, K: Integer;
  M: Byte;
  TreatMask: Boolean;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
begin
  pngWidth := fRXData.Size[aIndex].X;
  pngHeight := fRXData.Size[aIndex].Y;

  SetLength(pngData, pngWidth * pngHeight);

  //Export RGB values
  for I := 0 to pngHeight - 1 do
  for K := 0 to pngWidth - 1 do
  begin
    TreatMask := fRXData.HasMask[aIndex] and (fRXData.Mask[aIndex, I*pngWidth + K] > 0);
    if (fRT = rxHouses) and ((aIndex < 680) or (aIndex = 1657) or (aIndex = 1659) or (aIndex = 1681) or (aIndex = 1683)) then
      TreatMask := False;

    if TreatMask then
    begin
      M := fRXData.Mask[aIndex, I*pngWidth + K];

      //Replace background with corresponding brightness of Red
      if fRXData.RGBA[aIndex, I*pngWidth + K] = FLAG_COLOR_DARK then
        //Brightness < 0.5, mix with black
        pngData[I*pngWidth + K] := M
      else
        //Brightness > 0.5, mix with white
        pngData[I*pngWidth + K] := $FF + (255 - M) * $010100;
    end
    else
      pngData[I*pngWidth + K] := fRXData.RGBA[aIndex, I*pngWidth + K] and $FFFFFF;

    pngData[I*pngWidth + K] := pngData[I*pngWidth + K] or (fRXData.RGBA[aIndex, I*pngWidth + K] and $FF000000);
  end;

  //Mark pivot location with a dot
//  K := pngWidth + fRXData.Pivot[aIndex].x;
//  I := pngHeight + fRXData.Pivot[aIndex].y;
//  if InRange(I, 0, pngHeight-1) and InRange(K, 0, pngWidth-1) then
//    pngData[I*pngWidth + K] := $FFFF00FF;

  SaveToPng(pngWidth, pngHeight, pngData, aFile);
end;


procedure TKMSpritePack.ExportMask(const aFile: string; aIndex: Integer);
var
  I, K: Integer;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
begin
  pngWidth := fRXData.Size[aIndex].X;
  pngHeight := fRXData.Size[aIndex].Y;

  SetLength(pngData, pngWidth * pngHeight);

  //Export Mask
  if fRXData.HasMask[aIndex] then
  begin
    for I := 0 to pngHeight - 1 do
    for K := 0 to pngWidth - 1 do
      pngData[I * pngWidth + K] := (Byte(fRXData.Mask[aIndex, I * pngWidth + K] > 0) * $FFFFFF) or $FF000000;

    SaveToPng(pngWidth, pngHeight, pngData, aFile);
  end;
end;


function TKMSpritePack.GetSpriteColors(aCount: Word): TRGBArray;
var
  I, L, M: Integer;
  PixelCount: Word;
  R,G,B: Integer;
begin
  SetLength(Result, Min(fRXData.Count, aCount));

  for I := 1 to Min(fRXData.Count, aCount) do
  begin
    R := 0;
    G := 0;
    B := 0;
    for L := 0 to fRXData.Size[I].Y - 1 do
    for M := 0 to fRXData.Size[I].X - 1 do
    begin
      Inc(R, fRXData.RGBA[I, L * fRXData.Size[I].X + M] and $FF);
      Inc(G, fRXData.RGBA[I, L * fRXData.Size[I].X + M] shr 8 and $FF);
      Inc(B, fRXData.RGBA[I, L * fRXData.Size[I].X + M] shr 16 and $FF);
    end;
    PixelCount := fRXData.Size[I].X * fRXData.Size[I].Y;
    Result[I-1].R := Round(R / PixelCount);
    Result[I-1].G := Round(G / PixelCount);
    Result[I-1].B := Round(B / PixelCount);
  end;
end;


procedure TKMSpritePack.MakeGFX(aAlphaShadows: Boolean; aStartingIndex: Integer = 1);
var
  TexType: TTexFormat;
  BaseRAM, IdealRAM, ColorRAM, TexCount: Cardinal;
  I: Integer;
begin
  if SKIP_RENDER then Exit;
  if fRXData.Count = 0 then Exit;

  if aAlphaShadows and (fRT in [rxTrees,rxHouses,rxUnits,rxGui]) then
    TexType := tf_RGBA8
  else
    TexType := tf_RGB5A1;

  MakeGFX_BinPacking(TexType, aStartingIndex, BaseRAM, ColorRAM, TexCount);

  if LOG_EXTRA_GFX then
  begin
    IdealRAM := 0;
    for I := aStartingIndex to fRXData.Count do
    if fRXData.Flag[I] <> 0 then
      Inc(IdealRAM, fRXData.Size[I].X * fRXData.Size[I].Y * TexFormatSize[TexType]);

    gLog.AddTime(IntToStr(TexCount) + ' Textures created');
    gLog.AddNoTime(Format('%d/%d', [BaseRAM div 1024, IdealRAM div 1024]) +
                  ' Kbytes allocated/ideal for ' + RXInfo[fRT].FileName + ' GFX when using Packing');
    gLog.AddNoTime(IntToStr(ColorRAM div 1024) + ' KBytes for team colors');
  end;
end;


//This algorithm is planned to take advantage of more efficient 2D bin packing
procedure TKMSpritePack.MakeGFX_BinPacking(aTexType: TTexFormat; aStartingIndex: Word; var BaseRAM, ColorRAM, TexCount: Cardinal);
type
  TSpriteAtlas = (saBase, saMask);
  procedure PrepareAtlases(SpriteInfo: TBinArray; aMode: TSpriteAtlas; aTexType: TTexFormat);
  const ExportName: array [TSpriteAtlas] of string = ('Base', 'Mask');
  var
    I, K, L, M: Integer;
    CT, CL, Pixel: Cardinal;
    Tx: Cardinal;
    ID: Word;
    TxCoords: TKMTexCoords;
    TD: TKMCardinalArray;
  begin
    //Prepare atlases
    for I := 0 to High(SpriteInfo) do
    begin
      Assert(MakePOT(SpriteInfo[I].Width) = SpriteInfo[I].Width);
      Assert(MakePOT(SpriteInfo[I].Height) = SpriteInfo[I].Height);
      SetLength(TD, 0);
      SetLength(TD, SpriteInfo[I].Width * SpriteInfo[I].Height);

      //Copy sprite to Atlas
      for K := 0 to High(SpriteInfo[I].Sprites) do
      begin
        ID := SpriteInfo[I].Sprites[K].SpriteID;
        for L := 0 to fRXData.Size[ID].Y - 1 do
        for M := 0 to fRXData.Size[ID].X - 1 do
        begin
          CT := SpriteInfo[I].Sprites[K].PosY;
          CL := SpriteInfo[I].Sprites[K].PosX;
          Pixel := (CT + L) * SpriteInfo[I].Width + CL + M;
          if aMode = saBase then
            TD[Pixel] := fRXData.RGBA[ID, L * fRXData.Size[ID].X + M]
          else
            TD[Pixel] := $FFFFFF or (fRXData.Mask[ID, L * fRXData.Size[ID].X + M] shl 24);

          //Fill padding with edge pixels
          if fPad > 0 then
          begin
            if (M = 0) then
            begin
              TD[Pixel - 1] := TD[Pixel];
              if (L = 0) then
                TD[Pixel - SpriteInfo[I].Width - 1] := TD[Pixel]
              else
              if (L = fRXData.Size[ID].Y - 1) then
                TD[Pixel + SpriteInfo[I].Width - 1] := TD[Pixel];
            end;

            if (M = fRXData.Size[ID].X - 1) then
            begin
              TD[Pixel + 1] := TD[Pixel];
              if (L = 0) then
                TD[Pixel - SpriteInfo[I].Width + 1] := TD[Pixel]
              else
              if (L = fRXData.Size[ID].Y - 1) then
                TD[Pixel + SpriteInfo[I].Width + 1] := TD[Pixel];
            end;

            if (L = 0) then                       TD[Pixel - SpriteInfo[I].Width] := TD[Pixel];
            if (L = fRXData.Size[ID].Y - 1) then  TD[Pixel + SpriteInfo[I].Width] := TD[Pixel];
          end;

          //Sprite outline
          if OUTLINE_ALL_SPRITES and (
            (L = 0) or (M = 0)
            or (L = fRXData.Size[ID].Y - 1)
            or (M = fRXData.Size[ID].X - 1)) then
            TD[Pixel] := $FF0000FF;
        end;
      end;

      //Generate texture once
      Tx := TRender.GenTexture(SpriteInfo[I].Width, SpriteInfo[I].Height, @TD[0], aTexType);

      //Now that we know texture IDs we can fill GFXData structure
      for K := 0 to High(SpriteInfo[I].Sprites) do
      begin
        ID := SpriteInfo[I].Sprites[K].SpriteID;

        TxCoords.ID := Tx;
        TxCoords.u1 := SpriteInfo[I].Sprites[K].PosX / SpriteInfo[I].Width;
        TxCoords.v1 := SpriteInfo[I].Sprites[K].PosY / SpriteInfo[I].Height;
        TxCoords.u2 := (SpriteInfo[I].Sprites[K].PosX + fRXData.Size[ID].X) / SpriteInfo[I].Width;
        TxCoords.v2 := (SpriteInfo[I].Sprites[K].PosY + fRXData.Size[ID].Y) / SpriteInfo[I].Height;

        if aMode = saBase then
        begin
          gGFXData[fRT, ID].Tex := TxCoords;
          gGFXData[fRT, ID].PxWidth := fRXData.Size[ID].X;
          gGFXData[fRT, ID].PxHeight := fRXData.Size[ID].Y;
        end
        else
          gGFXData[fRT, ID].Alt := TxCoords;
      end;

      if aMode = saBase then
        Inc(BaseRAM, SpriteInfo[I].Width * SpriteInfo[I].Height * TexFormatSize[aTexType])
      else
        Inc(ColorRAM, SpriteInfo[I].Width * SpriteInfo[I].Height * TexFormatSize[aTexType]);

      Inc(TexCount);

      SaveTextureToPNG(SpriteInfo[I].Width, SpriteInfo[I].Height, RXInfo[fRT].FileName + '_' +
                       ExportName[aMode] + IntToStr(aStartingIndex+I), TD);
    end;
  end;

var
  I, K: Integer;
  SpriteSizes: TIndexSizeArray;
  SpriteInfo: TBinArray;
  AtlasSize, AllTilesAtlasSize: Integer;
begin
  BaseRAM := 0;
  ColorRAM := 0;
  //Prepare base atlases
  SetLength(SpriteSizes, fRXData.Count - aStartingIndex + 1);
  K := 0;
  for I := aStartingIndex to fRXData.Count do
  if (fRXData.Size[I].X * fRXData.Size[I].Y <> 0) then
  begin
    SpriteSizes[K].ID := I;
    SpriteSizes[K].X := fRXData.Size[I].X;
    SpriteSizes[K].Y := fRXData.Size[I].Y;
    Inc(K);
  end;
  SetLength(SpriteSizes, K);

  //For RX with only 1 texture we can set small size, as 512, it will be auto enlarged to POT(image size)
  if K = 1 then
    AtlasSize := 512
  else if fRT = rxTiles then
  begin
    AllTilesAtlasSize := MakePOT(Ceil(sqrt(K))*(32+2*fPad)); //Tiles are 32x32
    AtlasSize := Min(MaxAtlasSize, AllTilesAtlasSize);       //Use smallest possible atlas size for tiles (should be 1024, until many new tiles were added)
    if AtlasSize = AllTilesAtlasSize then
      ALL_TILES_IN_ONE_TEXTURE := True;
  end else
    AtlasSize := MaxAtlasSize;

  SetLength(SpriteInfo, 0);
  BinPack(SpriteSizes, AtlasSize, fPad, SpriteInfo);
  PrepareAtlases(SpriteInfo, saBase, aTexType);

  //Prepare masking atlases
  SetLength(SpriteSizes, fRXData.Count - aStartingIndex + 1);
  K := 0;
  for I := aStartingIndex to fRXData.Count do
  if (fRXData.Size[I].X * fRXData.Size[I].Y <> 0) and fRXData.HasMask[I] then
  begin
    SpriteSizes[K].ID := I;
    SpriteSizes[K].X := fRXData.Size[I].X;
    SpriteSizes[K].Y := fRXData.Size[I].Y;
    Inc(K);
  end;
  SetLength(SpriteSizes, K);

  SetLength(SpriteInfo, 0);
  BinPack(SpriteSizes, AtlasSize, fPad, SpriteInfo);
  PrepareAtlases(SpriteInfo, saMask, tf_Alpha8);
end;


procedure TKMSpritePack.SaveTextureToPNG(aWidth, aHeight: Word; aFilename: string; const Data: TKMCardinalArray);
var
  I, K: Word;
  Folder: string;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
begin
  if not EXPORT_SPRITE_ATLASES then Exit;

  Folder := ExeDir + 'Export'+PathDelim+'GenTextures'+PathDelim;
  ForceDirectories(Folder);

  pngWidth := aWidth;
  pngHeight := aHeight;
  SetLength(pngData, pngWidth * pngHeight);

  for I := 0 to aHeight - 1 do
  for K := 0 to aWidth - 1 do
    pngData[I * aWidth + K] := (PCardinal(Cardinal(@Data[0]) + (I * aWidth + K) * 4))^;

  SaveToPng(pngWidth, pngHeight, pngData, Folder + aFilename + '.png');
end;


{ TKMResSprites }
constructor TKMResSprites.Create(aStepProgress: TEvent; aStepCaption: TUnicodeStringEvent);
var
  RT: TRXType;
begin
  inherited Create;

  for RT := Low(TRXType) to High(TRXType) do
    fSprites[RT] := TKMSpritePack.Create(RT);

  fStepProgress := aStepProgress;
  fStepCaption := aStepCaption;
end;


destructor TKMResSprites.Destroy;
var
  RT: TRXType;
begin
  for RT := Low(TRXType) to High(TRXType) do
    fSprites[RT].Free;

  inherited;
end;


//Clear unused RAM
procedure TKMResSprites.ClearTemp;
var RT: TRXType;
begin
  for RT := Low(TRXType) to High(TRXType) do
    fSprites[RT].ClearTemp;
end;


procedure TKMResSprites.GenerateTerrainTransitions(aSprites: TKMSpritePack);
//  procedure Rotate(aAngle: Byte; aXFrom, aYFrom: Integer; var aXTo, aYTo: Integer; aBase: Integer);
//  begin
//    case aAngle of
//      0:  begin
//            aXTo := aXFrom;
//            aYTo := aYFrom;
//          end;
//      1:  begin
//            aYTo := aXFrom;
//            aXTo := aBase - aYFrom;
//          end;
//      2:  begin
//            aXTo := aBase - aXFrom;
//            aYTo := aBase - aYFrom;
//          end;
//      3:  begin
//            aXTo := aYFrom;
//            aYTo := aBase - aXFrom;
//          end
//      else raise Exception.Create('Wrong Rotate angle');
//    end;
//
//  end;

type
  PKMMaskFullType = ^TKMMaskFullType;
  TKMMaskFullType = record
    MType: TKMTileMaskType;
    SubType: Byte;
  end;

var
  I: TKMTerrainKind;
  J: TKMTileMaskType;
  TerrainId, MaskId: Word;
  MaskFullType: PKMMaskFullType;
  TexId,{ K,} C, L, M, P, Q, MId, Tmp: Integer;
  StraightPixel{, RotatePixel}: Cardinal;
  GeneratedMasks: TStringList;
begin
  TexId := Length(aSprites.fRXData.RGBA) + 1;
  fGenTexIdStartI := TexId;
  aSprites.Allocate(TexId + 3*(Integer(High(TKMTerrainKind)))*Integer(High(TKMTileMaskType)));
  SetLength(fGenTerrainToTerKind, 3*(Integer(High(TKMTerrainKind)))*Integer(High(TKMTileMaskType)));
  GeneratedMasks := TStringList.Create;
//  K := 0;
  C := 0;
  try
    for I := Low(TKMTerrainKind) to High(TKMTerrainKind) do
    begin
      if I = tkCustom then Continue;

      TerrainId := BASE_TERRAIN[I] + 1; // in fRXData Tiles are 1-based
      for J := Low(TKMTileMaskType) to High(TKMTileMaskType) do
      begin
        if J = mt_None then Continue;

        for C := 0 to 1 do //Mask subtypes (actual masks for layers)
        begin
          MaskId := TILE_MASKS_FOR_LAYERS[J, C] + 1;
          if MaskId = 0 then Continue;   //Ignore non existent masks

          // We could use same mask image for several masktypes/subtypes
          MId := GeneratedMasks.IndexOf(IntToStr(MaskId));
          if MId > -1 then
          begin
            MaskFullType := PKMMaskFullType(GeneratedMasks.Objects[MId]);

            Tmp := gGenTerrainTransitions[I, MaskFullType.MType, MaskFullType.SubType];
            if Tmp <> 0 then
            begin
              gGenTerrainTransitions[I, J, C] := Tmp;
              Continue;
            end;
          end else begin
            System.New(MaskFullType); // := TKMMaskFullType.Create;
            MaskFullType.MType := J;
            MaskFullType.SubType := C;
            GeneratedMasks.AddObject(IntToStr(MaskId), TObject(MaskFullType));
          end;

  //        for K := 0 to 3 do //Rotation
  //        begin
            SetLength(aSprites.fRXData.RGBA[TexId], aSprites.fRXData.Size[TerrainId].X*aSprites.fRXData.Size[TerrainId].Y); //32*32 actually...
            SetLength(aSprites.fRXData.Mask[TexId], aSprites.fRXData.Size[TerrainId].X*aSprites.fRXData.Size[TerrainId].Y);
            aSprites.fRXData.Flag[TexId] := aSprites.fRXData.Flag[TerrainId];
            aSprites.fRXData.Size[TexId].X := aSprites.fRXData.Size[TerrainId].X;
            aSprites.fRXData.Size[TexId].Y := aSprites.fRXData.Size[TerrainId].Y;
            aSprites.fRXData.Pivot[TexId] := aSprites.fRXData.Pivot[TerrainId];
            aSprites.fRXData.HasMask[TexId] := False;
            gGenTerrainTransitions[I, J, C] := TexId - 1; //TexId is 1-based, but textures we use - 0 based
  //          gLog.AddTime(Format('TerKind: %10s Mask: %10s TexId: %d ', [GetEnumName(TypeInfo(TKMTerrainKind), Integer(I)),
  //                                                        GetEnumName(TypeInfo(TKMTileMaskType), Integer(J)), TexId]));

            fGenTerrainToTerKind[TexId - fGenTexIdStartI] := I;
  //          fGenTerrainToTerKind.Add(IntToStr(TexId) + '=' + IntToStr(Integer(I)));
            for L := 0 to aSprites.fRXData.Size[TerrainId].Y - 1 do
              for M := 0 to aSprites.fRXData.Size[TerrainId].X - 1 do
              begin
  //              Rotate(K, L, M, P, Q, aSprites.fRXData.Size[TerrainId].X - 1);
                StraightPixel := L * aSprites.fRXData.Size[TerrainId].X  + M;
  //              RotatePixel := StraightPixel; //P * aSprites.fRXData.Size[TerrainId].X  + Q;
                aSprites.fRXData.RGBA[TexId, StraightPixel] := ($FFFFFF or (aSprites.fRXData.RGBA[MaskId, StraightPixel] shl 24))
                                                   and aSprites.fRXData.RGBA[TerrainId, StraightPixel{RotatePixel}];
              end;
            Inc(TexId);
  //        end;
        end;
      end;
    end;
    aSprites.Allocate(TexId);
  finally
    for Q := 0 to GeneratedMasks.Count - 1 do
      System.Dispose(PKMMaskFullType(GeneratedMasks.Objects[Q]));
    FreeAndNil(GeneratedMasks);
  end;
end;


function TKMResSprites.GetGenTerrainKindByTerrain(aTerrain: Integer): TKMTerrainKind;
begin
  Result := fGenTerrainToTerKind[aTerrain + 1 - fGenTexIdStartI]; //TexId is 1-based, but textures we use - 0 based
end;


function TKMResSprites.GetRXFileName(aRX: TRXType): string;
begin
  Result := RXInfo[aRX].FileName;
end;


function TKMResSprites.GetSprites(aRT: TRXType): TKMSpritePack;
begin
  Result := fSprites[aRT];
end;


procedure TKMResSprites.LoadMenuResources;
var
  RT: TRXType;
begin
  for RT := Low(TRXType) to High(TRXType) do
    if RXInfo[RT].Usage = ruMenu then
    begin
      fStepCaption('Reading ' + RXInfo[RT].FileName + ' ...');
      LoadSprites(RT, RT = rxGUI); //Only GUI needs alpha shadows
      fSprites[RT].MakeGFX(RT = rxGUI);
      fStepProgress;
    end;
end;


procedure TKMResSprites.LoadGameResources(aAlphaShadows: Boolean);
var
  RT: TRXType;
begin
  //Remember which version we load, so if it changes inbetween games we reload it
  fAlphaShadows := aAlphaShadows;

  for RT := Low(TRXType) to High(TRXType) do
  if RXInfo[RT].Usage = ruGame then
  begin
    fStepCaption(gResTexts[RXInfo[RT].LoadingTextID]);
    gLog.AddTime('Reading ' + RXInfo[RT].FileName + '.rx');
    LoadSprites(RT, fAlphaShadows);
    fSprites[RT].MakeGFX(fAlphaShadows);
  end;
end;


//Try to load RXX first, then RX, then use Folder
function TKMResSprites.LoadSprites(aRT: TRXType; aAlphaShadows: Boolean): Boolean;
begin
  Result := False;
  if aAlphaShadows and FileExists(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[aRT].FileName + '_a.rxx') then
  begin
    fSprites[aRT].LoadFromRXXFile(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[aRT].FileName + '_a.rxx');
    Result := True;
  end
  else
  if FileExists(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[aRT].FileName + '.rxx') then
  begin
    fSprites[aRT].LoadFromRXXFile(ExeDir + 'data' + PathDelim + 'Sprites' + PathDelim + RXInfo[aRT].FileName + '.rxx');
    Result := True;
  end
  else
    Exit;

  fSprites[aRT].OverloadFromFolder(ExeDir + 'Sprites' + PathDelim);

  if aRT = rxTiles then
    GenerateTerrainTransitions(fSprites[aRT]);

end;


class function TKMResSprites.AllTilesOnOneAtlas: Boolean;
begin
  Result := ALL_TILES_IN_ONE_TEXTURE;
end;


class procedure TKMResSprites.SetMaxAtlasSize(aMaxSupportedTxSize: Integer);
begin
  MaxAtlasSize := Min(aMaxSupportedTxSize, MAX_GAME_ATLAS_SIZE);
end;


procedure TKMResSprites.ExportToPNG(aRT: TRXType);
begin
  if LoadSprites(aRT, False) then
  begin
    fSprites[aRT].ExportAll(ExeDir + 'Export' + PathDelim + RXInfo[aRT].FileName + '.rx' + PathDelim);
    ClearTemp;
  end;
end;


end.
