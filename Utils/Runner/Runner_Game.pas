unit Runner_Game;
{$I KaM_Remake.inc}
interface
uses
  Forms, Unit_Runner, Windows, SysUtils, Classes, KromUtils, Math,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_ResLocales, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_ResTexts, KM_Resource,
  KM_Terrain, KM_Units, KM_UnitWarrior, KM_Campaigns, KM_AIFields, KM_Houses,
  GeneticAlgorithm, KM_AICityPlanner,
  KM_CityManagement, KM_CityPredictor, KM_CityBuilder, KM_CityPlanner, KM_Eye,
  KM_HandLogistics,
  ComInterface;


type
  //Typical usage:
  //SetUp, Execute(1), Execute(2) .. Execute(N), TearDown

  TKMRunnerGA_Common = class(TKMRunnerCommon)
  private
    fCrashDetectionMode: Boolean; // only for single thread
    fAlgorithm: TGAAlgorithm;
    fOldPopulation, fNewPopulation: TGAPopulation;
    //fFitnessCalc: TGAFitnessCalc;
    fLog, fLogPar: TKMLog;

    f_SIM_SimulationTimeInMin: Single; // Time of each simulation (GA doest not take simulation from game menu because it is only in minutes)
    f_SIM_NumberOfMaps: Word; // Count of simulated maps for each invididual
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
    procedure SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String; aSaveGame: Boolean = False); virtual;
    function Incr(var Idx: Integer): Integer;
    function CostFunction(): Single; virtual;
    procedure Execute(aRun: Integer); override;
  public
    SimSetup: TSimSetup;
    IOData: TGASetup;
  end;

  TKMRunnerGA_TestParRun = class(TKMRunnerGA_Common)
  protected
    procedure Execute(aRun: Integer); override;
  end;

  TKMRunnerGA_HandLogistics = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_CityBuilder = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_CityRoadPlanner = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_Forest = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
  end;

  TKMRunnerGA_CityPlanner = class(TKMRunnerGA_Common)
  protected
    procedure InitGAParameters(); override;
    procedure SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False); override;
    //function CostFunction(): Single; override;
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
uses KM_HandSpectator, KM_ResWares, KM_ResHouses, KM_Hand, KM_UnitsCollection;




{ TKMRunnerGA_Common }
procedure TKMRunnerGA_Common.InitGAParameters();
begin
  f_SIM_SimulationTimeInMin      := 60;
  f_SIM_NumberOfMaps             := 10;
  f_GA_POPULATION_CNT            := 40;
  f_GA_GENE_CNT                  := 5;
  f_GA_START_TOURNAMENT_IndividualsCnt := 3;
  f_GA_FINAL_TOURNAMENT_IndividualsCnt := 3;
  f_GA_START_MUTATION_ResetGene  := 1;
  f_GA_FINAL_MUTATION_ResetGene  := 5;
  f_GA_START_MUTATION_Gaussian   := 10;
  f_GA_FINAL_MUTATION_Gaussian   := 20;
  f_GA_START_MUTATION_Variance := 1;
  f_GA_FINAL_MUTATION_Variance := 0.1;
end;

procedure TKMRunnerGA_Common.SetUp;
var
  K,L: Integer;
  Pop: TGAPopulation;
begin
  inherited;
  // Deactivate KaM log
  if (gLog = nil) then
    gLog := TKMLog.Create(ExeDir + 'Utils\Runner\Runner_Log.log');
  gLog.MessageTypes := [];
  // Init common variables
  fOldPopulation := nil;
  fAlgorithm := TGAAlgorithm.Create;
  InitGAParameters();

  // Prepare parallel simulation
  if PARALLEL_RUN then
  begin
    fCrashDetectionMode := False;
    f_SIM_SimulationTimeInMin := SimSetup.SimTimeInMin;
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
    fCrashDetectionMode := True;
    // Init new population
    fNewPopulation := TGAPopulation.Create(f_GA_POPULATION_CNT, f_GA_GENE_CNT, f_SIM_NumberOfMaps, True);
    SetRndGenes();
    // Init logs
    fLog := TKMLog.Create(ExeDir + '\Utils\Runner\LOG_GA.log');
    fLogPar := TKMLog.Create(ExeDir + '\Utils\Runner\LOG_GA_PAR.log');
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


