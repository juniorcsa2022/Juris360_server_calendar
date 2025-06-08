unit uModels;

interface

uses
  System.SysUtils, System.JSON, DateUtils, System.Generics.Collections;

type
  TEventStatus = (esConfirmed, esTentative, esCancelled);
  TParticipantStatus = (psNeedsAction, psAccepted, psDeclined, psTentative);
  TParticipantRole = (prOrganizer, prAttendee, prOptional);

  TParticipant = class
  public
    ID, EventID: Integer;
    Name, Email: string;
    Role: TParticipantRole;
    Status: TParticipantStatus;
    constructor Create;
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSONObject: TJSONObject);
    class function FromJSONObject(AJSONObject: TJSONObject): TParticipant;
    class function RoleToString(ARole: TParticipantRole): string; static;
    class function StringToRole(ARoleStr: string): TParticipantRole; static;
    class function StatusToString(AStatus: TParticipantStatus): string; static;
    class function StringToStatus(AStatusStr: string): TParticipantStatus; static;
  end;

  TEvent = class
  public
    ID: Integer;
    Title, Description, Location, RecurrenceRule: string;
    StartDateTime, EndDateTime, CreatedAt, UpdatedAt: TDateTime;
    AllDay: Boolean;
    ReminderMinutes: Integer;
    Status: TEventStatus;
    Participants: TObjectList<TParticipant>;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSONObject: TJSONObject);
    class function FromJSONObject(AJSONObject: TJSONObject): TEvent;
    class function StatusToString(AStatus: TEventStatus): string; static;
    class function StringToStatus(AStatusStr: string): TEventStatus; static;
  end;

implementation

function GetLocalUtcOffsetString: string;
var
  LOffsetMinutes, LHours, LMinutes: Integer;
  LSign: Char;
begin
  LOffsetMinutes := Round((Now - TDateTime.NowUTC) * MinsPerDay);
  if LOffsetMinutes < 0 then
    LSign := '-'
  else
    LSign := '+';
  LOffsetMinutes := Abs(LOffsetMinutes);
  LHours := LOffsetMinutes div 60;
  LMinutes := LOffsetMinutes mod 60;
  Result := Format('%s%.2d:%.2d', [LSign, LHours, LMinutes]);
end;

{ TParticipant }

constructor TParticipant.Create;
begin
  // Implementation
end;

function TParticipant.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', ID);
  Result.AddPair('event_id', EventID);
  Result.AddPair('name', Name);
  Result.AddPair('email', Email);
  Result.AddPair('role', RoleToString(Role));
  Result.AddPair('status', StatusToString(Status));
end;

procedure TParticipant.FromJSON(AJSONObject: TJSONObject);
var
  LValue: TJSONValue;
begin
  ID := 0;
  EventID := 0;
  LValue := AJSONObject.GetValue('id');
  if Assigned(LValue) and (LValue is TJSONNumber) then
    ID := TJSONNumber(LValue).AsInt;
  LValue := AJSONObject.GetValue('event_id');
  if Assigned(LValue) and (LValue is TJSONNumber) then
    EventID := TJSONNumber(LValue).AsInt;
  LValue := AJSONObject.GetValue('name');
  if Assigned(LValue) and (LValue is TJSONString) then
    Name := TJSONString(LValue).Value;
  LValue := AJSONObject.GetValue('email');
  if Assigned(LValue) and (LValue is TJSONString) then
    Email := TJSONString(LValue).Value;
  LValue := AJSONObject.GetValue('role');
  if Assigned(LValue) and (LValue is TJSONString) then
    Role := StringToRole(TJSONString(LValue).Value);
  LValue := AJSONObject.GetValue('status');
  if Assigned(LValue) and (LValue is TJSONString) then
    Status := StringToStatus(TJSONString(LValue).Value);
end;

class function TParticipant.FromJSONObject(AJSONObject: TJSONObject): TParticipant;
begin
  Result := TParticipant.Create;
  Result.FromJSON(AJSONObject);
end;

class function TParticipant.RoleToString(ARole: TParticipantRole): string;
begin
  case ARole of
    prOrganizer: Result := 'ORGANIZER';
    prAttendee: Result := 'ATTENDEE';
    prOptional: Result := 'OPTIONAL';
  else
    Result := '';
  end;
end;

class function TParticipant.StringToRole(ARoleStr: string): TParticipantRole;
begin
  if SameText(ARoleStr, 'ORGANIZER') then Result := prOrganizer
  else if SameText(ARoleStr, 'ATTENDEE') then Result := prAttendee
  else if SameText(ARoleStr, 'OPTIONAL') then Result := prOptional
  else Result := prAttendee;
end;

class function TParticipant.StatusToString(AStatus: TParticipantStatus): string;
begin
  case AStatus of
    psNeedsAction: Result := 'NEEDS-ACTION';
    psAccepted: Result := 'ACCEPTED';
    psDeclined: Result := 'DECLINED';
    psTentative: Result := 'TENTATIVE';
  else
    Result := '';
  end;
end;

class function TParticipant.StringToStatus(AStatusStr: string): TParticipantStatus;
begin
  if SameText(AStatusStr, 'NEEDS-ACTION') then Result := psNeedsAction
  else if SameText(AStatusStr, 'ACCEPTED') then Result := psAccepted
  else if SameText(AStatusStr, 'DECLINED') then Result := psDeclined
  else if SameText(AStatusStr, 'TENTATIVE') then Result := psTentative
  else Result := psNeedsAction;
end;

{ TEvent }

constructor TEvent.Create;
begin
  Clear;
  Participants := TObjectList<TParticipant>.Create(True);
end;

