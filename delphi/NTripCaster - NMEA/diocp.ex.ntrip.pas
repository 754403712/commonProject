(*
  *	 Unit owner: D10.Mofen, delphi iocp framework author
  *         homePage: http://www.Diocp.org
  *	       blog: http://www.cnblogs.com/dksoft

  *   2015-02-22 08:29:43
  *     DIOCP-V5 ����

  *    HttpЭ�鴦��Ԫ
  *    ���д󲿷�˼·������delphi iocp framework�е�iocp.HttpServer
  *

// ��֤
GET /1 HTTP/1.1
Host: 127.0.0.1
Ntrip-Version: Ntrip/2.0
User-Agent: NTRIP NtripClientPOSIX/1.49
Connection: close
Authorization: Basic dXNlcjpwYXNzd29yZA==


*)
unit diocp.ex.ntrip;

interface

/// �������뿪�أ�ֻ�ܿ���һ��
{$DEFINE INNER_IOCP}     // iocp�̴߳����¼�
{.$DEFINE  QDAC_QWorker} // ��qworker���е��ȴ����¼�
{.$DEFINE DIOCP_Task}    // ��diocp.task���е��ȴ����¼�


uses
  Classes, StrUtils, SysUtils, utils.buffer, utils.strings

  {$IFDEF QDAC_QWorker}, qworker{$ENDIF}
  {$IFDEF DIOCP_Task}, diocp.task{$ENDIF}
  , diocp.tcp.server, utils.queues, utils.hashs;



const
  HTTPLineBreak = #13#10;

