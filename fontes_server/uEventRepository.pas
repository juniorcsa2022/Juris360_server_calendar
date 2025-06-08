unit uEventRepository;

interface

uses
  FireDAC.DApt, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.DApt.Intf, FireDAC.Phys.IBBase, FireDAC.Phys.FB,
  FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.Phys,
  FireDAC.Phys.FBDef, FireDAC.Stan.Param, FireDAC.DatS, Data.DB, System.SysUtils,
  System.Generics.Collections, uModels, uDM;

type
  TEventRepository = class
  private
    FConnection: TFDConnection;
    procedure SaveParticipants(AEvent: TEvent);
    procedure DeleteParticipants(AEventID: Integer);
  public
    constructor Create(AConnection: TFDConnection);
    destructor Destroy; override;
    procedure AddEvent(AEvent: TEvent; const ACreatedAtUTC: TDateTime);
    procedure UpdateEvent(AEvent: TEvent; const AUpdatedAtUTC: TDateTime);
    function GetEventById(AID: Integer): TEvent;
    function GetAllEvents: TObjectList<TEvent>;
    procedure DeleteEvent(AID: Integer);
    procedure LoadParticipants(AEvent: TEvent);
  end;

implementation

constructor TEventRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  FConnection := AConnection;
end;

destructor TEventRepository.Destroy;
begin
  inherited;
end;

procedure TEventRepository.AddEvent(AEvent: TEvent; const ACreatedAtUTC: TDateTime);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'INSERT INTO TB_EVENTS (TITLE, DESCRIPTION, LOCATION, START_DATETIME, END_DATETIME, ' +
      'ALL_DAY, REMINDER_MINUTES, RECURRENCE_RULE, STATUS, CREATED_AT, UPDATED_AT) ' +
      'VALUES (:TITLE, :DESCRIPTION, :LOCATION, :START_DATETIME, :END_DATETIME, :ALL_DAY, ' +
      ':REMINDER_MINUTES, :RECURRENCE_RULE, :STATUS, :CREATED_AT, :UPDATED_AT) ' +
      'RETURNING ID';
    Q.ParamByName('TITLE').AsString := AEvent.Title;
    Q.ParamByName('DESCRIPTION').AsMemo := AEvent.Description;
    Q.ParamByName('LOCATION').AsString := AEvent.Location;
    Q.ParamByName('START_DATETIME').AsDateTime := AEvent.StartDateTime;
    Q.ParamByName('END_DATETIME').AsDateTime := AEvent.EndDateTime;
    Q.ParamByName('ALL_DAY').AsBoolean := AEvent.AllDay;
    Q.ParamByName('REMINDER_MINUTES').AsInteger := AEvent.ReminderMinutes;
    Q.ParamByName('RECURRENCE_RULE').AsString := AEvent.RecurrenceRule;
    Q.ParamByName('STATUS').AsString := TEvent.StatusToString(AEvent.Status);
    Q.ParamByName('CREATED_AT').AsDateTime := ACreatedAtUTC;
    Q.ParamByName('UPDATED_AT').AsDateTime := ACreatedAtUTC;

    Q.Open;
    AEvent.ID := Q.FieldByName('ID').AsInteger;

    SaveParticipants(AEvent);
  finally
    Q.Free;
  end;
end;

procedure TEventRepository.UpdateEvent(AEvent: TEvent; const AUpdatedAtUTC: TDateTime);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'UPDATE TB_EVENTS SET TITLE = :TITLE, DESCRIPTION = :DESCRIPTION, LOCATION = :LOCATION, ' +
      'START_DATETIME = :START_DATETIME, END_DATETIME = :END_DATETIME, ALL_DAY = :ALL_DAY, ' +
      'REMINDER_MINUTES = :REMINDER_MINUTES, RECURRENCE_RULE = :RECURRENCE_RULE, STATUS = :STATUS, ' +
      'UPDATED_AT = :UPDATED_AT WHERE ID = :ID';
    Q.ParamByName('TITLE').AsString := AEvent.Title;
    Q.ParamByName('DESCRIPTION').AsMemo := AEvent.Description;
    Q.ParamByName('LOCATION').AsString := AEvent.Location;
    Q.ParamByName('START_DATETIME').AsDateTime := AEvent.StartDateTime;
    Q.ParamByName('END_DATETIME').AsDateTime := AEvent.EndDateTime;
    Q.ParamByName('ALL_DAY').AsBoolean := AEvent.AllDay;
    Q.ParamByName('REMINDER_MINUTES').AsInteger := AEvent.ReminderMinutes;
    Q.ParamByName('RECURRENCE_RULE').AsString := AEvent.RecurrenceRule;
    Q.ParamByName('STATUS').AsString := TEvent.StatusToString(AEvent.Status);
    Q.ParamByName('UPDATED_AT').AsDateTime := AUpdatedAtUTC;
    Q.ParamByName('ID').AsInteger := AEvent.ID;
    Q.ExecSQL;

    SaveParticipants(AEvent);
  finally
    Q.Free;
  end;
end;

