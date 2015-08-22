unit diocp.p2p;

interface

uses
  diocp.udp, SysUtils, utils.strings, Windows, utils.hashs;


type
  TSessionInfo = class(TObject)
  private
    FIP: string;
    FLastActivity: Integer;
    FPort: Integer;
    FSessionID: Integer;
  public
    function CheckActivity(pvTickcount: Cardinal; pvTimeOut: Integer): Boolean;
    property IP: string read FIP write FIP;
    property LastActivity: Integer read FLastActivity write FLastActivity;
    property Port: Integer read FPort write FPort;
    // ����ʱ���ɵ�һ��ID,���߿ͻ��˹̶���һ��ID
    property SessionID: Integer read FSessionID write FSessionID;

     
  end;
  
  TDiocpP2PManager = class(TObject)
  private
    FDiocpUdp: TDiocpUdp;
    FSessions: TDHashTableSafe;
    FSessionID: Integer;
    FKickTimeOut:Integer;
    procedure OnRecv(pvReqeust:TDiocpUdpRecvRequest);
    procedure Process2CMD(pvReqeust: TDiocpUdpRecvRequest; var lvCMDPtr: PAnsiChar);
  public
    constructor Create;
    destructor Destroy; override;
    property DiocpUdp: TDiocpUdp read FDiocpUdp;
    property KickTimeOut: Integer read FKickTimeOut write FKickTimeOut;
  end;

implementation

uses
  utils.safeLogger;

/// <summary>
///   ��������TickCountʱ�����ⳬ��49������
///      ��л [��ɽ]�׺�һЦ  7041779 �ṩ
///      copy�� qsl���� 
/// </summary>
function tick_diff(tick_start, tick_end: Cardinal): Cardinal;
begin
  if tick_end >= tick_start then
    result := tick_end - tick_start
  else
    result := High(Cardinal) - tick_start + tick_end;
end;


constructor TDiocpP2PManager.Create;
begin
  inherited Create;
  FDiocpUdp := TDiocpUdp.Create(nil);
  FDiocpUdp.OnRecv := OnRecv;
  FSessions := TDHashTableSafe.Create();
  FSessionID := 1000;    // Session��ʼֵ
  FKickTimeOut := 30000; // 30��
end;

destructor TDiocpP2PManager.Destroy;
begin
  FDiocpUdp.Stop();
  FreeAndNil(FDiocpUdp);
  FSessions.FreeAllDataAsObject;
  FSessions.Free;
  inherited Destroy;
end;

procedure TDiocpP2PManager.OnRecv(pvReqeust:TDiocpUdpRecvRequest);
var
  lvCMD, lvTempStr:AnsiString;
  lvCMDPtr:PAnsiChar;
  lvSessionID:Integer;
  lvSession:TSessionInfo;
begin
   // 0                      : ���󼤻����0, id
   // 1,id                   : ������
   // 2,request_id, dest_id  : �����, ���� 2, id, ip, port(�Է�����), 2, -1 (�Է�������)
   // 3,id                   : �����Ͽ�
   SetLength(lvCMD, pvReqeust.RecvBufferLen);
   Move(pvReqeust.RecvBuffer^, PAnsiChar(lvCMD)^, pvReqeust.RecvBufferLen);

   lvCMDPtr := PAnsiChar(lvCMD);
   SkipChars(lvCMDPtr, [' ']);
   if lvCMDPtr^ = '0' then
   begin
     lvSessionID := InterlockedIncrement(FSessionID);
     FSessions.Lock;
     lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
     if lvSession = nil then
     begin
       lvSession := TSessionInfo.Create;
       lvSession.SessionID := lvSessionID;
       FSessions.Values[lvSessionID] := lvSession;
     end;
     lvSession.FIP   := pvReqeust.RemoteAddr;
     lvSession.FPort := pvReqeust.RemotePort;
     lvSession.FLastActivity := GetTickCount;
     FSessions.unLock;

     lvCMD := '0, ' + IntToStr(lvSessionID);
     pvReqeust.SendResponse(PAnsiChar(lvCMD), Length(lvCMD));
     sfLogger.logMessage('[%s:%d]���󼤻�, ID:%d', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID]);
   end else if lvCMDPtr^ = '1' then
   begin     //1,id                   : ������
     SkipUntil(lvCMDPtr, [' ', ',']);

     // ���������֮��ķָ���
     SkipChars(lvCMDPtr, [' ', ',']);
     lvTempStr := LeftUntil(lvCMDPtr, [',', ' ']);
     if Length(lvTempStr) = 0 then lvTempStr := lvCMDPtr;  //���û��',' ȥʣ�����е�          
     lvSessionID := StrToIntDef(lvTempStr, 0);
     if lvSessionID = 0 then Exit;  // ����ID��Ч


     FSessions.Lock;
     lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
     if lvSession <> nil then
     begin
       if lvSession.FIP <> pvReqeust.RemoteAddr then
       begin
         sfLogger.logMessage('[%s:%d]��������ID(%d)ԭ�е�ַ:[%s,%d]', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID, lvSession.IP, lvSession.Port]);
       end;
     end else
     begin
       // ֱ�Ӽ���
       lvSession := TSessionInfo.Create;
       lvSession.SessionID := lvSessionID;
       FSessions.Values[lvSessionID] := lvSession;
       sfLogger.logMessage('[%s:%d]��������, ID:%d', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID]);
     end;
     lvSession.FLastActivity := GetTickCount;
     lvSession.FIP   := pvReqeust.RemoteAddr;
     lvSession.FPort := pvReqeust.RemotePort;
     FSessions.unLock;
   end else if lvCMDPtr^ = '2' then
   begin  // 2,request_id, dest_id  : �����, ���� 2, id, ip, port(�Է�����), 2, -1 (�Է�������)
     Process2CMD(pvReqeust, lvCMDPtr);
   end else if lvCMDPtr^ = '3' then
   begin         // 3,id,                   : �����Ͽ�
     // ���������
     SkipUntil(lvCMDPtr, [' ', ',']);

     // ���������֮��ķָ���
     SkipChars(lvCMDPtr, [' ', ',']);
     lvTempStr := LeftUntil(lvCMDPtr, [',', ' ']);
     if Length(lvTempStr) = 0 then lvTempStr := lvCMDPtr;  //���û��',' ȥʣ�����е�          
     lvSessionID := StrToIntDef(lvTempStr, 0);
     if lvSessionID = 0 then Exit;  // ����ID��Ч
     
     FSessions.Lock;
     lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
     if lvSession <> nil then
     begin
       if lvSession.FIP <> pvReqeust.RemoteAddr then
       begin
         sfLogger.logMessage('[%s:%d]�Ƿ�������������[%d]����:[%s,%d]', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID, lvSession.IP, lvSession.Port]);
       end else
       begin
         sfLogger.logMessage('[%s:%d-%d]�������', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID]);
         
         // �ͷ�Session, ���Ըĳɶ����
         lvSession.Free;

         // Session�б����Ƴ�
         FSessions.DeleteFirst(lvSessionID);
       end;
     end;
     FSessions.unLock;
   end;

