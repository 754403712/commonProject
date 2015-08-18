(*
 *	 Unit owner: D10.Mofen
 *         homePage: http://www.diocp.org
 *	       blog: http://www.cnblogs.com/dksoft
 *
 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
  *   2015-04-08 12:34:33
  *    (��л suoler����bug���ṩbug����)
  *    �첽�����߼������OnContextAction
  *      �������Ѿ��رգ���������û�����ü�����Ȼ�������������Ѿ��黹���أ����ʱ��Ӧ�÷�����������()
 *)
unit diocp.coder.tcpServer;

interface

// call DoContextAction procedure with qworker
{.$DEFINE QDAC_QWorker}

{$IFDEF DEBUG}
  {$DEFINE DEBUG_ON}
{$ENDIF}

uses
  diocp.tcp.server, utils.buffer, SysUtils, Classes,
  diocp.coder.baseObject, utils.queues, utils.locker
  {$IFDEF QDAC_QWorker}
    , qworker
  {$ELSE}
    , diocp.task
  {$ENDIF}
  ;

type
  TDiocpCoderTcpServer = class;

  TDiocpCoderSendRequest = class(TIocpSendRequest)
  private
    FMemBlock:PMemoryBlock;
  protected
    procedure ResponseDone; override;
    procedure CancelRequest;override;
  end;

  /// <summary>
  ///   �����������, ���ڴ����첽����ʱ�����ԶԱ�����ʱ����Ϣ�����ڿ��Խ���ȡ������
  /// </summary>
  TDiocpTaskObject = class(TObject)
  private
    FOwner:TDiocpCoderTcpServer;
    /// <summary>
    ///   Ͷ���첽֮ǰ��¼DNA���������첽����ʱ���Ƿ�ȡ����ǰ����
    /// </summary>
    FContextDNA:Integer;
    // �������
    FData: TObject;
  public
    /// <summary>
    ///   �黹�������
    /// </summary>
    procedure Close;
  end;

  TIOCPCoderClientContext = class(diocp.tcp.server.TIOCPClientContext)
  private
    /// �Ƿ����ڴ�������
    FIsProcessRequesting:Boolean;
    
    /// ������������
    FRequestQueue:TSimpleQueue;
    
    /// ���ڷ��͵�BufferLink
    FCurrentSendBufferLink: TBufferLink;

    //  �����Ͷ���<TBufferLink����>
    FSendingQueue: TSimpleQueue;

    FRecvBuffers: TBufferLink;
    FStateINfo: String;
    function GetStateINfo: String;

    /// <summary>
    ///  ִ��һ������
    /// </summary>
    function DoExecuteRequest(pvTaskObj: TDiocpTaskObject): HRESULT;

    /// <summary>
    ///   ���������б��еĶ���
    /// </summary>
    procedure ClearRequestTaskObject();

   {$IFDEF QDAC_QWorker}
    procedure OnExecuteJob(pvJob:PQJob);
   {$ELSE}
    procedure OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
   {$ENDIF}
  protected
    procedure Add2Buffer(buf:PAnsiChar; len:Cardinal);
    procedure ClearRecvedBuffer;
    function DecodeObject: TObject;
    procedure OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: WORD); override;
    
    procedure RecvBuffer(buf:PAnsiChar; len:Cardinal); virtual;

    procedure DoCleanUp;override;
  protected
    /// <summary>
    ///   �ӷ��Ͷ�����ȡ��һ��Ҫ���͵Ķ�����з���
    /// </summary>
    procedure CheckStartPostSendBufferLink;

    /// <summary>
    ///   Ͷ����ɺ󣬼���Ͷ����һ������,
    ///     ֻ��HandleResponse�е���
    /// </summary>
    procedure PostNextSendRequest; override;
  public
    constructor Create;override;

    destructor Destroy; override;

    /// <summary>
    ///   ���յ�һ�����������ݰ�
    /// </summary>
    /// <param name="pvDataObject"> (TObject) </param>
    procedure DoContextAction(const pvDataObject:TObject); virtual;

    /// <summary>
    ///   ��д����(���Ͷ����ͻ���, ����ý��������н���)
    /// </summary>
    /// <param name="pvDataObject"> Ҫ��д�Ķ��� </param>
    procedure WriteObject(const pvDataObject:TObject);

    /// <summary>
    ///   received buffer
    /// </summary>
    property Buffers: TBufferLink read FRecvBuffers;

    /// <summary>
    ///   һЩ״̬��Ϣ
    /// </summary>
    property StateINfo: String read GetStateINfo write FStateINfo;
  end;



  TOnContextAction = procedure(pvClientContext:TIOCPCoderClientContext;
      pvObject:TObject) of object;

  {$IF RTLVersion>22}
  // thanks: �����ٷ�19183455
  //  vcl for win64
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  {$IFEND}
  TDiocpCoderTcpServer = class(TDiocpTcpServer)
  private
    ///�첽����Ͷ�ݶ����
    FTaskObjectPool: TBaseQueue;

    FInnerEncoder: TIOCPEncoder;
    FInnerDecoder: TIOCPDecoder;

    FEncoder: TIOCPEncoder;
    FDecoder: TIOCPDecoder;
    FLogicWorkerNeedCoInitialize: Boolean;
    FOnContextAction: TOnContextAction;

    function GetTaskObject:TDiocpTaskObject;
    procedure GiveBackTaskObject(pvObj:TDiocpTaskObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>
    ///   ע��������ͽ�������
    /// </summary>
    procedure RegisterCoderClass(pvDecoderClass:TIOCPDecoderClass;
        pvEncoderClass:TIOCPEncoderClass);

    /// <summary>
    ///   register Decoder instance
    /// </summary>
    /// <param name="pvDecoder"> (TIOCPDecoder) </param>
    procedure RegisterDecoder(pvDecoder:TIOCPDecoder);

    /// <summary>
    ///   register Encoder instance
    /// </summary>
    /// <param name="pvEncoder"> (TIOCPEncoder) </param>
    procedure RegisterEncoder(pvEncoder:TIOCPEncoder);

  published

    /// <summary>
    ///   �����߼��߳�ִ���߼�ǰִ��CoInitalize
    /// </summary>
    property LogicWorkerNeedCoInitialize: Boolean read FLogicWorkerNeedCoInitialize write FLogicWorkerNeedCoInitialize;

    /// <summary>
    ///   �յ�һ�����������ݰ���ִ���¼�(��IocpTask/Qworker�߳��д���)
    /// </summary>
    property OnContextAction: TOnContextAction read FOnContextAction write FOnContextAction;
  end;



implementation

uses
  utils.safeLogger;

constructor TIOCPCoderClientContext.Create;
begin
  inherited Create;
  FSendingQueue := TSimpleQueue.Create();
  FRequestQueue := TSimpleQueue.Create();
  FRecvBuffers := TBufferLink.Create();
end;

destructor TIOCPCoderClientContext.Destroy;
begin
  if IsDebugMode then
  begin
    Assert(FSendingQueue.size = 0);
  end;

  FSendingQueue.Free;
  FRecvBuffers.Free;

  // ����������������
  ClearRequestTaskObject();

  FRequestQueue.Free;
  inherited Destroy;
end;

procedure TIOCPCoderClientContext.DoCleanUp;
begin
  /// ����ǰ���Ͷ���
  if FCurrentSendBufferLink <> nil then
  begin
    FCurrentSendBufferLink.Free;
  end;

  // �����ͷŴ����Ͷ��е�BufferLinkʵ�� 
  FSendingQueue.FreeDataObject;

  // ����������������
  ClearRequestTaskObject;

  // ���ڴ���
  FIsProcessRequesting := False;                   

  // �����Ѿ����ջ�������
  FRecvBuffers.clearBuffer;
  inherited;
end;

procedure TIOCPCoderClientContext.Add2Buffer(buf:PAnsiChar; len:Cardinal);
begin
  //add to context receivedBuffer
  FRecvBuffers.AddBuffer(buf, len);
end;

procedure TIOCPCoderClientContext.CheckStartPostSendBufferLink;
var
  lvMemBlock:PMemoryBlock;
  lvValidCount, lvDataLen: Integer;
  lvSendRequest:TDiocpCoderSendRequest;
begin
  lock();
  try
    // �����ǰ����BufferΪnil ���˳�
    if FCurrentSendBufferLink = nil then Exit;

    // ��ȡ��һ��
    lvMemBlock := FCurrentSendBufferLink.FirstBlock;

    lvValidCount := FCurrentSendBufferLink.validCount;
    if (lvValidCount = 0) or (lvMemBlock = nil) then
    begin
      // �ͷŵ�ǰ�������ݶ���
      FCurrentSendBufferLink.Free;
            
      // �����ǰ�� û���κ�����, ���ȡ��һ��Ҫ���͵�BufferLink
      FCurrentSendBufferLink := TBufferLink(FSendingQueue.DeQueue);
      // �����ǰ����BufferΪnil ���˳�
      if FCurrentSendBufferLink = nil then Exit;

      // ��ȡ��Ҫ���͵�һ������
      lvMemBlock := FCurrentSendBufferLink.FirstBlock;
      
      lvValidCount := FCurrentSendBufferLink.validCount;
      if (lvValidCount = 0) or (lvMemBlock = nil) then
      begin  // û����Ҫ���͵�������
        FCurrentSendBufferLink := nil;  // û��������, �´�ѹ��ʱִ���ͷ�
        exit;      
      end; 
    end;
    if lvValidCount > Integer(lvMemBlock.DataLen) then
    begin
      lvDataLen := lvMemBlock.DataLen;
    end else
    begin
      lvDataLen := lvValidCount;
    end;


  finally
    unLock();
  end;

  if lvDataLen > 0 then
  begin
    // �ӵ�ǰBufferLink���Ƴ��ڴ��
    FCurrentSendBufferLink.RemoveBlock(lvMemBlock);

    lvSendRequest := TDiocpCoderSendRequest(GetSendRequest);
    lvSendRequest.FMemBlock := lvMemBlock;
    lvSendRequest.SetBuffer(lvMemBlock.Memory, lvDataLen, dtNone);
    if InnerPostSendRequestAndCheckStart(lvSendRequest) then
    begin
      // Ͷ�ݳɹ� �ڴ����ͷ���HandleResponse��
    end else
    begin
      lvSendRequest.UnBindingSendBuffer;
      lvSendRequest.FMemBlock := nil;
      lvSendRequest.CancelRequest;

      /// �ͷŵ��ڴ��
      FreeMemBlock(lvMemBlock);
      
      TDiocpCoderTcpServer(FOwner).ReleaseSendRequest(lvSendRequest);
    end;
  end;          
end;

procedure TIOCPCoderClientContext.ClearRecvedBuffer;
begin
  if FRecvBuffers.validCount = 0 then
  begin
    FRecvBuffers.clearBuffer;
  end else
  begin
    FRecvBuffers.clearHaveReadBuffer;
  end;
end;

procedure TIOCPCoderClientContext.ClearRequestTaskObject;
var
  lvTask:TDiocpTaskObject;
  lvObj:TObject;
begin
  self.Lock;
  try
    while True do
    begin
      lvTask := TDiocpTaskObject(FRequestQueue.DeQueue);
      if lvTask = nil then Break;

      lvObj := lvTask.FData;
      
      // �黹�������
      lvTask.Close;
      try
        // �ͷŽ������
        if lvObj <> nil then FreeAndNil(lvObj);
      except
      end; 
    end;
  finally
    self.UnLock;
  end;

  
end;

procedure TIOCPCoderClientContext.DoContextAction(const pvDataObject:TObject);
begin

end;

function TIOCPCoderClientContext.DoExecuteRequest(pvTaskObj: TDiocpTaskObject):
    HRESULT;
var
  lvObj:TObject;
begin
  Result := S_FALSE;
  lvObj := pvTaskObj.FData;
  // �����Ѿ��Ͽ�
  if Owner = nil then Exit;

  // �����Ѿ��ͷ�
  if Self = nil then Exit;

  // �Ѿ����ǵ���Ͷ�ݵ�����
  if self.ContextDNA <> pvTaskObj.FContextDNA then Exit;

  if self.LockContext('�����߼�', Self) then
  try
    try
      // ִ��Owner���¼�
      if Assigned(TDiocpCoderTcpServer(Owner).FOnContextAction) then
        TDiocpCoderTcpServer(Owner).FOnContextAction(Self, lvObj);
      DoContextAction(lvObj);
    except
     on E:Exception do
      begin
        FOwner.LogMessage('�ػ����߼��쳣:' + e.Message);
      end;
    end;
    Result := S_OK;
  finally
    self.UnLockContext('�����߼�', Self);
  end; 
end;

function TIOCPCoderClientContext.DecodeObject: TObject;
begin
  Result := TDiocpCoderTcpServer(Owner).FDecoder.Decode(FRecvBuffers, Self);
end;

function TIOCPCoderClientContext.GetStateINfo: String;
begin
  Result := FStateINfo;
end;



procedure TIOCPCoderClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal;
  ErrCode: WORD);