function TEventRepository.GetEventById(AID: Integer): TEvent;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT * FROM TB_EVENTS WHERE ID = :ID';
    Q.ParamByName('ID').AsInteger := AID;
    Q.Open;
    if not Q.IsEmpty then
    begin
      Result := TEvent.Create;
      Result.ID := Q.FieldByName('ID').AsInteger;
      Result.Title := Q.FieldByName('TITLE').AsString;
      Result.Description := Q.FieldByName('DESCRIPTION').AsString;
      Result.Location := Q.FieldByName('LOCATION').AsString;
      Result.StartDateTime := Q.FieldByName('START_DATETIME').AsDateTime;
      Result.EndDateTime := Q.FieldByName('END_DATETIME').AsDateTime;
      Result.AllDay := Q.FieldByName('ALL_DAY').AsBoolean;
      Result.ReminderMinutes := Q.FieldByName('REMINDER_MINUTES').AsInteger;
      Result.RecurrenceRule := Q.FieldByName('RECURRENCE_RULE').AsString;
      Result.Status := TEvent.StringToStatus(Q.FieldByName('STATUS').AsString);
      Result.CreatedAt := Q.FieldByName('CREATED_AT').AsDateTime;
      Result.UpdatedAt := Q.FieldByName('UPDATED_AT').AsDateTime;
      LoadParticipants(Result);
    end;
  finally
    Q.Free;
  end;
end;

function TEventRepository.GetAllEvents: TObjectList<TEvent>;
var
  Q: TFDQuery;
  LItem: TEvent;
begin
  Result := TObjectList<TEvent>.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT * FROM TB_EVENTS ORDER BY START_DATETIME';
    Q.Open;
    while not Q.Eof do
    begin
      LItem := TEvent.Create;
      LItem.ID := Q.FieldByName('ID').AsInteger;
      LItem.Title := Q.FieldByName('TITLE').AsString;
      LItem.Description := Q.FieldByName('DESCRIPTION').AsString;
      LItem.Location := Q.FieldByName('LOCATION').AsString;
      LItem.StartDateTime := Q.FieldByName('START_DATETIME').AsDateTime;
      LItem.EndDateTime := Q.FieldByName('END_DATETIME').AsDateTime;
      LItem.AllDay := Q.FieldByName('ALL_DAY').AsBoolean;
      LItem.ReminderMinutes := Q.FieldByName('REMINDER_MINUTES').AsInteger;
      LItem.RecurrenceRule := Q.FieldByName('RECURRENCE_RULE').AsString;
      LItem.Status := TEvent.StringToStatus(Q.FieldByName('STATUS').AsString);
      LItem.CreatedAt := Q.FieldByName('CREATED_AT').AsDateTime;
      LItem.UpdatedAt := Q.FieldByName('UPDATED_AT').AsDateTime;
      Result.Add(LItem);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TEventRepository.DeleteEvent(AID: Integer);
var
  Q: TFDQuery;
begin
  DeleteParticipants(AID);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'DELETE FROM TB_EVENTS WHERE ID = :ID';
    Q.ParamByName('ID').AsInteger := AID;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TEventRepository.LoadParticipants(AEvent: TEvent);
var
  Q: TFDQuery;
  Participant: TParticipant;
begin
  AEvent.Participants.Clear;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT ID, EVENT_ID, NAME, EMAIL, ROLE, STATUS FROM TB_EVENT_PARTICIPANTS WHERE EVENT_ID = :EVENT_ID ORDER BY ID';
    Q.ParamByName('EVENT_ID').AsInteger := AEvent.ID;
    Q.Open;
    while not Q.Eof do
    begin
      Participant := TParticipant.Create;
      Participant.ID := Q.FieldByName('ID').AsInteger;
      Participant.EventID := Q.FieldByName('EVENT_ID').AsInteger;
      Participant.Name := Q.FieldByName('NAME').AsString;
      Participant.Email := Q.FieldByName('EMAIL').AsString;
      Participant.Role := TParticipant.StringToRole(Q.FieldByName('ROLE').AsString);
      Participant.Status := TParticipant.StringToStatus(Q.FieldByName('STATUS').AsString);
      AEvent.Participants.Add(Participant);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TEventRepository.SaveParticipants(AEvent: TEvent);
var
  Q: TFDQuery;
  Participant: TParticipant;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    DeleteParticipants(AEvent.ID);
    if AEvent.Participants.Count > 0 then
    begin
      Q.SQL.Text := 'INSERT INTO TB_EVENT_PARTICIPANTS (EVENT_ID, NAME, EMAIL, ROLE, STATUS) ' +
        'VALUES (:EVENT_ID, :NAME, :EMAIL, :ROLE, :STATUS)';
      for Participant in AEvent.Participants do
      begin
        Participant.EventID := AEvent.ID;
        Q.ParamByName('EVENT_ID').AsInteger := Participant.EventID;
        Q.ParamByName('NAME').AsString := Participant.Name;
        Q.ParamByName('EMAIL').AsString := Participant.Email;
        Q.ParamByName('ROLE').AsString := TParticipant.RoleToString(Participant.Role);
        Q.ParamByName('STATUS').AsString := TParticipant.StatusToString(Participant.Status);
        Q.ExecSQL;
      end;
    end;
  finally
    Q.Free;
  end;
end;

procedure TEventRepository.DeleteParticipants(AEventID: Integer);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'DELETE FROM TB_EVENT_PARTICIPANTS WHERE EVENT_ID = :EVENT_ID';
    Q.ParamByName('EVENT_ID').AsInteger := AEventID;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
