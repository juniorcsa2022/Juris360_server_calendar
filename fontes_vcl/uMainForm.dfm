object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Gerenciador de Eventos'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 50
    Align = alTop
    TabOrder = 0
    object btnRefresh: TButton
      Left = 8
      Top = 13
      Width = 75
      Height = 25
      Caption = 'Atualizar'
      TabOrder = 0
      OnClick = btnRefreshClick
    end
    object btnNew: TButton
      Left = 91
      Top = 13
      Width = 75
      Height = 25
      Caption = 'Novo'
      TabOrder = 1
      OnClick = btnNewClick
    end
    object btnEdit: TButton
      Left = 172
      Top = 13
      Width = 75
      Height = 25
      Caption = 'Editar'
      TabOrder = 2
      OnClick = btnEditClick
    end
    object btnDelete: TButton
      Left = 257
      Top = 13
      Width = 75
      Height = 25
      Caption = 'Excluir'
      TabOrder = 3
      OnClick = btnDeleteClick
    end
    object btnDownloadIcs: TButton
      Left = 340
      Top = 13
      Width = 100
      Height = 25
      Caption = 'Baixar ICS Evento'
      TabOrder = 4
      OnClick = btnDownloadIcsClick
    end
    object btnDownloadAllIcs: TButton
      Left = 448
      Top = 13
      Width = 100
      Height = 25
      Caption = 'Baixar Todos ICS'
      TabOrder = 5
      OnClick = btnDownloadAllIcsClick
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 50
    Width = 615
    Height = 528
    Align = alClient
    DataSource = dsEvents
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 578
    Width = 800
    Height = 22
    Panels = <>
    SimplePanel = True
    SimpleText = 'Pronto.'
  end
  object Panel1: TPanel
    Left = 615
    Top = 50
    Width = 185
    Height = 528
    Align = alRight
    Caption = 'Panel1'
    TabOrder = 3
    ExplicitLeft = 320
    ExplicitTop = 296
    ExplicitHeight = 41
    object DBEdit2: TDBEdit
      AlignWithMargins = True
      Left = 4
      Top = 31
      Width = 177
      Height = 21
      Align = alTop
      DataField = 'EndDateTime'
      DataSource = dsEvents
      TabOrder = 0
      ExplicitLeft = 16
      ExplicitTop = 32
      ExplicitWidth = 121
    end
    object DBEdit3: TDBEdit
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 177
      Height = 21
      Align = alTop
      DataField = 'StartDateTime'
      DataSource = dsEvents
      TabOrder = 1
      ExplicitLeft = 16
      ExplicitTop = 32
      ExplicitWidth = 121
    end
    object DBEdit4: TDBEdit
      AlignWithMargins = True
      Left = 4
      Top = 58
      Width = 177
      Height = 21
      Align = alTop
      DataField = 'ReminderMinutes'
      DataSource = dsEvents
      TabOrder = 2
      ExplicitLeft = 36
      ExplicitTop = 199
    end
  end
  object DBEdit1: TDBEdit
    Left = 352
    Top = 312
    Width = 121
    Height = 21
    TabOrder = 4
  end
  object dsEvents: TDataSource
    DataSet = mtEvents
    Left = 32
    Top = 64
  end
  object mtEvents: TFDMemTable
    FieldDefs = <>
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvPersistent]
    ResourceOptions.Persistent = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 120
    Top = 64
  end
  object FDMemTable1: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 392
    Top = 304
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 512
    Top = 304
  end
  object FDConnection1: TFDConnection
    Left = 400
    Top = 312
  end
end
