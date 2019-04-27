unit PlotGraph;
interface
uses
  Classes, SysUtils, Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Samples.Spin,
  GeneticAlgorithm;

type
  TPlotGraph = class
  private
    fImgGenes: TImage;
    fImgFitness: TImage;
    fActualGeneration: Integer;
    fGeneTrackBar: TTrackBar;
    fGeneTrackBarPos: Integer;
    fGeneHistory: array of array of array of Single;
    fFitnessHistory: array of array of array of Single;
    procedure PlotFitness();
    function GetFitnessSum(K,L: Integer): Single;
    procedure GetMinMaxFit(var aMinF, aMaxF: Single; aGeneration: Integer = -1);
    function GetWeightColor(aMinFit,aMaxFit,aFitnes: Single): Cardinal;
  public
    constructor Create(aImgGenes, aImgFitness: TImage; aGeneTrackBar: TTrackBar);
    destructor Destroy(); override;

    procedure InitSimulation(aGenerationsCnt,aIndividualsCnt,aGenesCnt,aMapsCnt: Word; aStartIdx: Integer = 0);
    procedure AddGeneration(aPopulation: TGAPopulation);
    procedure PlotGenes(aGenIdx: Integer);
  end;

implementation
uses
  Log;

constructor TPlotGraph.Create(aImgGenes, aImgFitness: TImage; aGeneTrackBar: TTrackBar);
var
  ResultsFile,GAFile: TextFile;
begin
  inherited Create();
  gLog.Log('TPlotGraph: Create');
  // Init variables
  fImgGenes := aImgGenes;
  fImgFitness := aImgFitness;
  SetLength(fGeneHistory,0);
  fActualGeneration := 0;
  fGeneTrackBarPos := 0;
  fGeneTrackBar := aGeneTrackBar;
end;


destructor TPlotGraph.Destroy();
begin
  gLog.Log('TPlotGraph: Destroy');
  inherited Destroy();
end;


procedure TPlotGraph.InitSimulation(aGenerationsCnt,aIndividualsCnt,aGenesCnt,aMapsCnt: Word; aStartIdx: Integer = 0);
var
  K,L: Integer;
begin
  fActualGeneration := aStartIdx;
  fGeneTrackBar.Max := 0;
  fGeneTrackBar.Visible := False;
  fGeneTrackBarPos := 0;
  SetLength(fGeneHistory,aGenerationsCnt);
  SetLength(fFitnessHistory,aGenerationsCnt);
  for K := 0 to aGenerationsCnt - 1 do
  begin
    SetLength(fGeneHistory[K],aIndividualsCnt);
    SetLength(fFitnessHistory[K],aIndividualsCnt);
    for L := 0 to aIndividualsCnt - 1 do
    begin
      SetLength(fGeneHistory[K,L],aGenesCnt);
      SetLength(fFitnessHistory[K,L],aMapsCnt);
    end;
  end;
end;


procedure TPlotGraph.AddGeneration(aPopulation: TGAPopulation);
var
  K,L,M: Integer;
begin
  if (aPopulation = nil) OR (aPopulation.Count <= 0) OR (aPopulation[0].GenesCount <= 0) then
    Exit;

  K := fActualGeneration;
  for L := 0 to aPopulation.Count - 1 do
  begin
    for M := 0 to aPopulation[L].GenesCount - 1 do
      fGeneHistory[K,L,M] := aPopulation[L].Gene[M];
    for M := 0 to aPopulation[L].FitnessCount - 1 do
      fFitnessHistory[K,L,M] := aPopulation[L].Fitness[M];
  end;
  if (fActualGeneration > 0) then
  begin
    fGeneTrackBar.Visible := True;
    fGeneTrackBar.Max := fActualGeneration;
    fGeneTrackBar.Position := fActualGeneration;
  end;
  try // Dont let GUI crashes break the simulation
    PlotGenes(fActualGeneration);
    PlotFitness();
  except
  end;
  Inc(fActualGeneration);
end;



function TPlotGraph.GetFitnessSum(K,L: Integer): Single;
var
  M: Integer;