type
  TDiocpNtripState = (hsCompleted, hsRecevingNEMA, hsRequest { �������� }, hsRecvingSource { ����NtripSource���� } );
  TDiocpNtripContextMode = (ncmNtripNone, ncmNtripSource, ncmNtripClient);
  TDiocpNtripResponse = class;
  TDiocpNtripClientContext = class;
  TDiocpNtripServer = class;
  TDiocpNtripRequest = class;

  TOnRequestAcceptEvent = procedure(pvRequest:TDiocpNtripRequest; var vIsNMEA:Boolean) of object;

  TDiocpNtripRequest = class(TObject)
  private
    /// <summary>
    ///   ������Closeʱ�黹�ض����
    /// </summary>
    FDiocpNtripServer:TDiocpNtripServer;

    FDiocpContext: TDiocpNtripClientContext;

    /// ͷ��Ϣ
    FHttpVersion: Word; // 10, 11

    FRequestVersionStr: String;

    FRequestMethod: String;

    FMountPoint: String;

    /// <summary>
    ///  ԭʼ�����е�URL��������(û�о���URLDecode����Ϊ��DecodeRequestHeader��Ҫƴ��RequestURLʱ��ʱ������URLDecode)
    ///  û�о���URLDecode�ǿ��ǵ�����ֵ�б������&�ַ�������DecodeURLParam���ֲ������쳣
    /// </summary>
    FRequestURLParamData: string;


    FRequestParamsList: TStringList; // TODO:���http������StringList

    FContextType: string;
    FContextLength: Int64;
    FKeepAlive: Boolean;
    FRequestAccept: String;
    FRequestAcceptLanguage: string;
    FRequestAcceptEncoding: string;
    FRequestUserAgent: string;
    FRequestAuth: string;
    FRequestCookies: string;
    FRequestHostName: string;
    FRequestHostPort: string;

    FXForwardedFor: string;

    FRawHeaderData: TMemoryStream;

    /// <summary>
    ///   ԭʼ��POST����
    /// </summary>
    FRawPostData: TMemoryStream;

    FPostDataLen: Integer;

    FRequestHeader: TStringList;

    FResponse: TDiocpNtripResponse;
    FSourceRequestPass: String;

    /// <summary>
    ///   ����ʹ���ˣ��黹�ض����
    /// </summary>
    procedure Close;
    /// <summary>
    /// �Ƿ���Ч��Http ���󷽷�
    /// </summary>
    /// <returns>
    /// 0: ���ݲ��㹻���н���
    /// 1: ��Ч������ͷ
    /// 2: ��Ч����������ͷ
    /// </returns>
    function DecodeRequestMethod: Integer;

    /// <summary>
    /// ����Http���������Ϣ
    /// </summary>
    /// <returns>
    /// 1: ��Ч��Http��������
    /// </returns>
    function DecodeRequestHeader: Integer;

    /// <summary>
    /// ���յ���Buffer,д������
    /// </summary>
    procedure WriteRawBuffer(const buffer: Pointer; len: Integer);
  protected
  public
    constructor Create;
    destructor Destroy; override;


    /// <summary>
    ///   ��Post��ԭʼ���ݽ��룬�ŵ������б���
    ///   ��OnDiocpNtripRequest�е���
    /// </summary>
    procedure DecodePostDataParam(
      {$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});

    function ExtractNMEAString():String;

    /// <summary>
    ///   ����
    /// </summary>
    procedure Clear;

    property ContextLength: Int64 read FContextLength;


    /// <summary>
    ///   ��ͻ��˽���������
    /// </summary>
    property Connection: TDiocpNtripClientContext read FDiocpContext;

    property HttpVersion: Word read FHttpVersion;
    /// <summary>
    ///   ԭʼ��Post����������
    /// </summary>
    property RawPostData: TMemoryStream read FRawPostData;
    property RequestAccept: String read FRequestAccept;
    property RequestAcceptEncoding: string read FRequestAcceptEncoding;
    property RequestAcceptLanguage: string read FRequestAcceptLanguage;
    property RequestCookies: string read FRequestCookies;

    /// <summary>
    ///   �����ͷ��Ϣ
    /// </summary>
    property RequestHeader: TStringList read FRequestHeader;

    /// <summary>
    ///   �ҽڵ�
    /// </summary>
    property MountPoint: String read FMountPoint;

    /// <summary>
    ///   Source���������е�Password
    /// </summary>
    property SourceRequestPass: String read FSourceRequestPass write  FSourceRequestPass;

    /// <summary>
    ///  ��ͷ��Ϣ�ж�ȡ���������������ʽ
    /// </summary>
    property RequestMethod: string read FRequestMethod;

    /// <summary>
    ///   ��ͷ��Ϣ�ж�ȡ�����������IP��ַ
    /// </summary>
    property RequestHostName: string read FRequestHostName;

    /// <summary>
    ///   ��ͷ��Ϣ�ж�ȡ������������˿�
    /// </summary>
    property RequestHostPort: string read FRequestHostPort;

    /// <summary>
    /// Http��Ӧ���󣬻�д����
    /// </summary>
    property Response: TDiocpNtripResponse read FResponse;

    /// <summary>
    ///   ��Url��Post�����еõ��Ĳ�����Ϣ: key = value
    /// </summary>
    property RequestParamsList: TStringList read FRequestParamsList;


    /// <summary>
    ///   ��ȡͷ��Ϣ�е��û�����������Ϣ
    /// </summary>
    /// <returns>
    ///   ��ȡ�ɹ�����true
    /// </returns>
    /// <param name="vUser"> (string) </param>
    /// <param name="vPass"> (string) </param>
    function ExtractBasicAuthenticationInfo(var vUser, vPass:string): Boolean;


    /// <summary>
    ///  �ر�����
    /// </summary>
    procedure CloseContext;

    /// <summary>
    /// �õ�http�������
    /// </summary>
    /// <params>
    /// <param name="ParamsKey">http���������key</param>
    /// </params>
    /// <returns>
    /// 1: http���������ֵ
    /// </returns>
    function GetRequestParam(ParamsKey: string): string;

    /// <summary>
    /// ����POST��GET����
    /// </summary>
    /// <pvParamText>
    /// <param name="pvParamText">Ҫ������ȫ������</param>
    /// </pvParamText>
    procedure ParseParams(pvParamText: string);


  end;

  TDiocpNtripResponse = class(TObject)
  private
    FResponseHeader: string;
    FData: TMemoryStream;
    FDiocpContext : TDiocpNtripClientContext;
  public
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
    procedure WriteBuf(pvBuf: Pointer; len: Cardinal);
    procedure WriteString(pvString: string; pvUtf8Convert: Boolean = true);

    /// <summary>
    ///  ����ICY200OK��Ϣ
    /// </summary>
    procedure ICY200OK();

    /// <summary>
    ///   NtripSource��֤ʱ�������Ļظ����ظ��󣬹ر�����
    /// </summary>
    procedure BadPassword();

    /// <summary>
    ///   ����SourceTableOK��Ϣ
    /// </summary>
    procedure SourceTableOK();

    /// <summary>
    ///   ����SourceTableOK��SourceTable����
    /// </summary>
    procedure SourceTableOKAndData(pvSourceTable:AnsiString);

    /// <summary>
    ///   NtripClient��֤ʧ��
    /// </summary>
    procedure Unauthorized();

    /// <summary>
    ///   ��Ч���û���֤��Ϣ
    /// </summary>
    /// <param name="pvMountpoint"> �ҽڵ� </param>
    procedure InvalidPasswordMsg(pvMountpoint: string);


    /// <summary>
    ///   ��ͻ��˽���������
    /// </summary>
    property Connection: TDiocpNtripClientContext read FDiocpContext;

  end;

  /// <summary>
  /// Http �ͻ�������
  /// </summary>
  TDiocpNtripClientContext = class(TIocpClientContext)
  private
    // NtripSource����Ϊת��ʹ��
    FNtripClients:TList;
    // ���ַ�����ʱ��ʱʹ��
    FTempNtripClients:TList;

    FContextMode: TDiocpNtripContextMode;
    FNtripState: TDiocpNtripState;
    FCurrentRequest: TDiocpNtripRequest;
    FMountPoint: String;
    FTag: Integer;
    FTagStr: String;
    {$IFDEF QDAC_QWorker}
    procedure OnExecuteJob(pvJob:PQJob);
    {$ENDIF}
    {$IFDEF DIOCP_Task}
    procedure OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
    {$ENDIF}

    // ִ���¼�
    procedure DoRequest(pvRequest:TDiocpNtripRequest);

    /// <summary>
    ///   ����NtripSource����֤����
    /// </summary>
    procedure DoNtripSourceAuthentication(pvRequest:TDiocpNtripRequest);
  protected

    /// <summary>
    ///   ���������Request����
    /// </summary>
    procedure OnRequest(pvRequest:TDiocpNtripRequest); virtual;

    procedure OnDisconnected; override;

  public
    constructor Create; override;
    destructor Destroy; override;
  protected
    /// <summary>
    /// �黹������أ�����������
    /// </summary>
    procedure DoCleanUp; override;

    /// <summary>
    /// ���յ��ͻ��˵�HttpЭ������, ���н����TDiocpNtripRequest����ӦHttp����
    /// </summary>
    procedure OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: Word); override;
  public
    /// <summary>
    ///   ��ӵ�NtripSource�ķַ��б�
    /// </summary>
    procedure AddNtripClient(pvContext:TDiocpNtripClientContext);

    /// <summary>
    ///   �Ƴ���NtripSource�ķַ��б�
    ///   �����ַ�����ʱ����ִ���Ƴ�����(��Ӧ��Context���������mountpoint�����ݣ����߶Ͽ�)
    /// </summary>
    procedure RemoveNtripClient(pvContext:TDiocpNtripClientContext);

    /// <summary>
    ///   �ַ�GNSSData
    /// </summary>
    procedure DispatchGNSSDATA(buf: Pointer; len: Cardinal);





    property ContextMode: TDiocpNtripContextMode read FContextMode write FContextMode;

    property MountPoint: String read FMountPoint write FMountPoint;



    property Tag: Integer read FTag write FTag;

    property TagStr: String read FTagStr write FTagStr;


  end;

