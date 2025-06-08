object InputParticipantForm: TInputParticipantForm
  Left = 0
  Top = 0
  Caption = 'Detalhes do Participante'
  ClientHeight = 220
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 185
    Width = 350
    Height = 35
    Align = alBottom
    TabOrder = 0
    object btnOK: TButton
      Left = 186
      Top = 5
      Width = 75
      Height = 25
      Caption = 'OK'
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 271
      Top = 5
      Width = 75
      Height = 25
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 31
    Height = 13
    Caption = 'Nome:'
  end
  object edtName: TEdit
    Left = 16
    Top = 32
    Width = 313
    Height = 21
    TabOrder = 1
  end
  object Label2: TLabel
    Left = 16
    Top = 64
    Width = 35
    Height = 13
    Caption = 'E-mail:'
  end
  object edtEmail: TEdit
    Left = 16
    Top = 80
    Width = 313
    Height = 21
    TabOrder = 2
  end
  object Label3: TLabel
    Left = 16
    Top = 112
    Width = 33
    Height = 13
    Caption = 'Papel:'
  end
  object cbRole: TComboBox
    Left = 16
    Top = 128
    Width = 145
    Height = 21
    TabOrder = 3
    Items.Strings = (
      'ORGANIZER'
      'ATTENDEE'
      'OPTIONAL')
  end
  object Label4: TLabel
    Left = 176
    Top = 112
    Width = 36
    Height = 13
    Caption = 'Status:'
  end
  object cbStatus: TComboBox
    Left = 176
    Top = 128
    Width = 153
    Height = 21
    TabOrder = 4
    Items.Strings = (
      'NEEDS-ACTION'
      'ACCEPTED'
      'DECLINED'
      'TENTATIVE')
  end
end