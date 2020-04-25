unit Runner_Game;
{$I KaM_Remake.inc}
interface
uses
  Forms, Unit_Runner, Windows, SysUtils, Classes, KromUtils, Math,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils, KM_HandLogistics,
  KM_GameApp, KM_ResLocales, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_ResTexts, KM_Resource,
  KM_Terrain, KM_Units, KM_UnitWarrior, KM_Campaigns, KM_AIFields, KM_Houses,
  GeneticAlgorithm, GeneticAlgorithmParameters, KM_AIParameters,
  ComInterface, Generics.Collections, KM_RenderControl;


type
  //Typical usage:
  //SetUp, Execute(1), Execute(2) .. Execute(N), TearDown

  TKMRunnerGA_Common = class(TKMRunnerCommon)
  private
    fCrashDetectionMode: Boolean; // only for single thread
    fSaveGame: Boolean;
    fAlgorithm: TGAAlgorithm;
    fParametrization: TGAParameterization;
    fOldPopulation, fNewPopulation: TGAPopulation;
    //fFitnessCalc: TGAFitnessCalc;
    fLog, fLogPar: TKMLog;

    f_SIM_SimulationTimeInMin: Single; // Time of each simulation (GA doest not take simulation from game menu because it is only in minutes)
    f_SIM_NumberOfMaps: Word; // Count of simulated maps for each invididual
    f_SIM_PeaceTime: Word; // Peace time
    f_SIM_ThreadNumber: Word; // Number of thread (for saving maps)
    f_SIM_SimulationNumber: Word; // Number of thread (for saving maps)
    f_SIM_MapNamePrefix: String; // Prefix of map names
    f_GA_POPULATION_CNT: Word; // Population count
    f_GA_GENE_CNT: Word; // Count of genes
    f_GA_START_TOURNAMENT_IndividualsCnt: Word; // Initial count of individuals in tournament
    f_GA_FINAL_TOURNAMENT_IndividualsCnt: Word; // Final count of individuals in tournament
    f_GA_START_MUTATION_ResetGene: Single; // Initial mutation (first generation)
    f_GA_FINAL_MUTATION_ResetGene: Single; // Final mutation (last generation)
    f_GA_START_MUTATION_Gaussian: Single; // Initial mutation (first generation)
    f_GA_FINAL_MUTATION_Gaussian: Single; // Final mutation (last generation)
    f_GA_START_MUTATION_Variance: Single; // Initial mutation (first generation)
    f_GA_FINAL_MUTATION_Variance: Single; // Final mutation (last generation)

    procedure SetRndGenes(); virtual;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure InitGAParameters(); virtual;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); virtual; abstract;
    procedure SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String); virtual;
    function CostFunction(): Single; virtual;
    procedure Execute(aRun: Integer); override;
  public
    SimSetup: TSimSetup;
    IOData: TGASetup;
  end;

  TKMRunnerGA_TestParRun = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerGA_HandLogistics = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_Manager = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_CityAllIn = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_CityBuilder = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_Farm = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_Quarry = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_RoadPlanner = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_Forest = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_CityPlanner = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_ArmyAttack = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerGA_ArmyAttackNew = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
  end;

  TKMRunnerFindBugs = class(TKMRunnerCommon)
  private
    fBestScore, fWorstScore, fAverageScore: Double;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerCombatAITest = class(TKMRunnerCommon)
  private
    fBestScore, fWorstScore, fAverageScore: Double;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerPushModes = class(TKMRunnerCommon)
  private
    fBestScore, fWorstScore, fAverageScore: Double;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerDesyncTest = class(TKMRunnerCommon)
  type
    TKMDesyncRunKind = (drkGame, drkReplay, drkGameCRC, drkReplayCRC);
  private
    fSaveName: string;
    fDesyncsDir: string;
    fRunKind: TKMDesyncRunKind;
    fRun: Integer;
    fMap: string;
    fSavePointTick: Cardinal;
    fRngMismatchFound: Boolean;
    fRngMismatchTick: Integer;
    fCRCDesyncFound: Boolean;
    fCRCDesyncTick: Integer;
    fTickCRC: array of Cardinal;
    procedure ReplayCrashed(aTick: Integer);
    function BeforeTickPlayed(aTick: Cardinal): Boolean;
    procedure SaveGame; overload;
    procedure SaveGame(aSaveName: string); overload;
    procedure MoveSave(aSaveName: string);
    procedure SaveGameAndMove; overload;
    procedure SaveGameAndMove(aSaveName: string); overload;
    function GetRunKindStr: string; overload;
    function GetRunKindStr(aRunKind: TKMDesyncRunKind): string; overload;
    function GetSaveName: string; overload;
    function GetSaveName(aRunKind: TKMDesyncRunKind; aTick: Integer): string; overload;
    function TickPlayed(aTick: Cardinal): Boolean;
    procedure Tick_GIPRandom;
    procedure Reset;
    function GetSaveDir(aSaveName: string): string;
    procedure Log(const aString: string);
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerStone = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMRunnerFight95 = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMRunnerAIBuild = class(TKMRunnerCommon)
  private
    HTotal, WTotal, WFTotal, GTotal: Cardinal;
    HAver, WAver, WFAver, GAver: Single;
    HandsCnt, Runs: Integer;
    Time: Cardinal;
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMVortamicPF = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMReplay = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

  TKMVas01 = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;


  TKMStabilityTest = class(TKMRunnerCommon)
  private
    fTime: Cardinal;
    fRuns: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown(); override;
    procedure Execute(aRun: Integer); override;
  end;


implementation
uses
  TypInfo, StrUtils,
  KM_HandSpectator, KM_ResWares, KM_ResHouses, KM_Hand, KM_UnitsCollection, KM_UnitGroup, KM_GameSavedReplays,
  KM_CommonTypes, KM_MapTypes, KM_RandomChecks, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame;




{ TKMRunnerGA_Common }
procedure TKMRunnerGA_Common.InitGAParameters();
begin
  fSaveGame := False;
  fCrashDetectionMode := True;
  f_SIM_SimulationTimeInMin      := 40;
  f_SIM_NumberOfMaps             := 3;
  f_SIM_PeaceTime                := 70;
  f_SIM_ThreadNumber             := 1;
  f_SIM_SimulationNumber         := 1;
  f_SIM_MapNamePrefix            := 'GA_S1_%.3d';
  f_GA_POPULATION_CNT            := 4;
  f_GA_GENE_CNT                  := 5; // It will be overriden by class
  f_GA_START_TOURNAMENT_IndividualsCnt := 3;
  f_GA_FINAL_TOURNAMENT_IndividualsCnt := 4;
  f_GA_START_MUTATION_ResetGene  := 0.01;
  f_GA_FINAL_MUTATION_ResetGene  := 0.0001;
  f_GA_START_MUTATION_Gaussian   := 0.2;
  f_GA_FINAL_MUTATION_Gaussian   := 0.1;
  f_GA_START_MUTATION_Variance := 0.1;
  f_GA_FINAL_MUTATION_Variance := 0.01;
end;

procedure TKMRunnerGA_Common.SetUp;
var
  K,L: Integer;
  Pop: TGAPopulation;
begin
  inherited;
  // Create parametrization
  fParametrization := TGAParameterization.Create;
  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];
  // Init common variables
  fOldPopulation := nil;
  fAlgorithm := TGAAlgorithm.Create;
  InitGAParameters();

  // Prepare parallel simulation
  if PARALLEL_RUN then
  begin
    {$IFDEF PARALLEL_RUNNER}
      THREAD_NUMBER := SimSetup.ThreadNumber;
    {$ENDIF}
    f_SIM_SimulationTimeInMin := SimSetup.SimTimeInMin;
    f_SIM_PeaceTime := SimSetup.PeaceTime;
    f_SIM_ThreadNumber := SimSetup.ThreadNumber;
    f_SIM_SimulationNumber := SimSetup.SimNumber;
    f_SIM_NumberOfMaps := IOData.MapCnt;
    Pop := IOData.Population;
    if (Pop <> nil) then
    begin
      f_GA_POPULATION_CNT := Pop.Count;
      f_GA_GENE_CNT := Pop.Individual[0].GenesCount;
      // Create new population and copy genes
      fNewPopulation := TGAPopulation.Create(Pop.Count, Pop.Individual[0].GenesCount, f_SIM_NumberOfMaps, True);
      for K := 0 to fNewPopulation.Count - 1 do
        for L := 0 to fNewPopulation.Individual[K].GenesCount - 1 do
          fNewPopulation.Individual[K].Gene[L] := Pop.Individual[K].Gene[L];
    end;
  end
  else
  begin
    // Init new population
    fNewPopulation := TGAPopulation.Create(f_GA_POPULATION_CNT, f_GA_GENE_CNT, f_SIM_NumberOfMaps, True);
    SetRndGenes();
    // Init logs
    fLog := TKMLog.Create(Format('%s\Utils\Runner\LOG_GA.log',[ExeDir]));
    fLogPar := TKMLog.Create(Format('%s\Utils\Runner\LOG_GA_PAR.log',[ExeDir]));
    fParametrization.SetLogPar := fLogPar;
  end;
  // Init simulation
  fResults.ValueCount := 1;
  fResults.TimesCount := Ceil(10*60 * f_SIM_SimulationTimeInMin);