{$IFDEF UNICODE}
  /// <summary>
  /// Request�¼�����
  /// </summary>
  TOnDiocpNtripRequestEvent = reference to procedure(pvRequest: TDiocpNtripRequest);

  /// <summary>
  /// ���յ�NtripSource����
  /// </summary>
  TDiocpRecvBufferEvent = reference to procedure(pvContext:TDiocpNtripClientContext; buf: Pointer; len: Cardinal);
{$ELSE}
  /// <summary>
  /// Request�¼�����
  /// </summary>
  TOnDiocpNtripRequestEvent = procedure(pvRequest: TDiocpNtripRequest) of object;

  /// <summary>
  /// ���յ�NtripSource����
  /// </summary>
  TDiocpRecvBufferEvent = procedure(pvContext:TDiocpNtripClientContext;buf: Pointer; len: Cardinal) of object;
{$ENDIF}

  /// <summary>
  /// Http ��������
  /// </summary>
  TDiocpNtripServer = class(TDiocpTcpServer)
  private
    FNtripSourcePassword: String;
    FRequestPool: TBaseQueue;

    /// <summary>
    ///  ���Source�б�
    /// </summary>
    FNtripSources: TDHashTableSafe;

    FOnDiocpNtripRequest: TOnDiocpNtripRequestEvent;
    FOnDiocpNtripRequestPostDone: TOnDiocpNtripRequestEvent;
    FOnDiocpRecvNtripSourceBuffer: TDiocpRecvBufferEvent;
    FOnRequestAcceptEvent: TOnRequestAcceptEvent;

    /// <summary>
    /// ��ӦHttp���� ִ����Ӧ�¼�
    /// </summary>
    procedure DoRequest(pvRequest: TDiocpNtripRequest);

    /// <summary>
    ///   ��ӦPost�����¼�
    /// </summary>
    procedure DoRequestPostDataDone(pvRequest: TDiocpNtripRequest);

    /// <summary>
    ///   �ӳ��л�ȡһ������
    /// </summary>
    function GetRequest: TDiocpNtripRequest;

    /// <summary>
    ///   ����һ������
    /// </summary>
    procedure GiveBackRequest(pvRequest:TDiocpNtripRequest);

  public
    constructor Create(AOwner: TComponent); override;

    destructor Destroy; override;



    /// <summary>
    ///   ����mountPoint����NtripSource
    /// </summary>
    function FindNtripSource(pvMountPoint:string):TDiocpNtripClientContext;

    /// <summary>
    ///   NtripSourcePassword, ����NtripSource����ʱ����֤
    /// </summary>
    property NtripSourcePassword: String read FNtripSourcePassword write FNtripSourcePassword;


    /// <summary>
    ///  �������
    /// </summary>
    property OnRequestAcceptEvent: TOnRequestAcceptEvent read FOnRequestAcceptEvent write FOnRequestAcceptEvent;

    /// <summary>
    ///   ���յ�NtripSource����
    /// </summary>
    property OnDiocpRecvNtripSourceBuffer: TDiocpRecvBufferEvent read
        FOnDiocpRecvNtripSourceBuffer write FOnDiocpRecvNtripSourceBuffer;

    /// <summary>
    ///   ��Http�����Post������ɺ󴥷����¼�
    ///   �����������һЩ����,����Post�Ĳ���
    /// </summary>
    property OnDiocpNtripRequestPostDone: TOnDiocpNtripRequestEvent read
        FOnDiocpNtripRequestPostDone write FOnDiocpNtripRequestPostDone;

    /// <summary>
    /// ��ӦHttp�����¼�
    /// </summary>
    property OnDiocpNtripRequest: TOnDiocpNtripRequestEvent read FOnDiocpNtripRequest
        write FOnDiocpNtripRequest;









  end;



