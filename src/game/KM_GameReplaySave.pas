unit KM_GameReplaySave;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses;

type
  TKMGameReplaySave = class
  private
    fStream: TKMemoryStream;
    // Tick / Description
  public
    constructor Create(aStream: TKMemoryStream);
    destructor Destroy();

    property Stream: TKMemoryStream read fStream;
  end;

  TKMGameReplaySaves = class
  private
    fReplaySaves: TKMList;

    function GetCount(): Integer;
    function GetSave(aIdx: Integer): TKMGameReplaySave;
    function GetStream(aIdx: Integer): TKMemoryStream;
  public
    constructor Create();
    destructor Destroy; override;

    property Count: Integer read GetCount;
    property Replay[aIdx: Integer]: TKMGameReplaySave read GetSave;
    property Stream[aIdx: Integer]: TKMemoryStream read GetStream; default;

    procedure Save(aStram: TKMemoryStream);
  end;

implementation
uses
  SysUtils;


{ TKMGameReplaySaves }
constructor TKMGameReplaySaves.Create();
begin
  fReplaySaves := TKMList.Create();
end;


destructor TKMGameReplaySaves.Destroy();
var
  K: Integer;
begin
  for K := fReplaySaves.Count - 1 downto 0 do
    TKMGameReplaySave( fReplaySaves[K] ).Free;
  FreeAndNil(fReplaySaves);
end;


function TKMGameReplaySaves.GetCount(): Integer;
begin
  Result := fReplaySaves.Count;
end;


function TKMGameReplaySaves.GetSave(aIdx: Integer): TKMGameReplaySave;
begin
  Result := nil;
  if (fReplaySaves.Count > aIdx) AND (aIdx >= 0) then
    Result := TKMGameReplaySave( fReplaySaves[aIdx] );
end;


function TKMGameReplaySaves.GetStream(aIdx: Integer): TKMemoryStream;
var
  Rpl: TKMGameReplaySave;
begin
  Result := nil;
  Rpl := Replay[aIdx];
  if (Rpl <> nil) then
    Result := Rpl.Stream;
end;


procedure TKMGameReplaySaves.Save(aStram: TKMemoryStream);
begin
  fReplaySaves.Add( TKMGameReplaySave.Create(aStram) );
end;



{ TKMGameReplaySave }
constructor TKMGameReplaySave.Create(aStream: TKMemoryStream);
begin
  fStream := aStream;
end;


destructor TKMGameReplaySave.Destroy();
begin
  FreeAndNil(fStream);
end;


end.
