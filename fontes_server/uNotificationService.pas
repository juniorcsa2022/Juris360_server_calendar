unit uNotificationService;

interface

uses
  System.SysUtils, System.Classes, System.Threading, System.Generics.Collections,
  uModels, uEventService;

type
  TNotificationAction = reference to procedure(AEvent: TEvent);
  TNotificationWorkerThread = class;

  TNotificationService = class
  private
    FWorkerThread: TNotificationWorkerThread;
    FEventService: TEventService;
    FCheckIntervalSeconds: Integer;
    FNotificationAction: TNotificationAction;
  public
    constructor Create(AEventService: TEventService; ACheckIntervalSeconds: Integer = 60);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    property OnNotification: TNotificationAction read FNotificationAction write FNotificationAction;
  end;

  TNotificationWorkerThread = class(TThread)
  private
    FOwnerService: TNotificationService;
    procedure CheckForReminders;
  protected
    procedure Execute; override;
  public
    constructor Create(AService: TNotificationService);
  end;

implementation

// *** NOVO: Usa a unit uPrincipal para ter acesso à função LogMessage ***
uses
  uPrincipal;

{ TNotificationWorkerThread }

constructor TNotificationWorkerThread.Create(AService: TNotificationService);
begin
  FOwnerService := AService;
  inherited Create(true);
end;

procedure TNotificationWorkerThread.Execute;
var
  I: Integer;
begin
  // *** Usa LogMessage em vez de Writeln ***
  LogMessage('Notification service worker thread started.');

  while not Terminated do
  begin
    try
      CheckForReminders;
    except
      on E: Exception do
        // *** Usa LogMessage em vez de Writeln ***
        LogMessage('[NOTIFICATION SERVICE ERROR]: ' + E.Message);
    end;

    for I := 1 to FOwnerService.FCheckIntervalSeconds do
    begin
      if Terminated then Break;
      Sleep(1000);
    end;
  end;
end;

procedure TNotificationWorkerThread.CheckForReminders;
var
  EventsToNotify: TObjectList<TEvent>;
 // EventsToNotify: TList<TEvent>;
  Event: TEvent;
begin
  EventsToNotify := FOwnerService.FEventService.GetEventsForReminder(FOwnerService.FCheckIntervalSeconds);
  try
    if EventsToNotify.Count > 0 then
    begin
      for Event in EventsToNotify do
      begin
        if Assigned(FOwnerService.FNotificationAction) then
        begin
          try
            TThread.Synchronize(nil,
              procedure
              begin
                FOwnerService.FNotificationAction(Event);
              end);
          except
            on E: Exception do
              // *** Usa LogMessage em vez de Writeln ***
              LogMessage(Format('[NOTIFICATION ACTION ERROR]: Failed to process event ID %d. Reason: %s', [Event.ID, E.Message]));
          end;
        end;
      end;
    end;
  finally
  EventsToNotify.Free;
  //  for Event in EventsToNotify do
    //  Event.Free;
 //   EventsToNotify.Free;
  end;
end;


{ TNotificationService }

constructor TNotificationService.Create(AEventService: TEventService; ACheckIntervalSeconds: Integer);
begin
  inherited Create;
  FEventService := AEventService;
  FCheckIntervalSeconds := ACheckIntervalSeconds;

  FNotificationAction := procedure(AEvent: TEvent)
    begin
      // *** Usa LogMessage em vez de Writeln ***
      LogMessage(Format('[NOTIFICATION]: Reminder for event ID %d ("%s")',
        [AEvent.ID, AEvent.Title]));
    end;
end;

destructor TNotificationService.Destroy;
begin
  Stop;
  inherited;
end;

procedure TNotificationService.Start;
begin
  if FWorkerThread = nil then
  begin
    FWorkerThread := TNotificationWorkerThread.Create(Self);
    FWorkerThread.Start;
  end;
end;

procedure TNotificationService.Stop;
begin
  if FWorkerThread <> nil then
  begin
    FWorkerThread.Terminate;
    FWorkerThread.WaitFor;
    FreeAndNil(FWorkerThread);
    // *** Usa LogMessage em vez de Writeln ***
    LogMessage('Notification service stopped.');
  end;
end;

end.
