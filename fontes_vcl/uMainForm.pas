unit uMainForm;

interface

uses

  Winapi.ShellAPI,
  Winapi.Windows,
  Winapi.Messages,

  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Generics.Collections,

  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Grids,
  Vcl.Buttons,
  Vcl.StdCtrls,

  Data.DB,


  uWebAPIClient, // Nosso cliente API
  uModels,       // Nossos modelos de dados TEvent
  uEventEditForm,

  FireDAC.Comp.DataSet,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.StorageBin, FireDAC.Comp.Client, Vcl.ComCtrls, Vcl.DBGrids,
  FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, Vcl.Mask, Vcl.DBCtrls; // Formulário de edição de eventos (vamos criar em breve)

type
  TMainForm = class(TForm)
    PanelTop: TPanel;
    btnRefresh: TButton;
    btnNew: TButton;
    btnEdit: TButton;
    btnDelete: TButton;
    btnDownloadIcs: TButton;
    btnDownloadAllIcs: TButton;
    DBGrid1: TDBGrid;
    dsEvents: TDataSource;
    mtEvents: TFDMemTable;
    StatusBar1: TStatusBar;
    FDMemTable1: TFDMemTable;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDConnection1: TFDConnection;
    Panel1: TPanel;
    DBEdit1: TDBEdit;
    DBEdit2: TDBEdit;
    DBEdit3: TDBEdit;
    DBEdit4: TDBEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnDownloadIcsClick(Sender: TObject);
    procedure btnDownloadAllIcsClick(Sender: TObject);
  private
    { Private declarations }
    WebAPIClient: TWebAPIClient; // Cliente da API
    procedure RefreshEventsList;
    function GetSelectedEventID: Integer;
    function GetSelectedEvent: TEvent;
    procedure ShowStatus(const Msg: string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Instanciar o cliente API, apontando para o seu servidor Horse
  // Certifique-se de que o servidor Horse esteja rodando na porta 8080 (ou a que você configurou)
  WebAPIClient := TWebAPIClient.Create('http://localhost:8080'); // <<< ATUALIZE O IP/PORTA DO SEU SERVIDOR AQUI!
  RefreshEventsList; // Carrega os eventos ao iniciar o formulário
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(WebAPIClient);
end;

procedure TMainForm.ShowStatus(const Msg: string);
begin
  StatusBar1.SimpleText := Msg;
  Application.ProcessMessages; // Atualiza a UI imediatamente
end;

procedure TMainForm.RefreshEventsList;
var
  EventsArray: TArray<TEvent>;
  Event: TEvent;
begin
  ShowStatus('Carregando eventos...');
  try
      try
        // 1. Fechar o dataset se estiver aberto.
        if mtEvents.Active then // Verifica se o dataset está ativo/aberto
          mtEvents.Close;      // Se sim, fecha.

        mtEvents.DisableControls;
     //   mtEvents.EmptyDataSet;

        EventsArray := WebAPIClient.GetEvents; // Chama a API para obter os eventos

        // Cria os campos no FDMemTable se ainda não existirem
        if mtEvents.FieldDefs.Count = 0 then
        begin
          mtEvents.FieldDefs.Add('ID', ftInteger);
          mtEvents.FieldDefs.Add('Title', ftString, 255);
          mtEvents.FieldDefs.Add('Description', ftMemo);
          mtEvents.FieldDefs.Add('Location', ftString, 255);
          mtEvents.FieldDefs.Add('StartDateTime', ftDateTime);
          mtEvents.FieldDefs.Add('EndDateTime', ftDateTime);
          mtEvents.FieldDefs.Add('AllDay', ftBoolean);
          mtEvents.FieldDefs.Add('ReminderMinutes', ftInteger);
          mtEvents.FieldDefs.Add('RecurrenceRule', ftString, 255);
          mtEvents.FieldDefs.Add('Status', ftString, 50);
        end;
        mtEvents.CreateDataSet; // Cria o dataset com os FieldDefs

        // Popula o FDMemTable com os dados obtidos da API
        for Event in EventsArray do
        begin
          mtEvents.Append;
          mtEvents.FieldByName('ID').AsInteger := Event.ID;
          mtEvents.FieldByName('Title').AsString := Event.Title;
          mtEvents.FieldByName('Description').AsString := Event.Description;
          mtEvents.FieldByName('Location').AsString := Event.Location;
          mtEvents.FieldByName('StartDateTime').AsDateTime := Event.StartDateTime;
          mtEvents.FieldByName('EndDateTime').AsDateTime := Event.EndDateTime;
          mtEvents.FieldByName('AllDay').AsBoolean := Event.AllDay;
          mtEvents.FieldByName('ReminderMinutes').AsInteger := Event.ReminderMinutes;
          mtEvents.FieldByName('RecurrenceRule').AsString := Event.RecurrenceRule;
          mtEvents.FieldByName('Status').AsString := TEvent.StatusToString(Event.Status);
          mtEvents.Post;
        end;
        ShowStatus('Eventos carregados com sucesso.');
      except
        on E: Exception do
          ShowMessage('Erro ao carregar eventos: ' + E.Message);
      end;
      //ShowStatus('Erro ao carregar eventos.');
  finally
    mtEvents.EnableControls; // Reativar a UI
  end;
end;

procedure TMainForm.btnRefreshClick(Sender: TObject);
begin
  RefreshEventsList;
end;

function TMainForm.GetSelectedEventID: Integer;
begin
  Result := -1;
  if Assigned(mtEvents) and not mtEvents.IsEmpty then
    Result := mtEvents.FieldByName('ID').AsInteger;
end;

function TMainForm.GetSelectedEvent: TEvent;
var
  EventID: Integer;
begin
  Result := nil;
  EventID := GetSelectedEventID;
  if EventID <> -1 then
  begin
    ShowStatus('Obtendo detalhes do evento...');
    try
      Result := WebAPIClient.GetEvent(EventID);
      ShowStatus('Detalhes do evento obtidos.');
    except
      on E: Exception do
        ShowMessage('Erro ao obter detalhes do evento: ' + E.Message);
        //ShowStatus('Erro ao obter detalhes do evento.');
    end;
  end;
end;

procedure TMainForm.btnNewClick(Sender: TObject);
var
  xEventEditForm: TEventEditForm;
  NewEvent: TEvent;
begin
  NewEvent := TEvent.Create;
  try
    xEventEditForm := TEventEditForm.Create(self); // Application como owner
    try
      xEventEditForm.LoadEvent(NewEvent); // Carrega um novo evento vazio no formulário
      if xEventEditForm.ShowModal = mrOk then
      begin
        xEventEditForm.SaveEvent(NewEvent); // Pega os dados do formulário para o objeto
        ShowStatus('Criando novo evento...');
        WebAPIClient.CreateEvent(NewEvent);
        RefreshEventsList;
        ShowMessage('Evento criado com sucesso!');
        ShowStatus('Pronto.');
      end;
    finally
      xEventEditForm.Free;
    end;
  finally
    NewEvent.Free;
  end;
end;

procedure TMainForm.btnEditClick(Sender: TObject);
var
  SelectedEvent: TEvent;
  EventEditForm: TEventEditForm;
begin
  SelectedEvent := GetSelectedEvent;
  if Assigned(SelectedEvent) then
  begin
    try
      EventEditForm := TEventEditForm.Create(Application); // Application como owner
      try
        EventEditForm.LoadEvent(SelectedEvent); // Carrega o evento selecionado para edição
        if EventEditForm.ShowModal = mrOk then
        begin
          EventEditForm.SaveEvent(SelectedEvent); // Salva as alterações do formulário no objeto
          ShowStatus('Atualizando evento...');
          WebAPIClient.UpdateEvent(SelectedEvent);
          RefreshEventsList;
          ShowMessage('Evento atualizado com sucesso!');
          ShowStatus('Pronto.');
        end;
      finally
        EventEditForm.Free;
      end;
    finally
      SelectedEvent.Free;
    end;
  end else
   begin
    ShowMessage('Nenhum evento selecionado para editar.');
  end;
end;

procedure TMainForm.btnDeleteClick(Sender: TObject);
var
  EventID: Integer;
begin
  EventID := GetSelectedEventID;
  if EventID <> -1 then
  begin
    if MessageDlg('Tem certeza que deseja excluir este evento?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowStatus('Excluindo evento...');
      try
        WebAPIClient.DeleteEvent(EventID);
        RefreshEventsList;
        ShowMessage('Evento excluído com sucesso!');
        ShowStatus('Pronto.');
      except
        on E: Exception do
          ShowMessage('Erro ao excluir evento: ' + E.Message);
          //ShowStatus('Erro ao excluir evento.');
      end;
    end;
  end else
    begin ShowMessage('Nenhum evento selecionado para excluir.');
    end;
end;

procedure TMainForm.btnDownloadIcsClick(Sender: TObject);
var
  EventID: Integer;
  DownloadURL: string;
begin
  EventID := GetSelectedEventID;
  if EventID <> -1 then
  begin
    DownloadURL := WebAPIClient.GetEventIcsUrl(EventID);
    ShellExecute(0, 'OPEN', PChar(DownloadURL), nil, nil, SW_SHOWNORMAL);
    ShowStatus('Download do ICS do evento iniciado. Verifique seus downloads.');
  end else
   begin
    ShowMessage('Nenhum evento selecionado para baixar ICS.');
   end;
end;

procedure TMainForm.btnDownloadAllIcsClick(Sender: TObject);
var
  DownloadURL: string;
begin
  DownloadURL := WebAPIClient.GetAllEventsIcsUrl;
  MessageDlg('A URL para assinar este calendário (Webcal) é: ' + #13#10 + DownloadURL + #13#10 +
             'Você pode colá-la em seu navegador para baixar o arquivo .ics, ou em seu calendário para assinar.', mtInformation, [mbOK], 0);

  ShellExecute(0, 'OPEN', PChar(DownloadURL), nil, nil, SW_SHOWNORMAL);
  ShowStatus('Download do ICS completo iniciado. Verifique seus downloads.');
end;

end.