unit KM_GUIGameSpectator;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Math, StrUtils, SysUtils,
  KM_Controls, KM_HandsCollection, KM_Defaults, KromOGLUtils, KM_Hand, KM_Units,
  KM_ResWares, KM_ResHouses, KM_Pics, KM_CommonTypes, KM_Points, KM_Houses;

const
  GUI_SPECTATOR_ITEM_WIDTH = 28;
  GUI_SPECTATOR_ITEM_HEIGHT = 34;
  GUI_SPECTATOR_ITEM_SPLITE_H = 4;
  GUI_SPECTATOR_ITEM_SPLITE_V = 4;
  GUI_SPECTATOR_ITEM_TEAM = 16;

  GUI_SPECTATOR_HEADER_HEIGHT = 14;

  GUI_SPECTATOR_HEADER_FLAG = 1164;
  GUI_SPECTATOR_HEADER_FLAG_FRAME = 5;


type
  TKMGUIGameSpectatorItem = class(TKMControl)
  private
    fHandID: Integer;
    fImageID: Word;
    fValue: String;
    fAdditionalValue: String;
    fProgress: Single;
    fItemTag: Integer;
    FOnItemClick: TIntegerEvent;
    FDoHighlight: TBoolIntFuncSimple;
    procedure ItemClicked(Sender: TObject);
  public
    constructor Create(aParent: TKMPanel; ATag: Integer; AImageID: Word; const AHint: String; AHandID: Integer;
                       aDoHighlight: TBoolIntFuncSimple; aOnItemClick: TIntegerEvent);
    property ItemTag: Integer read FItemTag;
    property Value: String read FValue write FValue;
    property AdditionalValue: String read FAdditionalValue write FAdditionalValue;
    property Progress: Single read FProgress write FProgress;
    procedure Paint; override;
  end;

  TKMGUIGameSpectatorItemLine = class;
  TKMGUIGameSpectatorItemLineClass = class of TKMGUIGameSpectatorItemLine;

  TKMGUIGameSpectatorItemLine = class(TKMPanel)
  private
    FShowEmptyItems: Boolean;
    FOnJumpToPlayer: TIntegerEvent;
    FSetViewportPos: TPointFEvent;
    FHandIndex: Integer;
    FAnimStep: Cardinal;
    FItems: array of TKMGUIGameSpectatorItem;
    procedure DoubleClicked(Sender: TObject);
    procedure ItemClicked(aItemTag: Integer);
    procedure Update;
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem; virtual; abstract;
    function GetTagCount: Integer; virtual; abstract;
    function GetTag(AIndex: Integer): Integer; virtual; abstract;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; virtual; abstract;
    function GetAdditionalValue(AHandIndex: Integer; ATag: Integer): String; virtual;
    function GetProgress(AHandIndex: Integer; ATag: Integer): Single; virtual;
    function GetLoc(AHandIndex: Integer; ATag: Integer): TKMPointF; virtual;
    property SetViewportPos: TPointFEvent read FSetViewportPos;
    function DontHighlight(aIndex: Integer): Boolean;
    function DoHighlight(aIndex: Integer): Boolean;
  public
    constructor Create(aParent: TKMPanel; AHandIndex: Integer; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent); virtual;
    procedure UpdateState(aTickCount: Cardinal); override;
    procedure Paint; override;
    property HandIndex: Integer read FHandIndex;
  end;


  TKMGUIGameSpectatorItemLineResources = class(TKMGUIGameSpectatorItemLine)
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;


  TKMGUIGameSpectatorItemLineWarFare = class(TKMGUIGameSpectatorItemLine)
  private
    class function GetIcon(aTag: Integer): Word;
    class function GetTitle(aTag: Integer): UnicodeString;
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  public
    constructor Create(aParent: TKMPanel; AHandIndex: Integer; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent); override;
  end;

  // Buildings
  TKMGUIGameSpectatorItemLineCustomBuildings = class(TKMGUIGameSpectatorItemLine)
  private
    fHouseSketch: TKMHouseSketchEdit;
    fLastHouseUIDs: array [HOUSE_MIN..HOUSE_MAX] of Cardinal;
    procedure ResetUIDs;
    function CheckHighlight(aIndex: Integer): Boolean;
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetLoc(AHandIndex: Integer; ATag: Integer): TKMPointF; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; virtual; abstract;
  public
    constructor Create(aParent: TKMPanel; AHandIndex: Integer; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent); override;
    destructor Destroy; override;
  end;

  TKMGUIGameSpectatorItemLineConstructing = class(TKMGUIGameSpectatorItemLineCustomBuildings)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
    function GetProgress(AHandIndex: Integer; ATag: Integer): Single; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; override;
  end;

  TKMGUIGameSpectatorItemLineHouses = class(TKMGUIGameSpectatorItemLineCustomBuildings)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
    function GetAdditionalValue(AHandIndex: Integer; ATag: Integer): String; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; override;
  end;

  // Units
  TKMGUIGameSpectatorItemLinePopulation = class(TKMGUIGameSpectatorItemLine)
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLineArmy = class(TKMGUIGameSpectatorItemLine)
  private
    fLastWarriorUIDs: array [WARRIOR_MIN..WARRIOR_MAX] of Cardinal;
    procedure ResetUIDs;
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetLoc(AHandIndex: Integer; ATag: Integer): TKMPointF; override;
    function CheckHighlight(aIndex: Integer): Boolean; virtual;
  end;

  TKMGUIGameSpectatorItemLineArmyInstantenious = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
    function CheckHighlight(aIndex: Integer): Boolean; override;
  end;

  TKMGUIGameSpectatorItemLineArmyTotal = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLineArmyKilling = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLineArmyLost = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  ///

  TKMGUIGameSpectator = class
  private
    FDropBoxPanel: TKMPanel;
    FDropBox: TKMDropList;
    FLastIndex: Integer;

    FOnJumpToPlayer: TIntegerEvent;
    FSetViewportPos: TPointFEvent;

    FLines: array of array[0..MAX_HANDS - 1] of TKMGUIGameSpectatorItemLine;

    procedure AddLineType(AIndex: Integer; ALineClass: TKMGUIGameSpectatorItemLineClass);
    procedure ChangePage(Sender: TObject);
  public
    constructor Create(aParent: TKMPanel; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent);

    procedure CloseDropBox;
  end;