end;


procedure TKMRunnerGA_Common.TearDown;
var
  K,L: Integer;
begin
  // Copy fitness
  if PARALLEL_RUN then
  begin
    for K := 0 to fOldPopulation.Count - 1 do
      for L := 0 to f_SIM_NumberOfMaps - 1 do
        IOData.Population.Individual[K].Fitness[L] := fOldPopulation.Individual[K].Fitness[L];
  end
  else
  begin
    fLog.Free;
    fLogPar.Free;
  end;
  // Do something after simulation
  FreeAndNil(fOldPopulation);
  FreeAndNil(fNewPopulation);
  FreeAndNil(fAlgorithm);
  fParametrization.Free;
  inherited;
end;


procedure TKMRunnerGA_Common.SetRndGenes();
var
  K,L: Integer;
  Idv: TGAIndividual;
begin
  for K := 0 to fNewPopulation.Count - 1 do
  begin
    Idv := fNewPopulation[K];
    for L := 0 to Idv.GenesCount - 1 do
      Idv.Gene[L] := Random;
  end;
end;


procedure TKMRunnerGA_Common.SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String);
var
  pathToSave: String;
begin
  DEFAULT_PEACE_TIME := f_SIM_PeaceTime;
  pathToSave := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))))));
  gGameApp.NewSingleMap(Format('%sMaps\%s\%s.dat',[pathToSave,aSinglePLMapName,aSinglePLMapName]), 'GA');
  //gGameApp.Game.GameOptions.Peacetime := f_SIM_PeaceTime;

  //gMySpectator.Hand.FogOfWar.RevealEverything;
  //gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(0, 60), 0);
  //gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;

  //SetKaMSeed(Max(1,Seed));
  try
    SimulateGame(0, 100);
    if fCrashDetectionMode then
      gGameApp.Game.Save(Format('GA_S%.2d_T%.2d_%s',[f_SIM_SimulationNumber, f_SIM_ThreadNumber, aSinglePLMapName]), Now);
    SimulateGame(101, -1);
    if fCrashDetectionMode then
      KMDeleteFolder(Format('%sSaves\GA_S%.2d_T%.2d_%s',[pathToSave,f_SIM_SimulationNumber, f_SIM_ThreadNumber, aSinglePLMapName]));
  except
    // We have problem
  end;
  if fSaveGame then
    gGameApp.Game.Save(Format('GA_end_S%.2d_T%.2d_%s',[f_SIM_SimulationNumber, f_SIM_ThreadNumber, aSinglePLMapName]), Now);
end;


function TKMRunnerGA_Common.CostFunction(): Single;
const
  PL = 1;
  HOUSE_WEIGHT = 1;
  WEAPONS_WEIGHT = 1;
  CITIZENS_LOST = 10;
  IRON_SOLDIER = 20;
  WOOD_SOLDIER = 10;
  MILITIA_SOLDIER = 3;
  COMPLETE_HOUSE = 5;
  {
    utMilitia,      utAxeFighter,   utSwordsman,     utBowman,
    utArbaletman,   utPikeman,      utHallebardman,  utHorseScout,
    utCavalry,      utBarbarian,
    utPeasant,      utSlingshot,    utMetalBarbarian,utHorseman,
  }
  WARRIOR_PRICE: array[WARRIOR_MIN..WARRIOR_MAX] of Integer = (
    1, 3, 6, 3+4, // Militia     AxeFighter  Swordsman       utBowman
    5+4, 3, 5, 4, // Arbaletman  Pikeman     Hallebardman    utHorseScout
    7, 6,       // Cavalry     Barbarian
    2, 2+4, 6, 3  // Peasant     Slingshot   MetalBarbarian  utHorseman
    );
var
  K, UnitKilledCnt, UnitSurvivedCnt, UnitSurvivedEnemyCnt: Integer;
  IronArmy, WoodArmy, Militia, Output: Single;
  UT: TKMUnitType;
begin
  // Production of weapons
  with gHands[PL].Stats do
  begin
    Output := + GetHouseQty(htAny) * HOUSE_WEIGHT
              + GetWeaponsProduced * WEAPONS_WEIGHT
              - GetCitizensLost * CITIZENS_LOST;
    IronArmy := Min( GetWaresProduced(wtMetalArmor),
                       GetWaresProduced(wtHallebard)
                     + GetWaresProduced(wtArbalet)
                     + Min(GetWaresProduced(wtSword), GetWaresProduced(wtMetalShield))
                   );
    WoodArmy := Min( GetWaresProduced(wtArmor),
                       GetWaresProduced(wtBow)
                     + GetWaresProduced(wtPike)
                     + Min(GetWaresProduced(wtShield), GetWaresProduced(wtAxe))
                   );
    Militia := Min( Max(0,WoodArmy - GetWaresProduced(wtArmor)), GetWaresProduced(wtAxe));
    Output := Output
              + IronArmy * IRON_SOLDIER
              + WoodArmy * WOOD_SOLDIER
              + Militia * MILITIA_SOLDIER;
  end;
  // Completed houses
  for K := 0 to gHands[PL].Houses.Count - 1 do
    Output := Output + Byte(gHands[PL].Houses[K].IsComplete) * COMPLETE_HOUSE;

  // Defeated soldiers
  UnitKilledCnt := 0;
  UnitSurvivedCnt := 0;
  with gHands[PL].Stats do
  begin
    for UT := WARRIOR_MIN to WARRIOR_MAX do
    begin
      UnitKilledCnt := UnitKilledCnt + GetUnitKilledQty(UT);
      UnitSurvivedCnt := UnitSurvivedCnt + GetUnitQty(UT);
      Output := Output + (GetUnitQty(UT) - GetUnitLostQty(UT)) * WARRIOR_PRICE[UT];
      Output := Output + GetUnitKilledQty(UT) * WARRIOR_PRICE[UT] * 2;
    end;
    Output := Output - Byte(UnitKilledCnt = 0) * 500;
  end;

  // Check combat maps (GA_S2_...)
  UnitSurvivedEnemyCnt := 0;
  with gHands[0].Stats do
    for UT := WARRIOR_MIN to WARRIOR_MAX do
      UnitSurvivedEnemyCnt := UnitSurvivedEnemyCnt + GetUnitQty(UT);
  // Sometimes it is third player in GA_S2_... maps
  if (gHands.Count >= 3) then
    with gHands[2].Stats do
      for UT := WARRIOR_MIN to WARRIOR_MAX do
        UnitSurvivedEnemyCnt := UnitSurvivedEnemyCnt + GetUnitQty(UT);
  if (UnitSurvivedEnemyCnt > 0) AND (UnitSurvivedCnt > 0) then // The fight is not finished
    Output := Output - (UnitSurvivedEnemyCnt + UnitSurvivedCnt) * 30;

  Result := Output;
end;


procedure TKMRunnerGA_Common.Execute(aRun: Integer);
const
  MIN_SCORE = - 1000000;
var
  K, MapNum: Integer;
  BestScore, Ratio: Single;
  Idv: TGAIndividual;
