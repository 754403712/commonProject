unit ufrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, diocp.ex.ntrip, Vcl.StdCtrls,
  Vcl.ComCtrls, System.Actions, Vcl.ActnList, utils.base64, IniFiles,
  Vcl.ExtCtrls, diocp.tcp.client, utils.queues, System.SyncObjs, diocp.sockets;

type
  TfrmMain = class(TForm)
    PageControl1: TPageControl;
    tsConfig: TTabSheet;
    edtPort: TEdit;
    Label1: TLabel;
    tsMonitor: TTabSheet;
    actlstMain: TActionList;
    btnStart: TButton;
    actStart: TAction;
    tmrCheck: TTimer;
    tsLog: TTabSheet;
    mmoLog: TMemo;
    edtNMEAHost: TEdit;
    edtNMEAPort: TEdit;
    procedure actStartExecute(Sender: TObject);
  private
    FLocker:TCriticalSection;


    FNtripServer:TDiocpNtripServer;

    FRequestNMEAClients:TDiocpTcpClient;
    FRequestContextPool: TSafeQueue;

    FNtripSourcePass:String;

    function GetRequestContext: TIocpRemoteContext;

    procedure OnRequestContextDisconnected(pvContext: TDiocpCustomContext);
    procedure OnRequestContextRecvBuffer(pvContext: TDiocpCustomContext; buf:
        Pointer; len: cardinal; pvErrorCode: Integer);

    procedure OnNTripRequest(pvRequest: TDiocpNTripRequest);
    procedure OnNTripRequestAccept(pvRequest: TDiocpNTripRequest; var vIsNMEA:Boolean);

    procedure OnNTripSourceRecvBuffer(pvContext:TDiocpNtripClientContext;buf: Pointer; len: Cardinal);

    // ����NMEA����
    procedure RequestNMEA(pvRequest: TDiocpNTripRequest);


    procedure ReloadConfig;
    procedure SaveConfig;
  public

    constructor Create(AOwner: TComponent); override;

    destructor Destroy; override;


  end;

var
  frmMain: TfrmMain;

implementation

uses
  uFMMonitor, utils.strings, utils.safeLogger, ntrip.handler;

{$R *.dfm}

{ TForm1 }

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited;
  FLocker := TCriticalSection.Create;

  FRequestNMEAClients := TDiocpTcpClient.Create(Self);
  FRequestNMEAClients.OnContextDisconnected := OnRequestContextDisconnected;
  FRequestNMEAClients.OnReceivedBuffer := OnRequestContextRecvBuffer;
  FRequestNMEAClients.Open;
  FRequestContextPool := TSafeQueue.Create;


  FNtripServer := TDiocpNtripServer.Create(Self);
  FNtripServer.OnDiocpNtripRequest := OnNTripRequest;
  FNtripServer.OnDiocpRecvNtripSourceBuffer := OnNTripSourceRecvBuffer;
  FNtripServer.OnRequestAcceptEvent := OnNTripRequestAccept;
  FNtripServer.CreateDataMonitor;

  TFMMonitor.CreateAsChild(tsMonitor, FNtripServer);
  ReloadConfig();


  sfLogger.setAppender(TStringsAppender.Create(mmoLog.Lines));
  sfLogger.AppendInMainThread := true;
end;

destructor TfrmMain.Destroy;
begin
  FRequestContextPool.Free;
  FLocker.Free;

  inherited;
end;

procedure TfrmMain.actStartExecute(Sender: TObject);
begin
  if FNtripServer.Active then
  begin
    FNtripServer.Active := false;
    actStart.Caption := '�������';
  end else
  begin
    ReloadSourceTable;
    __NMEAPort := StrToIntDef(edtNMEAPort.Text, 4001);
    __NMEAHost := edtNMEAHost.Text;
    SaveConfig;
    FNtripServer.Port := StrToInt(edtPort.Text);
    FNtripServer.Active := true;
    actStart.Caption := '���ֹͣ';
  end;
end;

function TfrmMain.GetRequestContext: TIocpRemoteContext;
begin
  Result :=TIocpRemoteContext(FRequestContextPool.DeQueue);
  if Result = nil then
  begin
    FLocker.Enter;
    try
      Result := FRequestNMEAClients.Add;
    finally
      FLocker.Leave;
    end;
  end;
end;

procedure TfrmMain.OnNTripRequest(pvRequest: TDiocpNTripRequest);
var
  lvAuth, lvValue, lvUser, lvPass:string;
  p:PChar;
  lvContext, lvNtripSourceContext:TDiocpNtripClientContext;
  lvAuthentication, lvIsNMEA:Boolean;