implementation

uses
  KM_RenderUI, KM_ResFonts, KM_Resource, KM_ResTexts, KM_ResUnits, KM_UnitGroup;

{ TKMGUIGameSpectatorItem }
constructor TKMGUIGameSpectatorItem.Create(aParent: TKMPanel; ATag: Integer; AImageID: Word; const AHint: String;
                                           AHandID: Integer; aDoHighlight: TBoolIntFuncSimple; aOnItemClick: TIntegerEvent);
begin
  inherited Create(aParent, 0, 0, GUI_SPECTATOR_ITEM_WIDTH, GUI_SPECTATOR_ITEM_HEIGHT);

  FItemTag := ATag;
  Hint := AHint;
  fHandID := AHandID;
  FImageID := AImageID;
  FValue := '';
  FAdditionalValue := '';
  FProgress := -1;
  FDoHighlight := aDoHighlight;
  FOnItemClick := aOnItemClick;
  OnClick := ItemClicked;
end;

procedure TKMGUIGameSpectatorItem.ItemClicked(Sender: TObject);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(FItemTag);
end;

procedure TKMGUIGameSpectatorItem.Paint;
var
  PaintLightness: Single;
begin
  inherited;

  TKMRenderUI.WriteBevel(AbsLeft, AbsTop, Width, Height);

  PaintLightness := DEFAULT_HIGHLIGHT_COEF * (Byte((csOver in State) and FDoHighlight(FItemTag)));
  TKMRenderUI.WritePicture(AbsLeft + 2, AbsTop, Width - 4, Height - 4, [], rxGui, FImageID, True,
                           gHands[fHandID].FlagColor, PaintLightness);

  if FProgress >= 0 then
    TKMRenderUI.WritePercentBar(AbsLeft, AbsTop + Height - 6, Width, 6, FProgress, 0);

  TKMRenderUI.WriteText(AbsLeft, AbsTop + Height - 16, Width, FValue, fntGrey, taCenter, $FFFFFFFF);
  if FAdditionalValue <> '' then
    TKMRenderUI.WriteText(AbsLeft - 2, AbsTop - 2, Width, FAdditionalValue, fntGrey, taRight, $FFFFFFFF);