begin
  RecvBuffer(buf, len);
end;

procedure TIOCPCoderClientContext.PostNextSendRequest;
begin
  inherited PostNextSendRequest;
  CheckStartPostSendBufferLink;
end;

{$IFDEF QDAC_QWorker}
procedure TIOCPCoderClientContext.OnExecuteJob(pvJob: PQJob);
var
  lvTask:TDiocpTaskObject;
  lvObj:TObject;
begin
  while (Self.Active) do
  begin
    //ȡ��һ������
    self.Lock;
    try
      lvTask := TDiocpTaskObject(FRequestQueue.DeQueue);
      if lvTask = nil then
      begin
        FIsProcessRequesting := False;
        Break;
      end;
    finally
      self.UnLock;
    end;

    lvObj := lvTask.FData;
    try
      try
        // ִ������
        if DoExecuteRequest(lvTask) <> S_OK then
        begin
          Break;
        end;
      except
      end;
    finally
      // �黹�������
      lvTask.Close;
      try
        // �ͷŽ������
        if lvObj <> nil then FreeAndNil(lvObj);
      except
      end;
    end;
  end;


end;
{$ELSE}

procedure TIOCPCoderClientContext.OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
var
  lvTask:TDiocpTaskObject;
  lvObj:TObject;
begin

  while (Self.Active) do
  begin
    //ȡ��һ������
    self.Lock;
    try
      lvTask := TDiocpTaskObject(FRequestQueue.DeQueue);
      if lvTask = nil then
      begin
        FIsProcessRequesting := False;
        Break;
      end;
    finally
      self.UnLock;
    end;

    lvObj := lvTask.FData;
    try
      try
        // �����Ҫִ��
        if TDiocpCoderTcpServer(Owner).FLogicWorkerNeedCoInitialize then
          pvTaskRequest.iocpWorker.checkCoInitializeEx();

        // ִ������
        if DoExecuteRequest(lvTask) <> S_OK then
        begin
          Break;
        end;
      except          
      end;
    finally
      // �黹�������
      lvTask.Close;
      try
        // �ͷŽ������
        if lvObj <> nil then FreeAndNil(lvObj);
      except
      end;
    end;
  end;

