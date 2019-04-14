unit KM_GameInputProcess_Single;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_GameInputProcess;


type
  TKMGameInputProcess_Single = class(TKMGameInputProcess)
  private
    fCurrTick: Cardinal;
    fLastTick: Cardinal;
  protected
    procedure TakeCommand(const aCommand: TKMGameInputCommand); override;
    procedure SaveExtra(aStream: TKMemoryStream); override;
    procedure LoadExtra(aStream: TKMemoryStream); override;
  public
    procedure ReplayTimer(aTick: Cardinal); override;
    procedure RunningTimer(aTick: Cardinal); override;
    procedure UpdateState(aTick: Cardinal); override;
    function GetLastTick: Cardinal; override;
    function ReplayEnded: Boolean; override;
  end;


implementation
uses
  KM_Game, KM_Defaults, KM_CommonUtils;


procedure TKMGameInputProcess_Single.TakeCommand(const aCommand: TKMGameInputCommand);
begin
  if gGame.IsReplay then Exit;

  StoreCommand(aCommand); //Store the command for the replay (store it first in case Exec crashes and we want to debug it)
  ExecCommand(aCommand);  //Execute the command now
end;


procedure TKMGameInputProcess_Single.ReplayTimer(aTick: Cardinal);
var
  MyRand: Cardinal;
begin
  //This is to match up with multiplayer random check generation, so multiplayer replays can be replayed in singleplayer mode
  KaMRandom(MaxInt, 'TKMGameInputProcess_Single.ReplayTimer');
  //There are still more commands left
  if fCursor <= Count then
  begin
    while (aTick > fQueue[fCursor].Tick) and (fQueue[fCursor].Command.CommandType <> gicNone) and (fCursor < Count) do
      Inc(fCursor);

    while (fCursor <= Count) and (aTick = fQueue[fCursor].Tick) do //Could be several commands in one Tick
    begin
      if (fQueue[fCursor].Command.CommandType = gicGameAutoSave) then // Maybe also gicGameAutoSaveAfterPT and gicGameSaveReturnLobby
        MyRand := 0
      else
        MyRand := Cardinal(KaMRandom(MaxInt, 'TKMGameInputProcess_Single.ReplayTimer 2')); //Just like in StoreCommand
      ExecCommand(fQueue[fCursor].Command);
      //CRC check after the command
      if CRASH_ON_REPLAY and (fQueue[fCursor].Rand <> MyRand) then //Should always be called to maintain randoms flow
      begin
        Inc(fCursor); //Must be done before exiting in case user decides to continue the replay
        gGame.ReplayInconsistancy(fQueue[fCursor-1], MyRand);
        Exit; //ReplayInconsistancy sometimes calls GIP.Free, so exit immidiately
      end;
      Inc(fCursor);
    end;
  end;
  fCurrTick := aTick;
end;


procedure TKMGameInputProcess_Single.RunningTimer(aTick: Cardinal);
begin
  inherited;

  KaMRandom(MaxInt, 'TKMGameInputProcess_Single.RunningTimer'); //This is to match up with multiplayer CRC generation, so multiplayer replays can be replayed in singleplayer mode
end;


function TKMGameInputProcess_Single.GetLastTick: Cardinal;
begin
  if IsLastTickValueCorrect(fLastTick) then
    Result := fLastTick
  else
    Result := inherited;
end;


function TKMGameInputProcess_Single.ReplayEnded: Boolean;
begin
  Result := inherited and (not IsLastTickValueCorrect(fLastTick) or (fLastTick <= fCurrTick));
end;


procedure TKMGameInputProcess_Single.UpdateState(aTick: Cardinal);
begin
  fCurrTick := aTick;
end;


procedure TKMGameInputProcess_Single.SaveExtra(aStream: TKMemoryStream);
begin
  //no inherited here. We override parent behaviour
  //aStream.Write(fCurrTick);

  aStream.Write(fCurrTick);
  aStream.Write(fLastTick);
end;


procedure TKMGameInputProcess_Single.LoadExtra(aStream: TKMemoryStream);
begin
  //no inherited here. We override parent behaviour
  //aStream.Read(fLastTick);

  aStream.Read(fCurrTick);
  aStream.Read(fLastTick);
end;


end.

