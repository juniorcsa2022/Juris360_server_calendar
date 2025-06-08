program HorseCalendarServer;

{$APPTYPE CONSOLE} // Ou {$APPTYPE GUI} se quiser uma aplicação de janela com console oculto

uses
  System.SysUtils,
  System.Classes,
  Horse,
  Horse.CORS, // Para permitir requisições de domínios diferentes
  Horse.Jhonson, // Para lidar com JSON nas rotas
  System.JSON,
  uDM,
  uModels,
  uEventRepository,
  uEventService,
  System.Net.Mime; // Para Content-Type

var
  EventService: TEventService;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    // Conecta ao banco de dados ao iniciar o servidor
    DM.Connect;
    EventService := TEventService.Create;

    Horse.Use(Cors); // Habilita CORS para permitir requisições de diferentes origens

    // =====================================================================
    // Rotas da API de Eventos (CRUD)
    // =====================================================================

    // GET /events - Listar todos os eventos
    Horse.Get('/events',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        Events: TList<TEvent>;
        Event: TEvent;
        JsonArray: TJSONArray;
      begin
        Events := EventService.GetAllEvents;
        JsonArray := TJSONArray.Create;
        try
          for Event in Events do
            JsonArray.Add(Event.ToJSON);
          Res.Send(JsonArray.ToString);
        finally
          JsonArray.Free;
          Events.Free; // Libera os objetos TEvent e a lista
        end;
      end);

    // GET /events/:id - Obter um evento específico
    Horse.Get('/events/:id',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        EventId: Integer;
        Event: TEvent;
      begin
        EventId := Req.Params.Items['id'].AsInteger;
        Event := EventService.GetEvent(EventId);
        if Assigned(Event) then
        begin
          Res.Send(Event.ToJSON.ToString);
          Event.Free;
        end
        else
          Res.Status(404).Send('Event not found');
      end);

    // POST /events - Criar um novo evento
    Horse.Post('/events',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        Event: TEvent;
        JSONObject: TJSONObject;
      begin
        JSONObject := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
        if not Assigned(JSONObject) then
        begin
          Res.Status(400).Send('Invalid JSON');
          Exit;
        end;
        try
          Event := TEvent.FromJSONObject(JSONObject);
          EventService.AddEvent(Event);
          Res.Status(201).Send(Event.ToJSON.ToString); // 201 Created
        finally
          FreeAndNil(JSONObject);
          FreeAndNil(Event);
        end;
      end);

    // PUT /events/:id - Atualizar um evento existente
    Horse.Put('/events/:id',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        EventId: Integer;
        Event: TEvent;
        JSONObject: TJSONObject;
      begin
        EventId := Req.Params.Items['id'].AsInteger;
        Event := EventService.GetEvent(EventId);
        if not Assigned(Event) then
        begin
          Res.Status(404).Send('Event not found');
          Exit;
        end;

        JSONObject := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
        if not Assigned(JSONObject) then
        begin
          Res.Status(400).Send('Invalid JSON');
          FreeAndNil(Event);
          Exit;
        end;

        try
          Event.FromJSON(JSONObject); // Atualiza o objeto existente
          if Event.ID <> EventId then // Garante que o ID no corpo seja o mesmo da URL
          begin
            Res.Status(400).Send('ID in body does not match ID in URL');
            Exit;
          end;

          EventService.UpdateEvent(Event);
          Res.Send(Event.ToJSON.ToString);
        finally
          FreeAndNil(JSONObject);
          FreeAndNil(Event);
        end;
      end);

    // DELETE /events/:id - Excluir um evento
    Horse.Delete('/events/:id',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        EventId: Integer;
      begin
        EventId := Req.Params.Items['id'].AsInteger;
        EventService.DeleteEvent(EventId);
        Res.Status(204).Send; // 204 No Content
      end);

    // =====================================================================
    // Rotas para ICS
    // =====================================================================

    // GET /events/ics/:id - Download ICS de um evento específico
    Horse.Get('/events/ics/:id',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        EventId: Integer;
        Event: TEvent;
        IcsContent: string;
      begin
        EventId := Req.Params.Items['id'].AsInteger;
        Event := EventService.GetEvent(EventId);
        if Assigned(Event) then
        begin
          IcsContent := EventService.GenerateIcsForEvent(Event);
          Res.ContentType(TMimeTypes.GetMimeType('.ics'))
             .Send(IcsContent);
          Event.Free;
        end
        else
          Res.Status(404).Send('Event not found');
      end);

    // GET /events/ics - Download ICS de todos os eventos (para Webcal)
    Horse.Get('/events/ics',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        Events: TList<TEvent>;
        IcsContent: string;
      begin
        Events := EventService.GetAllEvents;
        if Assigned(Events) then
        begin
          IcsContent := EventService.GenerateIcsForAllEvents(Events);
          Res.ContentType(TMimeTypes.GetMimeType('.ics'))
             .Send(IcsContent);
        end
        else
          Res.Status(404).Send('No events found');
      finally
        Events.Free; // Libera os objetos TEvent e a lista
      end);

    // Opcional: POST /events/import-ics - Importar ICS (requer parser de ICS)
    // Horse.Post('/events/import-ics',
    //   procedure(Req: THorseRequest; Res: THorseResponse)
    //   begin
    //     // Implementar parser de ICS aqui.
    //     Res.Send('Import ICS - NOT IMPLEMENTED YET');
    //   end);

    // Iniciar o servidor Horse na porta 8080 (ou outra porta)
    Horse.Listen(8080);
    Writeln('Horse Calendar Server is running on port 8080');
    Readln; // Mantém o console aberto

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.