begin
  lvContext := pvRequest.Connection;
  lvAuthentication := false;
  if pvRequest.ExtractBasicAuthenticationInfo(lvUser, lvPass) then
  begin
    // ׼��������֤
    // lvAuthentication := __ntripCasterDataCenter.Authentication(lvUser, lvPass);
    lvAuthentication := true;
    if lvAuthentication then
    begin   // ��֤�ɹ�
      if pvRequest.MountPoint <> '' then
      begin
        lvIsNMEA := true;
        if lvIsNMEA then         // NMEA �Ĺ��ص�
        begin
          sfLogger.logMessage(pvRequest.ExtractNMEAString);

          RequestNMEA(pvRequest);


        end else
        begin
          // �����NtripSource
          lvNtripSourceContext := FNtripServer.FindNtripSource(pvRequest.MountPoint);
          if lvNtripSourceContext = nil then
          begin  // �Ҳ������ߵ�NtripSource
            ResponseSourceTableAndOK(pvRequest);
            pvRequest.CloseContext;
            Exit;
          end else
          begin  // ��֤�ɹ�
            // ������ַ�����
            lvNtripSourceContext.AddNtripClient(lvContext);

            // �ظ��ͻ���
            pvRequest.Response.ICY200OK;
            Exit;
          end;
        end;
      end else
      begin
        ResponseSourceTableAndOK(pvRequest);

        pvRequest.CloseContext;
        Exit;
      end;
    end;
  end;

  if not lvAuthentication then      // ��֤ʧ��
  begin
    if pvRequest.MountPoint = '' then
    begin  // ��ȡMountPoint����
      ResponseSourceTableAndOK(pvRequest);

      pvRequest.CloseContext;
    end else
    begin
      pvRequest.Response.Unauthorized;
      pvRequest.Response.InvalidPasswordMsg(pvRequest.MountPoint);
      pvRequest.CloseContext;
    end;
  end;


end;

procedure TfrmMain.OnNTripRequestAccept(pvRequest: TDiocpNTripRequest;
  var vIsNMEA: Boolean);
begin
  //  if pvRequest.MountPoint = '' then
  vIsNMEA := true;

end;

procedure TfrmMain.OnNTripSourceRecvBuffer(pvContext: TDiocpNtripClientContext;
  buf: Pointer; len: Cardinal);
begin
  // �ַ�GNSS����
  pvContext.DispatchGNSSDATA(buf, len);
end;

procedure TfrmMain.OnRequestContextDisconnected(pvContext: TDiocpCustomContext);
begin
  pvContext.Data := nil;
  FRequestContextPool.EnQueue(pvContext);
end;

procedure TfrmMain.OnRequestContextRecvBuffer(pvContext: TDiocpCustomContext;
    buf: Pointer; len: cardinal; pvErrorCode: Integer);
var
  lvContext:TDiocpNtripClientContext;
begin
  lvContext := TDiocpNtripClientContext(pvContext.Data);
  if lvContext = nil then
  begin
    // ��Ӧ������ͻ��˲�����
    pvContext.Close;
    exit;
  end;

  if not lvContext.Active then
  begin
    // ��Ӧ������ͻ��˶Ͽ�
    pvContext.Close;
    exit;
  end;

  if lvContext.Data <> pvContext then
  begin  // ��Ӧ������ͻ��˰󶨵Ĳ��Ǹ�����
    pvContext.Close;
    exit;
  end;

  /// Ͷ�ݻؿͻ���
  lvContext.PostWSASendRequest(buf, len, true);
end;

procedure TfrmMain.ReloadConfig;
var
  lvINIFile:TINIFile;
  lvIntValue:Integer;
  lvStrValue:String;
begin
  lvINIFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.config.ini'));
  try
    lvIntValue := lvINIFile.ReadInteger('main', 'port', 0);
    if lvIntValue = 0 then
    begin
      lvIntValue := 2101;
      lvINIFile.WriteInteger('main', 'port', lvIntValue);
    end;

    lvStrValue := lvINIFile.ReadString('main', 'sourcePass', '');
    if lvStrValue = '' then
    begin
      lvStrValue := 'admin';
      lvINIFile.WriteString('main', 'sourcePass', lvStrValue);
    end;
    edtPort.Text := intToStr(lvIntValue);
    FNtripServer.NtripSourcePassword := lvStrValue;

    edtNMEAHost.Text := lvINIFile.ReadString('main', 'NMEAHost', '127.0.0.1');
    edtNMEAPort.Text := lvINIFile.ReadString('main', 'NMEAPort', '4001');
  finally
    lvINIFile.Free;
  end;

end;

procedure TfrmMain.RequestNMEA(pvRequest: TDiocpNTripRequest);
var
  lvRequestClient:TIocpRemoteContext;
  lvNMEAData:AnsiString;
begin
  lvRequestClient :=TIocpRemoteContext(pvRequest.Connection.Data);
  if lvRequestClient = nil then
  begin
    lvRequestClient := GetRequestContext;

    // �໥��
    pvRequest.Connection.Data := lvRequestClient;
    lvRequestClient.Data := pvRequest.Connection;
  end;

  if (not lvRequestClient.Active) then
  begin
    try
      lvRequestClient.Host := __NMEAHost;
      lvRequestClient.Port := __NMEAPort;
      lvRequestClient.Connect;
    except
      on e:Exception do
      begin
        sfLogger.logMessage('ת��NMEA����ʱ�������쳣:' + e.Message);
      end;
    end;
  end;



  lvNMEAData := trim(pvRequest.ExtractNMEAString);
  lvRequestClient.PostWSASendRequest(PAnsiChar(lvNMEAData), Length(lvNMEAData));
end;

procedure TfrmMain.SaveConfig;
var
  lvINIFile:TINIFile;
  lvIntValue:Integer;
begin
  lvINIFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.config.ini'));
  try
    lvIntValue := StrToIntDef(edtPort.Text, 2101);
    lvINIFile.WriteInteger('main', 'port', lvIntValue);

    lvINIFile.WriteString('main', 'NMEAHost', edtNMEAHost.Text);

    lvIntValue := StrToIntDef(edtNMEAPort.Text, 2101);
    lvINIFile.WriteInteger('main', 'NMEAPort', lvIntValue);
  finally
    lvINIFile.Free;
  end;
end;

end.
