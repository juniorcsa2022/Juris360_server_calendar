unit uEventEditForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Samples.Spin,
  Vcl.Mask, Vcl.DBCtrls, Vcl.ComCtrls, Vcl.Grids, Data.DB, FireDAC.Comp.DataSet,
  System.Generics.Collections, // Para TObjectList
  uModels, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.StorageBin, FireDAC.Comp.Client, Vcl.DBGrids; // Nossos modelos de dados TEvent e TParticipant

type
  TEventEditForm = class(TForm)
    Panel1: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    Label1: TLabel;
    edtTitle: TEdit;
    Label2: TLabel;
    memDescription: TMemo;
    Label3: TLabel;
    edtLocation: TEdit;
    Label4: TLabel;
    dtpStartDate: TDateTimePicker;
    dtpStartTime: TDateTimePicker;
    Label5: TLabel;
    dtpEndDate: TDateTimePicker;
    dtpEndTime: TDateTimePicker;
    chkAllDay: TCheckBox;
    Label6: TLabel;
    cbStatus: TComboBox;
    Label7: TLabel;
    SpinEdit1: TSpinEdit;
    Label8: TLabel;
    edtRecurrenceRule: TEdit;
    Label9: TLabel;

    // NOVOS COMPONENTES PARA PARTICIPANTES
    PanelParticipants: TPanel; // Um novo painel para conter os controles dos participantes
    LabelParticipants: TLabel;
    DBGridParticipants: TDBGrid;
    btnNewParticipant: TButton;
    btnEditParticipant: TButton;
    btnDeleteParticipant: TButton;
    dsParticipants: TDataSource; // Data Source para a grid de participantes
    mtParticipants: TFDMemTable;
    FDMemTable1: TFDMemTable;
    Button1: TButton; // MemTable para os dados dos participantes

    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure chkAllDayClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnNewParticipantClick(Sender: TObject);
    procedure btnEditParticipantClick(Sender: TObject);
    procedure btnDeleteParticipantClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FEvent: TEvent;
    procedure UpdateUIFromEvent;
    procedure UpdateEventFromUI;
    procedure LoadParticipantsIntoMemTable;
    procedure SaveParticipantsFromMemTable;
    function GetSelectedParticipantID: Integer;
    function GetSelectedParticipant: TParticipant;
  public
    { Public declarations }
    procedure LoadEvent(AEvent: TEvent);
    procedure SaveEvent(AEvent: TEvent);
  end;

var
  EventEditForm: TEventEditForm;

implementation

uses
  System.DateUtils, // Para Trunc e EncodeDate/Time
  uInputParticipantForm; // <<<< NOVO FORMULÁRIO: Para adicionar/editar um único participante

{$R *.dfm}

procedure TEventEditForm.FormCreate(Sender: TObject);
begin

  cbStatus.Clear;
  cbStatus.Items.Add('CONFIRMED');
  cbStatus.Items.Add('TENTATIVE');
  cbStatus.Items.Add('CANCELLED');
  cbStatus.ItemIndex := 0;

  // Configurar o mtParticipants
  mtParticipants.FieldDefs.Add('ID', ftInteger);
  mtParticipants.FieldDefs.Add('EventID', ftInteger);
  mtParticipants.FieldDefs.Add('Name', ftString, 255);
  mtParticipants.FieldDefs.Add('Email', ftString, 255);
  mtParticipants.FieldDefs.Add('Role', ftString, 100); // Exibir como string
  mtParticipants.FieldDefs.Add('Status', ftString, 50); // Exibir como string
  mtParticipants.CreateDataSet; // Cria a estrutura de campos no início

  // Conectar o DataSource à Grid
  dsParticipants.DataSet := mtParticipants;
  DBGridParticipants.DataSource := dsParticipants;
end;

procedure TEventEditForm.FormShow(Sender: TObject);
begin
  chkAllDayClick(nil);
end;

procedure TEventEditForm.LoadEvent(AEvent: TEvent);
begin
  FEvent := AEvent;
  UpdateUIFromEvent;
  LoadParticipantsIntoMemTable; // Carrega participantes do evento para o memtable
end;

procedure TEventEditForm.SaveEvent(AEvent: TEvent);
begin
  UpdateEventFromUI;
  SaveParticipantsFromMemTable; // Salva participantes do memtable de volta para o evento
end;

