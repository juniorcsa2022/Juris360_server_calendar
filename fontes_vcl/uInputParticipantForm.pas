unit uInputParticipantForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uModels; // Nossos modelos de dados TParticipant

type
  TInputParticipantForm = class(TForm)
    Panel1: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    Label1: TLabel;
    edtName: TEdit;
    Label2: TLabel;
    edtEmail: TEdit;
    Label3: TLabel;
    cbRole: TComboBox;
    Label4: TLabel;
    cbStatus: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    { Private declarations }
    FParticipant: TParticipant;
    procedure UpdateUIFromParticipant;
    procedure UpdateParticipantFromUI;
  public
    { Public declarations }
    procedure LoadParticipant(AParticipant: TParticipant);
    procedure SaveParticipant(AParticipant: TParticipant);
  end;

var
  InputParticipantForm: TInputParticipantForm;

implementation

{$R *.dfm}

procedure TInputParticipantForm.FormCreate(Sender: TObject);
begin
  // Preencher ComboBox de Papel
  cbRole.Clear;
  cbRole.Items.Add('ORGANIZER');
  cbRole.Items.Add('ATTENDEE');
  cbRole.Items.Add('OPTIONAL');
  cbRole.ItemIndex := 1; // Padrão: ATTENDEE

  // Preencher ComboBox de Status
  cbStatus.Clear;
  cbStatus.Items.Add('NEEDS-ACTION');
  cbStatus.Items.Add('ACCEPTED');
  cbStatus.Items.Add('DECLINED');
  cbStatus.Items.Add('TENTATIVE');
  cbStatus.ItemIndex := 0; // Padrão: NEEDS-ACTION
end;

procedure TInputParticipantForm.btnOKClick(Sender: TObject);
begin
  if (edtName.Text = '') or (edtEmail.Text = '') then
  begin
    ShowMessage('Nome e E-mail do participante são obrigatórios.');
    ModalResult := mrNone; // Não fechar o formulário
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TInputParticipantForm.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TInputParticipantForm.LoadParticipant(AParticipant: TParticipant);
begin
  FParticipant := AParticipant;
  UpdateUIFromParticipant;
end;

procedure TInputParticipantForm.SaveParticipant(AParticipant: TParticipant);
begin
  UpdateParticipantFromUI;
  // AParticipant já é a referência ao objeto FParticipant, então está atualizado.
end;

procedure TInputParticipantForm.UpdateUIFromParticipant;
begin
  edtName.Text := FParticipant.Name;
  edtEmail.Text := FParticipant.Email;

  case FParticipant.Role of
    prOrganizer: cbRole.ItemIndex := cbRole.Items.IndexOf('ORGANIZER');
    prAttendee: cbRole.ItemIndex := cbRole.Items.IndexOf('ATTENDEE');
    prOptional: cbRole.ItemIndex := cbRole.Items.IndexOf('OPTIONAL');
  end;
  if cbRole.ItemIndex = -1 then cbRole.ItemIndex := 1; // Default to ATTENDEE

  case FParticipant.Status of
    psNeedsAction: cbStatus.ItemIndex := cbStatus.Items.IndexOf('NEEDS-ACTION');
    psAccepted: cbStatus.ItemIndex := cbStatus.Items.IndexOf('ACCEPTED');
    psDeclined: cbStatus.ItemIndex := cbStatus.Items.IndexOf('DECLINED');
    psTentative: cbStatus.ItemIndex := cbStatus.Items.IndexOf('TENTATIVE');
  end;
  if cbStatus.ItemIndex = -1 then cbStatus.ItemIndex := 0; // Default to NEEDS-ACTION
end;

procedure TInputParticipantForm.UpdateParticipantFromUI;
begin
  FParticipant.Name := edtName.Text;
  FParticipant.Email := edtEmail.Text;
  FParticipant.Role := TParticipant.StringToRole(cbRole.Items[cbRole.ItemIndex]);
  FParticipant.Status := TParticipant.StringToStatus(cbStatus.Items[cbStatus.ItemIndex]);
end;

end.