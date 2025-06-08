unit uPrincipal;

interface

uses
    uDM, uModels, uEventRepository, uEventService, uNotificationService, Horse,
    Horse.Jhonson, Horse.CORS, Horse.Upload, Horse.Commons, Winapi.Windows,
    Winapi.Messages, System.Net.Mime, System.Generics.Collections,
    System.SysUtils, System.Variants, System.Classes, System.JSON,
    Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Threading,
    Vcl.StdCtrls, Vcl.ExtCtrls;

procedure LogMessage(const AMessage: string);

type
  TfrmPrincipal = class(TForm)
    MemoLOG: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;
  EventService: TEventService;
  NotificationService: TNotificationService;

implementation

{$R *.dfm}

procedure LogMessage(const AMessage: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(frmPrincipal) and Assigned(frmPrincipal.memoLOG) then
        frmPrincipal.memoLOG.Lines.Add(FormatDateTime('[hh:nn:ss] ', Now) + AMessage);
    end);
end;

procedure TfrmPrincipal.Button1Click(Sender: TObject);
begin
  MemoLOG.Clear;
  try
    DM.Connect;
    EventService := TEventService.Create;
    NotificationService := TNotificationService.Create(EventService, 10);
    NotificationService.Start;
    THorse.Use(Cors);

    tHorse.Get('/events',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        Events: TObjectList<TEvent>;
        Event: TEvent;
        JsonArray: TJSONArray;
      begin
        Events := EventService.GetAllEvents;
        try
          JsonArray := TJSONArray.Create;
          try
            for Event in Events do
              JsonArray.Add(Event.ToJSON);
            Res.Send(JsonArray.ToString);
          finally
            JsonArray.Free;
          end;
        finally
          Events.Free;
        end;
      end);

    tHorse.Get('/events/:id',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        EventId: Integer;
        Event: TEvent;
      begin
        EventId := strtoint(Req.Params.Items['id']);
        Event := EventService.GetEvent(EventId);
        try
          if Assigned(Event) then
            Res.Send(Event.ToJSON.ToString)
          else
            Res.Status(404).Send('Event not found');
        finally
          Event.Free;
        end;
      end);

    tHorse.Post('/events',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        Event: TEvent;
        JSONObject: TJSONObject;
      begin
        JSONObject := nil;
        Event := nil;
        try
          JSONObject := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
          if not Assigned(JSONObject) then
          begin
            Res.Status(400).Send('Invalid JSON');
            Exit;
          end;
          Event := TEvent.FromJSONObject(JSONObject);
          EventService.AddEvent(Event);
          Res.Status(201).Send(Event.ToJSON.ToString);
        finally
          FreeAndNil(Event);
          FreeAndNil(JSONObject);
        end;
      end);

    tHorse.Put('/events/:id',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        EventId: Integer;
        Event: TEvent;
        JSONObject: TJSONObject;
      begin
        EventId := StrToInt(Req.Params.Items['id']);
        JSONObject := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
        Event := nil;
        try
          if not Assigned(JSONObject) then
          begin
            Res.Status(400).Send('Invalid JSON');
            Exit;
          end;
          Event := TEvent.FromJSONObject(JSONObject);
          if Event.ID <> EventId then
          begin
            Res.Status(400).Send('ID in body does not match ID in URL');
            Exit;
          end;
          EventService.UpdateEvent(Event);
          Res.Send(Event.ToJSON.ToString);
        finally
          FreeAndNil(Event);
          FreeAndNil(JSONObject);
        end;
      end);

    tHorse.Delete('/events/:id',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        EventId: Integer;
      begin
        EventId := StrToInt(Req.Params.Items['id']);
        EventService.DeleteEvent(EventId);
        Res.Status(204).Send('');
      end);

    tHorse.Get('/events/ics/:id',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        EventId: Integer;
        Event: TEvent;
        IcsContent: string;
      begin
        EventId := StrToInt(Req.Params.Items['id']);
        Event := EventService.GetEvent(EventId);
        try
          if Assigned(Event) then
          begin
            IcsContent := EventService.GenerateIcsForEvent(Event);
            Res.ContentType('text/calendar').Send(IcsContent);
          end
          else
            Res.Status(404).Send('Event not found');
        finally
          Event.Free;
        end;
      end);

    tHorse.Get('/events/ics',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        Events: TObjectList<TEvent>;
        IcsContent: string;
      begin
        Events := EventService.GetAllEvents;
        try
          if Assigned(Events) then
          begin
            IcsContent := EventService.GenerateIcsForAllEvents(Events);
            Res.ContentType('text/calendar').Send(IcsContent);
          end
          else
            Res.Status(404).Send('No events found');
        finally
          Events.Free;
        end;
      end);

    tHorse.Listen(8080);
    LogMessage('Horse Calendar Server is running on port 8080');
  except
    on E: Exception do
      LogMessage(E.ClassName + ' : ' + E.Message);
  end;
end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  LogMessage('Server shutting down...');
  try
    if Assigned(NotificationService) then
    begin
      NotificationService.Stop;
      FreeAndNil(NotificationService);
    end;
    FreeAndNil(EventService);
    if Assigned(DM) and DM.Conexao.Connected then
      DM.Disconnect;
    THorse.StopListen;
  except
    //
  end;
  LogMessage('Server stopped.');
end;

end.