end;

{ TKMGUIGameSpectatorItemLine }
constructor TKMGUIGameSpectatorItemLine.Create(aParent: TKMPanel; AHandIndex: Integer; aOnJumpToPlayer: TIntegerEvent;
                                               aSetViewportPos: TPointFEvent);
var
  I: Integer;
begin
  inherited Create(aParent, aParent.Width, 32 + AHandIndex * (GUI_SPECTATOR_ITEM_HEIGHT + GUI_SPECTATOR_ITEM_SPLITE_V), 0, GUI_SPECTATOR_ITEM_HEIGHT + GUI_SPECTATOR_HEADER_HEIGHT + GUI_SPECTATOR_ITEM_SPLITE_V);
  fOnJumpToPlayer := aOnJumpToPlayer;
  fSetViewportPos := aSetViewportPos;
  OnClick := DoubleClicked;
  Anchors := [anTop, anRight];
  FAnimStep := 0;
  Focusable := False;
  FShowEmptyItems := False;
  FHandIndex := AHandIndex;
  SetLength(fItems, GetTagCount);
  for I := 0 to GetTagCount - 1 do
    fItems[I] := CreateItem(AHandIndex, GetTag(I), ItemClicked);
end;

procedure TKMGUIGameSpectatorItemLine.DoubleClicked(Sender: TObject);
begin
  if Assigned(fOnJumpToPlayer) then
    fOnJumpToPlayer(FHandIndex);
end;

procedure TKMGUIGameSpectatorItemLine.ItemClicked(aItemTag: Integer);
var
  Loc: TKMPointF;
begin
  if Assigned(FSetViewportPos) then
  begin
    Loc := GetLoc(FHandIndex, aItemTag);
    if Loc <> KMPOINTF_INVALID_TILE then
      FSetViewportPos(Loc);
  end;
end;

procedure TKMGUIGameSpectatorItemLine.Update;
begin
  UpdateState(0); //We do not use tick count actually here
end;

function TKMGUIGameSpectatorItemLine.DontHighlight(aIndex: Integer): Boolean;
begin
  Result := False;
end;

function TKMGUIGameSpectatorItemLine.DoHighlight(aIndex: Integer): Boolean;
begin
  Result := True;
end;

procedure TKMGUIGameSpectatorItemLine.UpdateState(aTickCount: Cardinal);
var
  i, Position, Count: Integer;
  Str: UnicodeString;
begin
  inherited;
  if not Visible then
    Exit;

  Inc(FAnimStep);

  Count := 0;
  for i := 0 to GetTagCount - 1 do
  begin
    fItems[i].Value := GetValue(FHandIndex, GetTag(i));
    fItems[i].AdditionalValue := GetAdditionalValue(FHandIndex, GetTag(i));
    fItems[i].Progress := GetProgress(FHandIndex, GetTag(i));
    fItems[i].Visible := FShowEmptyItems or (fItems[i].Value <> '') or (fItems[i].AdditionalValue <> '') or (fItems[i].Progress >= 0);
    if fItems[i].Visible then
      Inc(Count);
  end;

  Str := IfThen(gHands[FHandIndex].OwnerNiknameU <> '', gHands[FHandIndex].OwnerNiknameU, gHands[FHandIndex].OwnerName);
  Width := Max(Count * (GUI_SPECTATOR_ITEM_WIDTH + GUI_SPECTATOR_ITEM_SPLITE_H) + GUI_SPECTATOR_ITEM_SPLITE_H, gRes.Fonts[fntGrey].GetTextSize(Str).X + 32 + 4);
  Left := Parent.Width - Width;

  Position := Width - GUI_SPECTATOR_ITEM_SPLITE_H - GUI_SPECTATOR_ITEM_WIDTH;
  for i := 0 to GetTagCount - 1 do
    if fItems[i].Visible then
    begin
      fItems[i].Top := GUI_SPECTATOR_HEADER_HEIGHT;
      fItems[i].Left := Position;
      Dec(Position, GUI_SPECTATOR_ITEM_WIDTH + GUI_SPECTATOR_ITEM_SPLITE_H);
    end;