begin
  if not PARALLEL_RUN then
    f_SIM_SimulationNumber := aRun + 1;
  // Set up parameters
  Ratio := 1 - aRun / (fResults.ChartsCount * 1.0);
  fAlgorithm.MutationResetGene := Abs(f_GA_FINAL_MUTATION_ResetGene + (f_GA_START_MUTATION_ResetGene - f_GA_FINAL_MUTATION_ResetGene) * Ratio);
  fAlgorithm.MutationGaussian  := Abs(f_GA_FINAL_MUTATION_Gaussian  + (f_GA_START_MUTATION_Gaussian  - f_GA_FINAL_MUTATION_Gaussian ) * Ratio);
  fAlgorithm.MutationVariance  := Abs(f_GA_FINAL_TOURNAMENT_IndividualsCnt + (f_GA_START_TOURNAMENT_IndividualsCnt - f_GA_FINAL_MUTATION_Variance) * Ratio);
  fAlgorithm.IndividualsInTournament := Ceil(Abs(f_GA_FINAL_TOURNAMENT_IndividualsCnt + (f_GA_START_TOURNAMENT_IndividualsCnt - f_GA_FINAL_TOURNAMENT_IndividualsCnt) * Ratio));

  // Evolve population in next run (used because of parallel run)
  if (fOldPopulation <> nil) then
  begin
    fAlgorithm.EvolvePopulation(fOldPopulation, fNewPopulation);
    fOldPopulation.Free;
  end;

  fOldPopulation := fNewPopulation;
  fNewPopulation := nil;
  for MapNum := 1 to f_SIM_NumberOfMaps do
    for K := 0 to f_GA_POPULATION_CNT - 1 do
    begin
      fParametrization.SetPar(fOldPopulation[K], False);
      // Save GA parameters so the game will be identical
      if fCrashDetectionMode then
      begin
        if (fLogPar <> nil) then
          fLogPar.Free;
        fLogPar := TKMLog.Create(Format('%s\Utils\Runner\LOG_GA_PAR.log',[ExeDir]));
        fParametrization.SetPar(fOldPopulation[K], True);
      end;
      SimulateMap(aRun, K, aRun, Format(f_SIM_MapNamePrefix,[MapNum]));// Name of maps are GA_001, GA_002 so use %.3d to fill zeros
      fOldPopulation[K].Fitness[MapNum-1] := CostFunction();
    end;

  if not PARALLEL_RUN then
  begin
    fNewPopulation := TGAPopulation.Create(f_GA_POPULATION_CNT, f_GA_GENE_CNT, f_SIM_NumberOfMaps, False);

    // Save best score + parameters of best individual
    Idv := fOldPopulation.GetFittest();
    fResults.Value[aRun, 0] := Round(Idv.FitnessSum);
    fLog.AddTime(Format('GA: %4d. run. Best score: %15.5f',[aRun,Idv.FitnessSum]));

    // Check history and find the most fitness individual
    BestScore := MIN_SCORE;
    for K := 0 to aRun - 1 do
      if (fResults.Value[K, 0] > BestScore) then
        BestScore := fResults.Value[K, 0];
    // If is the individual from the latest generation the best then log parameters
    if (BestScore < Idv.FitnessSum) then
      fParametrization.SetPar(Idv, not PARALLEL_RUN);
  end;

  // Stop simulation
  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerGA_TestParRun }
procedure TKMRunnerGA_TestParRun.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_TestParRun');
end;


procedure TKMRunnerGA_TestParRun.Execute(aRun: Integer);
var
  K,L,MapNum: Integer;
  Fitness: Single;
begin
  // Fitness is calculated from genes in this debug class
  if (fNewPopulation <> nil) then
    for MapNum := 0 to f_SIM_NumberOfMaps - 1 do
      for K := 0 to fNewPopulation.Count - 1 do
      begin
        Fitness := 0;
        for L := 0 to fNewPopulation.Individual[K].GenesCount - 1 do
          Fitness := 0.1 + Fitness - abs(L / fNewPopulation.Individual[K].GenesCount - fNewPopulation.Individual[K].Gene[L]);
        fNewPopulation.Individual[K].Fitness[MapNum] := Fitness;
      end;
  fOldPopulation := fNewPopulation;
  fNewPopulation := nil;

  //Sleep(500); // Debug sleep

  // Stop simulation
  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerGA_HandLogistics }
procedure TKMRunnerGA_HandLogistics.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_HandLogistics');
end;


{ TKMRunnerGA_Manager }
procedure TKMRunnerGA_Manager.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_Manager');
end;


{ TKMRunnerGA_CityAllIn }
procedure TKMRunnerGA_CityAllIn.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_CityAllIn');
end;


{ TKMRunnerGA_CityBuilder }
procedure TKMRunnerGA_CityBuilder.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_CityBuilder');
end;

{ TKMRunnerGA_Farm }
procedure TKMRunnerGA_Farm.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_Farm');
end;

{ TKMRunnerGA_Quarry }
procedure TKMRunnerGA_Quarry.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_Quarry');
end;

{ TKMRunnerGA_RoadPlanner }
procedure TKMRunnerGA_RoadPlanner.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_RoadPlanner');
end;

{ TKMRunnerGA_Forest }
procedure TKMRunnerGA_Forest.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_Forest');
end;

{ TKMRunnerGA_CityPlanner }
procedure TKMRunnerGA_CityPlanner.InitGAParameters();
begin
  inherited;
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_CityPlanner');
end;

{ TKMRunnerGA_ArmyAttack }
procedure TKMRunnerGA_ArmyAttack.InitGAParameters();
begin
  inherited;
  f_SIM_SimulationTimeInMin := 10;
  f_SIM_PeaceTime := 0;
  f_SIM_NumberOfMaps  := 20;
  f_SIM_MapNamePrefix := 'GA_S2_%.3d';
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_ArmyAttack');
end;

{ TKMRunnerGA_ArmyAttackNew }
procedure TKMRunnerGA_ArmyAttackNew.InitGAParameters();
begin
  inherited;
  f_SIM_SimulationTimeInMin := 10;
  f_SIM_PeaceTime := 0;
  f_SIM_NumberOfMaps  := 20;
  f_SIM_MapNamePrefix := 'GA_S2_%.3d';
  f_GA_GENE_CNT := fParametrization.GetParCnt('TKMRunnerGA_ArmyAttackNew');
end;




{ TKMRunnerFindBugs }
procedure TKMRunnerFindBugs.SetUp();
begin
  inherited;
  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];
end;


procedure TKMRunnerFindBugs.TearDown();
begin
  inherited;
end;


procedure TKMRunnerFindBugs.Execute(aRun: Integer);
  function EvalGame(): Double;
  const
    PL = 1;
    HOUSE_WEIGHT = 1;
    WEAPONS_WEIGHT = 1;
    CITIZENS_LOST = 10;
    IRON_SOLDIER = 20;
    WOOD_SOLDIER = 10;
    MILITIA_SOLDIER = 3;
    COMPLETE_HOUSE = 5;
  var
    I: Integer;
    IronArmy, WoodArmy, Militia, Output: Single;
  begin
    with gHands[PL].Stats do
    begin
      Output := + GetHouseQty(htAny) * HOUSE_WEIGHT
                + GetWeaponsProduced * WEAPONS_WEIGHT
                - GetCitizensLost * CITIZENS_LOST;
      IronArmy := Min( GetWaresProduced(wtMetalArmor),
                         GetWaresProduced(wtHallebard)
                       + GetWaresProduced(wtArbalet)
                       + Min(GetWaresProduced(wtSword), GetWaresProduced(wtMetalShield))
                     );
      WoodArmy := Min( GetWaresProduced(wtArmor),
                         GetWaresProduced(wtBow)
                       + GetWaresProduced(wtPike)
                       + Min(GetWaresProduced(wtShield), GetWaresProduced(wtAxe))
                     );
      Militia := Min( Max(0,WoodArmy - GetWaresProduced(wtArmor)), GetWaresProduced(wtAxe));
      Output := Output
                + IronArmy * IRON_SOLDIER
                + WoodArmy * WOOD_SOLDIER
                + Militia * MILITIA_SOLDIER;
    end;

    for I := 0 to gHands[PL].Houses.Count - 1 do
      Output := Output + Byte(gHands[PL].Houses[I].IsComplete) * COMPLETE_HOUSE;

    Result := Output;
  end;
const
  // Maps for simulation (I dont use for loop in this array)
  //MAPS: array [1..27] of String = ('GA_S1_001','GA_S1_002','GA_S1_003','GA_S1_004','GA_S1_005','GA_S1_006','GA_S1_007','GA_S1_008','GA_S1_009','GA_S1_010','GA_S1_011','GA_S1_012','GA_S1_013','GA_S1_014','GA_S1_015','GA_S1_016','GA_S1_017','GA_S1_018','GA_S1_019','GA_S1_020','GA_S1_021','GA_S1_022','GA_S1_023','GA_S1_024','GA_S1_025','GA_S1_026','GA_S1_027');
  MAPS: array [1..12] of String = ('GA_S1_002','GA_S1_003','GA_S1_007','GA_S1_008','GA_S1_010','GA_S1_014','GA_S1_015','GA_S1_019','GA_S1_023','GA_S1_024','GA_S1_026','GA_S1_027');
  cnt_MAP_SIMULATIONS = 25;
  CRASH_DETECTION_MODE = True;
var
  K,L: Integer;
  Score: Double;
  MapName: String;
