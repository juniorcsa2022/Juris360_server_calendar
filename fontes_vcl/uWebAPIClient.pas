unit uWebAPIClient;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.URLClient, System.Net.HttpClient, // System.Net.HttpClientComponent n�o � mais necess�rio
  System.Net.Mime, uModels, System.Net.HttpClientComponent; // Adicionado System.Net.HttpClientComponent

type
  TWebAPIClient = class
  private
    FHttpClient: TNetHttpClient;
    FBaseUrl: string;
    // A fun��o ExecuteRequest ser� um wrapper que cria e executa uma TNetHTTPRequest
    function ExecuteRequest(AMethod: string; APath: string; ABodyStream: TStream = nil; AContentType: string = ''): string;
  public
    constructor Create(const ABaseUrl: string);
    destructor Destroy; override;

    function GetEvents: TArray<TEvent>;
    function GetEvent(AID: Integer): TEvent;
    function CreateEvent(AEvent: TEvent): TEvent;
    function UpdateEvent(AEvent: TEvent): TEvent;
    procedure DeleteEvent(AID: Integer);

    function GetEventIcsUrl(AID: Integer): string;
    function GetAllEventsIcsUrl: string;
  end;

implementation

// Removida a necessidade de System.Net.HttpClientComponent na implementation
// pois TNetHTTPRequest � um componente e ser� instanciado.

{ TWebAPIClient }

constructor TWebAPIClient.Create(const ABaseUrl: string);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  // FHttpClient agora � o TNetHTTPClient (componente), n�o o THTTPClient (implementa��o base)
  FHttpClient := TNetHttpClient.Create(nil); // Nulo para Owner, pois n�o ser� um componente visual em um formul�rio
  FHttpClient.ConnectionTimeout := 10000;
  FHttpClient.ResponseTimeout := 15000;
end;

destructor TWebAPIClient.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

function TWebAPIClient.ExecuteRequest(AMethod: string; APath: string; ABodyStream: TStream = nil; AContentType: string = ''): string;
var
  LFullURL: string;
  LResponse: IHTTPResponse;
  LRequest: TNetHTTPRequest; // <<<< Declara��o do componente Request
begin
  LFullURL := FBaseUrl + APath;

  // Cria uma nova inst�ncia de TNetHTTPRequest para cada requisi��o
  LRequest := TNetHTTPRequest.Create(nil); // Nulo para Owner
  try
    LRequest.Client := FHttpClient; // Associa o Request ao nosso cliente HTTP
    LRequest.URL := LFullURL;
    LRequest.MethodString := AMethod;

    // Configura o Content-Type como um header da requisi��o, se fornecido.
    if AContentType <> '' then
      LRequest.CustomHeaders['Content-Type'] := AContentType;

    // Lida com o corpo da requisi��o para POST/PUT
    if (AMethod = 'POST') or (AMethod = 'PUT') then
    begin
      if ABodyStream <> nil then
      begin
        ABodyStream.Position := 0; // Garante que o stream est� no in�cio
        LRequest.SourceStream := ABodyStream; // Atribui o stream diretamente
      end
      else
        LRequest.SourceStream := nil; // Corpo vazio
    end
    else // Para GET/DELETE, garante que SourceStream esteja limpo
      LRequest.SourceStream := nil;

    // Executa a requisi��o.
    // O m�todo Execute do TNetHTTPRequest retorna IHTTPResponse.
    LResponse := LRequest.Execute;

    if (LResponse.StatusCode >= 200) and (LResponse.StatusCode < 300) then
    begin
      Result := LResponse.ContentAsString;
    end
    else
    begin
      raise Exception.CreateFmt ('Erro na requisi��o %s %s: %d - %s',
        [AMethod, LFullURL, LResponse.StatusCode, LResponse.ContentAsString]);
    end;
  finally
    LRequest.Free; // Libera a inst�ncia do Request
    // O ABodyStream (que � TStringStream) ainda � responsabilidade de quem chamou liber�-lo.
  end;
end;

function TWebAPIClient.GetEvents: TArray<TEvent>;
var
  LResponseJson: string;
  LJSONArray: TJSONArray;
  LJSONObject: TJSONObject;
  LItem: TEvent;
  I: Integer;
begin
  LResponseJson := ExecuteRequest('GET', '/events');
  LJSONArray := TJSONObject.ParseJSONValue(LResponseJson) as TJSONArray;
  if Assigned(LJSONArray) then
  begin
    SetLength(Result, LJSONArray.Count); // Usar .Count para TJSONArray
    for I := 0 to LJSONArray.Count - 1 do
    begin
      LJSONObject := LJSONArray.Items[I] as TJSONObject;
      LItem := TEvent.FromJSONObject(LJSONObject);
      Result[I] := LItem;
    end;
  end
  else
    SetLength(Result, 0);
end;

function TWebAPIClient.GetEvent(AID: Integer): TEvent;
var
  LResponseJson: string;
  LJSONObject: TJSONObject;
begin
  LResponseJson := ExecuteRequest('GET', Format('/events/%d', [AID]));
  LJSONObject := TJSONObject.ParseJSONValue(LResponseJson) as TJSONObject;
  if Assigned(LJSONObject) then
  begin
    Result := TEvent.FromJSONObject(LJSONObject);
  end
  else
    Result := nil;
end;

function TWebAPIClient.CreateEvent(AEvent: TEvent): TEvent;
var
  LRequestJson: TStringStream;
  LResponseJson: string;
  LJSONObject: TJSONObject;
begin
  LRequestJson := TStringStream.Create(AEvent.ToJSON.ToString, TEncoding.UTF8);
  try
    LResponseJson := ExecuteRequest('POST', '/events', LRequestJson, 'application/json');
    LJSONObject := TJSONObject.ParseJSONValue(LResponseJson) as TJSONObject;
    if Assigned(LJSONObject) then
    begin
      Result := TEvent.FromJSONObject(LJSONObject);
    end
    else
      Result := nil;
  finally
    LRequestJson.Free;
  end;
end;

function TWebAPIClient.UpdateEvent(AEvent: TEvent): TEvent;
var
  LRequestJson: TStringStream;
  LResponseJson: string;
  LJSONObject: TJSONObject;
begin
  LRequestJson := TStringStream.Create(AEvent.ToJSON.ToString, TEncoding.UTF8);
  try
    LResponseJson := ExecuteRequest('PUT', Format('/events/%d', [AEvent.ID]), LRequestJson, 'application/json');
    LJSONObject := TJSONObject.ParseJSONValue(LResponseJson) as TJSONObject;
    if Assigned(LJSONObject) then
    begin
      Result := TEvent.FromJSONObject(LJSONObject);
    end
    else
      Result := nil;
  finally
    LRequestJson.Free;
  end;
end;

procedure TWebAPIClient.DeleteEvent(AID: Integer);
begin
  ExecuteRequest('DELETE', Format('/events/%d', [AID]));
end;

function TWebAPIClient.GetEventIcsUrl(AID: Integer): string;
begin
  Result := FBaseUrl + Format('/events/ics/%d', [AID]);
end;

function TWebAPIClient.GetAllEventsIcsUrl: string;
begin
  Result := FBaseUrl + '/events/ics';
end;

end.