end;

function TKMGUIGameSpectatorItemLine.GetAdditionalValue(AHandIndex: Integer; ATag: Integer): String;
begin
  Result := '';
end;


function TKMGUIGameSpectatorItemLine.GetLoc(AHandIndex: Integer; ATag: Integer): TKMPointF;
begin
  Result := KMPOINTF_INVALID_TILE;
end;


function TKMGUIGameSpectatorItemLine.GetProgress(AHandIndex: Integer; ATag: Integer): Single;
begin
  Result := -1;
end;

procedure TKMGUIGameSpectatorItemLine.Paint;
var
  Str: UnicodeString;
  ID: Integer;
begin
  TKMRenderUI.WriteBevel(AbsLeft, AbsTop, Width, Height);
  inherited;
  Str := IfThen(gHands[FHandIndex].OwnerNiknameU <> '', gHands[FHandIndex].OwnerNiknameU, gHands[FHandIndex].OwnerName);
  TKMRenderUI.WriteText(AbsLeft, AbsTop, Width - 32, Str, fntGrey, taRight, $FFFFFFFF);

  ID := GUI_SPECTATOR_HEADER_FLAG + FAnimStep mod GUI_SPECTATOR_HEADER_FLAG_FRAME;
  TKMRenderUI.WritePicture(AbsLeft + Width - 32, AbsTop, 32, GUI_SPECTATOR_HEADER_HEIGHT, [], rxHouses, ID, True, gHands[FHandIndex].FlagColor);
end;

{ TKMGUIGameSpectatorItemLineResources }
function TKMGUIGameSpectatorItemLineResources.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag, gRes.Wares[TKMWareType(ATag)].GUIIcon, gRes.Wares[TKmWareType(ATag)].Title,
                                           FHandIndex, DontHighlight, aOnItemClick);
  Result.Visible := False;
end;

function TKMGUIGameSpectatorItemLineResources.GetTagCount: Integer;
begin
  Result := Integer(WARE_MAX) - Integer(WARE_MIN) + 1;
end;

function TKMGUIGameSpectatorItemLineResources.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(WARE_MIN) + AIndex;
end;

function TKMGUIGameSpectatorItemLineResources.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetWareBalance(TKMWareType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;


{ TKMGUIGameSpectatorItemLineWareFare }
constructor TKMGUIGameSpectatorItemLineWarFare.Create(aParent: TKMPanel; AHandIndex: Integer; aOnJumpToPlayer: TIntegerEvent;
                                                       aSetViewportPos: TPointFEvent);
begin
  inherited Create(aParent, AHandIndex, aOnJumpToPlayer, aSetViewportPos);
  FShowEmptyItems := True;
end;

function TKMGUIGameSpectatorItemLineWarFare.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           TKMGUIGameSpectatorItemLineWarFare.GetIcon(ATag),
                                           TKMGUIGameSpectatorItemLineWarFare.GetTitle(ATag), FHandIndex,
                                           DontHighlight, aOnItemClick);
  Result.Visible := False;
end;

class function TKMGUIGameSpectatorItemLineWarFare.GetIcon(aTag: Integer): Word;
begin
  if aTag = -1 then
    Result := gRes.Units[utRecruit].GUIIcon
  else
    Result := gRes.Wares[TKMWareType(ATag)].GUIIcon;
end;

class function TKMGUIGameSpectatorItemLineWarFare.GetTitle(aTag: Integer): UnicodeString;
begin
  if aTag = -1 then
    Result := gRes.Units[utRecruit].GUIName
  else
    Result := gRes.Wares[TKMWareType(ATag)].Title;
end;

