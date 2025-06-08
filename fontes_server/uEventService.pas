unit uEventService;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.DApt.Intf, FireDAC.Phys.IBBase, FireDAC.Phys.FB, FireDAC.VCLUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.Phys,
  FireDAC.Phys.FBDef, FireDAC.Stan.Param, FireDAC.DatS, System.Hash,
  System.SysUtils, System.Classes, System.Generics.Collections, uModels,
  uEventRepository, uDM;

type
  TEventService = class
  private
    FRepository: TEventRepository;
    function DateTimeToiCalFormat(ADateTime: TDateTime; AAllDay: Boolean): string;
  public
    constructor Create;
    destructor Destroy; override;
    function AddEvent(AEvent: TEvent): TEvent;
    function GetEvent(AID: Integer): TEvent;
    function GetAllEvents: TObjectList<TEvent>;
    procedure UpdateEvent(AEvent: TEvent);
    procedure DeleteEvent(AID: Integer);
    function GenerateIcsForEvent(AEvent: TEvent): string;
    function GenerateIcsForAllEvents(AEvents: TObjectList<TEvent>): string;
    // *** CORREÇÃO: Nome do parâmetro alterado para refletir que são segundos ***
    function GetEventsForReminder(ACheckIntervalSeconds: Integer): TObjectList<TEvent>;
  end;

implementation

uses
  DateUtils;

{ TEventService }

constructor TEventService.Create;
begin
  inherited Create;
  FRepository := TEventRepository.Create(DM.Conexao);
end;

destructor TEventService.Destroy;
begin
  FreeAndNil(FRepository);
  inherited;
end;

function TEventService.AddEvent(AEvent: TEvent): TEvent;
begin
  Result := AEvent;
  FRepository.AddEvent(AEvent, TDateTime.NowUTC);
end;

function TEventService.GetEvent(AID: Integer): TEvent;
begin
  Result := FRepository.GetEventById(AID);
end;

function TEventService.GetAllEvents: TObjectList<TEvent>;
begin
  Result := FRepository.GetAllEvents;
end;

procedure TEventService.UpdateEvent(AEvent: TEvent);
begin
  FRepository.UpdateEvent(AEvent, TDateTime.NowUTC);
end;

procedure TEventService.DeleteEvent(AID: Integer);
begin
  FRepository.DeleteEvent(AID);
end;

function TEventService.GetEventsForReminder(ACheckIntervalSeconds: Integer): TObjectList<TEvent>;
var
  Q: TFDQuery;
  LItem: TEvent;
  CurrentTimeUTC, LimitTimeUTC: TDateTime;
begin
  Result := TObjectList<TEvent>.Create(True); // A lista é dona dos objetos
  Q := TFDQuery.Create(nil);
  try
    if not DM.Conexao.Connected then
      DM.Connect;
    Q.Connection := DM.Conexao;

    CurrentTimeUTC := TDateTime.NowUTC;
    // *** CORREÇÃO: Usa IncSecond em vez de IncMinute ***
    LimitTimeUTC := IncSecond(CurrentTimeUTC, ACheckIntervalSeconds);

    Q.SQL.Text :=
      'SELECT * FROM TB_EVENTS WHERE REMINDER_MINUTES > 0 ' +
      'AND DATEADD(MINUTE, -REMINDER_MINUTES, START_DATETIME) > :p_current_time_utc ' +
      'AND DATEADD(MINUTE, -REMINDER_MINUTES, START_DATETIME) <= :p_limit_time_utc';

    Q.ParamByName('p_current_time_utc').AsDateTime := CurrentTimeUTC;
    Q.ParamByName('p_limit_time_utc').AsDateTime := LimitTimeUTC;

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
      FRepository.LoadParticipants(LItem);
      Result.Add(LItem);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TEventService.DateTimeToiCalFormat(ADateTime: TDateTime; AAllDay: Boolean): string;
var
  Year, Month, Day, Hour, Min, Sec, MSec: Word;
begin
  if AAllDay then
  begin
    DecodeDate(ADateTime, Year, Month, Day);
    Result := Format('%.4d%.2d%.2d', [Year, Month, Day]);
  end
  else
  begin
    DecodeDateTime(ADateTime, Year, Month, Day, Hour, Min, Sec, MSec);
    Result := Format('%.4d%.2d%.2dT%.2d%.2d%.2dZ', [Year, Month, Day, Hour, Min, Sec]);
  end;
end;