procedure TKMRunnerGA_Common.SimulateMap(aRun, aIdx, Seed: Integer; aSinglePLMapName: String; aSaveGame: Boolean = False);
begin
  gGameApp.NewSingleMap(ExtractFilePath(ParamStr(0)) + '..\..\Maps\' + aSinglePLMapName + '\' + aSinglePLMapName + '.dat', 'GA');

  //gMySpectator.Hand.FogOfWar.RevealEverything;
  //gGameApp.Game.GamePlayInterface.Viewport.PanTo(KMPointF(0, 60), 0);
  //gGameApp.Game.GamePlayInterface.Viewport.Zoom := 0.25;
  if fCrashDetectionMode then
    gGameApp.Game.Save('GA Test', Now);

  //SetKaMSeed(Max(1,Seed));
  try
    SimulateGame;
  except
    SimulateMap(aRun + 1, aIdx, Round(Random()*10000)+1, aSinglePLMapName);
  end;
  if aSaveGame then
    gGameApp.Game.Save('GA Test #' + IntToStr(aRun) + 'n' + IntToStr(aIdx), Now);
end;


// Small helping function
function TKMRunnerGA_Common.Incr(var Idx: Integer): Integer;
begin
  Result := Idx;
  Inc(Idx);
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


procedure TKMRunnerGA_Common.Execute(aRun: Integer);
const
  MIN_SCORE = - 1000000;
var
  K, MapNum: Integer;
  BestScore, Ratio: Single;
  MapName: String;
  Idv: TGAIndividual;
begin
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
      SetParameters(fOldPopulation[K], False);
      MapName := 'GA_S1_';
      if (MapNum < 10) then
        MapName := MapName + '00' // GA_S1_00X
      else if (MapNum < 100) then
        MapName := MapName + '0'; // GA_S1_0XY
      // Save GA parameters so the game will be identical
      if fCrashDetectionMode then
      begin
        if (fLogPar <> nil) then
          fLogPar.Free;
        fLogPar := TKMLog.Create(ExeDir + '\Utils\Runner\LOG_GA_PAR.log');
        SetParameters(fOldPopulation[K], True);
      end;
      SimulateMap(aRun, K, aRun, MapName + IntToStr(MapNum));// Name of maps are GA_1, GA_2 ...
      fOldPopulation[K].Fitness[MapNum-1] := CostFunction();
    end;

  if not PARALLEL_RUN then
  begin
    fNewPopulation := TGAPopulation.Create(f_GA_POPULATION_CNT, f_GA_GENE_CNT, f_SIM_NumberOfMaps, False);

    // Save best score + parameters of best individual
    Idv := fOldPopulation.GetFittest();
    fResults.Value[aRun, 0] := Round(Idv.FitnessSum);
    fLog.AddTime('GA: ' + IntToStr(aRun) + '. run. Best score: ' + FloatToStr(Idv.FitnessSum) + '.');

    // Check history and find the most fitness individual
    BestScore := MIN_SCORE;
    for K := 0 to aRun - 1 do
      if (fResults.Value[K, 0] > BestScore) then
        BestScore := fResults.Value[K, 0];
    // If is the individual from the latest generation the best then log parameters
    if (BestScore < Idv.FitnessSum) then
      SetParameters(Idv, not PARALLEL_RUN);
  end;

  // Stop simulation
  gGameApp.StopGame(grSilent);
end;



{ TKMRunnerGA_TestParRun }
procedure TKMRunnerGA_TestParRun.Execute(aRun: Integer);
var
  K,L,MapNum: Integer;
  Fitness: Single;
begin
  // Fitness is calculated from genes in this debug class
  for MapNum := 0 to f_SIM_NumberOfMaps - 1 do
    for K := 0 to fNewPopulation.Count - 1 do
    begin
      Fitness := 0;
      for L := 0 to fNewPopulation.Individual[K].GenesCount - 1 do
        Fitness := Fitness - abs(L / fNewPopulation.Individual[K].GenesCount - fNewPopulation.Individual[K].Gene[L]);
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
  f_SIM_SimulationTimeInMin   := 65;
  f_SIM_NumberOfMaps          := 20;
  f_GA_POPULATION_CNT         := 40;
  f_GA_GENE_CNT               := 4;
end;

procedure TKMRunnerGA_HandLogistics.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
//var
//  I: Integer;
begin
  //I := 0;

  //GA_TCBB_BasicInit   := Max(1, Round(aIdv.Gene[Incr(I)] * 20));
  //GA_TCBB_BasicRnd    := Max(1, Round(aIdv.Gene[Incr(I)] * 60)+40);
  //GA_TCBB_NormRnd     := Max(1, Round(aIdv.Gene[Incr(I)] * 32));
  //GA_TCBB_Rnd         := Max(1, Round(aIdv.Gene[Incr(I)] * 50));
  //GA_TCBB_BasicPwr    := Max(1, Round(GA_TCBB_BasicRnd / 5)); // GA has discovered that this is best strategy
  //GA_TCBB_NormPwr     := Max(1, Round(GA_TCBB_NormRnd / 5));
  //
  //if aLogIt then
  //begin
  //  fLogPar.AddTime('GA_TCBB_BasicInit   : Integer = ' + IntToStr( GA_TCBB_BasicInit ) + ';');
  //  fLogPar.AddTime('GA_TCBB_BasicRnd    : Integer = ' + IntToStr( GA_TCBB_BasicRnd  ) + ';');
  //  fLogPar.AddTime('GA_TCBB_BasicPwr    : Integer = ' + IntToStr( GA_TCBB_BasicPwr  ) + ';');
  //  fLogPar.AddTime('GA_TCBB_NormRnd     : Integer = ' + IntToStr( GA_TCBB_NormRnd   ) + ';');
  //  fLogPar.AddTime('GA_TCBB_NormPwr     : Integer = ' + IntToStr( GA_TCBB_NormPwr   ) + ';');
  //  fLogPar.AddTime('GA_TCBB_Rnd         : Integer = ' + IntToStr( GA_TCBB_Rnd       ) + ';');
  //end;
end;


{ TKMRunnerGA_CityBuilder }
procedure TKMRunnerGA_CityBuilder.InitGAParameters();
begin
  inherited;
  f_SIM_SimulationTimeInMin   := 65;
  f_SIM_NumberOfMaps          := 20;
  f_GA_POPULATION_CNT         := 40;
  f_GA_GENE_CNT               := 12+2;//2
end;

procedure TKMRunnerGA_CityBuilder.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;

  //GA_BUILDER_BuildHouse_FieldMaxWork    := Max(1, aIdv.Gene[Incr(I)] * 10);
  //GA_BUILDER_BuildHouse_RTPMaxWork      := Max(1, aIdv.Gene[Incr(I)] * 20);
  GA_BUILDER_BuildHouse_RoadMaxWork     := Max(1, aIdv.Gene[Incr(I)] * 30);
  GA_BUILDER_CreateShortcuts_MaxWork    := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_ChHTB_FractionCoef         := Max(1, aIdv.Gene[Incr(I)] * 30);
  GA_BUILDER_ChHTB_TrunkFactor          := Max(1, aIdv.Gene[Incr(I)] * 10);
  GA_BUILDER_ChHTB_TrunkBalance         := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_ChHTB_AllWorkerCoef        := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_ChHTB_FreeWorkerCoef       := Max(1, aIdv.Gene[Incr(I)] * 15);
  GA_BUILDER_Shortage_Trunk             := Max(0.1, aIdv.Gene[Incr(I)] * 20);
  GA_BUILDER_Shortage_Stone             := Max(1, aIdv.Gene[Incr(I)] * 20);
  GA_BUILDER_Shortage_StoneNoQuarry     := Max(1, aIdv.Gene[Incr(I)] * 20 + 20);
  GA_BUILDER_Shortage_Wood              := Max(1, aIdv.Gene[Incr(I)] * 20);
  GA_BUILDER_Shortage_Gold              := Max(1, aIdv.Gene[Incr(I)] * 20 + 20);
  GA_PREDICTOR_WareNeedPerAWorker_Stone := aIdv.Gene[Incr(I)] * 1;
  GA_PREDICTOR_WareNeedPerAWorker_Wood  := aIdv.Gene[Incr(I)] * 1;

  if aLogIt then
  begin
    //fLogPar.AddTime('GA_BUILDER_BuildHouse_FieldMaxWork    : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_BuildHouse_FieldMaxWork    ) + ';');
    //fLogPar.AddTime('GA_BUILDER_BuildHouse_RTPMaxWork      : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_BuildHouse_RTPMaxWork      ) + ';');
    fLogPar.AddTime('GA_BUILDER_BuildHouse_RoadMaxWork     : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_BuildHouse_RoadMaxWork     ) + ';');
    fLogPar.AddTime('GA_BUILDER_CreateShortcuts_MaxWork    : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_CreateShortcuts_MaxWork    ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_FractionCoef         : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_ChHTB_FractionCoef         ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_TrunkFactor          : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_ChHTB_TrunkFactor          ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_TrunkBalance         : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_ChHTB_TrunkBalance         ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_AllWorkerCoef        : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_ChHTB_AllWorkerCoef        ) + ';');
    fLogPar.AddTime('GA_BUILDER_ChHTB_FreeWorkerCoef       : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_ChHTB_FreeWorkerCoef       ) + ';');
    fLogPar.AddTime('GA_BUILDER_Shortage_Trunk             : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_Shortage_Trunk             ) + ';');
    fLogPar.AddTime('GA_BUILDER_Shortage_Stone             : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_Shortage_Stone             ) + ';');
    fLogPar.AddTime('GA_BUILDER_Shortage_StoneNoQuarry     : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_Shortage_StoneNoQuarry     ) + ';');
    fLogPar.AddTime('GA_BUILDER_Shortage_Wood              : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_Shortage_Wood              ) + ';');
    fLogPar.AddTime('GA_BUILDER_Shortage_Gold              : Single = ' + FormatFloat( '0.###########################', GA_BUILDER_Shortage_Gold              ) + ';');
    fLogPar.AddTime('GA_PREDICTOR_WareNeedPerAWorker_Stone : Single = ' + FormatFloat( '0.###########################', GA_PREDICTOR_WareNeedPerAWorker_Stone ) + ';');
    fLogPar.AddTime('GA_PREDICTOR_WareNeedPerAWorker_Wood  : Single = ' + FormatFloat( '0.###########################', GA_PREDICTOR_WareNeedPerAWorker_Wood  ) + ';');
  end;
end;


{ TKMRunnerGA_CityRoadPlanner }
procedure TKMRunnerGA_CityRoadPlanner.InitGAParameters();
begin
  inherited;
  f_SIM_SimulationTimeInMin   := 10;
  f_SIM_NumberOfMaps          := 5;
  f_GA_POPULATION_CNT         := 5;
  f_GA_GENE_CNT               := 14+2;
end;


procedure TKMRunnerGA_CityRoadPlanner.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;
  GA_PATHFINDING_BasePrice                := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_PATHFINDING_HouseOutside             := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_PATHFINDING_Field                    := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_PATHFINDING_NoBuildArea              := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_PATHFINDING_Coal                     := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_PATHFINDING_Forest                   := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_PATHFINDING_OtherCase                := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );

  GA_SHORTCUTS_BasePrice                  := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_SHORTCUTS_HouseOutside               := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_SHORTCUTS_Field                      := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_SHORTCUTS_NoBuildArea                := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_SHORTCUTS_Coal                       := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_SHORTCUTS_Forest                     := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );
  GA_SHORTCUTS_OtherCase                  := Round( Max(0, aIdv.Gene[Incr(I)] * 50) );

  GA_MANAGEMENT_CheckUnitCount_SerfCoef   := Max(1, aIdv.Gene[Incr(I)] * 5);
  GA_MANAGEMENT_CheckUnitCount_SerfLimit  := Max(1, aIdv.Gene[Incr(I)] * 5);

  if aLogIt then
  begin
    fLogPar.AddTime('GA_PATHFINDING_BasePrice               : Word = ' + IntToStr( GA_PATHFINDING_BasePrice               ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_HouseOutside            : Word = ' + IntToStr( GA_PATHFINDING_HouseOutside            ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_Field                   : Word = ' + IntToStr( GA_PATHFINDING_Field                   ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_NoBuildArea             : Word = ' + IntToStr( GA_PATHFINDING_NoBuildArea             ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_Coal                    : Word = ' + IntToStr( GA_PATHFINDING_Coal                    ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_Forest                  : Word = ' + IntToStr( GA_PATHFINDING_Forest                  ) + ';');
    fLogPar.AddTime('GA_PATHFINDING_OtherCase               : Word = ' + IntToStr( GA_PATHFINDING_OtherCase               ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_BasePrice                 : Word = ' + IntToStr( GA_SHORTCUTS_BasePrice                 ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_HouseOutside              : Word = ' + IntToStr( GA_SHORTCUTS_HouseOutside              ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_Field                     : Word = ' + IntToStr( GA_SHORTCUTS_Field                     ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_NoBuildArea               : Word = ' + IntToStr( GA_SHORTCUTS_NoBuildArea               ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_Coal                      : Word = ' + IntToStr( GA_SHORTCUTS_Coal                      ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_Forest                    : Word = ' + IntToStr( GA_SHORTCUTS_Forest                    ) + ';');
    fLogPar.AddTime('GA_SHORTCUTS_OtherCase                 : Word = ' + IntToStr( GA_SHORTCUTS_OtherCase                 ) + ';');
    fLogPar.AddTime('GA_MANAGEMENT_CheckUnitCount_SerfCoef  : Word = ' + FormatFloat( '0.###########################', GA_MANAGEMENT_CheckUnitCount_SerfCoef  ) + ';');
    fLogPar.AddTime('GA_MANAGEMENT_CheckUnitCount_SerfLimit : Word = ' + FormatFloat( '0.###########################', GA_MANAGEMENT_CheckUnitCount_SerfLimit ) + ';');
  end;
end;




{ TKMRunnerGA_Forest }
procedure TKMRunnerGA_Forest.InitGAParameters();
begin
  inherited;
  f_SIM_SimulationTimeInMin   := 60;
  f_SIM_NumberOfMaps          := 20;
  f_GA_POPULATION_CNT         := 40;
  f_GA_GENE_CNT               := 16;
end;


procedure TKMRunnerGA_Forest.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;

  GA_EYE_GetForests_MaxAB                       := 1 + aIdv.Gene[Incr(I)] * 200; // <0,201> Ignore trees in existing forest <0,255-AVOID_BUILDING_FOREST_MINIMUM)
  GA_EYE_GetForests_MinTrees                    := 1 + aIdv.Gene[Incr(I)] *   5; // Min trees in forest
  GA_EYE_GetForests_Radius                      := 3 + aIdv.Gene[Incr(I)] *   5; // Forest radius
  GA_EYE_GetForests_MinRndSoil                  := 0 + aIdv.Gene[Incr(I)] *  82; // 0-82
  GA_EYE_GetForests_SPRndOwnLimMin              := 0 + aIdv.Gene[Incr(I)] * 255; // Minimum influence of potential forest
  GA_EYE_GetForests_SPRndOwnLimMax              := 0 + aIdv.Gene[Incr(I)] * 255; // Maximum influence of potential forest
  GA_EYE_GetForests_RndCount                    := 1 + aIdv.Gene[Incr(I)] *  30; // Minimum count of potential forest
  GA_EYE_GetForests_RndLimit                    := 0 + aIdv.Gene[Incr(I)] *   1; // Random limit for forest plan

  GA_PLANNER_FindPlaceForWoodcutter_TreeCnt     := 0 + aIdv.Gene[Incr(I)] *   1 *  21; // 0-~12
  GA_PLANNER_FindPlaceForWoodcutter_ExistForest := 0 + aIdv.Gene[Incr(I)] *   1 * 255; // 0-1
  GA_PLANNER_FindPlaceForWoodcutter_Routes      := 0 + aIdv.Gene[Incr(I)] *   1 *   1; // 0-255
  GA_PLANNER_FindPlaceForWoodcutter_FlatArea    := 0 + aIdv.Gene[Incr(I)] *   1 *   3; // 0-81
  GA_PLANNER_FindPlaceForWoodcutter_Soil        := 0 + aIdv.Gene[Incr(I)] *   1 *   3; // 0-81
  GA_PLANNER_FindPlaceForWoodcutter_DistCrit    := 0 + aIdv.Gene[Incr(I)] *   1 *   2; // 0-40
  GA_PLANNER_FindPlaceForWoodcutter_ABRange     := 0 + aIdv.Gene[Incr(I)] * 200; // 0-200
  GA_PLANNER_FindPlaceForWoodcutter_Radius      := 4 + aIdv.Gene[Incr(I)] *   4;

  if aLogIt then
  begin
    fLogPar.AddTime('GA_EYE_GetForests_MaxAB                       : Single = ' + FormatFloat( '0.###########################', GA_EYE_GetForests_MaxAB                       ) + ';');
    fLogPar.AddTime('GA_EYE_GetForests_MinTrees                    : Single = ' + FormatFloat( '0.###########################', GA_EYE_GetForests_MinTrees                    ) + ';');
    fLogPar.AddTime('GA_EYE_GetForests_Radius                      : Single = ' + FormatFloat( '0.###########################', GA_EYE_GetForests_Radius                      ) + ';');
    fLogPar.AddTime('GA_EYE_GetForests_MinRndSoil                  : Single = ' + FormatFloat( '0.###########################', GA_EYE_GetForests_MinRndSoil                  ) + ';');
    fLogPar.AddTime('GA_EYE_GetForests_SPRndOwnLimMin              : Single = ' + FormatFloat( '0.###########################', GA_EYE_GetForests_SPRndOwnLimMin              ) + ';');
    fLogPar.AddTime('GA_EYE_GetForests_SPRndOwnLimMax              : Single = ' + FormatFloat( '0.###########################', GA_EYE_GetForests_SPRndOwnLimMax              ) + ';');
    fLogPar.AddTime('GA_EYE_GetForests_RndCount                    : Single = ' + FormatFloat( '0.###########################', GA_EYE_GetForests_RndCount                    ) + ';');
    fLogPar.AddTime('GA_EYE_GetForests_RndLimit                    : Single = ' + FormatFloat( '0.###########################', GA_EYE_GetForests_RndLimit                    ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_TreeCnt     : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForWoodcutter_TreeCnt     ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_ExistForest : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForWoodcutter_ExistForest ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_Routes      : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForWoodcutter_Routes      ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_FlatArea    : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForWoodcutter_FlatArea    ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_Soil        : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForWoodcutter_Soil        ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_DistCrit    : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForWoodcutter_DistCrit    ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_ABRange     : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForWoodcutter_ABRange     ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForWoodcutter_Radius      : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForWoodcutter_Radius      ) + ';');
  end;
end;


{ TKMRunnerGA_CityPlanner }
procedure TKMRunnerGA_CityPlanner.InitGAParameters();
begin
  inherited;
  f_SIM_SimulationTimeInMin   := 65;
  f_SIM_NumberOfMaps          := 26;
  f_GA_POPULATION_CNT         := 10;
  f_GA_GENE_CNT               := 16;
end;


procedure TKMRunnerGA_CityPlanner.SetParameters(aIdv: TGAIndividual; aLogIt: Boolean = False);
var
  I: Integer;
begin
  I := 0;

  GA_PLANNER_ObstaclesInHousePlan_Tree       := aIdv.Gene[Incr(I)] * 100 * 5; // 0-3+
  GA_PLANNER_ObstaclesInHousePlan_Road       := aIdv.Gene[Incr(I)] *  50 * 3; // 0-5+

  GA_PLANNER_FieldCrit_PolyRoute             := aIdv.Gene[Incr(I)] *   1 * 1; // 0-255
  GA_PLANNER_FieldCrit_FlatArea              := aIdv.Gene[Incr(I)] *   3 * 4; // 0-82
  GA_PLANNER_FieldCrit_Soil                  := aIdv.Gene[Incr(I)] *   3 * 1; // 0-82

  GA_PLANNER_SnapCrit_SnapToHouse            := aIdv.Gene[Incr(I)] *  10 * 5; // 0-5+
  GA_PLANNER_SnapCrit_SnapToFields           := aIdv.Gene[Incr(I)] *  10 * 5; // 0-5+
  GA_PLANNER_SnapCrit_SnapToRoads            := aIdv.Gene[Incr(I)] *  10 * 5; // 0-5+
  GA_PLANNER_SnapCrit_ClearEntrance          := aIdv.Gene[Incr(I)] *  10 * 7; // 0-6

  GA_PLANNER_FindPlaceForHouse_SnapCrit      := aIdv.Gene[Incr(I)] *   2 * 2; // var
  GA_PLANNER_FindPlaceForHouse_HouseDist     := aIdv.Gene[Incr(I)] *  10 * 1; // 3-100+
  GA_PLANNER_FindPlaceForHouse_SeedDist      := aIdv.Gene[Incr(I)] *  10 * 5; // 3-30
  GA_PLANNER_FindPlaceForHouse_CityCenter    := aIdv.Gene[Incr(I)] *  10 * 9; // 3-100+
  GA_PLANNER_FindPlaceForHouse_Route         := aIdv.Gene[Incr(I)] *   1 * 4; // 0-255
  GA_PLANNER_FindPlaceForHouse_FlatArea      := aIdv.Gene[Incr(I)] *   3 * 2; // 0-82
  GA_PLANNER_PlaceWoodcutter_DistFromForest  := aIdv.Gene[Incr(I)] *  10 * 1; // 0-X

  if aLogIt then
  begin
    fLogPar.AddTime('GA_PLANNER_ObstaclesInHousePlan_Tree       : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_ObstaclesInHousePlan_Tree      ) + ';');
    fLogPar.AddTime('GA_PLANNER_ObstaclesInHousePlan_Road       : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_ObstaclesInHousePlan_Road      ) + ';');
    fLogPar.AddTime('GA_PLANNER_FieldCrit_PolyRoute             : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FieldCrit_PolyRoute            ) + ';');
    fLogPar.AddTime('GA_PLANNER_FieldCrit_FlatArea              : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FieldCrit_FlatArea             ) + ';');
    fLogPar.AddTime('GA_PLANNER_FieldCrit_Soil                  : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FieldCrit_Soil                 ) + ';');
    fLogPar.AddTime('GA_PLANNER_SnapCrit_SnapToHouse            : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_SnapCrit_SnapToHouse           ) + ';');
    fLogPar.AddTime('GA_PLANNER_SnapCrit_SnapToFields           : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_SnapCrit_SnapToFields          ) + ';');
    fLogPar.AddTime('GA_PLANNER_SnapCrit_SnapToRoads            : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_SnapCrit_SnapToRoads           ) + ';');
    fLogPar.AddTime('GA_PLANNER_SnapCrit_ClearEntrance          : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_SnapCrit_ClearEntrance         ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_SnapCrit      : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForHouse_SnapCrit     ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_HouseDist     : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForHouse_HouseDist    ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_SeedDist      : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForHouse_SeedDist     ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_CityCenter    : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForHouse_CityCenter   ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_Route         : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForHouse_Route        ) + ';');
    fLogPar.AddTime('GA_PLANNER_FindPlaceForHouse_FlatArea      : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_FindPlaceForHouse_FlatArea     ) + ';');
    fLogPar.AddTime('GA_PLANNER_PlaceWoodcutter_DistFromForest  : Single = ' + FormatFloat( '0.###########################', GA_PLANNER_PlaceWoodcutter_DistFromForest ) + ';');
  end;
end;







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
    gLog := TKMLog.Create(ExeDir + 'Utils\Runner\Runner_Log.log');

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
  RegisterRunner(TKMRunnerGA_TestParRun);
  RegisterRunner(TKMRunnerGA_HandLogistics);
  RegisterRunner(TKMRunnerGA_CityRoadPlanner);
  RegisterRunner(TKMRunnerGA_Forest);
  RegisterRunner(TKMRunnerGA_CityBuilder);
  RegisterRunner(TKMRunnerGA_CityPlanner);
  RegisterRunner(TKMRunnerStone);
  RegisterRunner(TKMRunnerFight95);
  RegisterRunner(TKMRunnerAIBuild);
  RegisterRunner(TKMVortamicPF);
  RegisterRunner(TKMReplay);
  RegisterRunner(TKMVas01);
  RegisterRunner(TKMStabilityTest);
end.