function TKMGUIGameSpectatorItemLineWarFare.GetTagCount: Integer;
begin
  Result := Integer(WARFARE_MAX) - Integer(WARFARE_MIN) + 1 + 1; //+1 for recruit
end;

function TKMGUIGameSpectatorItemLineWarFare.GetTag(AIndex: Integer): Integer;
begin
  Result := IfThen(AIndex = 0, -1, Integer(WARFARE_MAX) - AIndex + 1); //Recruit is the last
end;

function TKMGUIGameSpectatorItemLineWarFare.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  if aTag = -1 then
    Value := gHands[AHandIndex].Stats.GetUnitQty(utRecruit)
  else
    Value := gHands[AHandIndex].Stats.GetWareBalance(TKMWareType(ATag));

  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

{ TKMGUIGameSpectatorItemLineCustomBuildings }
constructor TKMGUIGameSpectatorItemLineCustomBuildings.Create(aParent: TKMPanel; AHandIndex: Integer;
                                                              aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent);
begin
  inherited Create(aParent, AHandIndex, aOnJumpToPlayer, aSetViewportPos);

  fHouseSketch := TKMHouseSketchEdit.Create;
end;

destructor TKMGUIGameSpectatorItemLineCustomBuildings.Destroy;
begin
  FreeAndNil(fHouseSketch);

  inherited;
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Houses[TKMHouseType(ATag)].GUIIcon,
                                           gRes.Houses[TKMHouseType(ATag)].HouseName, FHandIndex,
                                           CheckHighlight, aOnItemClick);
  Result.Visible := False;
  ResetUIDs;
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := gHands[FHandIndex].Stats.GetHouseTotal(TKMHouseType(aIndex))
          - gHands[FHandIndex].Stats.GetHousePlans(TKMHouseType(aIndex)) > 0;
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.GetTagCount: Integer;
begin
  Result := Integer(HOUSE_MAX) - Integer(HOUSE_MIN) + 1;
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(HOUSE_MIN) + AIndex;
end;

procedure TKMGUIGameSpectatorItemLineCustomBuildings.ResetUIDs;
var
  HT: TKMHouseType;
begin
  for HT := Low(fLastHouseUIDs) to High(fLastHouseUIDs) do
    fLastHouseUIDs[HT] := 0;
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.GetLoc(AHandIndex: Integer; ATag: Integer): TKMPointF;
var
  HT: TKMHouseType;
begin
  Result := KMPOINTF_INVALID_TILE;

  HT := TKMHouseType(ATag);

  gHands[AHandIndex].GetNextHouseWSameType(HT, fLastHouseUIDs[HT], fHouseSketch, [hstHouse, hstHousePlan], GetVerifyHouseSketchFn());
  if not fHouseSketch.IsEmpty  then
  begin
    gMySpectator.Highlight := fHouseSketch;
    Result := KMPointF(fHouseSketch.Entrance); //get position on that house
    fLastHouseUIDs[HT] := fHouseSketch.UID;
  end;
end;