//
//  lvTask := TDiocpTaskObject(pvTaskRequest.TaskData);
//  lvObj := lvTask.FData;
//  try
//    // �����Ѿ��Ͽ�
//    if Owner = nil then Exit;
//
//    // �����Ѿ��ͷ�
//    if Self = nil then Exit;
//
//    // �Ѿ����ǵ���Ͷ�ݵ�����
//    if self.ContextDNA <> lvTask.FContextDNA then Exit;
//
//    if self.LockContext('�����߼�', Self) then
//    try
//      try
//        if TDiocpCoderTcpServer(Owner).FLogicWorkerNeedCoInitialize then
//          pvTaskRequest.iocpWorker.checkCoInitializeEx();
//
//        // ִ��Owner���¼�
//        if Assigned(TDiocpCoderTcpServer(Owner).FOnContextAction) then
//          TDiocpCoderTcpServer(Owner).FOnContextAction(Self, lvObj);
//
//        DoContextAction(lvObj);
//      except
//       on E:Exception do
//        begin
//          FOwner.LogMessage('�ػ����߼��쳣:' + e.Message);
//        end;
//      end;
//    finally
//      self.UnLockContext('�����߼�', Self);
//    end;
//  finally
//    // �黹�������
//    lvTask.Close;
//    try
//      // �ͷŽ������
//      if lvObj <> nil then FreeAndNil(lvObj);
//    except
//    end;
//  end;
end;
{$ENDIF}