function EscapeIcalText(const AText: string): string;
begin
  Result := StringReplace(AText, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, ';', '\;', [rfReplaceAll]);
  Result := StringReplace(Result, ',', '\,', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
end;

function TEventService.GenerateIcsForEvent(AEvent: TEvent): string;
var
  LStringBuilder: TStringList;
  LUID: string;
  Participant: TParticipant;
  LParticipantStatus, LParticipantRole: string;
begin
  LStringBuilder := TStringList.Create;
  try
    LStringBuilder.Add('BEGIN:VCALENDAR');
    LStringBuilder.Add('VERSION:2.0');
    LStringBuilder.Add('PRODID:-//Juris360//Agenda v1.0//PT-BR');
    LStringBuilder.Add('BEGIN:VEVENT');
    LUID := THashMD5.GetHashString(IntToStr(AEvent.ID));
    LStringBuilder.Add('UID:' + LUID + '@juris360.com.br');
    LStringBuilder.Add('DTSTAMP:' + DateTimeToiCalFormat(TDateTime.NowUTC, False));
    if AEvent.AllDay then
    begin
      LStringBuilder.Add('DTSTART;VALUE=DATE:' + DateTimeToiCalFormat(AEvent.StartDateTime, True));
      LStringBuilder.Add('DTEND;VALUE=DATE:' + DateTimeToiCalFormat(IncDay(AEvent.EndDateTime, 1), True));
    end
    else
    begin
      LStringBuilder.Add('DTSTART:' + DateTimeToiCalFormat(AEvent.StartDateTime, False));
      LStringBuilder.Add('DTEND:' + DateTimeToiCalFormat(AEvent.EndDateTime, False));
    end;
    LStringBuilder.Add('SUMMARY:' + EscapeIcalText(AEvent.Title));
    if AEvent.Description <> '' then
      LStringBuilder.Add('DESCRIPTION:' + EscapeIcalText(AEvent.Description));
    if AEvent.Location <> '' then
      LStringBuilder.Add('LOCATION:' + EscapeIcalText(AEvent.Location));
    case AEvent.Status of
      esConfirmed: LStringBuilder.Add('STATUS:CONFIRMED');
      esTentative: LStringBuilder.Add('STATUS:TENTATIVE');
      esCancelled: LStringBuilder.Add('STATUS:CANCELLED');
    end;
    if AEvent.RecurrenceRule <> '' then
      LStringBuilder.Add('RRULE:' + AEvent.RecurrenceRule);
    if AEvent.ReminderMinutes > 0 then
    begin
      LStringBuilder.Add('BEGIN:VALARM');
      LStringBuilder.Add('ACTION:DISPLAY');
      LStringBuilder.Add('DESCRIPTION:Lembrete: ' + EscapeIcalText(AEvent.Title));
      LStringBuilder.Add('TRIGGER:-PT' + IntToStr(AEvent.ReminderMinutes) + 'M');
      LStringBuilder.Add('END:VALARM');
    end;
    for Participant in AEvent.Participants do
    begin
      LParticipantStatus := TParticipant.StatusToString(Participant.Status);
      LParticipantRole := TParticipant.RoleToString(Participant.Role);
      LStringBuilder.Add(Format('ATTENDEE;ROLE=%s;PARTSTAT=%s;CN=%s:mailto:%s',
        [LParticipantRole, LParticipantStatus, EscapeIcalText(Participant.Name), Participant.Email]));
      if Participant.Role = prOrganizer then
        LStringBuilder.Add(Format('ORGANIZER;CN=%s:mailto:%s',
          [EscapeIcalText(Participant.Name), Participant.Email]));
    end;
    LStringBuilder.Add('END:VEVENT');
    LStringBuilder.Add('END:VCALENDAR');
    Result := LStringBuilder.Text;
  finally
    FreeAndNil(LStringBuilder);
  end;
end;

function TEventService.GenerateIcsForAllEvents(AEvents: TObjectList<TEvent>): string;
var
  LStringBuilder: TStringList;
  LEventWithParticipants: TEvent;
  iCalEventText: string;
  startPos: Integer;
begin
  LStringBuilder := TStringList.Create;
  try
    LStringBuilder.Add('BEGIN:VCALENDAR');
    LStringBuilder.Add('VERSION:2.0');
    LStringBuilder.Add('PRODID:-//Juris360//Agenda v1.0//PT-BR');
    for var Event in AEvents do
    begin
      LEventWithParticipants := GetEvent(Event.ID);
      if Assigned(LEventWithParticipants) then
      try
        iCalEventText := GenerateIcsForEvent(LEventWithParticipants);
        startPos := Pos('BEGIN:VEVENT', iCalEventText);
        if startPos > 0 then
          LStringBuilder.Add(Copy(iCalEventText, startPos, Pos('END:VCALENDAR', iCalEventText) - startPos));
      finally
        LEventWithParticipants.Free;
      end;
    end;
    LStringBuilder.Add('END:VCALENDAR');
    Result := LStringBuilder.Text;
  finally
    FreeAndNil(LStringBuilder);
  end;
end;

end.