begin
  Result := 0;
  for M := Low(fFitnessHistory[K,L]) to High(fFitnessHistory[K,L]) do
    Result := Result + fFitnessHistory[K,L,M];
end;


procedure TPlotGraph.GetMinMaxFit(var aMinF, aMaxF: Single; aGeneration: Integer = -1);
  procedure CheckGeneration(K: Integer);
  var
    L,M: Integer;
    FitSum: Single;
  begin
    for L := Low(fFitnessHistory[K]) to High(fFitnessHistory[K]) do
    begin
      FitSum := GetFitnessSum(K,L);
      if (FitSum > aMaxF) then
        aMaxF := FitSum
      else if (FitSum < aMinF) then
        aMinF := FitSum;
    end;
  end;
var
  K: Integer;
begin
  aMinF := +1E+30;
  aMaxF := -1E+30;
  if (aGeneration = -1) then
  begin
    for K := Low(fFitnessHistory) to Min( fActualGeneration, High(fFitnessHistory) ) do
      CheckGeneration(K);
  end
  else
    CheckGeneration(aGeneration);
end;


function TPlotGraph.GetWeightColor(aMinFit,aMaxFit,aFitnes: Single): Cardinal;
var
  R,G,B: Byte;
  FitRatio: Integer;
begin
  FitRatio := Round(3*255 / Max(0.0001,Abs(aMaxFit - aMinFit)) * Abs(aFitnes - aMinFit));
  G := Max(   0, 255 - FitRatio );
  FitRatio := FitRatio - 255 + G;
  R := Min( 255, FitRatio );
  FitRatio := FitRatio - R;
  B := Max(   0, 255 - FitRatio );
  Result := ($00 shl 24) OR (B shl 16) OR (G shl 8) OR (R shl 0);
end;


procedure TPlotGraph.PlotGenes(aGenIdx: Integer);
const
  OFFSET = 10;
var
  K,L,M, X,Y: Integer;
  ScaleX, ScaleY, MinF, MaxF: Single;
  Img: TImage;
begin
  Img := fImgGenes;
  if (Img = nil) OR (aGenIdx < 0) OR (aGenIdx > fActualGeneration) OR (Length(fGeneHistory) <= 0) OR (fGeneTrackBarPos = aGenIdx) then
    Exit;
  fGeneTrackBarPos := aGenIdx;
  // Clean image
  if (Img.Picture.Bitmap <> nil) then
    Img.Picture.Bitmap.SetSize(Img.Width, Img.Height);
  Img.Canvas.FillRect(Img.Canvas.ClipRect);
  // Prepare scale
  ScaleX := Max(0, (Img.Width - 2*OFFSET) / Max(1,Length(fGeneHistory[0,0])-1));
  ScaleY := Max(0, (Img.Height - 2*OFFSET));
  // Add axis
  with Img.Canvas do
  begin
    Pen.Color := ($00 shl 24) OR (200 shl 16) OR (200 shl 8) OR (200 shl 0);
    Pen.Width := 3;
    for L := Low(fGeneHistory[0,0]) to High(fGeneHistory[0,0]) do
    begin
      X := OFFSET + Round(ScaleX * L);
      Img.Canvas.PenPos := Point(X-1, OFFSET);
      Img.Canvas.LineTo(X-1,Img.Height - OFFSET);
    end;
    Pen.Color := clBlack;
    Pen.Width := 2;
    PenPos := Point(OFFSET, OFFSET);
    LineTo(OFFSET, Img.Height - OFFSET);
    LineTo(Img.Width - OFFSET, Img.Height - OFFSET);
    LineTo(Img.Width - OFFSET, OFFSET);
    LineTo(OFFSET, OFFSET);
  end;
  // Draw genes
  GetMinMaxFit(MinF, MaxF, aGenIdx);
  K := aGenIdx;
  for L := Low(fGeneHistory[K]) to High(fGeneHistory[K]) do
  begin
    Img.Canvas.Pen.Color := GetWeightColor(MinF,MaxF,GetFitnessSum(K,L));
    Img.Canvas.Pen.Width := 2;//Min(30,1 + High(fGeneHistory[K]) - L);
    for M := Low(fGeneHistory[K,L]) to High(fGeneHistory[K,L]) do
    begin
      X := OFFSET + Round(ScaleX * M);
      Y := Img.Height - OFFSET - Round(ScaleY * fGeneHistory[K,L,M]);
      if (M = 0) then
        Img.Canvas.PenPos := Point(X, Y)
      else
        Img.Canvas.LineTo(X,Y);
    end;
  end;
  Img.Repaint;