destructor TEvent.Destroy;
begin
  FreeAndNil(Participants);
  inherited;
end;

procedure TEvent.Clear;
begin
  ID := 0;
  Title := '';
  Description := '';
  Location := '';
  StartDateTime := 0;
  EndDateTime := 0;
  AllDay := False;
  ReminderMinutes := 0;
  RecurrenceRule := '';
  Status := esConfirmed;
  CreatedAt := 0;
  UpdatedAt := 0;
  if Assigned(Participants) then
    Participants.Clear;
end;

function TEvent.ToJSON: TJSONObject;
var
  LJSONArray: TJSONArray;
  Participant: TParticipant;
  LOffsetString: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', ID);
  Result.AddPair('title', Title);
  Result.AddPair('description', Description);
  Result.AddPair('location', Location);

  LOffsetString := GetLocalUtcOffsetString;

  if AllDay then
  begin
    Result.AddPair('start_datetime', FormatDateTime('yyyy-mm-dd', StartDateTime));
    Result.AddPair('end_datetime', FormatDateTime('yyyy-mm-dd', EndDateTime));
  end
  else
  begin
    Result.AddPair('start_datetime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', StartDateTime) + LOffsetString);
    Result.AddPair('end_datetime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', EndDateTime) + LOffsetString);
  end;

  Result.AddPair('all_day', TJSONBool.Create(AllDay));
  Result.AddPair('reminder_minutes', ReminderMinutes);
  Result.AddPair('recurrence_rule', RecurrenceRule);
  Result.AddPair('status', StatusToString(Status));

  LJSONArray := TJSONArray.Create;
  for Participant in Participants do
  begin
    LJSONArray.AddElement(Participant.ToJSON);
  end;
  // *** CORREÇÃO DEFINITIVA ***
  // A linha abaixo transfere a posse de LJSONArray para o Result.
  // Por isso, NÃO devemos mais chamar LJSONArray.Free.
  Result.AddPair('participants', LJSONArray);
end;

procedure TEvent.FromJSON(AJSONObject: TJSONObject);
var
  LValue: TJSONValue;
  LJSONArray: TJSONArray;
  LJSONObjectItem: TJSONValue;
  Participant: TParticipant;
begin
  Clear;
  LValue := AJSONObject.GetValue('id');
  if Assigned(LValue) and (LValue is TJSONNumber) then
    ID := TJSONNumber(LValue).AsInt;

  LValue := AJSONObject.GetValue('title');
  if Assigned(LValue) and (LValue is TJSONString) then
    Title := TJSONString(LValue).Value;

  LValue := AJSONObject.GetValue('description');
  if Assigned(LValue) and (LValue is TJSONString) then
    Description := TJSONString(LValue).Value;

  LValue := AJSONObject.GetValue('location');
  if Assigned(LValue) and (LValue is TJSONString) then
    Location := TJSONString(LValue).Value;

  LValue := AJSONObject.GetValue('start_datetime');
  if Assigned(LValue) and (LValue is TJSONString) then
    StartDateTime := ISO8601ToDate(TJSONString(LValue).Value, False);

  LValue := AJSONObject.GetValue('end_datetime');
  if Assigned(LValue) and (LValue is TJSONString) then
    EndDateTime := ISO8601ToDate(TJSONString(LValue).Value, False);

  LValue := AJSONObject.GetValue('all_day');
  if Assigned(LValue) and (LValue is TJSONBool) then
    AllDay := TJSONBool(LValue).AsBoolean;

  LValue := AJSONObject.GetValue('reminder_minutes');
  if Assigned(LValue) and (LValue is TJSONNumber) then
    ReminderMinutes := TJSONNumber(LValue).AsInt;

  LValue := AJSONObject.GetValue('recurrence_rule');
  if Assigned(LValue) and (LValue is TJSONString) then
    RecurrenceRule := TJSONString(LValue).Value;

  LValue := AJSONObject.GetValue('status');
  if Assigned(LValue) and (LValue is TJSONString) then
    Status := StringToStatus(TJSONString(LValue).Value);

  LValue := AJSONObject.GetValue('created_at');
  if Assigned(LValue) and (LValue is TJSONString) then
    CreatedAt := ISO8601ToDate(TJSONString(LValue).Value, False);

  LValue := AJSONObject.GetValue('updated_at');
  if Assigned(LValue) and (LValue is TJSONString) then
    UpdatedAt := ISO8601ToDate(TJSONString(LValue).Value, False);

  LValue := AJSONObject.GetValue('participants');
  if Assigned(LValue) and (LValue is TJSONArray) then
  begin
    LJSONArray := LValue as TJSONArray;
    for LJSONObjectItem in LJSONArray do
    begin
      Participant := TParticipant.FromJSONObject(LJSONObjectItem as TJSONObject);
      Participants.Add(Participant);
    end;
  end;
end;

class function TEvent.FromJSONObject(AJSONObject: TJSONObject): TEvent;
begin
  Result := TEvent.Create;
  Result.FromJSON(AJSONObject);
end;

class function TEvent.StatusToString(AStatus: TEventStatus): string;
begin
  case AStatus of
    esConfirmed: Result := 'CONFIRMED';
    esTentative: Result := 'TENTATIVE';
    esCancelled: Result := 'CANCELLED';
  else
    Result := '';
  end;
end;

class function TEvent.StringToStatus(AStatusStr: string): TEventStatus;
begin
  if SameText(AStatusStr, 'CONFIRMED') then Result := esConfirmed
  else if SameText(AStatusStr, 'TENTATIVE') then Result := esTentative
  else if SameText(AStatusStr, 'CANCELLED') then Result := esCancelled
  else Result := esConfirmed;
end;

end.