begin
  DEFAULT_PEACE_TIME := 60;
  for K := Low(MAPS) to High(MAPS) do
  begin
    fBestScore := -1e30;
    fAverageScore := 0;
    fWorstScore := 1e30;
    MapName := MAPS[K];
    for L := 1 to cnt_MAP_SIMULATIONS do
    begin
      OnProgress2(MapName + ' Run ' + IntToStr(L));
      gGameApp.NewSingleMap(Format('%s..\..\Maps\%s\%s.dat',[ExtractFilePath(ParamStr(0)),MapName,MapName]), MapName);

      SetKaMSeed(L + 1000);

      if CRASH_DETECTION_MODE then
        gGameApp.Game.Save('CrashDetection', Now);

      //SetKaMSeed(Max(1,Seed));
      SimulateGame();
      Score := Max(0,EvalGame());
      fAverageScore := fAverageScore + Score;
      //gGameApp.Game.Save(Format('%s__No_%.3d__Score_%.6d',[MapName, K, Round(Score)]), Now);
      if (Score < fWorstScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fWorstScore := Score;
        gGameApp.Game.Save(Format('W__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;
      if (Score > fBestScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fBestScore := Score;
        gGameApp.Game.Save(Format('B__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;

    end;
    fAverageScore := fAverageScore / cnt_MAP_SIMULATIONS;
    gGameApp.Game.Save(Format('AVRG_%s__%.6d',[MapName, Round(fAverageScore)]), Now);
  end;

  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerCombatAITest }
procedure TKMRunnerCombatAITest.SetUp();
begin
  inherited;
  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];
end;


procedure TKMRunnerCombatAITest.TearDown();
begin
  inherited;
end;


procedure TKMRunnerCombatAITest.Execute(aRun: Integer);
  function EvalGame(): Double;
  const
    PL = 1;
  var
    UT: TKMUnitType;
  begin
    Result := 0;
    with gHands[PL].Stats do
      for UT := WARRIOR_MIN to WARRIOR_MAX do
        Result := Result + GetUnitQty(UT);
  end;
const
  // Maps for simulation (I dont use for loop in this array)
  //MAPS: array [1..27] of String = ('GA_S1_001','GA_S1_002','GA_S1_003','GA_S1_004','GA_S1_005','GA_S1_006','GA_S1_007','GA_S1_008','GA_S1_009','GA_S1_010','GA_S1_011','GA_S1_012','GA_S1_013','GA_S1_014','GA_S1_015','GA_S1_016','GA_S1_017','GA_S1_018','GA_S1_019','GA_S1_020','GA_S1_021','GA_S1_022','GA_S1_023','GA_S1_024','GA_S1_025','GA_S1_026','GA_S1_027');
  //MAPS: array [1..12] of String = ('GA_S1_002','GA_S1_003','GA_S1_007','GA_S1_008','GA_S1_010','GA_S1_014','GA_S1_015','GA_S1_019','GA_S1_023','GA_S1_024','GA_S1_026','GA_S1_027');
  MAPS: array [1..1] of String = ('IV_1v1');
  //MAPS: array [1..1] of String = ('IV_1v1_AdvOldC');
  cnt_MAP_SIMULATIONS = 100;
  CRASH_DETECTION_MODE = True;
var
  K,L,Wins: Integer;
  Score: Double;
  MapName: String;
begin
  for K := Low(MAPS) to High(MAPS) do
  begin
    fBestScore := -1e30;
    fAverageScore := 0;
    fWorstScore := 1e30;
    Wins := 0;
    MapName := MAPS[K];
    for L := 1 to cnt_MAP_SIMULATIONS do
    begin
      OnProgress2(MapName + ' Run ' + IntToStr(L));
      gGameApp.NewSingleMap(Format('%s..\..\Maps\%s\%s.dat',[ExtractFilePath(ParamStr(0)),MapName,MapName]), MapName);

      //SetKaMSeed(L + 1000);

      if CRASH_DETECTION_MODE then
        gGameApp.Game.Save('CrashDetection', Now);

      //SetKaMSeed(Max(1,Seed));
      SimulateGame();
      Score := Max(0,EvalGame());
      Wins := Wins + Byte(Score > 0);
      fAverageScore := fAverageScore + Score;
      //gGameApp.Game.Save(Format('%s__No_%.3d__Score_%.6d',[MapName, K, Round(Score)]), Now);
      if (Score <= fWorstScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fWorstScore := Score;
        gGameApp.Game.Save(Format('W__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;

    end;
    fAverageScore := fAverageScore / cnt_MAP_SIMULATIONS;
    gGameApp.Game.Save(Format('AVRG_%s__%.6d',[MapName, Round(Wins)]), Now);
  end;

  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerPushModes }
procedure TKMRunnerPushModes.SetUp();
begin
  inherited;

  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));
  gLog.MessageTypes := [];
end;


procedure TKMRunnerPushModes.TearDown();
begin
  inherited;
end;


procedure TKMRunnerPushModes.Execute(aRun: Integer);
const
  // Maps for simulation (I dont use for loop in this array)
  //MAPS: array [1..27] of String = ('GA_S1_001','GA_S1_002','GA_S1_003','GA_S1_004','GA_S1_005','GA_S1_006','GA_S1_007','GA_S1_008','GA_S1_009','GA_S1_010','GA_S1_011','GA_S1_012','GA_S1_013','GA_S1_014','GA_S1_015','GA_S1_016','GA_S1_017','GA_S1_018','GA_S1_019','GA_S1_020','GA_S1_021','GA_S1_022','GA_S1_023','GA_S1_024','GA_S1_025','GA_S1_026','GA_S1_027');
  MAPS: array [1..13] of String = ('Test1','Test2','Test3','Test4','Test5','Test6','Test7','Test8','Test9','Test10','Test11','Test12',
                                   'Test13');
  MAPS_V: array [1..13] of Integer = (10, 10, 10, 20, 20, 20, 10, 10, 10, 10, 10, 10,
                                      120);
  cnt_MAP_SIMULATIONS = 100;
var
  K,L: Integer;
  Score: Double;
  MapName: String;
begin
  for K := 1 to 13 do//High(MAPS) do
  begin
    fBestScore := -1e30;
    fAverageScore := 0;
    fWorstScore := 1e30;
    MapName := MAPS[K];
    fIntParam := 0;
    fIntParam2 := 0;
    if K <= 12 then
      fIntParam := MAPS_V[K]
    else
      fIntParam2 := MAPS_V[K];
    for L := 1 to cnt_MAP_SIMULATIONS do
    begin
      gGameApp.NewSingleMap(Format('%s..\..\Maps\%s\%s.dat',[ExtractFilePath(ParamStr(0)),MapName,MapName]), MapName);

      SetKaMSeed(Max(1,L));

      SimulateGame();
      Score := gGameApp.Game.GameTick;//Max(0,EvalGame());
      fAverageScore := fAverageScore + Score;
      //gGameApp.Game.Save(Format('%s__No_%.3d__Score_%.6d',[MapName, K, Round(Score)]), Now);
      if (Score < fWorstScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fWorstScore := Score;
//        gGameApp.Game.Save(Format('W__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;
      if (Score > fBestScore) AND (cnt_MAP_SIMULATIONS > 1) then
      begin
        fBestScore := Score;
//        gGameApp.Game.Save(Format('B__%s__No_%.3d__Score_%.6d',[MapName, L, Round(Score)]), Now);
      end;
      OnProgress2(MapName + ' Run ' + IntToStr(L));
    end;
    fAverageScore := fAverageScore / cnt_MAP_SIMULATIONS;
//    gGameApp.Game.Save(Format('AVRG_%s__%.6d',[MapName, Round(fAverageScore)]), Now);
    gLog.SetDefaultMessageTypes;
    gLog.AddNoTime(Format('%d;%d;%d', [{MAPS[K], }Round(fAverageScore), Round(fWorstScore), Round(fBestScore)]), False);
    gLog.MessageTypes := [];
  end;

  gGameApp.StopGame(grSilent);
end;


const
  SAVE_LAST_SYNC_TICK = False;

{ TKMRunnerDesyncTest }
procedure TKMRunnerDesyncTest.SetUp();
begin
  inherited;

  fDesyncsDir := Format('%s..\..\Desync\', [ExtractFilePath(ParamStr(0))]);
  ForceDirectories(fDesyncsDir);

  SetLength(fTickCRC, fResults.TimesCount);

  fOnTick := TickPlayed;
  fOnBeforeTick := BeforeTickPlayed;

  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(Format('%sUtils\Runner\Runner_Log.log',[ExeDir]));
//  gLog.MessageTypes := [];

  gLog.SetDefaultMessageTypes;

//  Include(gLog.MessageTypes, lmtRandomChecks);
//  Include(gLog.MessageTypes, lmtCommands);

//  LOG_GAME_TICK := True;
  USE_CUSTOM_SEED := True;

  CALC_EXPECTED_TICK := False;
  CRASH_ON_REPLAY := False;
  SAVE_GAME_AS_TEXT := True;
  ALLOW_SAVE_IN_REPLAY := True;
  SAVE_GAME_AS_TEXT := True;
  GAME_NO_UPDATE_ON_TIMER := True;
  GAME_SAVE_STRIP_FOR_CRC := True;
  SKIP_SAVE_SAVPTS_TO_FILE := True;
  SAVE_RANDOM_CHECKS := False;
  GAME_SAVE_CHECKPOINT_FREQ_MIN := 10;
  GAME_SAVE_CHECKPOINT_CNT_LIMIT_MAX := 100;

//  Include(gLog.MessageTypes, lmtRandomChecks)
end;


procedure TKMRunnerDesyncTest.TearDown();
begin

  inherited;
end;


procedure TKMRunnerDesyncTest.Reset;
begin
  FillChar(fTickCRC, SizeOf(fTickCRC), #0);

  SetLength(fTickCRC, fResults.TimesCount);
end;


procedure TKMRunnerDesyncTest.ReplayCrashed(aTick: Integer);
begin
  Assert(fRunKind = drkReplay);

  fRngMismatchFound := True;
  fRngMismatchTick := gGame.GameTick;
end;


procedure TKMRunnerDesyncTest.SaveGame;
begin
  SaveGame(GetSaveName);
end;


procedure TKMRunnerDesyncTest.SaveGame(aSaveName: string);
var
  gameMode: TKMGameMode;
begin
  gameMode := gGame.GameMode;
  gGame.SetGameMode(gmSingle);
  gGame.Save(aSaveName);
  gGame.SetGameMode(gameMode);
end;

procedure TKMRunnerDesyncTest.MoveSave(aSaveName: string);
begin
  KMMoveFolder(GetSaveDir(aSaveName), fDesyncsDir + aSaveName);
end;


procedure TKMRunnerDesyncTest.SaveGameAndMove;
begin
  SaveGameAndMove(GetSaveName);
end;


procedure TKMRunnerDesyncTest.SaveGameAndMove(aSaveName: string);
begin
  SaveGame(aSaveName);
  MoveSave(aSaveName);
end;


function TKMRunnerDesyncTest.GetRunKindStr: string;
begin
  Result := GetRunKindStr(fRunKind);
end;


function TKMRunnerDesyncTest.GetRunKindStr(aRunKind: TKMDesyncRunKind): string;
begin
  Result := GetEnumName(TypeInfo(TKMDesyncRunKind), Integer(aRunKind));
  Result := RightStr(Result, Length(Result) - 3);
end;


function TKMRunnerDesyncTest.GetSaveName: string;
begin
  Result := GetSaveName(fRunKind, gGame.GameTick);
end;


function TKMRunnerDesyncTest.GetSaveName(aRunKind: TKMDesyncRunKind; aTick: Integer): string;
begin
  Result := Format('%s_%s_L%d_T%d', [fSaveName, GetRunKindStr(aRunKind), fSavePointTick, aTick]);
end;


function TKMRunnerDesyncTest.BeforeTickPlayed(aTick: Cardinal): Boolean;
begin
  Result := (fRunKind <> drkReplay) or not fRngMismatchFound;

  if SAVE_LAST_SYNC_TICK and (fRunKind = drkReplayCRC) then
    SaveGame; // Make replay save
end;


function TKMRunnerDesyncTest.TickPlayed(aTick: Cardinal): Boolean;
var
  tickCRC: Cardinal;
begin
  Result := True;

  case fRunKind of
    drkGame:      begin
//                    Tick_GIPRandom;
                  end;
    drkReplay:    ;
    drkGameCRC:   begin
                    if gGame.GameTick >= fSavePointTick then
                    begin
                      tickCRC := gGame.GetCurrectTickSaveCRC;
                      fTickCRC[gGame.GameTick - fSavePointTick] := tickCRC;

                      SaveGame();
                    end;
                  end;
    drkReplayCRC: begin
                    tickCRC := gGame.GetCurrectTickSaveCRC;
                    if tickCRC <> fTickCRC[gGame.GameTick - fSavePointTick] then
                    begin
                      SaveGameAndMove;
                      MoveSave(GetSaveName(drkGameCRC, gGame.GameTick));

                      //Move last sync saves
                      if SAVE_LAST_SYNC_TICK then
                      begin
                        MoveSave(GetSaveName(drkReplayCRC, gGame.GameTick - 1));
                        MoveSave(GetSaveName(drkGameCRC, gGame.GameTick - 1));
                      end;

                      fCRCDesyncFound := True;
                      fCRCDesyncTick := gGame.GameTick;

                      Result := False;
                    end;
                  end;
  end;

  OnProgress2(Format('%s: %s R%d T%d', [GetRunKindStr, LeftStr(fMap, Min(Length(fMap), 17)), fRun, aTick]));
end;


procedure TKMRunnerDesyncTest.Log(const aString: string);
begin
  gLog.AddTime('[DESYNC] ' + aString);
end;


procedure TKMRunnerDesyncTest.Execute(aRun: Integer);
const
  SIMUL_TIME_MAX = 10*60*60; //1 hour
  SAVEPT_FREQ = 10*60*1; //every 1 min
  REPLAY_LENGTH = 50; // ticks to find RNG mismatch
  SAVEPT_CNT = (SIMUL_TIME_MAX div SAVEPT_FREQ) - 1;

  // Maps for simulation (I dont use for loop in this array)
//  MAPS: array [1..17] of String = ('Across the Desert','Mountainous Region','Battle Sun','Neighborhood Clash','Valley of the Equilibrium','Wilderness',
//                                   'Border Rivers','Blood and Ice','A Midwinter''s Day','Coastal Expedition','Defending the Homeland','Eruption',
//                                   'Forgotten Lands','Golden Cliffs','Rebound','Riverlands', 'Shadow Realm');
  MAPS_8P: array [1..29] of String = ('A War of Justice','Babylon','Back in the Desert','Center Castle Looting','Cold Water 8P',
                                   'Complication in Simplicity','Crystalline Falls','Cursed Ravine','Dance of Death','Dead of Winter',
                                   'Drastic Measures','Ending the Tyranny','Twin Peaks','Valley of the Equilibrium 8P', 'Frozen Waters',
                                   'Hand in Hand','Mega Land','Nibenay Basin','Paradise Island','Reborn','Rich Land','Tale of Two Lands',
                                   'The Final Frontier','The Last Port','The Same Rocks','The Valley of Dangers 2','Volcanic Violence',
                                   'Volcano Valley','Voros Arany');
  //Fighting maps
  FIGHT_MAPS: array[1..33] of string = ('Icewind Valley 6P', 'Red Valley', 'Clarity Falls - Escape', 'Enter the Heat', 'Pirate Bond',
                                  'Sharks Islands', 'Dangerous Shore', 'Ambushed', 'Bannockburn','Battle of Great Generals',
                                  'Gorges', 'Spring of Events', 'Inner Struggle', 'Last Fight for Oasis','Lost Road',
                                  'River Crossing','Shoulder to Shoulder','The Pirates','Unknown Danger','Battle in the Ruined City',
                                  'Lost City Struggle','Cross','Cursed Land','Gunplay','Icewind Valley','Rocky Mountains',
                                  'Shallows of Death','Snow Cross','The Citadel','The King Says','Tundra','Atoll','Coastal Encounter');
  cnt_MAP_SIMULATIONS = 30;
var
  K,L,I: Integer;
  desyncCnt: Integer;
  simulLastTick: Integer;
  mapFullName, desyncSaveName: string;
begin
  desyncCnt := 0;
  for K := Low(MAPS) to High(MAPS) do
  begin
    fMap := MAPS[K];

    for L := 1 to cnt_MAP_SIMULATIONS do
    begin
      Reset;
      fRun := L;
      CUSTOM_SEED_VALUE := Max(1,L+11);

      fSaveName := Format('%s_SD_%d_RN%.3d',[fMap, CUSTOM_SEED_VALUE, L]);

      fRunKind := drkGame;

//      SetKaMSeed(Max(1,L));
      mapFullName := Format('%s..\..\MapsMP\%s\%s.dat',[ExtractFilePath(ParamStr(0)),fMap,fMap]);
      gGameApp.NewSingleMap(mapFullName, fMap, -1, 0, mdNone, aitAdvanced);

      gGameApp.GameSettings.DebugSaveGameAsText := True;

      gGameApp.GameSettings.SaveCheckpoints := True;
      gGameApp.GameSettings.SaveCheckpointsFreq := SAVEPT_FREQ;
      gGameApp.GameSettings.SaveCheckpointsLimit := SAVEPT_CNT;

//      LOG_GAME_TICK := True;
//      Include(gLog.MessageTypes, lmtCommands);

      SimulateGame(0, SIMUL_TIME_MAX);

//      LOG_GAME_TICK := False;
//      Exclude(gLog.MessageTypes, lmtCommands);

      simulLastTick := min(SIMUL_TIME_MAX, fResults.TimesCount - 1);

      fRngMismatchFound := False;
      fRngMismatchTick := -1;

      gGame.SetGameMode(gmReplaySingle);

      for I := 0 to SAVEPT_CNT - 1 do
      begin
        fSavePointTick := (I + 1) * SAVEPT_FREQ;
        Log('SavePointTick = ' + IntToStr(fSavePointTick));
//        tick := (Random((simulTicks div SAVEPT_FREQ)) + 1) * SAVEPT_FREQ + 1;
        if gGameApp.TryLoadSavedReplay(fSavePointTick) then
        begin
          fRunKind := drkReplay;
          gGame.GameInputProcess.OnReplayDesync := ReplayCrashed;

          SimulateGame(fSavePointTick + 1, Min(fSavePointTick + REPLAY_LENGTH, simulLastTick));

          // RNG mismatch found. Simulate game to collect every tick save CRC
          if fRngMismatchFound then
          begin
            Log(Format('Found rng mismatch on ''%s'' at tick %d', [fMap, fRngMismatchTick]));
            Inc(desyncCnt);
            OnProgress3('Desyncs: ' + IntToStr(desyncCnt));

            fRunKind := drkGameCRC;

            gGameApp.NewSingleMap(mapFullName, fMap, -1, 0, mdNone, aitAdvanced);

            SimulateGame(0, fRngMismatchTick - 1);

            gGame.SetGameMode(gmReplaySingle);

            fCRCDesyncFound := False;
            fCRCDesyncTick := -1;

            // Load at certain savepoint
            if gGameApp.TryLoadSavedReplay(fSavePointTick) then
            begin
              fRunKind := drkReplayCRC;
              SimulateGame(fSavePointTick - 1, simulLastTick);

              // tick CRC desync found
              if fCRCDesyncFound then
                Log(Format('Found save CRC desync on ''%s'' Seed = %d at tick %d', [fMap, CUSTOM_SEED_VALUE, fCRCDesyncTick]))
              else
                Log('!!! Could not find save CRC desync tick !!!');
            end;
            Break;
          end;
        end;
      end;
      OnProgress2(fMap + ' Run ' + IntToStr(L));
      OnProgress3('Desyncs: ' + IntToStr(desyncCnt));
    end;
  end;

  gGameApp.StopGame(grSilent);
end;



function TKMRunnerDesyncTest.GetSaveDir(aSaveName: string): string;
begin
  Result := Format('%s..\..\Saves\%s\',[ExtractFilePath(ParamStr(0)), aSaveName]);
end;


procedure TKMRunnerDesyncTest.Tick_GIPRandom;
const
  FREQ = 10;
var
  hand, enemyHand: TKMHand;
  group, group2: TKMUnitGroup;
  enemyUnit: TKMUnit;
  house, enemyHouse: TKMHouse;
  ht: TKMHouseType;
  P: TKMPoint;
begin
  // Enable to allow gMySpectator.HandIndex change
//  SHOW_STATUS_BAR := True;
//  DEV_CHEATS := True;

  // We use gRandom.Get for repeatability in Stadium

  if KaMRandom(100, '') = 0 then
  begin
    gMySpectator.HandID := KaMRandom(gHands.Count, '');
    hand := gMySpectator.Hand;

    if hand.IsAnimal then Exit;

    // Army
    if hand.UnitGroups.Count > 0 then
    begin
      group := hand.UnitGroups[KaMRandom(hand.UnitGroups.Count, '')];

      case KaMRandom(FREQ, '') of
        0:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmyFeed, group);
        1:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmySplit, group);
        2:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmySplitSingle, group);
        3:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmyStorm, group);
        4:  gGameApp.Game.GameInputProcess.CmdArmy(gicArmyHalt, group);
      end;

      enemyHand := gHands[KaMRandom(gHands.Count, '')];
      if enemyHand <> hand then
      if enemyHand.Units.Count > 0 then
      begin
        enemyUnit := enemyHand.Units[KaMRandom(enemyHand.Units.Count, '')];

        if KaMRandom(FREQ, '') = 0 then
          gGameApp.Game.GameInputProcess.CmdArmy(gicArmyAttackUnit, group, enemyUnit);
      end;

      group2 := hand.UnitGroups[KaMRandom(hand.UnitGroups.Count, '')];

      if KaMRandom(FREQ, '') = 0 then
        gGameApp.Game.GameInputProcess.CmdArmy(gicArmyLink, group, group2);

      if enemyHand.Houses.Count > 0 then
      begin
        enemyHouse := enemyHand.Houses[KaMRandom(enemyHand.Houses.Count, '')];

        if KaMRandom(FREQ, '') = 0 then
          gGameApp.Game.GameInputProcess.CmdArmy(gicArmyAttackHouse, group, enemyHouse);
      end;

//      if hand.Houses.Count > 0 then
//      begin
//        house := hand.Houses[KaMRandom(hand.Houses.Count, '')];
//        if house.HouseType in [htTowerArrow, htTower2] then
//        if KaMRandom(FREQ, '') = 0 then
//          gGameApp.Game.GameInputProcess.CmdArmyCrewTower(group, house);
//      end;

//      if group.IsInsideTower then
//      begin
//        if KaMRandom(FREQ, '') = 0 then
//          gGameApp.Game.GameInputProcess.CmdArmyExitHouse(group, group.Members[0].InHouse);
//      end;

      if KaMRandom(FREQ, '') = 0 then
        gGameApp.Game.GameInputProcess.CmdArmy(gicArmyFormation, group, TKMTurnDirection(KaMRandom(3, '')), KaMRandom(group.Count, ''));
      if KaMRandom(FREQ, '') = 0 then
        gGameApp.Game.GameInputProcess.CmdArmy(gicArmyWalk, group, TKMPoint.New(KaMRandom(gTerrain.MapX-1,''), KaMRandom(gTerrain.MapY-1, '')), TKMDirection(KaMRandom(9, '')));
    end;

    // Building
    begin
      // gicBuildRemoveFieldPlan
      P := gTerrain.EnsureTileInMapCoords(hand.CenterScreen + TKMPoint.New(KaMRandomI2(30,''), KaMRandomI2(30,'')));
      case KaMRandom(FREQ, '') of
        0: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveFieldPlan, P);
        1: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveHouse, P);
        2: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveHousePlan, P);
      end;

      P := gTerrain.EnsureTileInMapCoords(hand.CenterScreen + TKMPoint.New(KaMRandomI2(30,''), KaMRandomI2(30,'')));
      case KaMRandom(FREQ, '') of
        0: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveFieldPlan, P);
        1: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveHouse, P);
        2: gGameApp.Game.GameInputProcess.CmdBuild(gicBuildRemoveHousePlan, P);
      end;

      // CmdBuildAddFieldPlan
      if KaMRandom(FREQ, '') = 0 then
      begin
        P := gTerrain.EnsureTileInMapCoords(hand.CenterScreen + TKMPoint.New(KaMRandomI2(30,''), KaMRandomI2(30,'')));
        gGameApp.Game.GameInputProcess.CmdBuild(gicBuildAddFieldPlan, P, TKMFieldType(KaMRandom(3, '') + 1))
      end;
