object Paraller_Runner: TParaller_Runner
  Left = 0
  Top = 0
  Caption = 'Paraller_Runner'
  ClientHeight = 660
  ClientWidth = 1401
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    1401
    660)
  PixelsPerInch = 96
  TextHeight = 13
  object lbClasses: TListBox
    Left = 8
    Top = 8
    Width = 185
    Height = 113
    ItemHeight = 13
    TabOrder = 3
  end
  object bRunSimulation: TButton
    Left = 70
    Top = 575
    Width = 44
    Height = 31
    Caption = 'Run'
    TabOrder = 1
    OnClick = bRunSimulationClick
  end
  object pcMainPages: TPageControl
    Left = 199
    Top = 8
    Width = 1202
    Height = 644
    ActivePage = tsFitness
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 2
    object tsFitness: TTabSheet
      Caption = 'Fitness'
      DesignSize = (
        1194
        616)
      object imgFitness: TImage
        Left = 3
        Top = 3
        Width = 1188
        Height = 610
        Anchors = [akLeft, akTop, akRight, akBottom]
      end
    end
    object tsGenes: TTabSheet
      Caption = 'Genes'
      ImageIndex = 1
      DesignSize = (
        1194
        616)
      object imgGenes: TImage
        Left = 3
        Top = 3
        Width = 1188
        Height = 610
        Anchors = [akLeft, akTop, akRight, akBottom]
      end
      object tbGeneSwitch: TTrackBar
        Left = 3
        Top = 0
        Width = 486
        Height = 33
        Anchors = [akTop, akRight]
        Max = 25
        Position = 10
        TabOrder = 0
        Visible = False
        OnChange = tbGeneSwitchChange
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Times'
      ImageIndex = 2
      DesignSize = (
        1194
        616)
      object Image3: TImage
        Left = 3
        Top = 3
        Width = 1188
        Height = 610
        Anchors = [akLeft, akTop, akRight, akBottom]
      end
    end
    object tsLog: TTabSheet
      Caption = 'Log'
      ImageIndex = 3
      object mLog: TMemo
        Left = 0
        Top = 0
        Width = 1194
        Height = 616
        Align = alClient
        TabOrder = 0
      end
    end
  end
  object gbGA: TGroupBox
    Left = 8
    Top = 251
    Width = 185
    Height = 318
    Caption = 'GA parameters'
    TabOrder = 0
    object lGenerations: TLabel
      Left = 10
      Top = 63
      Width = 62
      Height = 13
      Caption = 'Generations:'
    end
    object lGenes: TLabel
      Left = 96
      Top = 16
      Width = 34
      Height = 13
      Caption = 'Genes:'
    end
    object lPopulation: TLabel
      Left = 10
      Top = 16
      Width = 54
      Height = 13
      Caption = 'Population:'
    end
    object lTournament: TLabel
      Left = 10
      Top = 119
      Width = 125
      Height = 13
      Caption = 'Individuals in tournament:'
    end
    object lResetGene: TLabel
      Left = 10
      Top = 166
      Width = 109
      Height = 13
      Caption = 'Probability reset gene:'
    end
    object lNormalMutation: TLabel
      Left = 10
      Top = 213
      Width = 134
      Height = 13
      Caption = 'Probability normal mutation:'
    end
    object lVariance: TLabel
      Left = 10
      Top = 260
      Width = 138
      Height = 13
      Caption = 'Variance of normal mutation:'
    end
    object seGenerations: TSpinEdit
      Left = 10
      Top = 82
      Width = 80
      Height = 22
      MaxValue = 1000000
      MinValue = 1
      TabOrder = 0
      Value = 10
    end
    object seGenes: TSpinEdit
      Left = 96
      Top = 35
      Width = 80
      Height = 22
      MaxValue = 1000000
      MinValue = 1
      TabOrder = 1
      Value = 10
    end
    object sePopulation: TSpinEdit
      Left = 10
      Top = 35
      Width = 80
      Height = 22
      MaxValue = 1000000
      MinValue = 1
      TabOrder = 2
      Value = 10
    end
    object eStartVariance: TEdit
      Left = 10
      Top = 279
      Width = 80
      Height = 21
      TabOrder = 3
      Text = '0.1'
    end
    object eEndVariance: TEdit
      Left = 96
      Top = 279
      Width = 80
      Height = 21
      TabOrder = 4
      Text = '0.1'
    end
    object eEndGaussMut: TEdit
      Left = 96
      Top = 233
      Width = 80
      Height = 21
      TabOrder = 5
      Text = '0.1'
    end
    object eStartResetGene: TEdit
      Left = 10
      Top = 185
      Width = 80
      Height = 21
      TabOrder = 6
      Text = '0.1'
    end
    object eEndResetGene: TEdit
      Left = 96
      Top = 185
      Width = 80
      Height = 21
      TabOrder = 7
      Text = '0.1'
    end
    object eStartGaussMut: TEdit
      Left = 10
      Top = 232
      Width = 80
      Height = 21
      TabOrder = 8
      Text = '0.1'
    end
    object seEndTournament: TSpinEdit
      Left = 96
      Top = 138
      Width = 80
      Height = 22
      MaxValue = 1000000
      MinValue = 1
      TabOrder = 9
      Value = 10
    end
    object seStartTournament: TSpinEdit
      Left = 10
      Top = 138
      Width = 80
      Height = 22
      MaxValue = 1000000
      MinValue = 1
      TabOrder = 10
      Value = 10
    end
  end
  object gbSim: TGroupBox
    Left = 8
    Top = 136
    Width = 185
    Height = 109
    Caption = 'Simulation parameters'
    TabOrder = 4
    object lThreads: TLabel
      Left = 10
      Top = 61
      Width = 43
      Height = 13
      Caption = 'Threads:'
    end
    object lMaps: TLabel
      Left = 10
      Top = 14
      Width = 29
      Height = 13
      Caption = 'Maps:'
    end
    object lDuration: TLabel
      Left = 96
      Top = 14
      Width = 72
      Height = 13
      Caption = 'Duration (min):'
    end
    object seThreads: TSpinEdit
      Left = 10
      Top = 77
      Width = 80
      Height = 22
      MaxValue = 1000000
      MinValue = 1
      TabOrder = 0
      Value = 10
    end
    object seMaps: TSpinEdit
      Left = 10
      Top = 33
      Width = 80
      Height = 22
      MaxValue = 1000000
      MinValue = 1
      TabOrder = 1
      Value = 10
    end
    object seDuration: TSpinEdit
      Left = 96
      Top = 33
      Width = 80
      Height = 22
      MaxValue = 1000000
      MinValue = 0
      TabOrder = 2
      Value = 60
    end
  end
  object bLoad: TButton
    Left = 16
    Top = 576
    Width = 41
    Height = 25
    Caption = 'Load'
    TabOrder = 5
    OnClick = bLoadClick
  end
end