procedure TIOCPCoderClientContext.RecvBuffer(buf:PAnsiChar; len:Cardinal);
var
  lvTaskObject:TDiocpTaskObject;
  lvDecodeObj:TObject;
begin
  Add2Buffer(buf, len);

  self.StateINfo := '���յ�����,׼�����н���';

  ////����һ���յ������ʱ����ֻ������һ���߼��Ĵ���(DoContextAction);
  ///  2013��9��26�� 08:57:20
  ///    ��лȺ��JOE�ҵ�bug��
  while True do
  begin

    //����ע��Ľ�����<���н���>
    lvDecodeObj := DecodeObject;
    if Integer(lvDecodeObj) = -1 then
    begin
      /// ����İ���ʽ, �ر�����
      DoDisconnect;
      exit;
    end else if lvDecodeObj <> nil then
    begin
      // ��һ��������
      lvTaskObject := TDiocpCoderTcpServer(Owner).GetTaskObject;
      lvTaskObject.FContextDNA := self.ContextDNA;

      // ������Ҫ����Ľ������
      lvTaskObject.FData := lvDecodeObj;
      try
        self.StateINfo := '����ɹ�,׼������dataReceived�����߼�����';


        // ���뵽���������
        self.Lock;
        try
          FRequestQueue.EnQueue(lvTaskObject);
          
          if not FIsProcessRequesting then
          begin
            FIsProcessRequesting := true;
           {$IFDEF QDAC_QWorker}
             Workers.Post(OnExecuteJob, FRequestQueue);
           {$ELSE}
             iocpTaskManager.PostATask(OnExecuteJob, FRequestQueue);
           {$ENDIF}
          end;
        finally
          self.UnLock();
        end;

      except
        on E:Exception do
        begin
          Owner.LogMessage('�ػ�Ͷ���߼������쳣!' + e.Message);

          // Ͷ���쳣 �黹�������
          lvTaskObject.Close;
        end;
      end;
    end else
    begin
      //������û�п���ʹ�õ��������ݰ�,����ѭ��
      Break;
    end;
  end;

  //������<���û�п��õ��ڴ��>����
  ClearRecvedBuffer;
