program Juris360Diario_Calendar_SERVER;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  uEventService in 'uEventService.pas',
  uEventRepository in 'uEventRepository.pas',
  uModels in 'uModels.pas',
  uDM in 'uDM.pas',
  uNotificationService in 'uNotificationService.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