{ TKMGUIGameSpectatorItemLineBuild }
function TKMGUIGameSpectatorItemLineConstructing.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetHouseWip(TKMHouseType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

function TKMGUIGameSpectatorItemLineConstructing.GetProgress(AHandIndex: Integer; ATag: Integer): Single;
var
  i: Integer;
  House, HouseProgress: TKMHouse;
  HouseType: TKMHouseType;
begin
  Result := inherited;
  if GetValue(AHandIndex, ATag) = '' then
    Exit;

  HouseType := TKMHouseType(ATag);
  HouseProgress := nil;
  for i := 0 to gHands[AHandIndex].Houses.Count - 1 do
  begin
    House := gHands[AHandIndex].Houses[i];
    if (House.HouseType = HouseType) and (House.BuildingState in [hbsWood, hbsStone]) and (not Assigned(HouseProgress) or (House.BuildingProgress > HouseProgress.BuildingProgress)) then
      HouseProgress := House;
  end;

  if Assigned(HouseProgress) then
    Result := HouseProgress.BuildingProgress / HouseProgress.MaxHealth;
end;

function TKMGUIGameSpectatorItemLineConstructing.GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn;
begin
  Result := function(aSketch: TKMHouseSketch): Boolean
    begin
      Result := not (aSketch is TKMHouse) or not TKMHouse(aSketch).IsComplete;
    end;
end;

{ TKMGUIGameSpectatorItemLineBuildings }
function TKMGUIGameSpectatorItemLineHouses.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetHouseQty(TKMHouseType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

function TKMGUIGameSpectatorItemLineHouses.GetAdditionalValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetHouseWip(TKMHouseType(ATag));
  Result := IfThen(Value > 0, '+' + IntToStr(Value), '');
end;

function TKMGUIGameSpectatorItemLineHouses.GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn;
begin
  Result := function(aSketch: TKMHouseSketch): Boolean
    begin
      Result := True;
    end;
end;


{ TKMGUIGameSpectatorItemLinePopulation }
function TKMGUIGameSpectatorItemLinePopulation.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Units[TKMUnitType(ATag)].GUIIcon,
                                           gRes.Units[TKMUnitType(ATag)].GUIName, FHandIndex,
                                           DontHighlight, aOnItemClick);
end;

function TKMGUIGameSpectatorItemLinePopulation.GetTagCount: Integer;
begin
  Result := Integer(CITIZEN_MAX) - Integer(CITIZEN_MIN) + 1;
end;

function TKMGUIGameSpectatorItemLinePopulation.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(CITIZEN_MIN) + AIndex;
end;

function TKMGUIGameSpectatorItemLinePopulation.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetUnitQty(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;


{ TKMGUIGameSpectatorItemLineArmy }
function TKMGUIGameSpectatorItemLineArmy.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntegerEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Units[TKMUnitType(ATag)].GUIIcon,
                                           gRes.Units[TKMUnitType(ATag)].GUIName, FHandIndex,
                                           CheckHighlight, aOnItemClick);
  ResetUIDs;
end;

function TKMGUIGameSpectatorItemLineArmy.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := gHands[FHandIndex].Stats.GetUnitQty(TKMUnitType(aIndex)) > 0;
end;

function TKMGUIGameSpectatorItemLineArmy.GetTagCount: Integer;
begin
  Result := Integer(WARRIOR_MAX) - Integer(WARRIOR_MIN) + 1;
end;

function TKMGUIGameSpectatorItemLineArmy.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(WARRIOR_MIN) + AIndex;
end;

procedure TKMGUIGameSpectatorItemLineArmy.ResetUIDs;
var
  UT: TKMUnitType;
begin
  for UT := Low(fLastWarriorUIDs) to High(fLastWarriorUIDs) do
    fLastWarriorUIDs[UT] := 0;
end;

function TKMGUIGameSpectatorItemLineArmy.GetLoc(AHandIndex: Integer; ATag: Integer): TKMPointF;
var
  NextGroup: TKMUnitGroup;
  UT: TKMUnitType;
begin
  Result := KMPOINTF_INVALID_TILE;

  UT := TKMUnitType(ATag);

  NextGroup := gHands[AHandIndex].GetNextGroupWSameType(UT, fLastWarriorUIDs[UT]);
  if NextGroup <> nil then
  begin
    Result := NextGroup.FlagBearer.PositionF; //get position on that warrior
    fLastWarriorUIDs[UT] := NextGroup.UID;
  end;
end;


{ TKMGUIGameSpectatorItemLineArmyInstantenious }
function TKMGUIGameSpectatorItemLineArmyInstantenious.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetUnitQty(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

function TKMGUIGameSpectatorItemLineArmyInstantenious.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := True; //We always have soldiers to set viewport on
end;


{ TKMGUIGameSpectatorItemLineArmyTotal }
function TKMGUIGameSpectatorItemLineArmyTotal.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetWarriorsTotal(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;


{ TKMGUIGameSpectatorItemLineArmyKilling }
function TKMGUIGameSpectatorItemLineArmyKilling.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetUnitKilledQty(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

{ TKMGUIGameSpectatorItemLineArmyLost }
function TKMGUIGameSpectatorItemLineArmyLost.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetUnitLostQty(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

{ TKMGUIGameSpectator }
constructor TKMGUIGameSpectator.Create(aParent: TKMPanel; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent);
const
  DROPBOX_W = 270;
begin
  inherited Create;

  fOnJumpToPlayer := aOnJumpToPlayer;
  fSetViewportPos := aSetViewportPos;

  FDropBoxPanel := TKMPanel.Create(aParent, aParent.Width - DROPBOX_W - 10, 0, DROPBOX_W + 10, 30);
  FDropBoxPanel.Anchors := [anTop, anRight];
  //FDropBoxPanel.Focusable := false;
  FDropBoxPanel.Show;

  FLastIndex := 0;

  SetLength(FLines, 10);

  AddLineType(0, nil);
  AddLineType(1, TKMGUIGameSpectatorItemLineResources);
  AddLineType(2, TKMGUIGameSpectatorItemLineWarFare);
  AddLineType(3, TKMGUIGameSpectatorItemLineHouses);
  AddLineType(4, TKMGUIGameSpectatorItemLineConstructing);
  AddLineType(5, TKMGUIGameSpectatorItemLinePopulation);
  AddLineType(6, TKMGUIGameSpectatorItemLineArmyInstantenious);
  AddLineType(7, TKMGUIGameSpectatorItemLineArmyTotal);
  AddLineType(8, TKMGUIGameSpectatorItemLineArmyKilling);
  AddLineType(9, TKMGUIGameSpectatorItemLineArmyLost);

  FDropBox := TKMDropList.Create(FDropBoxPanel, 5, 5, DROPBOX_W, 20, fntMetal, '', bsGame);
  FDropBox.OnChange := ChangePage;

  FDropBox.Add(gResTexts[TX_WORD_NONE]);
  FDropBox.Add(gResTexts[TX_WORD_RESOURCES]);
  FDropBox.Add(gResTexts[TX_RESOURCES_WARFARE]);
  FDropBox.Add(gResTexts[TX_WORD_HOUSES]);
  FDropBox.Add(gResTexts[TX_WORD_CONSTRUCTING]);
  FDropBox.Add(gResTexts[TX_WORD_CITIZENS]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_INSTANTANEOUS]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_TOTAL_EQUIPPED]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_DEFEATED]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_LOST]);

  FDropBox.ItemIndex := 0;
end;

procedure TKMGUIGameSpectator.AddLineType(AIndex: Integer; ALineClass: TKMGUIGameSpectatorItemLineClass);
var
  i: Integer;
begin
  if ALineClass <> nil then
    for i := 0 to MAX_HANDS - 1 do
    begin
      FLines[AIndex, i] := ALineClass.Create(FDropBoxPanel.Parent, i, fOnJumpToPlayer, fSetViewportPos);
      FLines[AIndex, i].Visible := False;
    end;
end;

procedure TKMGUIGameSpectator.ChangePage(Sender: TObject);
var
  I, J: Integer;
  Teams: TKMByteSetArray;
  Position: Integer;
begin
  for I := 0 to MAX_HANDS - 1 do
    if Assigned(FLines[FLastIndex, I]) then
      FLines[FLastIndex, I].Visible := False;

  FLastIndex := FDropBox.ItemIndex;

  Position := 32;
  Teams := gHands.GetFullTeams;

  for I := Low(Teams) to High(Teams) do
  begin
    for J in Teams[I] do
    begin
      if Assigned(FLines[FLastIndex, J]) then
      begin
        FLines[FLastIndex, J].Top := Position;
        FLines[FLastIndex, J].Visible := True;
        FLines[FLastIndex, J].Update;
      end;
      Position := Position + GUI_SPECTATOR_ITEM_HEIGHT + GUI_SPECTATOR_ITEM_SPLITE_V * 2 + GUI_SPECTATOR_HEADER_HEIGHT;
    end;
    Position := Position + GUI_SPECTATOR_ITEM_TEAM;
  end;
end;

procedure TKMGUIGameSpectator.CloseDropBox;
begin
  FDropBox.ItemIndex := 0;
  FDropBox.CloseList;
  ChangePage(nil);
end;


end.