implementation

uses
  utils.base64;

function FixHeader(const Header: string): string;
begin
  Result := Header;
  if (RightStr(Header, 4) <> #13#10#13#10) then
  begin
    if (RightStr(Header, 2) = #13#10) then
      Result := Result + #13#10
    else
      Result := Result + #13#10#13#10;
  end;
end;

function MakeHeader(const Status, pvRequestVersionStr: string; pvKeepAlive:
    Boolean; const ContType, Header: string; pvContextLength: Integer): string;
var
  lvVersionStr:string;
begin
  Result := '';

  lvVersionStr := pvRequestVersionStr;
  if lvVersionStr = '' then lvVersionStr := 'HTTP/1.0';

  if (Status = '') then
    Result := Result + lvVersionStr + ' 200 OK' + #13#10
  else
    Result := Result + lvVersionStr + ' ' + Status + #13#10;

  if (ContType = '') then
    Result := Result + 'Content-Type: gnss/data' + #13#10    // Ĭ��GNNS����
  else
    Result := Result + 'Content-Type: ' + ContType + #13#10;

  if (pvContextLength > 0) then
    Result := Result + 'Content-Length: ' + IntToStr(pvContextLength) + #13#10;
  // Result := Result + 'Cache-Control: no-cache'#13#10;

  if pvKeepAlive then
    Result := Result + 'Connection: keep-alive'#13#10
  else
    Result := Result + 'Connection: close'#13#10;

  Result := Result + 'Server: DIOCP-V5/1.0'#13#10;

end;

procedure TDiocpNtripRequest.Clear;
begin
  FRawHeaderData.Clear;
  FRawPostData.Clear;
  FMountPoint := '';
  FSourceRequestPass := '';
  FRequestVersionStr := '';
  FRequestMethod := '';
  FRequestCookies := '';
  FRequestParamsList.Clear;
  FContextLength := 0;
  FPostDataLen := 0;
  FResponse.Clear;  
end;

procedure TDiocpNtripRequest.Close;
begin
  if FDiocpNtripServer = nil then exit;
  FDiocpNtripServer.GiveBackRequest(Self);
end;

procedure TDiocpNtripRequest.CloseContext;
begin
  FDiocpContext.PostWSACloseRequest();
end;

function TDiocpNtripRequest.GetRequestParam(ParamsKey: string): string;
var
  lvTemp: string; // ���صĲ���ֵ
  lvParamsCount: Integer; // ��������
  I: Integer;
begin
  Result := '';

  lvTemp := ''; // ���صĲ���ֵĬ��ֵΪ��

  // �õ��ύ�����Ĳ���������
  lvParamsCount := self.FRequestParamsList.Count;

  // �ж��Ƿ����ύ�����Ĳ�������
  if lvParamsCount = 0 then exit;

  // ѭ���Ƚ�ÿһ�������key���Ƿ�͵�ǰ����һ��
  for I := 0 to lvParamsCount - 1 do
  begin 
    if Trim(self.FRequestParamsList.Names[I]) = Trim(ParamsKey) then
    begin
      lvTemp := Trim(self.FRequestParamsList.ValueFromIndex[I]);
      Break;
    end;
  end; 

  Result := lvTemp;
end;

constructor TDiocpNtripRequest.Create;
begin
  inherited Create;
  FRawHeaderData := TMemoryStream.Create();
  FRawPostData := TMemoryStream.Create();
  FRequestHeader := TStringList.Create();
  FResponse := TDiocpNtripResponse.Create();

  FRequestParamsList := TStringList.Create; // TODO:�������http������StringList
end;

destructor TDiocpNtripRequest.Destroy;
begin
  FreeAndNil(FResponse);
  FRawPostData.Free;
  FRawHeaderData.Free;
  FRequestHeader.Free;

  FreeAndNil(FRequestParamsList); // TODO:�ͷŴ��http������StringList

  inherited Destroy;
end;

function TDiocpNtripRequest.DecodeRequestMethod: Integer;
var
  lvBuf: PAnsiChar;
begin
  Result := 0;
  if FRawHeaderData.Size <= 7 then
    Exit;

  lvBuf := FRawHeaderData.Memory;

  if FRequestMethod <> '' then
  begin
    Result := 1; // �Ѿ�����
    Exit;
  end;

  // ���󷽷������з���ȫΪ��д���ж��֣����������Ľ������£�
  // GET     �����ȡRequest-URI����ʶ����Դ

  Result := 1;
  if (StrLIComp(lvBuf, 'GET', 3) = 0) then
  begin
    FRequestMethod := 'GET';
  end else if (StrLIComp(lvBuf, 'SOURCE', 6) = 0) then
  begin   // NtripSERVER
    FRequestMethod := 'SOURCE';
  end else
  begin
    Result := 2;
  end;
end;

function TDiocpNtripRequest.DecodeRequestHeader: Integer;
var
  lvRawString: AnsiString;
  lvMethod, lvRawTemp: AnsiString;
  lvRequestCmdLine, lvTempStr, lvRemainStr: String;
  I, J: Integer;
  p : PChar;
begin
  Result := 1;
  SetLength(lvRawString, FRawHeaderData.Size);
  FRawHeaderData.Position := 0;
  FRawHeaderData.Read(lvRawString[1], FRawHeaderData.Size);
  FRequestHeader.Text := lvRawString;

  // GET /test?v=abc HTTP/1.1
  // SOURCE letmein /Mountpoint
  lvRequestCmdLine := FRequestHeader[0];
  P := PChar(lvRequestCmdLine);
  FRequestHeader.Delete(0);

  // Method
  lvTempStr := LeftUntil(P, [' ']);
  if lvTempStr = '' then Exit;
  lvTempStr := UpperCase(lvTempStr);

  // �����ո�
  SkipChars(P, [' ']);
  if lvTempStr = 'GET' then
  begin
    FMountPoint := LeftUntil(P, [' ']);

    if FMountPoint <> '' then
    begin
      FMountPoint := StrPas(PChar(@FMountPoint[2]));
    end;


    // �����ո�
    SkipChars(P, [' ']);

    // �����HTTP�汾
    lvTempStr := P;
    FRequestVersionStr := UpperCase(lvTempStr);
  end else
  begin    // SOURCE
    Inc(P);
    if P^=' ' then
    begin
      FSourceRequestPass := '';
    end else
    begin
      FSourceRequestPass := LeftUntil(P, [' ']);
    end;
    // �����ո�
    SkipChars(P, [' ']);
    FMountPoint := P;

  end;
end;

procedure TDiocpNtripRequest.DecodePostDataParam({$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});
var
  lvRawData : AnsiString;
  lvRawParams, s:String;
  i:Integer;
  lvStrings:TStrings;
{$IFDEF UNICODE}
var
  lvBytes:TBytes;
{$ELSE}
{$ENDIF}
begin
  // ��ȡԭʼ����
  SetLength(lvRawData, FRawPostData.Size);
  FRawPostData.Position := 0;
  FRawPostData.Read(lvRawData[1], FRawPostData.Size);

  lvStrings := TStringList.Create;
  try
    // �ȷ��뵽Strings
    SplitStrings(lvRawData, lvStrings, ['&']);

    for i := 0 to lvStrings.Count - 1 do
    begin
      lvRawData := URLDecode(lvStrings.ValueFromIndex[i]);
      if lvRawData <> '' then   // ���Ϸ���Key-Value�ᵼ�¿��ַ���
      begin
        {$IFDEF UNICODE}
        if pvEncoding <> nil then
        begin
          // �ַ�����ת��
          SetLength(lvBytes, length(lvRawData));
          Move(PByte(lvRawData)^, lvBytes[0], Length(lvRawData));
          s := pvEncoding.GetString(lvBytes);
        end else
        begin
          s := lvRawData;
        end;
        {$ELSE}
        if pvUseUtf8Decode then
        begin
          s := UTF8Decode(lvRawData);
        end else
        begin
          s := lvRawData;
        end;
        {$ENDIF}

        // �������
        lvStrings.ValueFromIndex[i] := s;
      end;
    end;
    FRequestParamsList.AddStrings(lvStrings);
  finally
    lvStrings.Free;
  end;
end;

function TDiocpNtripRequest.ExtractBasicAuthenticationInfo(var vUser,
    vPass:string): Boolean;
var
  lvAuth, lvValue:string;
  p:PChar;
begin
  Result := False;
  // Authorization: Basic aHVnb2JlbjpodWdvYmVuMTIz
  lvAuth := Trim(StringsValueOfName(FRequestHeader, 'Authorization', [':'], true));
  if lvAuth <> '' then
  begin  // ��֤��Ϣ
    p := PChar(lvAuth);    //Basic aHVnb2JlbjpodWdvYmVuMTIz

    // ����Basic
    SkipUntil(P, [' ']);
    SkipChars(P, [' ']);


    // Base64
    lvValue := P;
    lvValue := Base64ToStr(lvValue);

    /// userid:pasword
    P := PChar(lvValue);

    // ȡ�û�ID
    vUser := LeftUntil(P, [':']);
    SkipChars(P, [':']);
    // ȡ����
    vPass := P;

    Result := true;
  end;

end;


function TDiocpNtripRequest.ExtractNMEAString: String;
var
  lvRawString:AnsiString;
begin
  SetLength(lvRawString, self.FRawPostData.Size);
  FRawPostData.Position := 0;
  FRawPostData.Read(lvRawString[1], FRawPostData.Size);
  Result := lvRawString;
end;

/// <summary>
///  ����POST��GET����
/// </summary>
/// <pvParamText>
/// <param name="pvParamText">Ҫ������ȫ������</param>
/// </pvParamText>
procedure TDiocpNtripRequest.ParseParams(pvParamText: string);
begin
  SplitStrings(pvParamText, FRequestParamsList, ['&']);
end;

procedure TDiocpNtripRequest.WriteRawBuffer(const buffer: Pointer; len: Integer);
begin
  FRawHeaderData.WriteBuffer(buffer^, len);
end;

procedure TDiocpNtripResponse.BadPassword;
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'ERROR - Bad Password' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);

end;

procedure TDiocpNtripResponse.Clear;
begin
  FData.Clear;
  FResponseHeader := '';
end;

constructor TDiocpNtripResponse.Create;
begin
  inherited Create;
  FData := TMemoryStream.Create();
end;

destructor TDiocpNtripResponse.Destroy;
begin
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TDiocpNtripResponse.ICY200OK;
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'ICY 200 OK' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.InvalidPasswordMsg(pvMountpoint: string);
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'Server: NtripCaster/1.0' + sLineBreak
          + 'WWW-Authenticate: Basic realm="/' +pvMountpoint + '"' + sLineBreak
          + 'Content-Type: text/html' + sLineBreak
          + 'Connection: close' + sLineBreak
          + '<html><head><title>401 Unauthorized</title></head><body bgcolor=black text=white link=blue alink=red>' + sLineBreak
          + '<h1><center>The server does not recognize your privileges to the requested entity stream</center></h1>' + sLineBreak
          + '</body></html>' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.SourceTableOKAndData(pvSourceTable:AnsiString);
var
  lvData:AnsiString;
  len: Integer;
begin
//SOURCETABLE 200 OK
//Content-Type: text/plain
//Content-Length: n
//CAS;129.217.182.51;80;EUREF;BKG;0;DEU;51.5;7.5;http://igs.ifag.de/index_ntrip_cast.htm
//CAS;62.159.109.248;8080;Trimble GPSNet;Trimble Terrasat;1;DEU;48.03;11.72;http://www.virtualrtk.com
//NET;EUREF;EUREF;B;N;http://www.epncb.oma.be/euref_IP;http://www.epncb.oma.be/euref_IP;http
//ENDSOURCETABLE

  lvData := 'SOURCETABLE 200 OK' + sLineBreak +
            'Content-Type: text/plain' + sLineBreak +
            'Content-Length: ' + IntToStr(length(pvSourceTable)) + sLineBreak + sLineBreak +
            pvSourceTable + sLineBreak +
           'ENDSOURCETABLE' + sLineBreak + sLineBreak;


  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.SourceTableOK;
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'SOURCETABLE 200 OK' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.Unauthorized;
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'HTTP/1.0 401 Unauthorized' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.WriteBuf(pvBuf: Pointer; len: Cardinal);
begin
  FData.Write(pvBuf^, len);
end;

procedure TDiocpNtripResponse.WriteString(pvString: string; pvUtf8Convert:
    Boolean = true);
var
  lvRawString: AnsiString;
begin
  if pvUtf8Convert then
  begin     // ����Utf8ת��
    lvRawString := UTF8Encode(pvString);
  end else
  begin
    lvRawString := AnsiString(pvString);
  end;
  FData.WriteBuffer(PAnsiChar(lvRawString)^, Length(lvRawString));
end;

procedure TDiocpNtripClientContext.AddNtripClient(
  pvContext: TDiocpNtripClientContext);
begin
  // ��ǰ�Ƿ�NtripSource
  if FContextMode <> ncmNtripSource then Exit;

  self.Lock;
  try
    FNtripClients.Add(pvContext);
  finally
    self.UnLock;
  end;
end;

constructor TDiocpNtripClientContext.Create;
begin
  inherited Create;
  FNtripClients := TList.Create;
  FTempNtripClients := TList.Create;
end;

destructor TDiocpNtripClientContext.Destroy;
begin
  FNtripClients.Free;
  FTempNtripClients.Free;
  inherited Destroy;
end;

procedure TDiocpNtripClientContext.DispatchGNSSDATA(buf: Pointer;
  len: Cardinal);
var
  i:Integer;
  lvContext:TDiocpNtripClientContext;
begin
  FTempNtripClients.Clear;
  // copy����ʱ�б���
  Self.Lock;
  FTempNtripClients.Assign(FNtripClients);
  Self.UnLock;

  for i := 0 to FTempNtripClients.Count -1 do
  begin
    lvContext :=TDiocpNtripClientContext(FTempNtripClients[i]);
    if lvContext.LockContext('�ַ�GNSS����', Self) then
    begin
      try
        if lvContext.FMountPoint <> self.FMountPoint then  // ��������Ĺҽڵ�
        begin
          RemoveNtripClient(lvContext);
        end else
        begin
          // �ַ�����
          lvContext.PostWSASendRequest(buf, len);
        end;
      finally
        lvContext.UnLockContext('�ַ�GNSS����', Self);
      end;
    end else
    begin
      RemoveNtripClient(lvContext);
    end;
  end;
end;

procedure TDiocpNtripClientContext.DoCleanUp;
begin
  inherited;
  FTag := 0;
  FTagStr := '';
  FNtripState := hsCompleted;
  FContextMode := ncmNtripNone;
  FMountPoint := '';
  // ����б�
  FNtripClients.Clear;
  if FCurrentRequest <> nil then
  begin
    FCurrentRequest.Close;
    FCurrentRequest := nil;
  end;
end;

procedure TDiocpNtripClientContext.DoNtripSourceAuthentication(
    pvRequest:TDiocpNtripRequest);
begin
  // ����������֤
  if pvRequest.SourceRequestPass <> TDiocpNtripServer(FOwner).FNtripSourcePassword then
  begin
    pvRequest.Response.BadPassword;
    pvRequest.CloseContext;
    Exit;
  end else
  begin
    Self.FContextMode := ncmNtripSource;

    // �ı�װ������������ģʽ
    FNtripState := hsRecvingSource;

    // ��ӵ�NtripSource��Ӧ����
    TDiocpNtripServer(FOwner).FNtripSources.Lock;
    TDiocpNtripServer(FOwner).FNtripSources.ValueMap[FMountPoint] := Self;
    TDiocpNtripServer(FOwner).FNtripSources.unLock;

    // ��Ӧ����
    pvRequest.Response.ICY200OK;

  end;
end;

procedure TDiocpNtripClientContext.DoRequest(pvRequest: TDiocpNtripRequest);
begin
   {$IFDEF QDAC_QWorker}
   Workers.Post(OnExecuteJob, pvRequest);
   {$ELSE}
     {$IFDEF DIOCP_TASK}
     iocpTaskManager.PostATask(OnExecuteJob, pvRequest);
     {$ELSE}
     try
       // ֱ�Ӵ����¼�
       OnRequest(pvRequest);
       TDiocpNtripServer(FOwner).DoRequest(pvRequest);
     finally
       pvRequest.close();
     end;
     {$ENDIF}
   {$ENDIF}
end;

{$IFDEF QDAC_QWorker}
procedure TDiocpNtripClientContext.OnExecuteJob(pvJob:PQJob);
var
  lvObj:TDiocpNtripRequest;
begin
  lvObj := TDiocpNtripRequest(pvJob.Data);
  try
    // �����¼�
    OnRequest(lvObj);
    TDiocpNtripServer(FOwner).DoRequest(lvObj);
  finally
    lvObj.close();
  end;
end;

{$ENDIF}

{$IFDEF DIOCP_Task}
procedure TDiocpNtripClientContext.OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
var
  lvObj:TDiocpNtripRequest;
begin
  lvObj := TDiocpNtripRequest(pvTaskRequest.TaskData);
  try
    // �����¼�
    OnRequest(lvObj);
    TDiocpNtripServer(FOwner).DoRequest(lvObj);
  finally
    lvObj.close();
  end;
end;
{$ENDIF}



procedure TDiocpNtripClientContext.OnDisconnected;
begin
  if ContextMode = ncmNtripSource then
  begin
    // �Ƴ�
    TDiocpNtripServer(FOwner).FNtripSources.Lock;
    TDiocpNtripServer(FOwner).FNtripSources.ValueMap[FMountPoint] := nil;
    TDiocpNtripServer(FOwner).FNtripSources.unLock;
  end;

  inherited;
end;

procedure TDiocpNtripClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal;
  ErrCode: Word);
