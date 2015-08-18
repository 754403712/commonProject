(*
 *	 Unit owner: d10.�����
 *	       blog: http://www.cnblogs.com/dksoft
 *     homePage: www.diocp.org
 *
 *   2015-07-16 18:15:25
 *     TDiocpBlockTcpClient���RecvBufEnd����
 *
 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
 *   2015-03-16 13:51:06
 *     ���ConnectTimeOut����(���Խ��г�ʱ����,andriodƽ̨��ʱδʵ��)
 *
 *)
 
unit diocp.tcp.blockClient;

interface

uses
  SysUtils
  , diocp.res
  {$IFDEF POSIX}
  , diocp.core.rawPosixSocket
  {$ELSE}
  , diocp.core.rawWinSocket
  {$ENDIF}

  ,Classes
  , SysConst;

{$if CompilerVersion < 23}
type
     NativeUInt = Cardinal;
     IntPtr = Cardinal;
{$ifend}

// before delphi 2007
{$if CompilerVersion < 18}
type
     ULONG_PTR = Cardinal;
{$ifend}

type


  TDiocpBlockTcpClient = class(TComponent)
  private
    FActive: Boolean;
    FHost: String;
    FPort: Integer;
    FRawSocket: TRawSocket;
    FReadTimeOut: Integer;
    procedure SetActive(const Value: Boolean);
    
    procedure CheckSocketResult(pvSocketResult:Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect;
    /// <summary>
    ///   ��ʱ����
    /// </summary>
    /// <param name="pvMs"> (Cardinal) </param>
    procedure ConnectTimeOut(pvMs:Cardinal);
    procedure Disconnect;

    /// <summary>
    ///  recv buffer
    /// </summary>
    procedure recv(buf: Pointer; len: cardinal);

    function Peek(buf: Pointer; len: Cardinal): Integer;
    function RecvBuffer(buf: Pointer; len: cardinal): Integer;
    function SendBuffer(buf: Pointer; len: cardinal): Integer;
    /// <summary>
    ///   ������������ֱ�����յ�һ��endBufΪֹ
    ///   ����յ������ݵ���len��С����ֱ�ӷ���
    /// </summary>
    /// <returns>
    ///   ���ؽ��յ������ݳ���
    /// </returns>
    /// <param name="buf"> ������ŵ���ʼ�ڴ��ַ </param>
    /// <param name="len"> �ڴ��С </param>
    /// <param name="endBuf"> �жϽ�������ʼ�ڴ��ַ </param>
    /// <param name="endBufLen"> �ڴ��С </param>
    function RecvBufferEnd(buf: Pointer; len: cardinal; endBuf: Pointer; endBufLen:
        Integer): Integer;
    property Active: Boolean read FActive write SetActive;
    property RawSocket: TRawSocket read FRawSocket;
  published
    property Host: String read FHost write FHost;
    property Port: Integer read FPort write FPort;
    /// <summary>
    ///   unit ms
    /// </summary>
    property ReadTimeOut: Integer read FReadTimeOut write FReadTimeOut;
  end;

implementation

constructor TDiocpBlockTcpClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRawSocket := TRawSocket.Create;
  FReadTimeOut := 30000;
end;

destructor TDiocpBlockTcpClient.Destroy;
begin
  FRawSocket.Free;
  inherited Destroy;
end;

{$IFDEF POSIX}
  // posix��֪���Ƿ��иú���
{$ELSE}
procedure RaiseLastOSErrorException(LastError: Integer);
var
  Error: EOSError;
begin
  if LastError <> 0 then
    Error := EOSError.CreateResFmt(@SOSError, [LastError,
      SysErrorMessage(LastError)])
  else
    Error := EOSError.CreateRes(@SUnkOSError);
  Error.ErrorCode := LastError;
  raise Error;
end;
{$ENDIF}

procedure TDiocpBlockTcpClient.CheckSocketResult(pvSocketResult: Integer);
var
  lvErrorCode:Integer;
begin
  ///  Posix, fail return 0
  ///  ms_windows, fail return -1
  {$IFDEF POSIX}
  if (pvSocketResult = -1) or (pvSocketResult = 0) then
  begin
     try
       RaiseLastOSError;
     except
       Disconnect;
       raise;
     end;
   end;
  {$ELSE}
  if (pvSocketResult = -1) then
  begin
    lvErrorCode := GetLastError;
    Disconnect;     // �����쳣��Ͽ�����
    RaiseLastOSErrorException(lvErrorCode);

  end;
  {$ENDIF}
end;

procedure TDiocpBlockTcpClient.Connect;
var
  lvIpAddr:String;
begin
  if FActive then exit;

  FRawSocket.createTcpSocket;
  FRawSocket.setReadTimeOut(FReadTimeOut);

  // ������������
  lvIpAddr := FRawSocket.GetIpAddrByName(FHost);

  FActive := FRawSocket.connect(lvIpAddr, FPort);
  if not FActive then
  begin
    RaiseLastOSError;
  end;
end;

procedure TDiocpBlockTcpClient.ConnectTimeOut(pvMs:Cardinal);
var
  lvIpAddr:String;
begin
  if FActive then exit;

  FRawSocket.createTcpSocket;
  FRawSocket.setReadTimeOut(FReadTimeOut);

  // ������������
  lvIpAddr := FRawSocket.GetIpAddrByName(FHost);

  FActive := FRawSocket.ConnectTimeOut(lvIpAddr, FPort, pvMs);
  if not FActive then
  begin
    raise Exception.CreateFmt(strConnectTimeOut, [FHost, FPort]);
  end;

end;

procedure TDiocpBlockTcpClient.Disconnect;
begin
  if not FActive then Exit;

  FRawSocket.close;

  FActive := false;
end;

function TDiocpBlockTcpClient.Peek(buf: Pointer; len: Cardinal): Integer;
begin
  Result := FRawSocket.PeekBuf(buf^, len);
end;

procedure TDiocpBlockTcpClient.recv(buf: Pointer; len: cardinal);
var
  lvTempL :Integer;
  lvReadL :Cardinal;
  lvPBuf:Pointer;
begin
  lvReadL := 0;
  lvPBuf := buf;
  while lvReadL < len do
  begin
    lvTempL := FRawSocket.RecvBuf(lvPBuf^, len - lvReadL);

    CheckSocketResult(lvTempL);

    lvPBuf := Pointer(IntPtr(lvPBuf) + Cardinal(lvTempL));
    lvReadL := lvReadL + Cardinal(lvTempL);
  end;
end;

function TDiocpBlockTcpClient.RecvBuffer(buf: Pointer; len: cardinal): Integer;
begin
  Result := FRawSocket.RecvBuf(buf^, len);
  CheckSocketResult(Result);
end;

function TDiocpBlockTcpClient.RecvBufferEnd(buf: Pointer; len: cardinal;
    endBuf: Pointer; endBufLen: Integer): Integer;
begin
  Result := FRawSocket.RecvBufEnd(buf, len, endBuf, endBufLen);
  CheckSocketResult(Result);
end;

function TDiocpBlockTcpClient.sendBuffer(buf: Pointer; len: cardinal): Integer;
begin
  Result := FRawSocket.SendBuf(buf^, len);

  CheckSocketResult(Result);
end;

procedure TDiocpBlockTcpClient.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
    begin
      Connect;
    end else
    begin
      Disconnect;
    end;
  end;
end;

end.