procedure TEventEditForm.UpdateUIFromEvent;
begin
  edtTitle.Text := FEvent.Title;
  memDescription.Text := FEvent.Description;
  edtLocation.Text := FEvent.Location;

  dtpStartDate.DateTime := FEvent.StartDateTime;
  dtpStartTime.DateTime := FEvent.StartDateTime;
  dtpEndDate.DateTime := FEvent.EndDateTime;
  dtpEndTime.DateTime := FEvent.EndDateTime;

  chkAllDay.Checked := FEvent.AllDay;
  chkAllDayClick(nil);

  SpinEdit1.Value := FEvent.ReminderMinutes;
  edtRecurrenceRule.Text := FEvent.RecurrenceRule;

  case FEvent.Status of
    esConfirmed: cbStatus.ItemIndex := cbStatus.Items.IndexOf('CONFIRMED');
    esTentative: cbStatus.ItemIndex := cbStatus.Items.IndexOf('TENTATIVE');
    esCancelled: cbStatus.ItemIndex := cbStatus.Items.IndexOf('CANCELLED');
  end;
  if cbStatus.ItemIndex = -1 then cbStatus.ItemIndex := 0;
end;

procedure TEventEditForm.UpdateEventFromUI;
begin
  FEvent.Title := edtTitle.Text;
  FEvent.Description := memDescription.Text;
  FEvent.Location := edtLocation.Text;

  FEvent.AllDay := chkAllDay.Checked;
  if FEvent.AllDay then
  begin
    FEvent.StartDateTime := Trunc(dtpStartDate.DateTime);
    FEvent.EndDateTime := Trunc(dtpEndDate.DateTime);
  end
  else
  begin
    FEvent.StartDateTime := dtpStartDate.Date + dtpStartTime.Time;
    FEvent.EndDateTime := dtpEndDate.Date + dtpEndTime.Time;
  end;

  FEvent.ReminderMinutes := SpinEdit1.Value;
  FEvent.RecurrenceRule := edtRecurrenceRule.Text;

  FEvent.Status := TEvent.StringToStatus(cbStatus.Items[cbStatus.ItemIndex]);
end;

procedure TEventEditForm.LoadParticipantsIntoMemTable;
var
  Participant: TParticipant;
begin
  mtParticipants.DisableControls;
  mtParticipants.EmptyDataSet; // Limpa o memtable antes de carregar novos dados
  mtParticipants.Open; // Garante que esteja aberto para adicionar registros

  for Participant in FEvent.Participants do
  begin
    mtParticipants.Append;
    mtParticipants.FieldByName('ID').AsInteger := Participant.ID;
    mtParticipants.FieldByName('EventID').AsInteger := Participant.EventID;
    mtParticipants.FieldByName('Name').AsString := Participant.Name;
    mtParticipants.FieldByName('Email').AsString := Participant.Email;
    mtParticipants.FieldByName('Role').AsString := TParticipant.RoleToString(Participant.Role);
    mtParticipants.FieldByName('Status').AsString := TParticipant.StatusToString(Participant.Status);
    mtParticipants.Post;
  end;
  mtParticipants.EnableControls;
end;

procedure TEventEditForm.SaveParticipantsFromMemTable;
var
  Participant: TParticipant;
begin
  FEvent.Participants.Clear; // Limpa a lista no objeto TEvent antes de popular do memtable
  mtParticipants.DisableControls;
  mtParticipants.First;
  while not mtParticipants.Eof do
  begin
    Participant := TParticipant.Create;
    Participant.ID := mtParticipants.FieldByName('ID').AsInteger;
    Participant.EventID := mtParticipants.FieldByName('EventID').AsInteger;
    Participant.Name := mtParticipants.FieldByName('Name').AsString;
    Participant.Email := mtParticipants.FieldByName('Email').AsString;
    Participant.Role := TParticipant.StringToRole(mtParticipants.FieldByName('Role').AsString);
    Participant.Status := TParticipant.StringToStatus(mtParticipants.FieldByName('Status').AsString);
    FEvent.Participants.Add(Participant);
    mtParticipants.Next;
  end;
  mtParticipants.EnableControls;
end;

function TEventEditForm.GetSelectedParticipantID: Integer;
begin
  Result := -1;
  if Assigned(mtParticipants) and not mtParticipants.IsEmpty then
    Result := mtParticipants.FieldByName('ID').AsInteger;
end;

function TEventEditForm.GetSelectedParticipant: TParticipant;
var
  ParticipantID: Integer;
  CurrentParticipant: TParticipant;