end;


procedure TPlotGraph.PlotFitness();
const
  OFFSET = 10;
var
  K,L,M, X,Y: Integer;
  ScaleX, ScaleY, MinF, MaxF, Mean, MaxVariance: Single;
  Samples, VarianceArr: array of Single;
  Img: TImage;
begin
  Img := fImgFitness;
  if (Img = nil) then
    Exit;
  // Clean image
  if (Img.Picture.Bitmap <> nil) then
    Img.Picture.Bitmap.SetSize(Img.Width, Img.Height);
  Img.Canvas.FillRect(Img.Canvas.ClipRect);
  // Add axis
  with Img.Canvas do
  begin
    Pen.Color := clBlack;
    Pen.Width := 2;
    PenPos := Point(OFFSET, OFFSET);
    LineTo(OFFSET, Img.Height - OFFSET);
    LineTo(Img.Width - OFFSET, Img.Height - OFFSET);
  end;
  // Draw mean, relative fitness, and variance
  GetMinMaxFit(MinF, MaxF);
  ScaleX := Max(0, (Img.Width  - 2*OFFSET) / Max(1,Length(fFitnessHistory)-1));
  ScaleY := Max(0, (Img.Height - 2*OFFSET) / Max(0.001, Abs(MaxF - MinF)) );
  SetLength( Samples, Length(fFitnessHistory[0]) );
  SetLength( VarianceArr, Min( fActualGeneration, High(fFitnessHistory) ) + 1 );
  MaxVariance := -1E30;
  for K := Low(fFitnessHistory) to Min( fActualGeneration, High(fFitnessHistory) ) do
  begin
    X := OFFSET + Round(ScaleX * K);
    // Get mean
    Mean := 0;
    for L := Low(fFitnessHistory[K]) to High(fFitnessHistory[K]) do
    begin
      Samples[L] := GetFitnessSum(K,L);
      Y := Img.Height - OFFSET - Round(Abs(ScaleY * (Samples[L] - MinF)));
      Img.Canvas.Pen.Color := GetWeightColor(MinF,MaxF,Samples[L]);
      Img.Canvas.Ellipse(X-2, Y-2, X+2, Y+2);
      Mean := Mean + Samples[L];
    end;
    Mean := Mean / Length(fFitnessHistory[K]);
    // Draw mean
    Y := Img.Height - OFFSET - Round(Abs(ScaleY * (Mean - MinF)));
    Img.Canvas.Pen.Color := GetWeightColor(MinF,MaxF,Mean);
    Img.Canvas.Ellipse(X-5, Y-5, X+5, Y+5);
    if (K = 0) then
      Img.Canvas.PenPos := Point(X, Y)
    else
      Img.Canvas.LineTo(X,Y);
    // Get variance
    VarianceArr[K] := 0;
    for L := Low(Samples) to High(Samples) do
      VarianceArr[K] := VarianceArr[K] + sqr(Samples[L] - Mean);
    VarianceArr[K] := VarianceArr[K] / Max(1, (Length(fFitnessHistory[K]) - 1) );
    if (MaxVariance < VarianceArr[K]) then
      MaxVariance := VarianceArr[K];
  end;
  // Draw variance
  for K := Low(VarianceArr) to High(VarianceArr) do
  begin
    X := OFFSET + Round(ScaleX * K);
    Img.Canvas.Pen.Color := 0;
    Img.Canvas.Rectangle(X+5, Img.Height - OFFSET, X+10, Img.Height - OFFSET - Round(VarianceArr[K] / Max(0.001,MaxVariance) * 50));
  end;
end;



end.