var
  lvTmpBuf: PAnsiChar;
  CR, LF: Integer;
  lvRemain: Cardinal;
  lvTempRequest: TDiocpNtripRequest;
  lvIsNMEA:Boolean;
begin
  if self.FNtripState = hsRecvingSource then
  begin   // ֱ�ӽ���NtripSource����
    if Assigned(TDiocpNtripServer(FOwner).FOnDiocpRecvNtripSourceBuffer) then
    begin
      TDiocpNtripServer(FOwner).FOnDiocpRecvNtripSourceBuffer(Self, buf, len);
    end;
  end else
  begin
    lvTmpBuf := buf;
    CR := 0;
    LF := 0;
    lvRemain := len;
    while (lvRemain > 0) do
    begin
      if FNtripState = hsCompleted then
      begin // ��ɺ����ã����´�����һ����
        FCurrentRequest := TDiocpNtripServer(Owner).GetRequest;
        FCurrentRequest.FDiocpContext := self;
        FCurrentRequest.Response.FDiocpContext := self;
        FCurrentRequest.Clear;
        FNtripState := hsRequest;
      end;

      if (FNtripState = hsRequest) then
      begin
        case lvTmpBuf^ of
          #13:
            Inc(CR);
          #10:
            Inc(LF);
        else
          CR := 0;
          LF := 0;
        end;

        // д����������
        FCurrentRequest.WriteRawBuffer(lvTmpBuf, 1);

        if FCurrentRequest.DecodeRequestMethod = 2 then
        begin // ��Ч��Http����
          // ���ض����
          self.RequestDisconnect('��Ч��Http����', self);
          Exit;
        end;

        // ���������ѽ������(#13#10#13#10��HTTP��������ı�־)
        if (CR = 2) and (LF = 2) then
        begin
          if FCurrentRequest.DecodeRequestHeader = 0 then
          begin
            self.RequestDisconnect('��Ч��HttpЭ������', self);
            Exit;
          end;

          // ����Context�Ĺһ���
          Self.FMountPoint := FCurrentRequest.FMountPoint;

          if SameText(FCurrentRequest.FRequestMethod, 'SOURCE') then
          begin    // NtripSource������֤

            lvTempRequest := FCurrentRequest;

            // ����Ͽ��󻹻ض���أ�����ظ�����
            FCurrentRequest := nil;

            DoNtripSourceAuthentication(lvTempRequest);

          end else
          begin
            // client����ģʽ
            FContextMode := ncmNtripClient;

            lvIsNMEA := false;
            if Assigned(TDiocpNtripServer(FOwner).OnRequestAcceptEvent) then
            begin
              TDiocpNtripServer(FOwner).OnRequestAcceptEvent(FCurrentRequest, lvIsNMEA);
            end;

            if lvIsNMEA then
            begin  // ����NMEA����
              FNtripState := hsRecevingNEMA;
              FCurrentRequest.RawPostData.Clear();
            end else
            begin
              FNtripState := hsCompleted;

              lvTempRequest := FCurrentRequest;

              // ����Ͽ��󻹻ض���أ�����ظ�����
              FCurrentRequest := nil;

              // �����¼�
              DoRequest(lvTempRequest);

              FCurrentRequest := nil;
              Break;
            end;
          end;
        end; //
      end else if FNtripState = hsRecevingNEMA then
      begin
        case lvTmpBuf^ of
          #13:
            Inc(CR);
          #10:
            Inc(LF);
        else
          CR := 0;
          LF := 0;
        end;

        // д����������
        FCurrentRequest.RawPostData.Write(lvTmpBuf^, 1);
        if (CR = 1) and (LF = 1) then
        begin
          FNtripState := hsCompleted;

          lvTempRequest := FCurrentRequest;

          // ����Ͽ��󻹻ض���أ�����ظ�����
          FCurrentRequest := nil;

          // �����¼�
          DoRequest(lvTempRequest);

          FCurrentRequest := nil;
          Break;
        end;
      end;
      Dec(lvRemain);
      Inc(lvTmpBuf);
    end;
  end;
