object EventEditForm: TEventEditForm
  Left = 0
  Top = 0
  Caption = 'Detalhes do Evento'
  ClientHeight = 700
  ClientWidth = 468
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 30
    Height = 13
    Caption = 'T'#237'tulo:'
  end
  object Label2: TLabel
    Left = 16
    Top = 64
    Width = 50
    Height = 13
    Caption = 'Descri'#231#227'o:'
  end
  object Label3: TLabel
    Left = 16
    Top = 176
    Width = 28
    Height = 13
    Caption = 'Local:'
  end
  object Label4: TLabel
    Left = 16
    Top = 224
    Width = 29
    Height = 13
    Caption = 'In'#237'cio:'
  end
  object Label5: TLabel
    Left = 16
    Top = 272
    Width = 20
    Height = 13
    Caption = 'Fim:'
  end
  object Label6: TLabel
    Left = 16
    Top = 320
    Width = 35
    Height = 13
    Caption = 'Status:'
  end
  object Label7: TLabel
    Left = 16
    Top = 368
    Width = 49
    Height = 13
    Caption = 'Lembrete:'
  end
  object Label8: TLabel
    Left = 87
    Top = 388
    Width = 37
    Height = 13
    Caption = 'minutos'
  end
  object Label9: TLabel
    Left = 200
    Top = 368
    Width = 93
    Height = 13
    Caption = 'Regra Recorr'#234'ncia:'
  end
  object Panel1: TPanel
    Left = 0
    Top = 665
    Width = 468
    Height = 35
    Align = alBottom
    TabOrder = 0
    ExplicitWidth = 450
    object btnOK: TButton
      Left = 280
      Top = 5
      Width = 75
      Height = 25
      Caption = 'OK'
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 365
      Top = 5
      Width = 75
      Height = 25
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object edtTitle: TEdit
    Left = 16
    Top = 32
    Width = 417
    Height = 21
    TabOrder = 1
  end
  object memDescription: TMemo
    Left = 16
    Top = 80
    Width = 417
    Height = 89
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object edtLocation: TEdit
    Left = 16
    Top = 192
    Width = 417
    Height = 21
    TabOrder = 3
  end
  object dtpStartDate: TDateTimePicker
    Left = 16
    Top = 240
    Width = 121
    Height = 21
    Date = 45815.000000000000000000
    Time = 0.632874513888964400
    TabOrder = 4
  end
  object dtpStartTime: TDateTimePicker
    Left = 143
    Top = 240
    Width = 80
    Height = 21
    Date = 45815.000000000000000000
    Format = 'HH:mm:ss'
    Time = 0.632874513888964400
    Kind = dtkTime
    TabOrder = 5
  end
  object dtpEndDate: TDateTimePicker
    Left = 16
    Top = 288
    Width = 121
    Height = 21
    Date = 45815.000000000000000000
    Time = 0.632874513888964400
    TabOrder = 6
  end
  object dtpEndTime: TDateTimePicker
    Left = 143
    Top = 288
    Width = 80
    Height = 21
    Date = 45815.000000000000000000
    Format = 'HH:mm:ss'
    Time = 0.632874513888964400
    Kind = dtkTime
    TabOrder = 7
  end
  object chkAllDay: TCheckBox
    Left = 240
    Top = 240
    Width = 97
    Height = 17
    Caption = 'Dia Inteiro'
    TabOrder = 8
    OnClick = chkAllDayClick
  end
  object cbStatus: TComboBox
    Left = 16
    Top = 336
    Width = 145
    Height = 21
    TabOrder = 9
    Items.Strings = (
      'CONFIRMED'
      'TENTATIVE'
      'CANCELLED')
  end
  object SpinEdit1: TSpinEdit
    Left = 16
    Top = 384
    Width = 65
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 10
    Value = 0
  end
  object edtRecurrenceRule: TEdit
    Left = 200
    Top = 384
    Width = 233
    Height = 21
    TabOrder = 11
  end
  object PanelParticipants: TPanel
    Left = 8
    Top = 424
    Width = 450
    Height = 225
    ParentBackground = False
    TabOrder = 12
    object LabelParticipants: TLabel
      Left = 16
      Top = 8
      Width = 66
      Height = 13
      Caption = 'Participantes:'
    end
    object DBGridParticipants: TDBGrid
      Left = 8
      Top = 32
      Width = 433
      Height = 150
      DataSource = dsParticipants
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'Name'
          Title.Caption = 'Nome'
          Width = 150
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Email'
          Title.Caption = 'E-mail'
          Width = 150
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Role'
          Title.Caption = 'Papel'
          Width = 80
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Status'
          Width = 80
          Visible = True
        end>
    end
    object btnNewParticipant: TButton
      Left = 8
      Top = 192
      Width = 75
      Height = 25
      Caption = 'Adicionar'
      TabOrder = 1
      OnClick = btnNewParticipantClick
    end
    object btnEditParticipant: TButton
      Left = 91
      Top = 192
      Width = 75
      Height = 25
      Caption = 'Editar'
      TabOrder = 2
      OnClick = btnEditParticipantClick
    end
    object btnDeleteParticipant: TButton
      Left = 174
      Top = 192
      Width = 75
      Height = 25
      Caption = 'Remover'
      TabOrder = 3
      OnClick = btnDeleteParticipantClick
    end
  end
  object Button1: TButton
    Left = 272
    Top = 284
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 13
    OnClick = Button1Click
  end
  object dsParticipants: TDataSource
    Left = 280
    Top = 440
  end
  object mtParticipants: TFDMemTable
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
    Left = 368
    Top = 440
  end
  object FDMemTable1: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 216
    Top = 352
  end
end