end;



procedure TIOCPCoderClientContext.WriteObject(const pvDataObject:TObject);
var
  lvOutBuffer:TBufferLink; 
  lvStart:Boolean;
begin
  lvStart := false;
  if not Active then Exit;

  if self.LockContext('WriteObject', Self) then
  try
    //sfLogger.logMessage('�����д����[%d]',[Integer(self)], 'BCB_DEBUG');
    lvOutBuffer := TBufferLink.Create;
    try
      TDiocpCoderTcpServer(Owner).FEncoder.Encode(pvDataObject, lvOutBuffer);
      lock();
      try
        if FSendingQueue.size >= TDiocpCoderTcpServer(Owner).MaxSendingQueueSize then
        begin
          raise Exception.Create('Out of MaxSendingQueueSize!!!');
        end;
        FSendingQueue.EnQueue(lvOutBuffer);
        if FCurrentSendBufferLink = nil then
        begin
          FCurrentSendBufferLink := TBufferLink(FSendingQueue.DeQueue);
          lvStart := true;
        end;
      finally
        unLock;
      end;
    except
      lvOutBuffer.Free;
      raise;           
    end;
    
    if lvStart then
    begin
      CheckStartPostSendBufferLink;
    end;
  finally
    self.unLockContext('WriteObject', Self);
    //sfLogger.logMessage('�뿪��д����[%d]',[Integer(self)], 'BCB_DEBUG'); 
  end;    