end;

procedure TDiocpNtripClientContext.OnRequest(pvRequest:TDiocpNtripRequest);
begin

end;

procedure TDiocpNtripClientContext.RemoveNtripClient(
  pvContext: TDiocpNtripClientContext);
begin
  self.Lock;
  try
    FNtripClients.Remove(pvContext);
  finally
    self.UnLock;
  end;
end;

{ TDiocpNtripServer }

constructor TDiocpNtripServer.Create(AOwner: TComponent);
begin
  inherited;
  FRequestPool := TBaseQueue.Create;
  FNtripSources := TDHashTableSafe.Create();

  KeepAlive := false;
  RegisterContextClass(TDiocpNtripClientContext);
end;

destructor TDiocpNtripServer.Destroy;
begin
  FRequestPool.FreeDataObject;
  FNtripSources.Free;
  inherited;
end;

procedure TDiocpNtripServer.DoRequest(pvRequest: TDiocpNtripRequest);
begin
  if Assigned(FOnDiocpNtripRequest) then
  begin
    FOnDiocpNtripRequest(pvRequest);
  end;
end;

procedure TDiocpNtripServer.DoRequestPostDataDone(pvRequest: TDiocpNtripRequest);
var
  lvRawData:AnsiString;
begin 
  if Assigned(FOnDiocpNtripRequestPostDone) then
  begin
    FOnDiocpNtripRequestPostDone(pvRequest);
  end;
end;

function TDiocpNtripServer.FindNtripSource(
  pvMountPoint: string): TDiocpNtripClientContext;
begin
  FNtripSources.Lock;
  Result := TDiocpNtripClientContext(FNtripSources.ValueMap[pvMountPoint]);
  FNtripSources.unLock();
end;

function TDiocpNtripServer.GetRequest: TDiocpNtripRequest;
begin
  Result := TDiocpNtripRequest(FRequestPool.DeQueue);
  if Result = nil then
  begin
    Result := TDiocpNtripRequest.Create;
  end;
  Result.FDiocpNtripServer := Self;
end;

procedure TDiocpNtripServer.GiveBackRequest(pvRequest: TDiocpNtripRequest);
begin
  FRequestPool.EnQueue(pvRequest);
end;

end.
