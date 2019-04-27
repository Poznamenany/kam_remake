unit MainForm;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.Samples.Spin,
  MainSimThread, PlotGraph, Log, Vcl.Mask, Vcl.DBCtrls;

type
  TParaller_Runner = class(TForm)
    lbClasses: TListBox;
    bRunSimulation: TButton;
    bLoad: TButton;

    pcMainPages: TPageControl;
      tsFitness: TTabSheet;
        imgFitness: TImage;
      tsGenes: TTabSheet;
        tbGeneSwitch: TTrackBar;
        imgGenes: TImage;
      TabSheet3: TTabSheet;
        Image3: TImage;
      tsLog: TTabSheet;
        mLog: TMemo;

    gbSim: TGroupBox;
      lMaps: TLabel;
      lDuration: TLabel;
      lThreads: TLabel;
      seMaps: TSpinEdit;
      seDuration: TSpinEdit;
      seThreads: TSpinEdit;

    gbGA: TGroupBox;
      lPopulation: TLabel;
      lGenerations: TLabel;
      lGenes: TLabel;
      sePopulation: TSpinEdit;
      seGenerations: TSpinEdit;
      seGenes: TSpinEdit;

      lTournament: TLabel;
      seStartTournament: TSpinEdit;
      seEndTournament: TSpinEdit;
      lResetGene: TLabel;
      eStartResetGene: TEdit;
      eEndResetGene: TEdit;
      lNormalMutation: TLabel;
      eStartGaussMut: TEdit;
      eEndGaussMut: TEdit;
      lVariance: TLabel;
      eStartVariance: TEdit;
      eEndVariance: TEdit;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure bRunSimulationClick(Sender: TObject);
    procedure tbGeneSwitchChange(Sender: TObject);
    procedure bLoadClick(Sender: TObject);
  private
    fPlot: TPlotGraph;
    fSim: TMainSimThread;
  public
    procedure Log(const aText: String);
    procedure ClearLog();
  end;

var
  Paraller_Runner: TParaller_Runner;

implementation
{$R *.dfm}


const
  COLORS_COUNT = 8;
  LineCol: array [0..COLORS_COUNT - 1] of TColor =
    (clRed, clBlue, clGreen, clPurple, clMaroon, clGray, clBlack, clOlive);




procedure TParaller_Runner.FormCreate(Sender: TObject);
var
  s: String;
begin
  s := ExtractFilePath(ParamStr(0));
  gLog := TLog.Create(Log);
  fPlot := TPlotGraph.Create(imgGenes,imgFitness,tbGeneSwitch);
  fSim := TMainSimThread.Create(fPlot,ExtractFilePath(ParamStr(0)));
  // Load default configuration
  with fSim do
  begin
      seMaps.Value            := GA_CountMaps;
      seDuration.Value        := SIM_TimeInMin;
      seThreads.Value         := SIM_CountThreads;

      sePopulation.Value      := GA_CountIndividuals;
      seGenerations.Value     := GA_Generations;
      seGenes.Value           := GA_CountGenes;

      seStartTournament.Value := GA_START_TOURNAMENT_IndividualsCnt;
      seEndTournament.Value   := GA_FINAL_TOURNAMENT_IndividualsCnt;
      eStartResetGene.Text    := FloatToStr(GA_START_MUTATION_ResetGene);
      eEndResetGene.Text      := FloatToStr(GA_FINAL_MUTATION_ResetGene);
      eStartGaussMut.Text     := FloatToStr(GA_START_MUTATION_Gaussian);
      eEndGaussMut.Text       := FloatToStr(GA_FINAL_MUTATION_Gaussian);
      eStartVariance.Text     := FloatToStr(GA_START_MUTATION_Variance);
      eEndVariance.Text       := FloatToStr(GA_FINAL_MUTATION_Variance);
  end;
end;


procedure TParaller_Runner.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fPlot);
  fSim.SimulationRequest := srTerminate;
  Sleep(100);
  FreeAndNil(fSim);
  FreeAndNil(gLog);
end;



procedure TParaller_Runner.bLoadClick(Sender: TObject);
begin
  if (fSim.SimulationRequest = srNone) then
  begin
    if fSim.InitSimulation(0) then
    begin
      gLog.Log('Simulation was loaded');
      // Load default configuration so GA can continue (other parameters does not makes sense)
      with fSim do
      begin
        seDuration.Value        := SIM_TimeInMin;
        sePopulation.Value      := GA_CountIndividuals;
        seGenes.Value           := GA_CountGenes;
        seMaps.Value            := GA_CountMaps;
      end;
    end
    else
      gLog.Log('Simulation could not be loaded');
  end;
end;

procedure TParaller_Runner.bRunSimulationClick(Sender: TObject);
var
  T: Cardinal;
  ID, Count: Integer;
begin
  if (fSim.SimulationRequest = srNone) then
  begin
    mLog.Clear;

    with fSim do
    begin
      GA_CountMaps	                         := seMaps.Value;
      SIM_TimeInMin                          := seDuration.Value;
      SIM_CountThreads                       := seThreads.Value;

      GA_CountIndividuals                    := sePopulation.Value;
      GA_Generations                         := seGenerations.Value;
      GA_CountGenes                          := seGenes.Value;

      GA_START_TOURNAMENT_IndividualsCnt     := seStartTournament.Value;
      GA_FINAL_TOURNAMENT_IndividualsCnt     := seEndTournament.Value;
      try
        GA_START_MUTATION_ResetGene          := StrToFloat(eStartResetGene.Text);
        GA_FINAL_MUTATION_ResetGene          := StrToFloat(eEndResetGene.Text  );
        GA_START_MUTATION_Gaussian           := StrToFloat(eStartGaussMut.Text );
        GA_FINAL_MUTATION_Gaussian           := StrToFloat(eEndGaussMut.Text   );
        GA_START_MUTATION_Variance           := StrToFloat(eStartVariance.Text );
        GA_FINAL_MUTATION_Variance           := StrToFloat(eEndVariance.Text   );
      except
        On E : Exception do
          Log('Exception StringToFloat');
      end;
    end;

    fSim.SimulationRequest := srRun;
  end
  else if (fSim.SimulationRequest = srRun) then
    fSim.SimulationRequest := srNone;
end;


procedure TParaller_Runner.ClearLog();
begin
  mLog.Clear;
end;


procedure TParaller_Runner.Log(const aText: String);
begin
  mLog.Lines.Append(aText);
end;


procedure TParaller_Runner.tbGeneSwitchChange(Sender: TObject);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      fPlot.PlotGenes(tbGeneSwitch.Position);
    end
  );
end;


end.