begin
  Result := nil;
  ParticipantID := GetSelectedParticipantID;
  if ParticipantID <> -1 then
  begin
    mtParticipants.First;
    while not mtParticipants.Eof do
    begin
      if mtParticipants.FieldByName('ID').AsInteger = ParticipantID then
      begin
        // Cria uma nova instância e copia os dados. Importante para edição.
        Result := TParticipant.Create;
        Result.ID := mtParticipants.FieldByName('ID').AsInteger;
        Result.EventID := mtParticipants.FieldByName('EventID').AsInteger;
        Result.Name := mtParticipants.FieldByName('Name').AsString;
        Result.Email := mtParticipants.FieldByName('Email').AsString;
        Result.Role := TParticipant.StringToRole(mtParticipants.FieldByName('Role').AsString);
        Result.Status := TParticipant.StringToStatus(mtParticipants.FieldByName('Status').AsString);
        Break;
      end;
      mtParticipants.Next;
    end;
  end;
end;


procedure TEventEditForm.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TEventEditForm.Button1Click(Sender: TObject);
begin
 dtpStartDate.DateTime := date;
  dtpStartTime.DateTime := time;
  dtpEndDate.DateTime := date;
  dtpEndTime.DateTime := time;
end;

procedure TEventEditForm.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TEventEditForm.chkAllDayClick(Sender: TObject);
begin
  dtpStartTime.Enabled := not chkAllDay.Checked;
  dtpEndTime.Enabled := not chkAllDay.Checked;
end;

procedure TEventEditForm.btnNewParticipantClick(Sender: TObject);
var
  InputParticipantForm: TInputParticipantForm;
  NewParticipant: TParticipant;
begin
  NewParticipant := TParticipant.Create;
  try
    InputParticipantForm := TInputParticipantForm.Create(Application);
    try
      InputParticipantForm.LoadParticipant(NewParticipant);
      if InputParticipantForm.ShowModal = mrOk then
      begin
        InputParticipantForm.SaveParticipant(NewParticipant);
        // Atribui um ID temporário se for um novo participante (ID 0)
        // A API/BD vai gerar o ID real.
        if NewParticipant.ID = 0 then
          NewParticipant.ID := -1; // ID temporário para identificação no MemTable

        mtParticipants.Append;
        mtParticipants.FieldByName('ID').AsInteger := NewParticipant.ID;
        mtParticipants.FieldByName('EventID').AsInteger := NewParticipant.EventID;
        mtParticipants.FieldByName('Name').AsString := NewParticipant.Name;
        mtParticipants.FieldByName('Email').AsString := NewParticipant.Email;
        mtParticipants.FieldByName('Role').AsString := TParticipant.RoleToString(NewParticipant.Role);
        mtParticipants.FieldByName('Status').AsString := TParticipant.StatusToString(NewParticipant.Status);
        mtParticipants.Post;
      end;
    finally
      InputParticipantForm.Free;
    end;
  finally
    NewParticipant.Free;
  end;
end;

procedure TEventEditForm.btnEditParticipantClick(Sender: TObject);
var
  InputParticipantForm: TInputParticipantForm;
  SelectedParticipant: TParticipant;
  OriginalID: Integer;
begin
  SelectedParticipant := GetSelectedParticipant;
  if Assigned(SelectedParticipant) then
  begin
    OriginalID := SelectedParticipant.ID; // Guarda o ID original
    try
      InputParticipantForm := TInputParticipantForm.Create(Application);
      try
        InputParticipantForm.LoadParticipant(SelectedParticipant);
        if InputParticipantForm.ShowModal = mrOk then
        begin
          InputParticipantForm.SaveParticipant(SelectedParticipant);
          // Encontra o registro no MemTable e atualiza
          if mtParticipants.Locate('ID', OriginalID, []) then
          begin
            mtParticipants.Edit;
            mtParticipants.FieldByName('Name').AsString := SelectedParticipant.Name;
            mtParticipants.FieldByName('Email').AsString := SelectedParticipant.Email;
            mtParticipants.FieldByName('Role').AsString := TParticipant.RoleToString(SelectedParticipant.Role);
            mtParticipants.FieldByName('Status').AsString := TParticipant.StatusToString(SelectedParticipant.Status);
            mtParticipants.Post;
          end;
        end;
      finally
        InputParticipantForm.Free;
      end;
    finally
      SelectedParticipant.Free;
    end;
  end else begin
    ShowMessage('Nenhum participante selecionado para editar.');

  end;
end;

procedure TEventEditForm.btnDeleteParticipantClick(Sender: TObject);
begin
  if not mtParticipants.IsEmpty then
  begin
    if MessageDlg('Tem certeza que deseja remover este participante?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      mtParticipants.Delete; // Remove o registro atual do memtable
    end;
  end
  else
  begin
    ShowMessage('Nenhum participante selecionado para remover.');
  end;
end;

end.