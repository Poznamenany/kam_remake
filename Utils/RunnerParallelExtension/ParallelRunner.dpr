program ParallelRunner;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Paraller_Runner},
  PlotGraph in 'PlotGraph.pas',
  MainSimThread in 'MainSimThread.pas',
  SimThread in 'SimThread.pas',
  ComInterface in '../Runner/ComInterface.pas',
  GeneticAlgorithm in '../Runner/GeneticAlgorithm.pas',
  Log in 'Log.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TParaller_Runner, Paraller_Runner);
  Application.Run;
end.