//
      // CmdBuildAddHousePlan
      if KaMRandom(FREQ * 5, '') = 0 then
      begin
        P := gTerrain.EnsureTileInMapCoords(hand.CenterScreen + TKMPoint.New(KaMRandomI2(30, ''), KaMRandomI2(30, '')));
        ht := TKMHouseType(KaMRandom(Ord(HOUSE_MAX) - Ord(HOUSE_MIN) + 1, '') + 2);
        if (ht <> htSiegeWorkshop)
          and gRes.Houses.IsValid(ht)
          {and gRes.Houses[ht].HouseEnabled
          and gRes.Houses[ht].Buildable} then
          gGameApp.Game.GameInputProcess.CmdBuild(gicBuildHousePlan, P, ht);
      end;
    end;

    // House
    if hand.Houses.Count > 0 then
    begin
      house := hand.Houses[KaMRandom(hand.Houses.Count, '')];

      // gicHouseRepairToggle, gicHouseClosedForWorkerTgl, gicHBarracksAcceptRecruitsTgl, gicHouseDeliveryModeNext, gicHouseDeliveryModePrev
      case KaMRandom(FREQ, '') of
        0:  gGameApp.Game.GameInputProcess.CmdHouse(gicHouseRepairToggle, house);
        1:  gGameApp.Game.GameInputProcess.CmdHouse(gicHouseClosedForWorkerTgl, house);
        2:  gGameApp.Game.GameInputProcess.CmdHouse(gicHBarracksAcceptRecruitsTgl, house);
        3:  gGameApp.Game.GameInputProcess.CmdHouse(gicHouseDeliveryModeNext, house);
        4:  gGameApp.Game.GameInputProcess.CmdHouse(gicHouseDeliveryModePrev, house);
      end;

      //gicHouseOrderProduct, gicHouseSchoolTrainChOrder
      if KaMRandom(FREQ, '') = 0 then
        if house.IsComplete then
          if gRes.Houses[house.HouseType].DoesOrders then
            gGameApp.Game.GameInputProcess.CmdHouse(gicHouseOrderProduct, house, KaMRandom(4, ''), KaMRandom(9, ''));

      //gicHouseRemoveTrain gicHouseSchoolTrainChOrder gicHouseRemoveTrain gicHouseSchoolTrain gicHouseSchoolTrainChLastUOrder
      if house.IsComplete then
        if house.HouseType = htSchool then
          case KaMRandom(FREQ, '') of
            0: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseRemoveTrain, house, KaMRandom(5, ''));
