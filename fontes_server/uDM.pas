unit uDM;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.DApt.Intf,
  FireDAC.Phys.IBBase, FireDAC.Phys.FB, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.Phys, FireDAC.Phys.FBDef,
  FireDAC.Stan.Param, FireDAC.DatS;

type
  TDM = class(TDataModule)
    Conexao: TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    FDMemTable1: TFDMemTable;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Connect;
    procedure Disconnect;
  end;

var
  DM: TDM;

implementation

{$R *.dfm}

procedure TDM.Connect;
begin
  if not Conexao.Connected then
  begin
    Conexao.Params.Clear;
    Conexao.Params.Add('DriverID=FB');
    Conexao.Params.Add('Database=C:\Juris360\api\server\DADOS.FDB');
    Conexao.Params.Add('User_Name=SYSDBA');
    Conexao.Params.Add('Password=masterkey');
    Conexao.Params.Add('Protocol=TCPIP');
    Conexao.Params.Add('Server=localhost');
    Conexao.Params.Add('Port=3040');
    Conexao.Params.Add('CharacterSet=UTF8');
    Conexao.Params.Add('SessionTimeZone=UTC');
    Conexao.Connected := True;
  end;
end;

procedure TDM.Disconnect;
begin
  if Conexao.Connected then
    Conexao.Connected := False;
end;

initialization
  DM := TDM.Create(nil);
finalization
  DM.Free;

end.
