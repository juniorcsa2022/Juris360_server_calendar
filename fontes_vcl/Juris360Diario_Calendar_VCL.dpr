program Juris360Diario_Calendar_VCL;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uWebAPIClient in 'uWebAPIClient.pas',
  uEventEditForm in 'uEventEditForm.pas' {EventEditForm},
  System.SysUtils,
  uInputParticipantForm in 'uInputParticipantForm.pas',
  uModels in 'uModels.pas';

{$R *.res}

begin
FormatSettings := TFormatSettings.Invariant; // <<<< ADICIONE ESTA LINHA AQUI
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  // Application.CreateForm(TEventEditForm, EventEditForm);
  Application.Run;
end.