//            1: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseSchoolTrainChOrder, house, KaMRandom(5, ''), KaMRandom(5, ''));
            2: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseRemoveTrain, house, KaMRandom(5, ''));
            3: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseSchoolTrain, house, School_Order[KaMRandom(Length(School_Order), '')], KaMRandom(10, ''));
//            4: gGameApp.Game.GameInputProcess.CmdHouse(gicHouseSchoolTrainChLastUOrder, house, KaMRandom(2, ''));
          end;


//      if KaMRandom(FREQ, '') = 0 then
//        if gRes.Houses[house.HouseType].IsSpacious then
//          if (gRes.Houses[house.HouseType].WareInCount > 0) then
//            gGameApp.Game.GameInputProcess.CmdHouseWareBlock(
//              house, gRes.Houses[house.HouseType].WareInType[KaMRandom(gRes.Houses[house.HouseType].WareInCount)]);
//
//    //procedure CmdHouseMarketFrom(aHouse: TKMHouse; aItem: TKMWareType);
//    //procedure CmdHouseMarketTo(aHouse: TKMHouse; aItem: TKMWareType);
//
//      if KaMRandom(FREQ, '') = 0 then
//        if house.HouseType = htWoodcutters then
//          gGameApp.Game.GameInputProcess.CmdHouseWoodcutterMode(house, TKMWoodcutterMode(KaMRandom(3, '')));
//
//      if KaMRandom(FREQ, '') = 0 then
//      if house.IsComplete then
//        if gRes.Houses[house.HouseType].TrainCount > 0 then
//          gGameApp.Game.GameInputProcess.CmdHouseTrainQueueAdd(
//            house, gRes.Houses[house.HouseType].Trains[KaMRandom(gRes.Houses[house.HouseType].TrainCount)], KaMRandom(3, ''));
//
//      if KaMRandom(FREQ, '') = 0 then
//      if house.IsComplete then
//        if gRes.Houses[house.HouseType].TrainCount > 0 then
//          gGameApp.Game.GameInputProcess.CmdHouseTrainQueueRemoveIndex(
//            house, KaMRandom(3, ''), KaMRandom(3, ''));
    end;
  end;