end;

procedure TDiocpP2PManager.Process2CMD(pvReqeust: TDiocpUdpRecvRequest; var
    lvCMDPtr: PAnsiChar);
var
  lvCMD, lvCMD2, lvTempStr, lvDestAddr:AnsiString;
  lvDestPort:Integer;

  lvSessionID, lvRequestID:Integer;
  lvSession:TSessionInfo;
  lvIsActive:Boolean;
begin
   // ���������
   SkipUntil(lvCMDPtr, [' ', ',']);

   // ���������֮��ķָ���
   SkipChars(lvCMDPtr, [' ', ',']);
   lvTempStr := LeftUntil(lvCMDPtr, [',', ' ']);
   lvRequestID := StrToIntDef(lvTempStr, 0);
   if lvRequestID = 0 then Exit;  // ����ID��Ч

   SkipChars(lvCMDPtr, [' ', ',']);
   lvTempStr := lvCMDPtr;
   lvSessionID := StrToIntDef(lvTempStr, 0);
   if lvSessionID = 0 then Exit;  // �Է�ID��Ч

   FSessions.Lock;
   lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
   if lvSession = nil then
   begin
      lvCMD := Format('2,%d,-1,', [lvSessionID]);
      lvIsActive := false;
   end else
   begin
     lvIsActive := lvSession.CheckActivity(GetTickCount, FKickTimeOut);
     if lvIsActive then
     begin
       lvDestAddr := lvSession.IP;
       lvDestPort := lvSession.Port;

       // ֪ͨ��ȥ���Խ��д�(�Է���ID,IP,Port)
       lvCMD := Format('2,%d,%s,%d', [lvSessionID, lvSession.FIP, lvSession.FPort]);

       // ֪ͨ�Է����д�(���󷽵�ID, IP, Port)
       lvCMD2 := Format('2,%d,%s,%d', [lvRequestID, pvReqeust.RemoteAddr, pvReqeust.RemotePort]);

       // ֪ͨ�Է����д�
       self.FDiocpUdp.WSASendTo(lvDestAddr, lvDestPort, PAnsiChar(lvCMD2), Length(lvCMD2));

       sfLogger.logMessage('[%s,%d:%d]�����->[%s,%d:%d]',
         [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvRequestID,
         lvSession.FIP, lvSession.FPort, lvSessionID]);
     end else
     begin       // �Է��Ѿ�ʧȥ��ϵ
       lvCMD := Format('2,%d,-1,', [lvSessionID]);

       sfLogger.logMessage('[%s:%d:%d]�����->[%s,%d:%d]', [
         pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvRequestID,
         lvSession.FIP, lvSession.FPort, lvSessionID]);

       // �ͷ�Session, ���Ըĳɶ����
       lvSession.Free;

       // Session�б����Ƴ�
       FSessions.DeleteFirst(lvSessionID);
     end;
   end;
   FSessions.unLock;

   // �ظ� (����Ϣ)
   pvReqeust.SendResponse(PAnsiChar(lvCMD), Length(lvCMD));
end;

function TSessionInfo.CheckActivity(pvTickcount: Cardinal; pvTimeOut: Integer): Boolean;
begin
  Result :=tick_diff(FLastActivity, GetTickCount) < pvTimeOut;
end;

end.