end;

constructor TDiocpCoderTcpServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTaskObjectPool := TBaseQueue.Create();
  FClientContextClass := TIOCPCoderClientContext;
  
  FIocpSendRequestClass := TDiocpCoderSendRequest;
end;

destructor TDiocpCoderTcpServer.Destroy;
begin
  if FInnerDecoder <> nil then FInnerDecoder.Free;
  if FInnerEncoder <> nil then FInnerEncoder.Free;
  FTaskObjectPool.FreeDataObject;
  FTaskObjectPool.Free;
  inherited Destroy;
end;

function TDiocpCoderTcpServer.GetTaskObject: TDiocpTaskObject;
begin
  Result := TDiocpTaskObject(FTaskObjectPool.DeQueue);
  if Result = nil then
  begin
    Result := TDiocpTaskObject.Create;
  end;
  Result.FContextDNA := 0;
  Result.FData := nil;
  Result.FOwner := Self; 
end;

procedure TDiocpCoderTcpServer.GiveBackTaskObject(pvObj: TDiocpTaskObject);
begin
  pvObj.FContextDNA := 0;
  pvObj.FData := nil;
  pvObj.FOwner := nil;
  FTaskObjectPool.EnQueue(pvObj);
end;

procedure TDiocpCoderTcpServer.RegisterCoderClass(
    pvDecoderClass:TIOCPDecoderClass; pvEncoderClass:TIOCPEncoderClass);
begin
  if FInnerDecoder <> nil then
  begin
    raise Exception.Create('�Ѿ�ע���˽�������');
  end;

  FInnerDecoder := pvDecoderClass.Create;
  RegisterDecoder(FInnerDecoder);

  if FInnerEncoder <> nil then
  begin
    raise Exception.Create('�Ѿ�ע���˱�������');
  end;
  FInnerEncoder := pvEncoderClass.Create;
  RegisterEncoder(FInnerEncoder);
end;

{ TDiocpCoderTcpServer }

procedure TDiocpCoderTcpServer.RegisterDecoder(pvDecoder:TIOCPDecoder);
begin
  FDecoder := pvDecoder;
end;

procedure TDiocpCoderTcpServer.RegisterEncoder(pvEncoder:TIOCPEncoder);
begin
  FEncoder := pvEncoder;
end;



{ TDiocpCoderSendRequest }

procedure TDiocpCoderSendRequest.CancelRequest;
begin
  if FMemBlock <> nil then
  begin
    FreeMemBlock(FMemBlock);
    FMemBlock := nil;
  end;
  inherited;  
end;

procedure TDiocpCoderSendRequest.ResponseDone;
begin
  if FMemBlock <> nil then
  begin
    FreeMemBlock(FMemBlock);
    FMemBlock := nil;
  end;
  inherited;
end;

{ TDiocpTaskObject }

procedure TDiocpTaskObject.Close;
begin
  Assert(FOwner <> nil, '�黹�ظ�!');
  FOwner.GiveBackTaskObject(Self);
end;

end.