end;




{ TKMRunnerStone }
procedure TKMRunnerStone.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 0;

  AI_GEN_INFLUENCE_MAPS := False;
  AI_GEN_NAVMESH := False;
  DYNAMIC_TERRAIN := False;
end;


procedure TKMRunnerStone.TearDown;
begin
  inherited;
  AI_GEN_INFLUENCE_MAPS := True;
  AI_GEN_NAVMESH := True;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMRunnerStone.Execute(aRun: Integer);
var
  I,K: Integer;
  L: TKMPointList;
  P: TKMPoint;
begin
  //Total amount of stone = 4140
  gTerrain := TKMTerrain.Create;
//  gTerrain.LoadFromFile(ExeDir + 'Maps\StoneMines\StoneMines.map', False);
  gTerrain.LoadFromFile(ExeDir + 'Maps\StoneMinesTest\StoneMinesTest.map', False);

  SetKaMSeed(aRun+1);

  //Stonemining is done programmatically, by iterating through all stone tiles
  //and mining them if conditions are right (like Stonemasons would do)

  L := TKMPointList.Create;
  for I := 1 to gTerrain.MapY - 2 do
  for K := 1 to gTerrain.MapX - 1 do
  if gTerrain.TileIsStone(K,I) > 0 then
    L.Add(KMPoint(K,I));

  I := 0;
  fResults.Value[aRun, 0] := 0;
  repeat
    L.GetRandom(P);

    if gTerrain.TileIsStone(P.X,P.Y) > 0 then
    begin
      if gTerrain.CheckPassability(KMPointBelow(P), tpWalk) then
      begin
        gTerrain.DecStoneDeposit(P);
        fResults.Value[aRun, 0] := fResults.Value[aRun, 0] + 3;
        I := 0;
      end;
    end
    else
      L.Remove(P);

    Inc(I);
    if I > 200 then
      Break;
  until (L.Count = 0);

  FreeAndNil(gTerrain);
end;




{ TKMRunnerFight95 }
procedure TKMRunnerFight95.SetUp;
begin
  inherited;
  fResults.ValueCount := 2;
//  fResults.TimesCount := 2*60*10;

  DYNAMIC_TERRAIN := False;
end;


procedure TKMRunnerFight95.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMRunnerFight95.Execute(aRun: Integer);
begin
  gGameApp.NewEmptyMap(128, 128);
  SetKaMSeed(aRun + 1);

  //fPlayers[0].AddUnitGroup(ut_Cavalry, KMPoint(63, 64), dir_E, 8, 24);
  //fPlayers[1].AddUnitGroup(ut_Swordsman, KMPoint(65, 64), dir_W, 8, 24);

  //fPlayers[0].AddUnitGroup(ut_Swordsman, KMPoint(63, 64), dir_E, 8, 24);
  //fPlayers[1].AddUnitGroup(ut_Hallebardman, KMPoint(65, 64), dir_W, 8, 24);

  //fPlayers[0].AddUnitGroup(ut_Hallebardman, KMPoint(63, 64), dir_E, 8, 24);
  //fPlayers[1].AddUnitGroup(ut_Cavalry, KMPoint(65, 64), dir_W, 8, 24);

  gHands[0].AddUnitGroup(utSwordsman, KMPoint(63, 64), TKMDirection(dirE), 8, 24);
  gHands[1].AddUnitGroup(utSwordsman, KMPoint(65, 64), TKMDirection(dirW), 8, 24);

  gHands[1].UnitGroups[0].OrderAttackUnit(gHands[0].Units[0], True);

  SimulateGame;

  fResults.Value[aRun, 0] := gHands[0].Stats.GetUnitQty(utAny);
  fResults.Value[aRun, 1] := gHands[1].Stats.GetUnitQty(utAny);

  gGameApp.StopGame(grSilent);
end;




{ TKMRunnerAIBuild }
procedure TKMRunnerAIBuild.SetUp;
begin
  inherited;
  if gLog = nil then
    gLog := TKMLog.Create(ExeDir + 'Utils\Runner\Runner_Log.log');

  fResults.ValueCount := 6;
//  fResults.TimesCount := 60*60*10;
  fResults.TimesCount := 10;
  HTotal := 0;
  HAver := 0;
  WTotal := 0;
  WAver := 0;
  GTotal := 0;
  GAver := 0;
  Runs := 0;
  Time := TimeGet;

  //SKIP_LOADING_CURSOR := True;
end;


procedure TKMRunnerAIBuild.TearDown;
begin
  //
  HAver := HTotal / (Runs*HandsCnt);
  WAver := WTotal / (Runs*HandsCnt);
  WFAver := WFTotal / (Runs*HandsCnt);
  GAver := GTotal / (Runs*HandsCnt);

  gLog.AddTime('==================================================================');
  gLog.AddTime(Format('HAver: %3.2f  WAver: %3.2f  WFAver: %3.2f  GAver: %5.2f', [HAver, WAver, WFAver, GAver]));
  gLog.AddTime('TimeAver: ' + IntToStr(Round(GetTimeSince(Time)/Runs)));
  gLog.AddTime('Time: ' + IntToStr(GetTimeSince(Time)));
  inherited;
end;


procedure TKMRunnerAIBuild.Execute(aRun: Integer);
var Str: String;
    I: Integer;
    HRun, HRunT, WRun, WRunT, WFRun, WFRunT, GRun, GRunT: Cardinal;
    StartT: Cardinal;
begin
  //gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\MapsMP\Cursed Ravine\Cursed Ravine.dat', 'Cursed Ravine');
  gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\Maps\GA_'+IntToStr(aRun+1)+'\GA_'+IntToStr(aRun+1)+'.dat', 'GA');
  Inc(Runs);
  gMySpectator.Hand.FogOfWar.RevealEverything;
  gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(136, 25), 0);
  gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;

  SetKaMSeed(aRun + 1);
  StartT := TimeGet;

  SimulateGame;

  gGameApp.Game.Save('AI Build #' + IntToStr(aRun), Now);

  {fResults.Value[aRun, 0] := gHands[0].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 1] := gHands[1].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 2] := gHands[2].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 3] := gHands[3].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 4] := gHands[4].Stats.GetWarriorsTrained;
  fResults.Value[aRun, 5] := gHands[5].Stats.GetWarriorsTrained;}

  {fResults.Value[aRun, 0] := gHands[0].Stats.GetGoodsProduced(rt_Stone);
  fResults.Value[aRun, 1] := gHands[1].Stats.GetGoodsProduced(rt_Stone);
  fResults.Value[aRun, 2] := gHands[2].Stats.GetGoodsProduced(rt_Stone);
  fResults.Value[aRun, 3] := gHands[3].Stats.GetGoodsProduced(rt_Stone);
  fResults.Value[aRun, 4] := gHands[4].Stats.GetGoodsProduced(rt_Stone);}

//  fResults.Value[aRun, 0] := gHands[0].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 1] := gHands[1].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 2] := gHands[2].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 3] := gHands[3].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 4] := gHands[4].Stats.GetHousesBuilt;
//  fResults.Value[aRun, 5] := gHands[5].Stats.GetHousesBuilt;

  gLog.AddTime('------- Run ' + IntToStr(Runs));
  HandsCnt := gHands.Count - 1;
  HRunT := 0;
  WRunT := 0;
  WFRunT := 0;
  GRunT := 0;
  for I := 1 to HandsCnt do
  begin
    Str := '';
    HRun := gHands[I].Stats.GetHousesBuilt;
    HRunT := HRunT + HRun;
    HTotal := HTotal + HRun;
    WRun := gHands[I].Stats.GetWarriorsTrained;
    WTotal := WTotal + WRun;
    WRunT := WRunT + WRun;
    WFRun := gHands[I].Stats.GetWaresProduced(wtWarfare);
    WFTotal := WFTotal + WFRun;
    WFRunT := WFRunT + WFRun;
    GRun := gHands[I].Stats.GetWaresProduced(wtAll);
    GTotal := GTotal + GRun;
    GRunT := GRunT + GRun;
    Str := Str + Format('Hand%d: H: %d  W: %d  WF: %d  G: %d', [I, HRun, WRun, WFRun, GRun]);
    gLog.AddTime(Str);
  end;
  gLog.AddTime(Format('HRunAver: %3.2f  WRunAver: %3.2f  WFRunAver: %3.2f  GRunAver: %5.2f',
               [HRunT/HandsCnt, WRunT/HandsCnt, WFRunT/HandsCnt,  GRunT/HandsCnt]));
  gLog.AddTime('Time: ' + IntToStr(GetTimeSince(StartT)));

  gGameApp.StopGame(grSilent);
end;




{ TKMVortamicPF }
procedure TKMVortamicPF.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 5*60*10;
end;

procedure TKMVortamicPF.TearDown;
begin
  inherited;

end;

procedure TKMVortamicPF.Execute(aRun: Integer);
var
  T: Cardinal;
begin
  inherited;

  //Intended to be run multiple of 4 times to compare different PF algorithms
//  PathFinderToUse := (aRun mod 4) div 2; //01230123 > 00110011
//  CACHE_PATHFINDING := Boolean(aRun mod 2);  //0101

  gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\Maps\Vortamic\Vortamic.dat', 'Across the Desert');

  SetKaMSeed(aRun div 4 + 1); //11112222

  T := TimeGet;
  SimulateGame;
  fResults.Value[aRun, 0] := TimeGet - T;

  gGameApp.StopGame(grSilent);
end;




{ TKMReplay }
procedure TKMReplay.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 2*60*60*10;
end;

procedure TKMReplay.TearDown;
begin
  inherited;

end;

procedure TKMReplay.Execute(aRun: Integer);
var
  T: Cardinal;
begin
  inherited;

  gGameApp.NewReplay(ExtractFilePath(ParamStr(0)) + '\runner_replay.bas');

  //Don't set random seed or the replay won't work

  T := TimeGet;
  SimulateGame;
  fResults.Value[aRun, 0] := TimeGet - T;

  gGameApp.StopGame(grSilent);
end;




{ TKMVas01 }
procedure TKMVas01.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 2*60*10;
end;

procedure TKMVas01.TearDown;
begin
  inherited;

end;

procedure TKMVas01.Execute(aRun: Integer);
const
  cmp: TKMCampaignId = (Byte('V'), Byte('A'), Byte('S'));
var
  C: TKMCampaign;
  T: Cardinal;
begin
  inherited;

  C := gGameApp.Campaigns.CampaignById(cmp);
  gGameApp.NewCampaignMap(C, 1);

  gMySpectator.FOWIndex := -1;
  gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(162, 26), 0);
  gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.5;

  //Don't set random seed or the replay won't work

  T := TimeGet;
  SimulateGame;
  fResults.Value[aRun, 0] := TimeGet - T;

  gGameApp.StopGame(grSilent);
end;




{ TKMStabilityTest }
procedure TKMStabilityTest.SetUp;
begin
  inherited;
  // Do something before simulation
  if gLog = nil then
    gLog := TKMLog.Create(Format('%s\Utils\Runner\Runner_Log.log',[ExeDir]));

  fTime := TimeGet;
end;


procedure TKMStabilityTest.TearDown;
begin
  // Do something after simulation
  gLog.AddTime('TimeAver: ' + IntToStr(Round(GetTimeSince(fTime)/fRuns)));
  gLog.AddTime('Time: ' + IntToStr(GetTimeSince(fTime)));

  inherited;
end;


procedure TKMStabilityTest.Execute(aRun: Integer);
const
  MAPS_COUNT = 1;
var
  aIdx: Integer;
begin
  Inc(fRuns);
  for aIdx := 0 to MAPS_COUNT - 1 do
  begin
	  gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\MapsMP\Cursed Ravine\Cursed Ravine.dat', 'GA');
	  // Set Runner interface (only in case that you want to watch game in real time)
	  //gMySpectator.Hand.FogOfWar.RevealEverything;
	  //gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(0, 60), 0);
	  //gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;
	  // Set seed
	  SetKaMSeed(aRun + 1);
	  // Save game before starts (save map and seed)
	  gGameApp.Game.Save('Stability Test ' + IntToStr(aRun) + ' map number ' + IntToStr(aIdx), Now);
	  SimulateGame;
	  // Save after is simulation done
	  //gGameApp.Game.Save('Stability Test #' + IntToStr(aRun) + '; map number: ' + IntToStr(aIdx), Now);
  end;

  gGameApp.StopGame(grSilent);
end;


initialization
  RegisterRunner(TKMRunnerDesyncTest);
  RegisterRunner(TKMRunnerPushModes);
  RegisterRunner(TKMRunnerGA_TestParRun);
  RegisterRunner(TKMRunnerGA_HandLogistics);
  RegisterRunner(TKMRunnerGA_Manager);
  RegisterRunner(TKMRunnerGA_RoadPlanner);
  RegisterRunner(TKMRunnerGA_Farm);
  RegisterRunner(TKMRunnerGA_Quarry);
  RegisterRunner(TKMRunnerGA_Forest);
  RegisterRunner(TKMRunnerGA_CityAllIn);
  RegisterRunner(TKMRunnerGA_CityBuilder);
  RegisterRunner(TKMRunnerGA_CityPlanner);
  RegisterRunner(TKMRunnerGA_ArmyAttack);
  RegisterRunner(TKMRunnerGA_ArmyAttackNew);
  RegisterRunner(TKMRunnerFindBugs);
  RegisterRunner(TKMRunnerCombatAITest);
  RegisterRunner(TKMRunnerStone);
  RegisterRunner(TKMRunnerFight95);
  RegisterRunner(TKMRunnerAIBuild);
  RegisterRunner(TKMVortamicPF);
  RegisterRunner(TKMReplay);
  RegisterRunner(TKMVas01);
  RegisterRunner(TKMStabilityTest);
end.
