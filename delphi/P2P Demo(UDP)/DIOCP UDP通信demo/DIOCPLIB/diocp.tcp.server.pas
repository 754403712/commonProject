(*
 *	 Unit owner: D10.Mofen
 *         homePage: http://www.diocp.org
 *	       blog: http://www.cnblogs.com/dksoft

 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
 *   2015-04-10 18:00:52
 *     ֹͣʱ����ȴ����е�Ͷ�ݵ�AcceptEx����ع�ع���ٽ��йر�IOCP����,(�ᵼ��Ͷ�ݳ�ȥ��AcceptEx�޷��ع�(XP�³���й©))
 *     ��л Xjumping  990669769, ����bug
 *
 *
 *   thanks qsl's suggestion
 *
 *
 *)
 
unit diocp.tcp.server;

{$I 'diocp.inc'}


//�����־��¼���뿪��
{$DEFINE WRITE_LOG}

interface 

uses
  Classes, diocp.sockets.utils, diocp.core.engine,
  winsock, diocp.winapi.winsock2, diocp.res,

  diocp.core.rawWinSocket, SyncObjs, Windows, SysUtils,
  utils.safeLogger,
  utils.hashs,
  utils.queues, utils.locker;

const
  SOCKET_HASH_SIZE = $FFFF;

  CORE_LOG_FILE = 'diocp_core_exception';
  CORE_DEBUG_FILE = 'diocp_core_debug';

type
  TDiocpTcpServer = class;
  TIocpAcceptorMgr = class;
  TIocpClientContext = class;
  TIocpRecvRequest = class;
  TIocpSendRequest = class;
  TIocpDisconnectExRequest = class;

  TDataReleaseType = (dtNone, dtFreeMem, dtDispose);

  TIocpClientContextClass = class of TIocpClientContext;

  TOnContextError = procedure(pvClientContext: TIocpClientContext; errCode:
      Integer) of object;

  TOnSendRequestResponse = procedure(pvContext:TIocpClientContext;
      pvRequest:TIocpSendRequest) of object;

  TOnDataReceived = procedure(pvClientContext:TIocpClientContext;
      buf:Pointer; len:cardinal; errCode:Integer) of object;

  TOnContextAcceptEvent = procedure(pvSocket: THandle; pvAddr: String; pvPort:
      Integer; var vAllowAccept: Boolean) of object;

  TContextNotifyEvent = procedure(pvClientContext: TIocpClientContext) of object;

  /// <summary>
  ///   on post request is completed
  /// </summary>
  TOnDataRequestCompleted = procedure(pvClientContext:TIocpClientContext;
      pvRequest:TIocpRequest) of object;

  /// <summary>
  ///   Զ��������
  ///   ��Ӧ�ͻ��˵�һ������
  /// </summary>
  TIocpClientContext = class(TObject)
  private
    // ��ǰ�����������׽��־��
    FSocketHandle:TSocket;

    // ��󽻻����ݵ�ʱ���
    FLastActivity: Cardinal;

    FDebugStrings:TStrings;

    {$IFDEF SOCKET_REUSE}
    FDisconnectExRequest:TIocpDisconnectExRequest;
    {$ENDIF}

    FSocketState: TSocketState;

    /// <summary>
    ///   �����õļ�����, ��������Ϊ0ʱ���Խ��йر��ͷ�
    /// </summary>
    FReferenceCounter:Integer;

    /// <summary>
    ///   �Ƿ�����رյı�־�����Ϊtrueʱ �����ü�����Ϊ0 ʱ���������Ĺر�����
    /// </summary>
    FRequestDisconnect:Boolean;



    FDebugInfo: string;
    procedure SetDebugInfo(const Value: string);



    /// <summary>
    ///   �������ü���
    /// </summary>
    /// <returns>
    ///   �ɹ�����true,
    ///   ʧ�ܷ���false ��ǰ������������ر�
    /// </returns>
    /// <param name="pvDebugInfo"> ���Լ�¼��Ϣ </param>
    /// <param name="pvObj"> ���Լ�¼���� </param>
    function IncReferenceCounter(pvDebugInfo: string; pvObj: TObject): Boolean;

    /// <summary>
    ///  �������ü���
    ///  �����ü����� = 0������رձ�־Ϊtrueʱ������öϿ�����(InnerCloseContext)
    /// </summary>
    function DecReferenceCounter(pvDebugInfo: string; pvObj: TObject): Integer;

    /// <summary>
    ///   �������ü�����������ر�
    ///   �����ü����� = 0ʱ������öϿ�����(InnerCloseContext)
    /// </summary>
    procedure DecReferenceCounterAndRequestDisconnect(pvDebugInfo: string; pvObj:
        TObject);


  {$IFDEF SOCKET_REUSE}
    /// <summary>
    ///   �׽�������ʱʹ�ã�������ӦDisconnectEx�����¼�
    /// </summary>
    procedure OnDisconnectExResponse(pvObject:TObject);
  {$ENDIF}
  private
    FAlive:Boolean;
    
    FContextLocker: TIocpLocker;
    


    /// <summary>
    ///  ���ڷ��ͱ��
    /// </summary>
    FSending: Boolean;

    FActive: Boolean;


    /// <summary>
    ///  ��ǰ���ڷ��͵�����
    /// </summary>
    FCurrSendRequest:TIocpSendRequest;
    
    FData: Pointer;

    /// <summary>
    ///  ���ӵ�DNA��ÿ�����Ӷ������һ���ۼ�
    /// </summary>
    FContextDNA: Integer;

    /// <summary>
    ///   ������������Ĭ������б��СΪ100,�����ڿ�������ǰ��������
    /// </summary>
    FSendRequestLink: TIocpRequestSingleLink;

    FRawSocket: TRawSocket;

    FRemoteAddr: String;
    FRemotePort: Integer;
    FTagStr: String;

    /// <summary>
    ///   ��Ͷ�ݵĽ���������Ӧ�е��ã��������������¼�
    /// </summary>
    procedure DoReceiveData;

    /// <summary>
    ///   called by sendRequest response
    /// </summary>
    procedure DoSendRequestCompleted(pvRequest: TIocpSendRequest);



    /// <summary>
    ///   post next sendRequest
    ///    must single thread operator
    /// </summary>
    procedure CheckNextSendRequest;

    /// <example>
    ///   �ͷ���Դ
    ///    1.���Ͷ����е�δ���͵�����(TSendRequest), ����÷���ʵ����TSendRequest.CancelRequest
    /// </example>
    procedure CheckReleaseRes;


    procedure SetOwner(const Value: TDiocpTcpServer);
    function GetDebugInfo: string;


  protected

    
    FOwner: TDiocpTcpServer;
    
    /// <summary>
    ///   ���ӵĽ�������ʵ��
    /// </summary>
    FRecvRequest:TIocpRecvRequest;

    /// <summary>
    ///   Ͷ�ݽ�������
    /// </summary>
    procedure PostWSARecvRequest();virtual;



    /// <summary>
    ///
    /// </summary>
    function GetSendRequest: TIocpSendRequest;

    /// <summary>
    ///   Give Back
    /// </summary>
    function ReleaseSendRequest(pvObject:TIocpSendRequest): Boolean;

    /// <summary>
    ///  1.post reqeust to sending queue,
    ///    return false if SendQueue Size is greater than maxSize,
    ///
    ///  2.check sending flag, start if sending is false
    /// </summary>
    function InnerPostSendRequestAndCheckStart(pvSendRequest:TIocpSendRequest): Boolean;

    /// <summary>
    ///   ִ�����������ӶϿ������������¼�
    ///   ���̵߳���
    /// </summary>
    procedure InnerCloseContext;

    /// <summary>
    ///   Ͷ����ɺ󣬼���Ͷ����һ������,
    ///     ֻ��HandleResponse�е���
    /// </summary>
    procedure PostNextSendRequest; virtual;


    /// <summary>
    ///   Ͷ�ݵķ���������Ӧʱִ�У�һ��Ӧ������ִ�У�Errcode <> 0Ҳ����Ӧ
    /// </summary>
    procedure DoSendRequestRespnonse(pvRequest: TIocpSendRequest); virtual;

    procedure AddDebugString(pvString:string);


    procedure Lock();{$IFDEF HAVE_INLINE} inline;{$ENDIF}
    procedure UnLock();{$IFDEF HAVE_INLINE} inline;{$ENDIF}
  protected
    procedure DoConnected;

    procedure DoCleanUp;virtual;

    procedure OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: WORD); virtual;

    procedure OnDisconnected; virtual;

    procedure OnConnected; virtual;

    procedure SetSocketState(pvState:TSocketState); virtual;
  public

    /// <summary>
    ///   ��ȡ��ǰ�����Ͷ����е���������
    /// </summary>
    function GetSendQueueSize: Integer;


    constructor Create; virtual;
    destructor Destroy; override;

    procedure DoDisconnect;

    /// <summary>
    ///   ����Context���ӣ�����رչ黹��Context�����
    ///    �����ɹ�����True, ���򷵻�False(�����Ѿ����Ͽ���������Ͽ�)
    /// </summary>
    function LockContext(pvDebugInfo: string; pvObj: TObject): Boolean;

    procedure UnLockContext(pvDebugInfo: string; pvObj: TObject);

    /// <summary>
    ///   Ͷ�ݹر�����
    ///     �ȴ�ǰ������ݷ���������йرպ�Ȼ����жϿ�����
    /// </summary>
    procedure PostWSACloseRequest();

    procedure RequestDisconnect(pvDebugInfo: string = ''; pvObj: TObject = nil);

    /// <summary>
    ///  post send request to iocp queue, if post successful return true.
    ///    if request is completed, will call DoSendRequestCompleted procedure
    /// </summary>
    function PostWSASendRequest(buf: Pointer; len: Cardinal; pvCopyBuf: Boolean =
        true; pvTag: Integer = 0; pvTagData: Pointer = nil): Boolean; overload;

    /// <summary>
    ///    Ͷ�ݷ�������IOCP����
    ///    post send request to iocp queue, if post successful return true.
    ///      if request is completed, will call DoSendRequestCompleted procedure
    ///    ��� ����Ϊ0, ���ڴ�������ʱ���йرա�
    /// </summary>
    /// <returns>
    ///    ���Ͷ�ݳɹ�����true�����򷵻�false(Ͷ�ݶ�������)
    /// </returns>
    /// <param name="buf"> (Pointer) </param>
    /// <param name="len"> (Cardinal) </param>
    /// <param name="pvBufReleaseType"> �ͷ����� </param>
    /// <param name="pvTag"> -1: ���������ر�,����ʱ�ر� </param>
    /// <param name="pvTagData"> (Pointer) </param>
    function PostWSASendRequest(buf: Pointer; len: Cardinal; pvBufReleaseType:
        TDataReleaseType; pvTag: Integer = 0; pvTagData: Pointer = nil): Boolean;
        overload;


    property Active: Boolean read FActive;

    property Data: Pointer read FData write FData;

    property DebugInfo: string read GetDebugInfo write SetDebugInfo;



    /// <summary>
    ///  ����ʱ���� +1
    /// </summary>
    property ContextDNA: Integer read FContextDNA;

    /// <summary>
    ///   ��󽻻����ݵ�ʱ���
    /// </summary>
    property LastActivity: Cardinal read FLastActivity;

    property Owner: TDiocpTcpServer read FOwner write SetOwner;

    property RawSocket: TRawSocket read FRawSocket;

    property RemoteAddr: String read FRemoteAddr;

    property RemotePort: Integer read FRemotePort;
    property SocketHandle: TSocket read FSocketHandle;
    property SocketState: TSocketState read FSocketState;
    property TagStr: String read FTagStr write FTagStr;
  end;



  /// <summary>
  ///   WSARecv io request
  /// </summary>
  TIocpRecvRequest = class(TIocpRequest)
  private
    FCounter:Integer;
    FDebugInfo:String;
    FInnerBuffer: diocp.winapi.winsock2.TWsaBuf;
    FRecvBuffer: diocp.winapi.winsock2.TWsaBuf;
    FRecvdFlag: Cardinal;
    FOwner: TDiocpTcpServer;
    FClientContext:TIocpClientContext;
  protected
    /// <summary>
    ///   iocp reply request, run in iocp thread
    /// </summary>
    procedure HandleResponse; override;
  public
    /// <summary>
    ///   post recv request to iocp queue
    /// </summary>
    function PostRequest: Boolean; overload;

    /// <summary>
    ///
    /// </summary>
    function PostRequest(pvBuffer:PAnsiChar; len:Cardinal): Boolean; overload;

  public
    constructor Create;
    destructor Destroy; override;
  end;


  TIocpSendRequestClass = class of TIocpSendRequest;
  /// <summary>
  ///   WSASend io request
  /// </summary>
  TIocpSendRequest = class(TIocpRequest)
  private
    FLastMsg : String;
    FSendBufferReleaseType: TDataReleaseType;
    
    FMaxSize:Integer;
    
    // for singlelinked
    FNext:TIocpSendRequest;

    FIsBusying:Boolean;

    FAlive: Boolean;

    FBytesSize:Cardinal;

    // send buf record
    FWSABuf:TWsaBuf;


    FBuf:Pointer;
    FLen:Cardinal;

    FOwner: TDiocpTcpServer;

    procedure CheckClearSendBuffer();
    
    function GetWSABuf: PWsaBuf;
 protected
    FClientContext:TIocpClientContext;

    FOnDataRequestCompleted: TOnDataRequestCompleted;

    procedure UnBindingSendBuffer();
  protected
    /// 0:none, 1:succ, 2:completed, 3: has err, 4:owner is off
    FReponseState:Byte;
    
    /// <summary>
    ///   post send
    /// </summary>
    function ExecuteSend: Boolean; virtual;
  protected
    /// <summary>
    ///   iocp reply request, run in iocp thread
    /// </summary>
    procedure HandleResponse; override;


    procedure ResponseDone; override;

    /// <summary>
    ///   give back to sendRequest ObjectPool
    /// </summary>
    procedure DoCleanUp;virtual;


    function GetStateINfo: String; override;
    

    /// <summary>
    ///   Ͷ�ݷ��͵����ݵ�IOCP�������(WSASend)
    /// </summary>
    /// <returns>
    ///   ����ʧ�ܷ���False, ������Ͽ�����
    /// </returns>
    /// <param name="buf"> (Pointer) </param>
    /// <param name="len"> (Cardinal) </param>
    function InnerPostRequest(buf: Pointer; len: Cardinal): Boolean;


  public
    constructor Create; virtual;

    destructor Destroy; override;

    /// <summary>
    ///   set buf inneed to send
    /// </summary>
    procedure SetBuffer(buf: Pointer; len: Cardinal; pvBufReleaseType: TDataReleaseType); overload;

    /// <summary>
    ///   set buf inneed to send
    /// </summary>
    procedure SetBuffer(buf: Pointer; len: Cardinal; pvCopyBuf: Boolean = true); overload;

    property ClientContext: TIocpClientContext read FClientContext;

    property Owner: TDiocpTcpServer read FOwner;

    /// <summary>
    ///   ��ȡ���һ�β�����Buff��Ϣ
    /// </summary>
    property WSABuf: PWsaBuf read GetWSABuf;

    

    

    /// <summary>
    ///   on entire buf send completed
    /// </summary>
    property OnDataRequestCompleted: TOnDataRequestCompleted read FOnDataRequestCompleted write FOnDataRequestCompleted;
  end;

  TIocpDisconnectExRequest = class(TIocpRequest)
  private
    FOwner:TDiocpTcpServer;

    FContext:TIocpClientContext;

  protected
    function PostRequest: Boolean;

    /// <summary>
    ///   directly post request,
    /// </summary>
    function DirectlyPost: Boolean;
  end;

  /// <summary>
  ///   acceptEx request
  /// </summary>
  TIocpAcceptExRequest = class(TIocpRequest)
  private
    /// <summary>
    ///   acceptEx lpOutBuffer[in]
    ///     A pointer to a buffer that receives the first block of data sent on a new connection,
    ///       the local address of the server, and the remote address of the client.
    ///       The receive data is written to the first part of the buffer starting at offset zero,
    ///       while the addresses are written to the latter part of the buffer.
    ///       This parameter must be specified.
    /// </summary>
    FAcceptBuffer: array [0.. (SizeOf(TSockAddrIn) + 16) * 2 - 1] of byte;

    FOwner: TDiocpTcpServer;
    FAcceptorMgr:TIocpAcceptorMgr;

    FClientContext:TIocpClientContext;
    /// <summary>
    ///   get socket peer info on acceptEx reponse
    /// </summary>
    procedure GetPeerINfo;
  protected
    function PostRequest: Boolean;

  protected
    procedure HandleResponse; override;

    procedure ResponseDone; override;

  public
    constructor Create(AOwner: TDiocpTcpServer);
  end;

  /// <summary>
  ///   manager acceptEx request
  /// </summary>
  TIocpAcceptorMgr = class(TObject)
  private
    FOwner: TDiocpTcpServer;

    // sendRequest pool
    FAcceptExRequestPool: TBaseQueue;

    // һͶ��δ��Ӧ��AcceptEx����
    FList:TList;
    FListenSocket: TRawSocket;
    FLocker: TIocpLocker;
    FMaxRequest:Integer;
    FMinRequest:Integer;

  protected
  public
    constructor Create(AOwner: TDiocpTcpServer; AListenSocket: TRawSocket);

    destructor Destroy; override;

    function GetRequestObject: TIocpAcceptExRequest;

    procedure ReleaseRequestObject(pvRequest:TIocpAcceptExRequest);

    /// <summary>
    ///   ������������б����Ƴ�
    /// </summary>
    procedure RemoveRequestObject(pvRequest:TIocpAcceptExRequest);

    /// <summary>
    ///   ����Ƿ���ҪͶ��AcceptEx
    /// </summary>
    procedure CheckPostRequest;

    procedure CancelAllRequest;
    /// <summary>
    ///   �ȴ��������ӹر�
    /// </summary>
    function WaitForCancel(pvTimeOut: Cardinal): Boolean;

    property ListenSocket: TRawSocket read FListenSocket;

    property MaxRequest: Integer read FMaxRequest write FMaxRequest;

    property MinRequest: Integer read FMinRequest write FMinRequest;


  end;

  /// <summary>
  ///   iocp�����ݼ������
  /// </summary>
  TIocpDataMonitor = class(TObject)
  private
    FSentSize:Int64;
    FRecvSize:Int64;
    FPostWSASendSize: Int64;

    FHandleCreateCounter:Integer;
    FHandleDestroyCounter:Integer;

    FContextCreateCounter: Integer;
    FContextOutCounter:Integer;
    FContextReturnCounter:Integer;

    FPushSendQueueCounter: Integer;
    FResponseSendObjectCounter:Integer;

    FSendRequestCreateCounter: Integer;
    FSendRequestOutCounter:Integer;
    FSendRequestReturnCounter:Integer;
    FSendRequestAbortCounter :Integer;

    FPostWSASendCounter:Integer;
    FResponseWSASendCounter:Integer;

    FPostWSARecvCounter:Integer;
    FResponseWSARecvCounter:Integer;

    FAcceptExObjectCounter: Integer;
    FPostWSAAcceptExCounter:Integer;
    FResponseWSAAcceptExCounter:Integer;

    FLocker: TCriticalSection;
    FPostSendObjectCounter: Integer;

    procedure incSentSize(pvSize:Cardinal);
    procedure incPostWSASendSize(pvSize:Cardinal);
    procedure incRecvdSize(pvSize:Cardinal);

    procedure incPostWSASendCounter();
    procedure incResponseWSASendCounter;

    procedure IncPostWSARecvCounter;
    procedure IncResponseWSARecvCounter;


    procedure IncAcceptExObjectCounter;

    procedure incPushSendQueueCounter;
    procedure incPostSendObjectCounter();
    procedure incResponseSendObjectCounter();
    {$IFDEF SOCKET_REUSE}
    procedure incHandleCreateCounter;
    procedure incHandleDestroyCounter;
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    property AcceptExObjectCounter: Integer read FAcceptExObjectCounter;
    property ContextCreateCounter: Integer read FContextCreateCounter;
    property ContextOutCounter: Integer read FContextOutCounter;
    property ContextReturnCounter: Integer read FContextReturnCounter;
    property HandleCreateCounter: Integer read FHandleCreateCounter;
    property HandleDestroyCounter: Integer read FHandleDestroyCounter;
    property Locker: TCriticalSection read FLocker;
    property PushSendQueueCounter: Integer read FPushSendQueueCounter;
    property PostSendObjectCounter: Integer read FPostSendObjectCounter;
    property ResponseSendObjectCounter: Integer read FResponseSendObjectCounter;

    property PostWSAAcceptExCounter: Integer read FPostWSAAcceptExCounter;
    property PostWSARecvCounter: Integer read FPostWSARecvCounter;
    property PostWSASendCounter: Integer read FPostWSASendCounter;


    property PostWSASendSize: Int64 read FPostWSASendSize;
    property RecvSize: Int64 read FRecvSize;

    property ResponseWSAAcceptExCounter: Integer read FResponseWSAAcceptExCounter;
    property ResponseWSARecvCounter: Integer read FResponseWSARecvCounter;
    property ResponseWSASendCounter: Integer read FResponseWSASendCounter;
    property SendRequestAbortCounter: Integer read FSendRequestAbortCounter;
    property SendRequestCreateCounter: Integer read FSendRequestCreateCounter;
    property SendRequestOutCounter: Integer read FSendRequestOutCounter;
    property SendRequestReturnCounter: Integer read FSendRequestReturnCounter;
    property SentSize: Int64 read FSentSize;
  end;

  {$IF RTLVersion>22}
  // thanks: �����ٷ�19183455
  //  vcl for win64 ��64λƽ̨�£��ؼ�����)
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  {$IFEND}

  TDiocpTcpServer = class(TComponent)
  private
    FContextDNA : Integer;
    
    FLogger: TSafeLogger;

    FMaxSendingQueueSize:Integer;

    FIsDestroying :Boolean;
    FWSARecvBufferSize: cardinal;
    procedure SetWSARecvBufferSize(const Value: cardinal);

    function isDestroying:Boolean;
    function LogCanWrite: Boolean;

    function RequestContextDNA:Integer;
    
  protected
    FClientContextClass:TIocpClientContextClass;

    FIocpSendRequestClass:TIocpSendRequestClass;

    procedure SetName(const NewName: TComponentName); override;



    /// <summary>
    ///   �������µ����Ӷ���ʱ����õĺ���
    ///   ��������������һЩ��ʼ��
    /// </summary>
    procedure OnCreateClientContext(const context: TIocpClientContext); virtual;

    /// <summary>
    ///    ��ȡһ�����Ӷ�������������û�У���ᴴ��һ���µ�ʵ��
    /// </summary>
    function GetClientContext: TIocpClientContext;

    /// <summary>
    ///   �ͷ����Ӷ��󣬹黹�������
    /// </summary>
    function ReleaseClientContext(pvObject:TIocpClientContext): Boolean;

    /// <summary>
    ///   ��ӵ������б���
    /// </summary>
    procedure AddToOnlineList(pvObject:TIocpClientContext);

    /// <summary>
    ///   �������б����Ƴ�
    /// </summary>
    procedure RemoveFromOnOnlineList(pvObject:TIocpClientContext); virtual;
  private
    // clientContext pool
    FContextPool: TBaseQueue;

    // sendRequest pool
    FSendRequestPool: TBaseQueue;

    // extend data
    FDataPtr: Pointer;

    /// data record
    FDataMoniter: TIocpDataMonitor;

    FActive: Boolean;



    // acceptEx request mananger
    FIocpAcceptorMgr:TIocpAcceptorMgr;

    FIocpEngine: TIocpEngine;

    FKeepAlive: Boolean;

    /// <summary>
    ///  ���������Socket�����ڽ��ܿͻ�������
    /// </summary>
    FListenSocket: TRawSocket;
    FOnContextConnected: TContextNotifyEvent;
    FOnContextDisconnected: TContextNotifyEvent;


    FOnDataReceived: TOnDataReceived;


    FOnContextError: TOnContextError;
    FOnContextAccept: TOnContextAcceptEvent;
    FOnSendRequestResponse: TOnSendRequestResponse;

    FPort: Integer;

    procedure DoClientContextError(pvClientContext: TIocpClientContext;
        pvErrorCode: Integer);
    function GetWorkerCount: Integer;

    procedure SetWorkerCount(const Value: Integer);

    procedure SetActive(pvActive:Boolean);


    procedure DoReceiveData(pvIocpClientContext:TIocpClientContext;
        pvRequest:TIocpRecvRequest);
  protected
    FLocker:TIocpLocker;

    /// <summary>
    ///   ά���������б�
    /// </summary>
    FOnlineContextList : TDHashTable;


    /// <summary>
    ///   ��ȡһ�������������(�����)
    /// </summary>
    function GetSendRequest: TIocpSendRequest;

    /// <summary>
    ///   �黹һ�������������(�����)
    /// </summary>
    function ReleaseSendRequest(pvObject:TIocpSendRequest): Boolean;

  private
    /// <summary>
    ///   ��Ͷ�ݵ�AcceptEx������Ӧʱ�е���
    /// </summary>
    /// <param name="pvRequest"> ��Ӧ������ </param>
    procedure DoAcceptExResponse(pvRequest: TIocpAcceptExRequest);

    function GetClientCount: Integer;
  public

    /// <summary>
    ///   ��ʱ���, �������Timeoutָ����ʱ�仹û���κ����ݽ������ݼ�¼��
    ///     �ͽ��йر�����
    ///   ʹ��ѭ����⣬������кõķ�������ӭ�ύ���ı������
    /// </summary>
    procedure KickOut(pvTimeOut:Cardinal = 60000);

    procedure LogMessage(pvMsg: string; pvMsgType: string = ''; pvLevel: TLogLevel
        = lgvMessage); overload;

    procedure LogMessage(pvMsg: string; const args: array of const; pvMsgType:
        string = ''; pvLevel: TLogLevel = lgvMessage); overload;


    constructor Create(AOwner: TComponent); override;

    /// <summary>
    ///   ��������ÿ��������������Ͷ��У������������ٽ���Ͷ��
    /// </summary>
    procedure SetMaxSendingQueueSize(pvSize:Integer);

    destructor Destroy; override;

    /// <summary>
    ///   ����SocketHandle�������б��в��Ҷ�Ӧ��Contextʵ��
    /// </summary>
    function FindContext(pvSocketHandle:TSocket): TIocpClientContext;

    procedure RegisterContextClass(pvContextClass: TIocpClientContextClass);

    procedure RegisterSendRequestClass(pvClass: TIocpSendRequestClass);

    /// <summary>
    ///   �������ݼ������ʵ��
    /// </summary>
    procedure CreateDataMonitor;


    /// <summary>
    ///   check clientContext object is valid.
    /// </summary>
    function checkClientContextValid(const pvClientContext: TIocpClientContext):  Boolean;

    /// <summary>
    ///   �Ͽ�������������
    /// </summary>
    procedure DisconnectAll;

    /// <summary>
    ///   �ȴ��������ӹر�
    /// </summary>
    function WaitForContext(pvTimeOut: Cardinal): Boolean;


    /// <summary>
    ///   get online client list
    /// </summary>
    procedure GetOnlineContextList(pvList:TList);

    /// <summary>
    ///   stop and wait all workers down
    /// </summary>
    procedure SafeStop;

    property Active: Boolean read FActive write SetActive;

    procedure Open;

    procedure Close;

    /// <summary>
    ///   
    /// </summary>
    function GetStateInfo: String;



    /// <summary>
    ///   client connections counter
    /// </summary>
    property ClientCount: Integer read GetClientCount;
    property DataMoniter: TIocpDataMonitor read FDataMoniter;
    property IocpEngine: TIocpEngine read FIocpEngine;

    /// <summary>
    ///   set socket Keep alive option when acceptex
    /// </summary>
    property KeepAlive: Boolean read FKeepAlive write FKeepAlive;

    /// <summary>
    ///   extend data
    /// </summary>
    property DataPtr: Pointer read FDataPtr write FDataPtr;
    property IocpAcceptorMgr: TIocpAcceptorMgr read FIocpAcceptorMgr;

    /// <summary>
    ///   SERVER Locker
    /// </summary>
    property Locker: TIocpLocker read FLocker;

    /// <summary>
    ///   ���Ĵ����ͻ������
    /// </summary>
    property MaxSendingQueueSize: Integer read FMaxSendingQueueSize;
    property Logger: TSafeLogger read FLogger;
  published

    /// <summary>
    ///   �����ӶϿ�ʱ�����¼�
    ///     ��TDiocpTcpServer.ActiveΪFalseʱ�����д���
    ///     ��Iocp�����߳��д���
    /// </summary>
    property OnContextDisconnected: TContextNotifyEvent read FOnContextDisconnected
        write FOnContextDisconnected;

    /// <summary>
    ///   �����ӽ����ɹ�ʱ�����¼�
    ///     ��TDiocpTcpServer.ActiveΪFalseʱ�����д���
    ///     ��Iocp�����߳��д���
    /// </summary>
    property OnContextConnected: TContextNotifyEvent read FOnContextConnected
        write FOnContextConnected;

    /// <summary>
    ///   ����������ʱ�����¼�
    ///     ��TDiocpTcpServer.ActiveΪFalseʱ�����д���
    ///     ��Iocp�����߳��д���
    /// </summary>
    property OnContextAccept: TOnContextAcceptEvent read FOnContextAccept write
        FOnContextAccept;

    property OnSendRequestResponse: TOnSendRequestResponse read
        FOnSendRequestResponse write FOnSendRequestResponse;

    /// <summary>
    ///   Ĭ�������Ķ˿�
    /// </summary>
    property Port: Integer read FPort write FPort;

    /// <summary>
    ///   iocp�����߳�
    ///    Ϊ0ʱĬ��Ϊ cpu count * 2 -1
    /// </summary>
    property WorkerCount: Integer read GetWorkerCount write SetWorkerCount;


    /// <summary>
    ///   post wsaRecv request block size
    /// </summary>
    property WSARecvBufferSize: cardinal read FWSARecvBufferSize write
        SetWSARecvBufferSize;



    /// <summary>
    ///  on work error
    ///    occur in post request methods or iocp worker thread
    /// </summary>
    property OnContextError: TOnContextError read FOnContextError write
        FOnContextError;



    /// <summary>
    ///  on clientcontext received data
    ///    called by iocp worker thread
    /// </summary>
    property OnDataReceived: TOnDataReceived read FOnDataReceived write
        FOnDataReceived;




  end;



implementation

uses
  DateUtils;


var
  __startTime:TDateTime;




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



function GetRunTimeINfo: String;
var
  lvMSec, lvRemain:Int64;
  lvDay, lvHour, lvMin, lvSec:Integer;
begin
  lvMSec := MilliSecondsBetween(Now(), __startTime);
  lvDay := Trunc(lvMSec / MSecsPerDay);
  lvRemain := lvMSec mod MSecsPerDay;

  lvHour := Trunc(lvRemain / (MSecsPerSec * 60 * 60));
  lvRemain := lvRemain mod (MSecsPerSec * 60 * 60);

  lvMin := Trunc(lvRemain / (MSecsPerSec * 60));
  lvRemain := lvRemain mod (MSecsPerSec * 60);

  lvSec := Trunc(lvRemain / (MSecsPerSec));

  if lvDay > 0 then
    Result := Result + IntToStr(lvDay) + ' d ';

  if lvHour > 0 then
    Result := Result + IntToStr(lvHour) + ' h ';

  if lvMin > 0 then
    Result := Result + IntToStr(lvMin) + ' m ';

  if lvSec > 0 then
    Result := Result + IntToStr(lvSec) + ' s ';
end;


///TRunTimeINfoTools
function TransByteSize(pvByte: Int64): String;
var
  lvTB, lvGB, lvMB, lvKB:Word;
  lvRemain:Int64;
begin
  lvRemain := pvByte;

  lvTB := Trunc(lvRemain/BytePerGB/1024);
  //lvRemain := pvByte - (lvTB * BytePerGB * 1024);
  
  lvGB := Trunc(lvRemain/BytePerGB);

  lvGB := lvGB mod 1024;      // trunc TB

  lvRemain := lvRemain mod BytePerGB;

  lvMB := Trunc(lvRemain/BytePerMB);
  lvRemain := lvRemain mod BytePerMB;

  lvKB := Trunc(lvRemain/BytePerKB);
  lvRemain := lvRemain mod BytePerKB;
  Result := Format('%d TB, %d GB, %d MB, %d KB, %d B', [lvTB, lvGB, lvMB, lvKB, lvRemain]);
end;


  

/// compare target, cmp_val same set target = new_val
/// return old value
function lock_cmp_exchange(cmp_val, new_val: Boolean; var target: Boolean): Boolean; overload;
asm
{$ifdef win32}
  lock cmpxchg [ecx], dl
{$else}
.noframe
  mov rax, rcx
  lock cmpxchg [r8], dl
{$endif}
end;


procedure TIocpClientContext.InnerCloseContext;
begin
  Assert(FOwner <> nil);

{$IFDEF WRITE_LOG}
  if FReferenceCounter <> 0 then
    FOwner.LogMessage('InnerCloseContext FReferenceCounter:%d',
      [FReferenceCounter], CORE_LOG_FILE, lgvError);

  if not FActive then
  begin
    FOwner.LogMessage('InnerCloseContext FActive is false', CORE_LOG_FILE, lgvError);
    exit;
  end;
{$ENDIF}
  if not FActive then exit;

//  Assert(FReferenceCounter = 0);
//  Assert(FActive);
  try
    FActive := false;
  {$IFDEF SOCKET_REUSE}

  {$ELSE}
    FRawSocket.Close;
  {$ENDIF}

    CheckReleaseRes;

    try
      if FOwner.Active then
      begin
        if Assigned(FOwner.FOnContextDisconnected) then
        begin
          FOwner.FOnContextDisconnected(Self);
        end;
        OnDisconnected;
      end;
    except
    end;
  finally
    {$IFDEF DEBUG_ON}
    AddDebugString(Format('#-(%d):Disconnected', [FContextDNA]));
    {$ENDIF}

    FOwner.RemoveFromOnOnlineList(Self);
    // �黹�����������ĳ�
    FOwner.ReleaseClientContext(Self);
  end;

end;

procedure TIocpClientContext.lock;
begin
  FContextLocker.lock();
end;

function TIocpClientContext.LockContext(pvDebugInfo: string; pvObj: TObject):
    Boolean;
begin
  Result := IncReferenceCounter(pvDebugInfo, pvObj);
end;

procedure TIocpClientContext.unLockContext(pvDebugInfo: string; pvObj: TObject);
begin
  if Self = nil then
  begin
    Assert(Self<> nil);
  end;
  DecReferenceCounter(pvDebugInfo, pvObj);
end;


procedure TIocpClientContext.CheckNextSendRequest;
var
  lvRequest:TIocpSendRequest;
begin
  Assert(FOwner <> nil);

  FContextLocker.lock();
  try
    lvRequest := TIocpSendRequest(FSendRequestLink.Pop);
    if lvRequest = nil then
    begin
      FSending := false;
      exit;
    end;
  finally
    FContextLocker.unLock;
  end;

  if lvRequest <> nil then
  begin   
    FcurrSendRequest := lvRequest;
    if lvRequest.ExecuteSend then
    begin
      if (FOwner.FDataMoniter <> nil) then
      begin
        FOwner.FDataMoniter.incPostSendObjectCounter;
      end;
    end else
    begin
      FCurrSendRequest := nil;

      /// ȡ������
      lvRequest.CancelRequest;

      /// �߳�����
      RequestDisconnect(Format(strFuncFail, [self.SocketHandle,'CheckNextSendRequest::lvRequest.ExecuteSend', lvRequest.FLastMsg]), lvRequest);

      FOwner.ReleaseSendRequest(lvRequest);
    end;
  end;
end;

procedure TIocpClientContext.CheckReleaseRes;
var
  lvRequest:TIocpSendRequest;
begin
  while true do
  begin
    lvRequest :=TIocpSendRequest(FSendRequestLink.Pop);
    if lvRequest <> nil then
    begin
      if (FOwner.FDataMoniter <> nil) then
      begin
        InterlockedIncrement(FOwner.FDataMoniter.FSendRequestAbortCounter);
      end;

      lvRequest.CancelRequest;
      FOwner.releaseSendRequest(lvRequest);
    end else
    begin
      Break;
    end;
  end;
end;

constructor TIocpClientContext.Create;
begin
  inherited Create;
  FDebugStrings := TStringList.Create;
  FReferenceCounter := 0;
  FContextLocker := TIocpLocker.Create('contextLocker');
  FAlive := False;
  FRawSocket := TRawSocket.Create();
  FActive := false;

  FSendRequestLink := TIocpRequestSingleLink.Create(100);
  FRecvRequest := TIocpRecvRequest.Create;
  FRecvRequest.FClientContext := self;

  {$IFDEF SOCKET_REUSE}
  FDisconnectExRequest:=TIocpDisconnectExRequest.Create;
  FDisconnectExRequest.FContext := Self;
  FDisconnectExRequest.OnResponse := OnDisconnectExResponse;
  {$ENDIF}
end;

function TIocpClientContext.IncReferenceCounter(pvDebugInfo: string; pvObj:
    TObject): Boolean;
begin
  FContextLocker.lock('IncReferenceCounter');
  if (not Active) or FRequestDisconnect then
  begin
    Result := false;
  end else
  begin
    Inc(FReferenceCounter);
    {$IFDEF DEBUG_ON}
    AddDebugString(Format('+(%d):%d,%s', [FReferenceCounter, IntPtr(pvObj), pvDebugInfo]));
    {$ENDIF}

    Result := true;
  end;
  FContextLocker.unLock;
end;


procedure TIocpClientContext.AddDebugString(pvString:string);
begin
  FDebugStrings.Add(pvString);
  if FDebugStrings.Count > 40 then FDebugStrings.Delete(0);
end;

function TIocpClientContext.DecReferenceCounter(pvDebugInfo: string; pvObj:
    TObject): Integer;
var
  lvCloseContext:Boolean;
begin
  lvCloseContext := false;
  if self = nil then
  begin
    Assert(False);
  end;
  FContextLocker.lock('DecReferenceCounter');
  Dec(FReferenceCounter);
  Result := FReferenceCounter;
  {$IFDEF DEBUG_ON}
  AddDebugString(Format('-(%d):%d,%s', [FReferenceCounter, IntPtr(pvObj), pvDebugInfo]));
  {$ENDIF}

  if FReferenceCounter < 0 then
  begin  // С��0�����������
    {$IFDEF DEBUG_ON}
    if IsDebugMode then
    begin
      FOwner.logMessage('TIocpClientContext.DecReferenceCounter:%d, DebugInfo:%s',
        [FReferenceCounter, FDebugStrings.Text], CORE_DEBUG_FILE, lgvError);
      Assert(FReferenceCounter >=0);
    end else
    begin
      FOwner.logMessage('TIocpClientContext.DecReferenceCounter:%d, DebugInfo:%s',
          [FReferenceCounter, FDebugStrings.Text], CORE_DEBUG_FILE, lgvError);
    end;
    {$ENDIF}
    FReferenceCounter :=0;
  end;
  if FReferenceCounter = 0 then
    if FRequestDisconnect then lvCloseContext := true;
    
  FContextLocker.unLock; 
  
  if lvCloseContext then InnerCloseContext;
end;

procedure TIocpClientContext.DecReferenceCounterAndRequestDisconnect(
    pvDebugInfo: string; pvObj: TObject);
var
  lvCloseContext:Boolean;
begin
  lvCloseContext := false;

  FContextLocker.lock('DecReferenceCounter');

{$IFDEF WRITE_LOG}
  FOwner.logMessage(pvDebugInfo, strRequestDisconnectFileID);
{$ENDIF}


  FRequestDisconnect := true;
  Dec(FReferenceCounter);
  
  {$IFDEF DEBUG_ON}
  AddDebugString(Format('-(%d):%d,%s', [FReferenceCounter, IntPtr(pvObj), pvDebugInfo]));
  {$ENDIF}

  if FReferenceCounter < 0 then
  begin
    {$IFDEF DEBUG_ON}
    if IsDebugMode then
    begin
      Assert(FReferenceCounter >=0);
    end else
    begin
      FOwner.logMessage('TIocpClientContext.DecReferenceCounterAndRequestDisconnect:%d, DebugInfo:%s',
          [FReferenceCounter, FDebugStrings.Text], CORE_DEBUG_FILE, lgvError);
    end;
    {$ENDIF}
    FReferenceCounter :=0;
  end;
  if FReferenceCounter = 0 then
    lvCloseContext := true;
    
  FContextLocker.unLock; 
  
  if lvCloseContext then InnerCloseContext;
end;

function TIocpClientContext.ReleaseSendRequest(
  pvObject: TIocpSendRequest): Boolean;
begin
  Result := FOwner.releaseSendRequest(pvObject);
end;

procedure TIocpClientContext.RequestDisconnect(pvDebugInfo: string = ''; pvObj:
    TObject = nil);
var
  lvCloseContext:Boolean;
begin
  if not FActive then exit;

{$IFDEF WRITE_LOG}
  FOwner.logMessage(pvDebugInfo, strRequestDisconnectFileID);
{$ENDIF}

  FContextLocker.lock('RequestDisconnect');
  {$IFDEF DEBUG_ON}
  if pvDebugInfo <> '' then
  begin
    AddDebugString(Format('*(%d):%d,%s', [FReferenceCounter, IntPtr(pvObj), pvDebugInfo]));
  end;
  {$ENDIF}
  
  {$IFDEF SOCKET_REUSE}
  lvCloseContext := False;
  if not FRequestDisconnect then
  begin
    // cancel
    FRawSocket.ShutDown();
    FRawSocket.CancelIO;

    // post succ, in handleReponse Event do
    if not FDisconnectExRequest.PostRequest then
    begin      // post fail,
      FRawSocket.close;
      if FReferenceCounter = 0 then  lvCloseContext := true;    //      lvCloseContext := true;   //directly close
    end;
    FRequestDisconnect := True;
  end;
  {$ELSE}


  lvCloseContext := False;
  FRequestDisconnect := True;
  if FReferenceCounter = 0 then  lvCloseContext := true;
  {$ENDIF}

  FContextLocker.unLock;

  {$IFDEF SOCKET_REUSE}
  if lvCloseContext then InnerCloseContext;
  {$ELSE}
  if lvCloseContext then InnerCloseContext else FRawSocket.close;
  {$ENDIF}

end;

destructor TIocpClientContext.Destroy;
begin
  if IsDebugMode then
  begin
    if FReferenceCounter <> 0 then
    begin
      Assert(FReferenceCounter = 0);
    end;

    if FSendRequestLink.Count > 0 then
    begin
      Assert(FSendRequestLink.Count = 0);
    end;
  end;

  FRawSocket.Close;
  FRawSocket.Free;

  FRecvRequest.Free;
  
  if IsDebugMode then
  begin
    Assert(FSendRequestLink.Count = 0);
  end;

  {$IFDEF SOCKET_REUSE}
  FDisconnectExRequest.Free;
  {$ENDIF}

  FSendRequestLink.Free;
  FContextLocker.Free;
  FDebugStrings.Free;
  inherited Destroy;
end;

procedure TIocpClientContext.DoCleanUp;
begin
  FLastActivity := 0;

  FOwner := nil;
  FRequestDisconnect := false;
  FSending := false;

  {$IFDEF DEBUG_ON}
  AddDebugString(Format('-(%d):%d,%s', [FReferenceCounter, IntPtr(Self), '-----DoCleanUp-----']));
  {$ENDIF}
  if IsDebugMode then
  begin
    Assert(FReferenceCounter = 0);
    Assert(not FActive);
  end;


//  if FActive then
//  begin
//    FRawSocket.close;
//    FActive := false;
//    CheckReleaseRes;
//  end;
end;

procedure TIocpClientContext.DoConnected;
begin
  FLastActivity := GetTickCount;

  FContextLocker.lock('DoConnected');
  try
    FSocketHandle := FRawSocket.SocketHandle;
    Assert(FOwner <> nil);
    if FActive then
    begin
      if IsDebugMode then
      begin
        Assert(not FActive);
      end;
      {$IFDEF WRITE_LOG}
       FOwner.logMessage(strDoConnectedError, [SocketHandle], CORE_DEBUG_FILE, lgvError);
      {$ENDIF}
    end else
    begin
      FContextDNA := FOwner.RequestContextDNA;
      FActive := true;

      {$IFDEF DEBUG_ON}
      AddDebugString(Format('#+(%d):Connected', [FContextDNA]));
      {$ENDIF}
      FOwner.AddToOnlineList(Self);

      if self.LockContext('onConnected', Self) then
      try
        if Assigned(FOwner.FOnContextConnected) then
        begin
          FOwner.FOnContextConnected(Self);
        end;

        try
          OnConnected();
        except
        end;

        PostWSARecvRequest;
      finally
        self.UnLockContext('OnConnected', Self);
      end;
    end;
  finally
    FContextLocker.unLock;
  end;
end;

procedure TIocpClientContext.DoDisconnect;
begin
  RequestDisconnect;
end;

procedure TIocpClientContext.DoReceiveData;
begin
  try
    FLastActivity := GetTickCount;

    OnRecvBuffer(FRecvRequest.FRecvBuffer.buf,
      FRecvRequest.FBytesTransferred,
      FRecvRequest.FErrorCode);
    if FOwner <> nil then
      FOwner.doReceiveData(Self, FRecvRequest);
  except
    on E:Exception do
    begin
      Owner.LogMessage(strOnRecvBufferException, [SocketHandle, e.Message]);
      Owner.OnContextError(Self, 0);
    end;
  end;
end;

procedure TIocpClientContext.DoSendRequestCompleted(pvRequest:
    TIocpSendRequest);
begin
  ;
end;

procedure TIocpClientContext.DoSendRequestRespnonse(
  pvRequest: TIocpSendRequest);
begin
  FLastActivity := GetTickCount;
  
  if Assigned(FOwner.FOnSendRequestResponse) then
  begin
    FOwner.FOnSendRequestResponse(Self, pvRequest);
  end;
end;

function TIocpClientContext.GetDebugInfo: string;
begin
  FContextLocker.lock();
  Result := FDebugInfo;
  FContextLocker.unLock();  
end;

function TIocpClientContext.GetSendQueueSize: Integer;
begin
  Result := FSendRequestLink.Count;
end;

function TIocpClientContext.GetSendRequest: TIocpSendRequest;
begin
  Result := FOwner.GetSendRequest;
  Assert(Result <> nil);
  Result.FClientContext := self;
end;


procedure TIocpClientContext.OnConnected;
begin
  
end;

procedure TIocpClientContext.OnDisconnected;
begin

end;


{$IFDEF SOCKET_REUSE}
procedure TIocpClientContext.OnDisconnectExResponse(pvObject:TObject);
var
  lvRequest:TIocpDisconnectExRequest;
begin
  if FActive then
  begin   // already connected
    lvRequest :=TIocpDisconnectExRequest(pvObject);
    if lvRequest.FErrorCode <> 0 then
    begin
      RawSocket.close;
      if (FOwner.FDataMoniter <> nil) then
        FOwner.FDataMoniter.incHandleDestroyCounter;
      DecReferenceCounter(
          Format('TIocpDisconnectExRequest.HandleResponse.Error, %d', [lvRequest.FErrorCode])
          , lvRequest
        );
    end else
    begin
      DecReferenceCounter(
          'TIocpDisconnectExRequest.HandleResponse', lvRequest
        );
    end;
  end else
  begin
    // not connected, onaccept allow is false
    FOwner.releaseClientContext(Self)
  end;
end;
{$ENDIF}


procedure TIocpClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode:
    WORD);
begin
    
end;

procedure TIocpClientContext.PostNextSendRequest;
begin
  CheckNextSendRequest;
end;

function TIocpClientContext.InnerPostSendRequestAndCheckStart(
    pvSendRequest:TIocpSendRequest): Boolean;
var
  lvStart:Boolean;
begin
  lvStart := false;
  FContextLocker.lock();
  try
    Result := FSendRequestLink.Push(pvSendRequest);
    if Result then
    begin
      if not FSending then
      begin
        FSending := true;
        lvStart := true;  // start send work
      end;
    end;
  finally
    FContextLocker.unLock;
  end;

  {$IFDEF WRITE_LOG}
  if not Result then
  begin
    FOwner.logMessage(
      strSendPushFail, [FSocketHandle, FSendRequestLink.Count, FSendRequestLink.MaxSize]);
  end;
  {$ENDIF}

  if lvStart then
  begin      // start send work
    if (FOwner<> nil) and (FOwner.FDataMoniter <> nil) then
    begin
      FOwner.FDataMoniter.incPushSendQueueCounter;
    end;
    CheckNextSendRequest;
  end;
end;

procedure TIocpClientContext.PostWSACloseRequest;
begin
  PostWSASendRequest(nil, 0, dtNone, -1);
end;

procedure TIocpClientContext.PostWSARecvRequest;
begin
  FRecvRequest.PostRequest;
end;



function TIocpClientContext.PostWSASendRequest(buf: Pointer; len: Cardinal;
    pvCopyBuf: Boolean = true; pvTag: Integer = 0; pvTagData: Pointer = nil):
    Boolean;
var
  lvBuf: PAnsiChar;
begin
  if len = 0 then raise Exception.Create('PostWSASendRequest::request buf is zero!');
  if pvCopyBuf then
  begin
    GetMem(lvBuf, len);
    Move(buf^, lvBuf^, len);
    Result := PostWSASendRequest(lvBuf, len, dtFreeMem, pvTag, pvTagData);
    if not Result then
    begin            //post fail
      FreeMem(lvBuf);
    end;
  end else
  begin
    lvBuf := buf;
    Result := PostWSASendRequest(lvBuf, len, dtNone, pvTag, pvTagData);
  end;

end;

function TIocpClientContext.PostWSASendRequest(buf: Pointer; len: Cardinal;
    pvBufReleaseType: TDataReleaseType; pvTag: Integer = 0; pvTagData: Pointer
    = nil): Boolean;
var
  lvRequest:TIocpSendRequest;
begin
  Result := false;
  if self.Active then
  begin
    if self.IncReferenceCounter('PostWSASendRequest', Self) then
    begin
      try
        lvRequest := GetSendRequest;
        lvRequest.SetBuffer(buf, len, pvBufReleaseType);
        lvRequest.Tag := pvTag;
        lvRequest.Data := pvTagData;
        Result := InnerPostSendRequestAndCheckStart(lvRequest);
        if not Result then
        begin
          /// Push Fail unbinding buf
          lvRequest.UnBindingSendBuffer;
          Self.RequestDisconnect('TIocpClientContext.PostWSASendRequest Post Fail',
            lvRequest);
          FOwner.ReleaseSendRequest(lvRequest);
        end;
      finally
        self.DecReferenceCounter('PostWSASendRequest', Self);
      end;
    end;
  end;
end;



procedure TIocpClientContext.SetDebugInfo(const Value: string);
begin
  FContextLocker.lock();
  FDebugInfo := Value;
  FContextLocker.unLock();
end;

procedure TIocpClientContext.SetOwner(const Value: TDiocpTcpServer);
begin
  FOwner := Value;
  FRecvRequest.FOwner := FOwner;
  {$IFDEF SOCKET_REUSE}
  FDisconnectExRequest.FOwner := FOwner;
  {$ENDIF}
end;

procedure TIocpClientContext.SetSocketState(pvState:TSocketState);
begin
  FSocketState := pvState;
//  if Assigned(FOnSocketStateChanged) then
//  begin
//    FOnSocketStateChanged(Self);
//  end;
end;

procedure TIocpClientContext.unLock;
begin
  FContextLocker.unLock;
end;


procedure TDiocpTcpServer.AddToOnlineList(pvObject: TIocpClientContext);
begin
  FLocker.lock('AddToOnlineList');
  try
    FOnlineContextList.Add(pvObject.FSocketHandle, pvObject);
  finally
    FLocker.unLock;
  end; 
end;

function TDiocpTcpServer.checkClientContextValid(const pvClientContext: TIocpClientContext): Boolean;
begin
  Result := (pvClientContext.FOwner = Self);
end;

procedure TDiocpTcpServer.Close;
begin
  SetActive(False);
end;

constructor TDiocpTcpServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContextDNA := 0;
  FLocker := TIocpLocker.Create('diocp.tcp.server');
  FLogger:=TSafeLogger.Create();
  FLogger.setAppender(TLogFileAppender.Create(True));

  // Ĭ�ϲ���������ѡ��
  FKeepAlive := False;
  
  FContextPool := TBaseQueue.Create;
  FSendRequestPool := TBaseQueue.Create;
    
  FIocpEngine := TIocpEngine.Create();

  FOnlineContextList := TDHashTable.Create(10949);

  FListenSocket := TRawSocket.Create;

  FMaxSendingQueueSize := 100;

  FIocpAcceptorMgr := TIocpAcceptorMgr.Create(Self, FListenSocket);
  FIocpAcceptorMgr.FMaxRequest := 100;
  FIocpAcceptorMgr.FMinRequest := 30;

  // post wsaRecv block size
  FWSARecvBufferSize := 1024 * 4;

  {$IFDEF DEBUG_ON}

  {$ELSE}
  FLogger.LogFilter := [lgvError];
  {$ENDIF}
end;

destructor TDiocpTcpServer.Destroy;
begin
  FLogger.Enable := false;

  FIsDestroying := true;

  SafeStop;

  if FDataMoniter <> nil then FDataMoniter.Free;

  FContextPool.FreeDataObject;

  FSendRequestPool.FreeDataObject;

  FListenSocket.Free;
  FIocpAcceptorMgr.Free;
  FIocpEngine.Free;

  FOnlineContextList.Free;

  FContextPool.Free;
  FSendRequestPool.Free;

  FLogger.Free;

  FLocker.Free;
  inherited Destroy;
end;



procedure TDiocpTcpServer.DisconnectAll;
var
  I:Integer;
  lvBucket: PDHashData;
  lvClientContext:TIocpClientContext;
begin
  FLocker.lock('DisconnectAll');
  try
    for I := 0 to FOnlineContextList.BucketSize - 1 do
    begin
      lvBucket := FOnlineContextList.Buckets[I];
      while lvBucket<>nil do
      begin
        lvClientContext := TIocpClientContext(lvBucket.Data);
        if lvClientContext <> nil then
        begin
          lvClientContext.RequestDisconnect;
        end;
        lvBucket:=lvBucket.Next;
      end;
    end;
  finally
    FLocker.unLock;
  end;
end;


function TDiocpTcpServer.LogCanWrite: Boolean;
begin
  Result := (not isDestroying) and FLogger.Enable;
end;


procedure TDiocpTcpServer.LogMessage(pvMsg: string; const args: array of const;
    pvMsgType: string = ''; pvLevel: TLogLevel = lgvMessage);
begin
  if LogCanWrite then
  begin
    FLogger.logMessage(pvMsg, args, pvMsgType, pvLevel);
  end;
end;

procedure TDiocpTcpServer.LogMessage(pvMsg: string; pvMsgType: string = '';
    pvLevel: TLogLevel = lgvMessage);
begin
  if LogCanWrite then
  begin
    FLogger.logMessage(pvMsg, pvMsgType, pvLevel);
  end;
end;

procedure TDiocpTcpServer.DoAcceptExResponse(pvRequest: TIocpAcceptExRequest);

{$IFDEF SOCKET_REUSE}
var
  lvErrCode:Integer;
{$ELSE}
var
  lvRet:Integer;
  lvErrCode:Integer;
{$ENDIF}
  function DoAfterAcceptEx():Boolean;
  begin
    Result := true;
    if Assigned(FOnContextAccept) then
    begin
      FOnContextAccept(pvRequest.FClientContext.RawSocket.SocketHandle,
         pvRequest.FClientContext.RemoteAddr, pvRequest.FClientContext.RemotePort, Result);

      if not Result then
      begin
        {$IFDEF WRITE_LOG}
        logMessage('OnAcceptEvent vAllowAccept = false');
        {$ENDIF}
      end;
    end;
    if Result then
    begin
      if FKeepAlive then
      begin
        Result := SetKeepAlive(pvRequest.FClientContext.FRawSocket.SocketHandle, 10000);
        if not Result then
        begin
          lvErrCode := GetLastError;
          {$IFDEF WRITE_LOG}
          logMessage('FClientContext.FRawSocket.setKeepAliveOption, Error:%d', [lvErrCode]);
          {$ENDIF}
        end;
      end;
    end;

  end;
begin
  if pvRequest.FErrorCode = 0 then
  begin
    if DoAfterAcceptEx then
    begin
     {$IFDEF SOCKET_REUSE}
      pvRequest.FClientContext.DoConnected;
     {$ELSE}
      lvRet := FIocpEngine.IocpCore.Bind2IOCPHandle(
         pvRequest.FClientContext.FRawSocket.SocketHandle, 0);
      if lvRet = 0 then
      begin     // binding error
        lvErrCode := GetLastError;

        {$IFDEF WRITE_LOG}
        logMessage(
            'bind2IOCPHandle(%d) in TDiocpTcpServer.DoAcceptExResponse occur Error :%d',
            [pvRequest.FClientContext.RawSocket.SocketHandle, lvErrCode]);
        {$ENDIF}

        DoClientContextError(pvRequest.FClientContext, lvErrCode);

        pvRequest.FClientContext.FRawSocket.Close;

        // relase client context object
        ReleaseClientContext(pvRequest.FClientContext);
        pvRequest.FClientContext := nil;
      end else
      begin
        pvRequest.FClientContext.DoConnected;
      end;
      {$ENDIF}
    end else
    begin
     {$IFDEF SOCKET_REUSE}
      pvRequest.FClientContext.FRawSocket.ShutDown;

      // post disconnectEx
      pvRequest.FClientContext.FDisconnectExRequest.DirectlyPost;
      pvRequest.FClientContext := nil;
     {$ELSE}
      pvRequest.FClientContext.FRawSocket.Close;

      // return to pool
      ReleaseClientContext(pvRequest.FClientContext);
      pvRequest.FClientContext := nil;
      {$ENDIF}
    end;
  end else
  begin
   {$IFDEF SOCKET_REUSE}
    
   {$ELSE}
    pvRequest.FClientContext.RawSocket.Close;
   {$ENDIF}
    // �黹�����������ĳ�
    ReleaseClientContext(pvRequest.FClientContext);
    pvRequest.FClientContext := nil;
  end;

  // ������������б����Ƴ�
  FIocpAcceptorMgr.RemoveRequestObject(pvRequest);

  if FActive then FIocpAcceptorMgr.CheckPostRequest;
end;

procedure TDiocpTcpServer.DoClientContextError(pvClientContext:
    TIocpClientContext; pvErrorCode: Integer);
begin
  if Assigned(FOnContextError) then
    FOnContextError(pvClientContext, pvErrorCode);
end;

procedure TDiocpTcpServer.DoReceiveData(pvIocpClientContext:TIocpClientContext;
    pvRequest:TIocpRecvRequest);
begin
  if Assigned(FOnDataReceived) then
    FOnDataReceived(pvIocpClientContext,
      pvRequest.FRecvBuffer.buf, pvRequest.FBytesTransferred,
      pvRequest.FErrorCode);
end;

function TDiocpTcpServer.FindContext(pvSocketHandle:TSocket):
    TIocpClientContext;
{$IFDEF USE_HASHTABLE}

{$ELSE}
var
  lvHash:Integer;
  lvObj:TIocpClientContext;
{$ENDIF}
begin
  FLocker.lock('FindContext');
  try
    {$IFDEF USE_HASHTABLE}
    Result := TIocpClientContext(FOnlineContextList.FindFirstData(pvSocketHandle));
    {$ELSE}
    Result := nil;
    lvHash := pvSocketHandle and SOCKET_HASH_SIZE;
    lvObj := FClientsHash[lvHash];
    while lvObj <> nil do
    begin
      if lvObj.FRawSocket.SocketHandle = pvSocketHandle then
      begin
        Result := lvObj;
        break;
      end;
      lvObj := lvObj.FNextForHash;
    end;
    {$ENDIF}
  finally
    FLocker.unLock;
  end;
end;

function TDiocpTcpServer.GetClientContext: TIocpClientContext;
begin
  Result := TIocpClientContext(FContextPool.DeQueue);
  if Result = nil then
  begin
    if FClientContextClass <> nil then
    begin
      Result := FClientContextClass.Create;
      OnCreateClientContext(Result);
    end else
    begin
      Result := TIocpClientContext.Create;
      OnCreateClientContext(Result);
    end;
    if (FDataMoniter <> nil) then
    begin
      InterlockedIncrement(FDataMoniter.FContextCreateCounter);
    end;
    Result.FSendRequestLink.SetMaxSize(FMaxSendingQueueSize);
  end;
  Result.FAlive := True;
  Result.DoCleanUp;
  Result.Owner := Self;
  if (FDataMoniter <> nil) then
  begin
    InterlockedIncrement(FDataMoniter.FContextOutCounter);
  end;
end;

function TDiocpTcpServer.GetWorkerCount: Integer;
begin
  Result := FIocpEngine.WorkerCount;
end;

function TDiocpTcpServer.isDestroying: Boolean;
begin
  Result := FIsDestroying or (csDestroying in self.ComponentState)
end;

procedure TDiocpTcpServer.OnCreateClientContext(const context:
    TIocpClientContext);
begin

end;

procedure TDiocpTcpServer.Open;
begin
  SetActive(true);
end;

procedure TDiocpTcpServer.RegisterContextClass(pvContextClass:
    TIocpClientContextClass);
begin
  FClientContextClass := pvContextClass;
end;

procedure TDiocpTcpServer.RegisterSendRequestClass(pvClass:
    TIocpSendRequestClass);
begin
  FIocpSendRequestClass := pvClass;
end;

function TDiocpTcpServer.ReleaseClientContext(pvObject:TIocpClientContext):
    Boolean;
begin
  if lock_cmp_exchange(True, False, pvObject.FAlive) = true then
  begin
    pvObject.DoCleanUp;
    FContextPool.EnQueue(pvObject);
    if (FDataMoniter <> nil) then
    begin
      InterlockedIncrement(FDataMoniter.FContextReturnCounter);
    end;
    Result := true;
  end else
  begin
    Result := false;
  end;
end;

function TDiocpTcpServer.ReleaseSendRequest(pvObject:TIocpSendRequest): Boolean;
begin
  if self = nil then
  begin
    Assert(False);
  end;
  if FSendRequestPool = nil then
  begin
    // check call stack is crash
    Assert(FSendRequestPool <> nil);
  end;

  if IsDebugMode then
  begin
    Assert(pvObject.FAlive)
  end;

  if lock_cmp_exchange(True, False, pvObject.FAlive) = True then
  begin
    if (FDataMoniter <> nil) then
    begin
      InterlockedIncrement(FDataMoniter.FSendRequestReturnCounter);
    end;
    pvObject.DoCleanUp;
    FSendRequestPool.EnQueue(pvObject);
    Result := true;
  end else
  begin
    Result := false;
  end;
end;

procedure TDiocpTcpServer.RemoveFromOnOnlineList(pvObject: TIocpClientContext);
{$IFDEF USE_HASHTABLE}
  {$IFDEF DEBUG_ON}
    var
      lvSucc:Boolean;
  {$ENDIF}
{$ELSE}
var
  lvHash:Integer;
{$ENDIF}
begin
{$IFDEF USE_HASHTABLE}
  FLocker.lock('RemoveFromOnOnlineList');
  try
    {$IFDEF DEBUG_ON}
    lvSucc := FOnlineContextList.DeleteFirst(pvObject.FSocketHandle);
    Assert(lvSucc);
    {$ELSE}
    FOnlineContextList.DeleteFirst(pvObject.FSocketHandle);
    {$ENDIF}                                               
  finally
    FLocker.unLock;
  end;
{$ELSE} 
  FOnlineContextList.remove(pvObject);

  FLocker.lock('RemoveFromOnOnlineList');
  try
    // hash
    if pvObject.FPreForHash <> nil then
    begin
      pvObject.FPreForHash.FNextForHash := pvObject.FNextForHash;
      if pvObject.FNextForHash <> nil then
        pvObject.FNextForHash.FPreForHash := pvObject.FPreForHash;
    end else
    begin     // first ele
      lvHash := pvObject.RawSocket.SocketHandle and SOCKET_HASH_SIZE;
      FClientsHash[lvHash] := pvObject.FNextForHash;
      if FClientsHash[lvHash] <> nil then
        FClientsHash[lvHash].FPreForHash := nil;
    end;
  finally
    FLocker.unLock;
  end;

  pvObject.FNextForHash := nil;
  pvObject.FPreForHash := nil;
{$ENDIF}

end;

function TDiocpTcpServer.RequestContextDNA: Integer;
begin
  Result := InterlockedIncrement(FContextDNA);
end;

procedure TDiocpTcpServer.SafeStop;
begin
  if FActive then
  begin
    FActive := false;



    // Close listen socket
    FListenSocket.Close;


    DisconnectAll;

    // �ȵ����е�Ͷ�ݵ�AcceptEx����ع�
    // ��л Xjumping  990669769, ����bug
    FIocpAcceptorMgr.WaitForCancel(12000);

    if not WaitForContext(120000) then
    begin  // wait time out
      Sleep(10);

      // stop workers 10's
      if not FIocpEngine.StopWorkers(10000) then
      begin        // record info
        SafeWriteFileMsg('EngineWorkerInfo:' +
           sLineBreak + FIocpEngine.GetStateINfo + sLineBreak +
           '================================================' + sLineBreak +
           'TcpServerInfo:' +
           sLineBreak + GetStateINfo, Self.Name + '_SafeStopTimeOut');
      end;

    end else
    begin    // all context is give back to pool
      if not FIocpEngine.StopWorkers(120000) then
      begin        // record info
        SafeWriteFileMsg('EngineWorkerInfo:' +
           sLineBreak + FIocpEngine.GetStateINfo + sLineBreak +
           '================================================' + sLineBreak +
           'TcpServerInfo:' +
           sLineBreak + GetStateINfo, Self.Name + '_SafeStopTimeOut');
      end;
    end;

    FIocpAcceptorMgr.FAcceptExRequestPool.FreeDataObject;
    FIocpAcceptorMgr.FAcceptExRequestPool.Clear;

    FContextPool.FreeDataObject;
    FContextPool.Clear;

    FSendRequestPool.FreeDataObject;
    FSendRequestPool.Clear;

    // engine stop
    FIocpEngine.SafeStop();


  end; 
end;

procedure TDiocpTcpServer.SetActive(pvActive:Boolean);
begin
  if pvActive <> FActive then
  begin
    if pvActive then
    begin
      if FDataMoniter <> nil then FDataMoniter.clear;
      
      // ����IOCP����
      FIocpEngine.CheckStart;
      
      // �����������׽���
      FListenSocket.CreateTcpOverlappedSocket;

//       FListenSocket.CreateTcpSocket;

      // �������˿�
      if not FListenSocket.Bind('', FPort) then
      begin
        RaiseLastOSError;
      end;

      // ��������
      if not FListenSocket.listen() then
      begin
        RaiseLastOSError;
      end;

      // �������׽��ְ󶨵�IOCP���
      FIocpEngine.IocpCore.Bind2IOCPHandle(FListenSocket.SocketHandle, 0);

//
//      FIocpAcceptorMgr.FMinRequest := 10;
//      FIocpAcceptorMgr.FMaxRequest := 100;

      // post AcceptEx request
      FIocpAcceptorMgr.CheckPostRequest;

      FActive := True;
    end else
    begin
      SafeStop;
    end;
  end;
end;

procedure TDiocpTcpServer.SetMaxSendingQueueSize(pvSize:Integer);
begin
  if pvSize <= 0 then
  begin
    FMaxSendingQueueSize := 10;
  end else
  begin
    FMaxSendingQueueSize := pvSize;
  end;
end;

procedure TDiocpTcpServer.SetName(const NewName: TComponentName);
begin
  inherited;
  if FLogger.Appender is TLogFileAppender then
  begin
    if NewName <> '' then
    begin
      TLogFileAppender(FLogger.Appender).FilePreFix := NewName + '_';
    end;
  end;
end;

procedure TDiocpTcpServer.SetWorkerCount(const Value: Integer);
begin
  FIocpEngine.SetWorkerCount(Value);
end;

procedure TDiocpTcpServer.CreateDataMonitor;
begin
  if FDataMoniter = nil then
  begin
    FDataMoniter := TIocpDataMonitor.Create;
  end;
end;

function TDiocpTcpServer.GetClientCount: Integer;
begin
  Result := FOnlineContextList.Count;
end;

procedure TDiocpTcpServer.GetOnlineContextList(pvList:TList);
var
  I:Integer;
  lvBucket: PDHashData;
begin
  FLocker.lock('GetOnlineContextList');
  try
    for I := 0 to FOnlineContextList.BucketSize - 1 do
    begin
      lvBucket := FOnlineContextList.Buckets[I];
      while lvBucket<>nil do
      begin
        if lvBucket.Data <> nil then
        begin
           pvList.Add(lvBucket.Data);
        end;
        lvBucket:=lvBucket.Next;
      end;
    end;
  finally
    FLocker.unLock;
  end;

end;

function TDiocpTcpServer.GetSendRequest: TIocpSendRequest;
begin
  if Self = nil then
  begin
    if IsDebugMode then
    begin
      Assert(Self <> nil)
    end;
    Result := nil;
    Exit;
  end;
  Result := TIocpSendRequest(FSendRequestPool.DeQueue);
  if Result = nil then
  begin
    if FIocpSendRequestClass <> nil then
    begin
      Result := FIocpSendRequestClass.Create;
    end else
    begin
      Result := TIocpSendRequest.Create;
    end;
    if (FDataMoniter <> nil) then
    begin
      InterlockedIncrement(FDataMoniter.FSendRequestCreateCounter);
    end;
  end;
  Result.Tag := 0;
  Result.FAlive := true;
  //Result.DoCleanup;
  Result.FOwner := Self;
  if (FDataMoniter <> nil) then
  begin
    InterlockedIncrement(FDataMoniter.FSendRequestOutCounter);
  end;
end;

function TDiocpTcpServer.GetStateInfo: String;
var
  lvStrings:TStrings;
begin
  Result := '';
  if FDataMoniter = nil then exit;
  lvStrings := TStringList.Create;
  try
    if Active then
    begin
      lvStrings.Add(strState_Active);
    end else
    begin
      lvStrings.Add(strState_Off);
    end;


    lvStrings.Add(Format(strRecv_PostInfo,
         [
           DataMoniter.PostWSARecvCounter,
           DataMoniter.ResponseWSARecvCounter,
           DataMoniter.PostWSARecvCounter -
           DataMoniter.ResponseWSARecvCounter
         ]
        ));


    lvStrings.Add(Format(strRecv_SizeInfo, [TransByteSize(DataMoniter.RecvSize)]));


    //  Format('post:%d, response:%d, recvd:%d',
    //     [
    //       FIocpTcpServer.DataMoniter.PostWSARecvCounter,
    //       FIocpTcpServer.DataMoniter.ResponseWSARecvCounter,
    //       FIocpTcpServer.DataMoniter.RecvSize
    //     ]
    //    );

    lvStrings.Add(Format(strSend_Info,
       [
         DataMoniter.PostWSASendCounter,
         DataMoniter.ResponseWSASendCounter,
         DataMoniter.PostWSASendCounter -
         DataMoniter.ResponseWSASendCounter
       ]
      ));

    lvStrings.Add(Format(strSendRequest_Info,
       [
         DataMoniter.SendRequestCreateCounter,
         DataMoniter.SendRequestOutCounter,
         DataMoniter.SendRequestReturnCounter
       ]
      ));

    lvStrings.Add(Format(strSendQueue_Info,
       [
         DataMoniter.PushSendQueueCounter,
         DataMoniter.PostSendObjectCounter,
         DataMoniter.ResponseSendObjectCounter,
         DataMoniter.SendRequestAbortCounter
       ]
      ));

    lvStrings.Add(Format(strSend_SizeInfo, [TransByteSize(DataMoniter.SentSize)]));

    lvStrings.Add(Format(strAcceptEx_Info,
       [
         DataMoniter.PostWSAAcceptExCounter,
         DataMoniter.ResponseWSAAcceptExCounter
       ]
      ));

    lvStrings.Add(Format(strSocketHandle_Info,
       [
         DataMoniter.HandleCreateCounter,
         DataMoniter.HandleDestroyCounter
       ]
      ));

    lvStrings.Add(Format(strContext_Info,
       [
         DataMoniter.ContextCreateCounter,
         DataMoniter.ContextOutCounter,
         DataMoniter.ContextReturnCounter
       ]
      ));

    lvStrings.Add(Format(strOnline_Info, [ClientCount]));
  
    lvStrings.Add(Format(strWorkers_Info, [WorkerCount]));

    lvStrings.Add(Format(strRunTime_Info, [GetRunTimeINfo]));

    Result := lvStrings.Text;
  finally
    lvStrings.Free;

  end;
end;

procedure TDiocpTcpServer.KickOut(pvTimeOut:Cardinal = 60000);
var
  lvNowTickCount:Cardinal;
  I:Integer;
  lvContext:TIocpClientContext;
{$IFDEF USE_HASHTABLE}
var    
  lvBucket, lvNextBucket: PDHashData;
{$ELSE}
  lvNextContext :TIocpClientContext;
{$ENDIF}
begin
  lvNowTickCount := GetTickCount;
  {$IFDEF USE_HASHTABLE}
  FLocker.lock('KickOut');
  try
    for I := 0 to FOnlineContextList.BucketSize - 1 do
    begin
      lvBucket := FOnlineContextList.Buckets[I];
      while lvBucket<>nil do
      begin
        lvNextBucket := lvBucket.Next;
        if lvBucket.Data <> nil then
        begin
          lvContext := TIocpClientContext(lvBucket.Data);
          if lvContext.FLastActivity <> 0 then
          begin
            if tick_diff(lvContext.FLastActivity, lvNowTickCount) > pvTimeOut then
            begin
              // ����ر�
              lvContext.PostWSACloseRequest();
            end;
          end;
        end;
        lvBucket:= lvNextBucket;
      end;
    end;
  finally
    FLocker.unLock;
  end;
  {$ELSE}
  FLocker.lock('KickOut');
  try
    lvContext := FOnlineContextList.FHead;

    // request all context discounnt
    while lvContext <> nil do
    begin
      lvNextContext := lvContext.FNext;
      if lvContext.FLastActivity <> 0 then
      begin
        if tick_diff(lvContext.FLastActivity, lvNowTickCount) > pvTimeOut then
        begin
          // ����ر�
          lvContext.PostWSACloseRequest();
        end;
      end;
      lvContext := lvNextContext;
    end;
  finally
    FLocker.unLock;
  end;
  {$ENDIF}
end;

procedure TDiocpTcpServer.SetWSARecvBufferSize(const Value: cardinal);
begin
  FWSARecvBufferSize := Value;
  if FWSARecvBufferSize = 0 then
  begin
    FWSARecvBufferSize := 1024 * 4;
  end;
end;

function TDiocpTcpServer.WaitForContext(pvTimeOut: Cardinal): Boolean;
var
  l:Cardinal;
  c:Integer;
begin
  l := GetTickCount;
  c := FOnlineContextList.Count;
  while (c > 0) do
  begin
    {$IFDEF MSWINDOWS}
    SwitchToThread;
    {$ELSE}
    TThread.Yield;
    {$ENDIF}

    if GetTickCount - l > pvTimeOut then
    begin
      {$IFDEF WRITE_LOG}
      logMessage('WaitForContext End Current Online num:%d', [c], CORE_LOG_FILE, lgvError);
      {$ENDIF}
      Break;
    end;
    c := FOnlineContextList.Count;
  end;

  Result := FOnlineContextList.Count = 0;
end;

procedure TIocpAcceptorMgr.CancelAllRequest;
var
  i:Integer;
  lvRequest:TIocpAcceptExRequest;
begin
  FLocker.lock();
  try
    for i := 0 to FList.Count - 1 do
    begin
      lvRequest := TIocpAcceptExRequest(FList[i]);
      lvRequest.FClientContext.RawSocket.CancelIO;
    end;
  finally
    FLocker.unLock;
  end;
end;

procedure TIocpAcceptorMgr.CheckPostRequest;
var
  lvRequest:TIocpAcceptExRequest;
  i:Integer;
begin
  Assert(FOwner <> nil);
  FLocker.lock;
  try
    if FList.Count > FMinRequest then Exit;

    i := 0;
    // post request
    while FList.Count < FMaxRequest do
    begin
      lvRequest := GetRequestObject;
      lvRequest.FClientContext := FOwner.GetClientContext;
      lvRequest.FAcceptorMgr := self;
      if lvRequest.PostRequest then
      begin
        FList.Add(lvRequest);
        if (FOwner.FDataMoniter <> nil) then
        begin
          InterlockedIncrement(FOwner.FDataMoniter.FPostWSAAcceptExCounter);
        end;
      end else
      begin     // post fail
        Inc(i);

        try
          // �����쳣��ֱ���ͷ�Context
          lvRequest.FClientContext.RawSocket.Close;
          lvRequest.FClientContext.FAlive := false;
          lvRequest.FClientContext.Free;
          lvRequest.FClientContext := nil;
        except
        end;

        // �黹�������
        ReleaseRequestObject(lvRequest);

        if i > 100 then
        begin    // Ͷ��ʧ�ܴ�������100 ��¼��־,������Ͷ��
           FOwner.logMessage('TIocpAcceptorMgr.CheckPostRequest errCounter:%d', [i], CORE_LOG_FILE);
           Break;
        end;
        
      end;


    end;
  finally
    FLocker.unLock;
  end;
end;

constructor TIocpAcceptorMgr.Create(AOwner: TDiocpTcpServer; AListenSocket:
    TRawSocket);
begin
  inherited Create;
  FLocker := TIocpLocker.Create();
  FLocker.Name := 'acceptorLocker';
  FMaxRequest := 200;
  FMinRequest := 10;  
  FList := TList.Create;
  FOwner := AOwner;
  FListenSocket := AListenSocket;

  FAcceptExRequestPool := TBaseQueue.Create;
end;

destructor TIocpAcceptorMgr.Destroy;
begin
  FAcceptExRequestPool.FreeDataObject;
  FList.Free;
  FLocker.Free;
  FAcceptExRequestPool.Free;
  inherited Destroy;
end;

function TIocpAcceptorMgr.GetRequestObject: TIocpAcceptExRequest;
begin
  Result := TIocpAcceptExRequest(FAcceptExRequestPool.DeQueue);
  if Result = nil then
  begin
    Result := TIocpAcceptExRequest.Create(FOwner);
    if (FOwner.FDataMoniter <> nil) then
      FOwner.DataMoniter.IncAcceptExObjectCounter;
  end;
end;

procedure TIocpAcceptorMgr.ReleaseRequestObject(pvRequest:TIocpAcceptExRequest);
begin
  FAcceptExRequestPool.EnQueue(pvRequest);
end;

procedure TIocpAcceptorMgr.RemoveRequestObject(pvRequest:TIocpAcceptExRequest);
begin
  FLocker.lock;
  try
    FList.Remove(pvRequest);
  finally
    FLocker.unLock;
  end;
end;

function TIocpAcceptorMgr.WaitForCancel(pvTimeOut: Cardinal): Boolean;
var
  l:Cardinal;
  c:Integer;
begin
  l := GetTickCount;
  c := FList.Count;
  while (c > 0) do
  begin
    {$IFDEF MSWINDOWS}
    SwitchToThread;
    {$ELSE}
    TThread.Yield;
    {$ENDIF}

    if GetTickCount - l > pvTimeOut then
    begin
      {$IFDEF WRITE_LOG}
      FOwner.logMessage('WaitForCancel End Current AccepEx num:%d', [c], CORE_LOG_FILE, lgvError);
      {$ENDIF}
      Break;
    end;
    c := FList.Count;
  end;

  Result := FList.Count = 0;
end;

constructor TIocpAcceptExRequest.Create(AOwner: TDiocpTcpServer);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TIocpAcceptExRequest.GetPeerINfo;
var
  localAddr: PSockAddr;
  remoteAddr: PSockAddr;
  localAddrSize : Integer;
  remoteAddrSize : Integer;
begin
  localAddrSize := SizeOf(TSockAddr) + 16;
  remoteAddrSize := SizeOf(TSockAddr) + 16;
  IocpGetAcceptExSockaddrs(@FAcceptBuffer[0],
                        0,
                        SizeOf(localAddr^) + 16,
                        SizeOf(remoteAddr^) + 16,
                        localAddr,
                        localAddrSize,
                        remoteAddr,
                        remoteAddrSize);

  FClientContext.FRemoteAddr := string(inet_ntoa(TSockAddrIn(remoteAddr^).sin_addr));
  FClientContext.FRemotePort := ntohs(TSockAddrIn(remoteAddr^).sin_port);
end;

procedure TIocpAcceptExRequest.HandleResponse;
begin
  Assert(FOwner <> nil);
  ///
  if (FOwner.FDataMoniter <> nil) then
  begin
    InterlockedIncrement(FOwner.FDataMoniter.FResponseWSAAcceptExCounter);
  end;

  if FErrorCode = 0 then
  begin
    // msdn
    // The socket sAcceptSocket does not inherit the properties of the socket
    //  associated with sListenSocket parameter until SO_UPDATE_ACCEPT_CONTEXT
    //  is set on the socket.
    FOwner.FListenSocket.UpdateAcceptContext(FClientContext.FRawSocket.SocketHandle);

    GetPeerINfo();
  end;
  FOwner.DoAcceptExResponse(Self); 
end;

function TIocpAcceptExRequest.PostRequest: Boolean;
var
  dwBytes: Cardinal;
  lvRet:BOOL;
  lvErrCode:Integer;
  lp:POverlapped;
  {$IFDEF SOCKET_REUSE}
  lvRetCode:Integer;
  {$ENDIF}
begin
  {$IFDEF SOCKET_REUSE}
  if
    (FClientContext.FRawSocket.SocketHandle = INVALID_SOCKET)
    or
    (FClientContext.FRawSocket.SocketHandle = 0) then
  begin
    if (FOwner.FDataMoniter <> nil) then
      FOwner.FDataMoniter.incHandleCreateCounter;

    FClientContext.FRawSocket.CreateTcpOverlappedSocket;

    lvRetCode := FOwner.IocpEngine.IocpCore.Bind2IOCPHandle(
      FClientContext.FRawSocket.SocketHandle, 0);
    if lvRetCode = 0 then
    begin     // binding error
      lvErrCode := GetLastError;
      FOwner.logMessage(
         Format(strBindingIocpError,
           [FClientContext.FRawSocket.SocketHandle, lvErrCode, 'TIocpAcceptExRequest.PostRequest(SOCKET_REUSE)'])
         , CORE_LOG_FILE);

      FClientContext.FRawSocket.close;
      if (FOwner.FDataMoniter <> nil) then
        FOwner.FDataMoniter.incHandleDestroyCounter;
      Result := false;
      Exit;
    end;
  end;
  {$ELSE}
  FClientContext.FRawSocket.CreateTcpOverlappedSocket;
  {$ENDIF}
  dwBytes := 0;
  lp := @FOverlapped;

  FClientContext.SetSocketState(ssAccepting);

  lvRet := IocpAcceptEx(FOwner.FListenSocket.SocketHandle
                , FClientContext.FRawSocket.SocketHandle
                , @FAcceptBuffer[0]
                , 0
                , SizeOf(TSockAddrIn) + 16
                , SizeOf(TSockAddrIn) + 16
                , dwBytes
                , lp);
  if not lvRet then
  begin
    lvErrCode := WSAGetLastError;
    Result := lvErrCode = WSA_IO_PENDING;
    if not Result then
    begin 
      FOwner.logMessage(
         Format(strBindingIocpError,
           [FClientContext.FRawSocket.SocketHandle, lvErrCode, 'TIocpAcceptExRequest.PostRequest'])
         , CORE_LOG_FILE);

      FOwner.DoClientContextError(FClientContext, lvErrCode);

      /// destroy socket
      FClientContext.RawSocket.close;
    end;
  end else
  begin
    Result := True;
  end;
end;

procedure TIocpAcceptExRequest.ResponseDone;
begin
  inherited;
  FAcceptorMgr.ReleaseRequestObject(Self);
end;

constructor TIocpRecvRequest.Create;
begin
  inherited Create;
end;

destructor TIocpRecvRequest.Destroy;
begin
  if FInnerBuffer.len > 0 then
  begin
    FreeMem(FInnerBuffer.buf, FInnerBuffer.len);
  end;
  inherited Destroy;
end;

procedure TIocpRecvRequest.HandleResponse;
var
  lvDNACounter:Integer;
  lvDebugInfo:String;
  lvRefCount:Integer;
begin
  lvDNACounter := Self.FCounter;

  {$IFDEF DEBUG_ON}
  InterlockedDecrement(FOverlapped.RefCount);
  if FOverlapped.RefCount <> 0 then
  begin        // ���ü����쳣
    if IsDebugMode then
    begin
      Assert(FOverlapped.RefCount <>0);
    end;
    {$IFDEF WRITE_LOG}
    FOwner.logMessage(strRecvResponseErr,
        [Integer(self.FClientContext), Integer(Self), FOverlapped.RefCount],
        CORE_LOG_FILE, lgvError);
    {$ENDIF}
  end;
  {$ENDIF}

  Assert(FOwner <> nil);
  try
    if (FOwner.FDataMoniter <> nil) then
    begin
      FOwner.FDataMoniter.incResponseWSARecvCounter;
      FOwner.FDataMoniter.incRecvdSize(FBytesTransferred);
    end;

    if not FOwner.Active then
    begin
      {$IFDEF WRITE_LOG}
      FOwner.logMessage(
          Format(strRecvEngineOff, [FClientContext.FSocketHandle])
        );
      {$ENDIF}
      // ��������ظ�Ͷ�ݽ�������
      FClientContext.RequestDisconnect(
        Format(strRecvEngineOff, [FClientContext.FSocketHandle])
        , Self);
    end else if FErrorCode <> 0 then
    begin
      if not FClientContext.FRequestDisconnect then
      begin   // �������رգ����������־,�ʹ�������
        {$IFDEF WRITE_LOG}
        FOwner.logMessage(
          Format(strRecvError, [FClientContext.FSocketHandle, FErrorCode])
          );
        {$ENDIF}
        FOwner.DoClientContextError(FClientContext, FErrorCode);
        FClientContext.RequestDisconnect(
          Format(strRecvError, [FClientContext.FSocketHandle, FErrorCode])
          ,  Self);
      end;
    end else if (FBytesTransferred = 0) then
    begin      // no data recvd, socket is break
      if not FClientContext.FRequestDisconnect then
      begin
        FClientContext.RequestDisconnect(
          Format(strRecvZero,  [FClientContext.FSocketHandle]),  Self);
      end;
    end else
    begin
      FClientContext.DoReceiveData;
    end;
  finally
    lvDebugInfo := FDebugInfo;
    lvRefCount := FOverlapped.RefCount;
    
    // PostWSARecv before decReferenceCounter
    if not FClientContext.FRequestDisconnect then
    begin
      FClientContext.PostWSARecvRequest;
    end;

    // may return to pool
    FClientContext.decReferenceCounter(
      Format('TIocpRecvRequest.WSARecvRequest.HandleResponse, DNACounter:%d, debugInfo:%s, refcount:%d',
        [lvDNACounter, lvDebugInfo, lvRefCount]), Self);

//  for debug context DebugStrings
//    if FClientContext.FRequestDisconnect then
//    begin
//      lvBreak := true;
//    end else
//    begin
//      lvBreak := False
//    end;
//    // may return to pool
//    FClientContext.decReferenceCounter(
//      Format('TIocpRecvRequest.WSARecvRequest.HandleResponse, DNACounter:%d, debugInfo:%s, refcount:%d',
//        [lvDNACounter, FDebugInfo, FOverlapped.refCount]), Self);
//    if lvBreak then
//    begin
//      FClientContext.PostWSARecvRequest;
//    end;

  end;
end;

function TIocpRecvRequest.PostRequest(pvBuffer: PAnsiChar;
  len: Cardinal): Boolean;
var
  lvRet, lvDNACounter:Integer;
  lpNumberOfBytesRecvd: Cardinal;
begin
  Result := False;
  lpNumberOfBytesRecvd := 0;
  FRecvdFlag := 0;

  FRecvBuffer.buf := pvBuffer;
  FRecvBuffer.len := len;
  lvDNACounter := InterlockedIncrement(FCounter);
  if FClientContext.incReferenceCounter(Format(
    'TIocpRecvRequest.WSARecvRequest.Post, DNACounter:%d', [lvDNACounter]), Self) then
  begin
    {$IFDEF DEBUG_ON}
    InterlockedIncrement(FOverlapped.refCount);
    {$ENDIF}  
    FDebugInfo := IntToStr(intPtr(FClientContext));
    lvRet := diocp.winapi.winsock2.WSARecv(FClientContext.FRawSocket.SocketHandle,
       @FRecvBuffer,
       1,
       lpNumberOfBytesRecvd,
       FRecvdFlag,
       LPWSAOVERLAPPED(@FOverlapped),   // d7 need to cast
       nil
       );
    if lvRet = SOCKET_ERROR then
    begin
      lvRet := WSAGetLastError;
      Result := lvRet = WSA_IO_PENDING;
      if not Result then
      begin
        {$IFDEF WRITE_LOG}
        FOwner.logMessage(strRecvPostError, [FClientContext.SocketHandle, lvRet]);
        {$ENDIF}
        {$IFDEF DEBUG_ON}
        InterlockedDecrement(FOverlapped.refCount);
        {$ENDIF}



        // trigger error event
        FOwner.DoClientContextError(FClientContext, lvRet);

        // decReferenceCounter
        FClientContext.decReferenceCounterAndRequestDisconnect(
        'TIocpRecvRequest.WSARecvRequest.Error', Self);

      end else
      begin
        if (FOwner <> nil) and (FOwner.FDataMoniter <> nil) then
        begin
          FOwner.FDataMoniter.incPostWSARecvCounter;
        end;
      end;
    end else
    begin
      Result := True;
    
      if (FOwner <> nil) and (FOwner.FDataMoniter <> nil) then
      begin
        FOwner.FDataMoniter.incPostWSARecvCounter;
      end;
    end;   
  end;
end;

function TIocpRecvRequest.PostRequest: Boolean;
begin
  if FInnerBuffer.len <> FOwner.FWSARecvBufferSize then
  begin
    if FInnerBuffer.len > 0 then FreeMem(FInnerBuffer.buf);
    FInnerBuffer.len := FOwner.FWSARecvBufferSize;
    GetMem(FInnerBuffer.buf, FInnerBuffer.len);
  end;
  Result := PostRequest(FInnerBuffer.buf, FInnerBuffer.len);
end;

function TIocpSendRequest.ExecuteSend: Boolean;
begin
  if Tag = -1 then
  begin
    FLastMsg := strWSACloseRequest;
    Result := False;
  end else if (FBuf = nil) or (FLen = 0) then
  begin
    FLastMsg := strWSACloseRequest;
    Result := False;
  end else
  begin
    Result := InnerPostRequest(FBuf, FLen);
  end;

end;

procedure TIocpSendRequest.CheckClearSendBuffer;
begin
  if FLen > 0 then
  begin
    case FSendBufferReleaseType of
      dtDispose: Dispose(FBuf);
      dtFreeMem: FreeMem(FBuf);
    end;
  end;
  FSendBufferReleaseType := dtNone;
  FLen := 0;
end;

constructor TIocpSendRequest.Create;
begin
  inherited Create;
end;

destructor TIocpSendRequest.Destroy;
begin
  CheckClearSendBuffer;
  inherited Destroy;
end;

procedure TIocpSendRequest.DoCleanUp;
begin
  CheckClearSendBuffer;
  FBytesSize := 0;
  FNext := nil;
  FOwner := nil;
  FClientContext := nil;
  FReponseState := 0;


  //FMaxSize := 0;
end;

procedure TIocpSendRequest.HandleResponse;
var
  lvContext:TIocpClientContext;
begin
  lvContext := FClientContext;
  FIsBusying := false;
  try
    Assert(FOwner<> nil);
    if (FOwner.FDataMoniter <> nil) then
    begin                                                       
      FOwner.FDataMoniter.incSentSize(FBytesTransferred);
      FOwner.FDataMoniter.incResponseWSASendCounter;
    end;



    // ��Ӧ����¼�
    lvContext.DoSendRequestRespnonse(Self);

    if not FOwner.Active then
    begin
      FReponseState := 4;
      {$IFDEF WRITE_LOG}
      FOwner.logMessage(
          Format(strSendEngineOff, [FClientContext.FSocketHandle])
          );
      {$ENDIF}
      // avoid postWSARecv
      FClientContext.RequestDisconnect(
        Format(strSendEngineOff, [FClientContext.FSocketHandle])
        , Self);
    end else if FErrorCode <> 0 then
    begin
      FReponseState := 3;

      if not FClientContext.FRequestDisconnect then
      begin   // �������رգ����������־,�ʹ�������
        {$IFDEF WRITE_LOG}
        FOwner.logMessage(
            Format(strSendErr, [FClientContext.FSocketHandle, FErrorCode])
            );
        {$ENDIF}
        FOwner.DoClientContextError(FClientContext, FErrorCode);
        FClientContext.RequestDisconnect(
           Format(strSendErr, [FClientContext.FSocketHandle, FErrorCode])
            , Self);
      end;
    end else
    begin
      FReponseState := 2;
      if FOwner.FDataMoniter <> nil then
      begin
        FOwner.FDataMoniter.incResponseSendObjectCounter;
      end;

      if Assigned(FOnDataRequestCompleted) then
      begin
        FOnDataRequestCompleted(FClientContext, Self);
      end;

      FClientContext.DoSendRequestCompleted(Self);

      FClientContext.PostNextSendRequest;
    end;
  finally
//    if FClientContext = nil then
//    begin
//      Assert(False);
//      FReponseState := lvResponseState;
//    end;
    lvContext.decReferenceCounter('TIocpSendRequest.WSASendRequest.Response', Self);
  end;
end;

function TIocpSendRequest.InnerPostRequest(buf: Pointer; len: Cardinal):
    Boolean;
var
  lvErrorCode, lvRet: Integer;
  dwFlag: Cardinal;
  lpNumberOfBytesSent:Cardinal;
  lvContext:TIocpClientContext;
  lvOwner:TDiocpTcpServer;
begin
  Result := false;
  FIsBusying := True;
  FBytesSize := len;
  FWSABuf.buf := buf;
  FWSABuf.len := len;
  dwFlag := 0;
  lvErrorCode := 0;
  lpNumberOfBytesSent := 0;

  // maybe on HandleResonse and release self
  lvOwner := FOwner;

  lvContext := FClientContext;
  if lvContext.incReferenceCounter('InnerPostRequest::WSASend_Start', self) then
  try
    lvRet := WSASend(lvContext.FRawSocket.SocketHandle,
                      @FWSABuf,
                      1,
                      lpNumberOfBytesSent,
                      dwFlag,
                      LPWSAOVERLAPPED(@FOverlapped),   // d7 need to cast
                      nil
    );
    if lvRet = SOCKET_ERROR then
    begin
      lvErrorCode := WSAGetLastError;
      Result := lvErrorCode = WSA_IO_PENDING;
      if not Result then
      begin
       FIsBusying := False;
       {$IFDEF WRITE_LOG}
       lvOwner.logMessage(
         Format(strSendPostError, [lvContext.FSocketHandle, lvErrorCode])
         );
       {$ENDIF}
        /// request kick out
       lvContext.RequestDisconnect(
          Format(strSendPostError, [lvContext.FSocketHandle, lvErrorCode])
          , Self);
      end else
      begin      // maybe on HandleResonse and release self
        if (lvOwner <> nil) and (lvOwner.FDataMoniter <> nil) then
        begin
          lvOwner.FDataMoniter.incPostWSASendSize(len);
          lvOwner.FDataMoniter.incPostWSASendCounter;
        end;
      end;
    end else
    begin       // maybe on HandleResonse and release self
      Result := True;
      if (lvOwner <> nil) and (lvOwner.FDataMoniter <> nil) then
      begin
        lvOwner.FDataMoniter.incPostWSASendSize(len);
        lvOwner.FDataMoniter.incPostWSASendCounter;
      end;
    end;
  finally
    if not Result then
    begin      // post fail, dec ref, if post succ, response dec ref
      if IsDebugMode then
      begin
        Assert(lvContext = FClientContext);
      end;
      lvContext.decReferenceCounter(
        Format('InnerPostRequest::WSASend_Fail, ErrorCode:%d', [lvErrorCode])
         , Self);

    end;

    // if result is true, maybe on HandleResponse dispose and push back to pool

  end;
end;

procedure TIocpSendRequest.ResponseDone;
begin
  inherited;
  if FOwner = nil then
  begin
    if IsDebugMode then
    begin
      Assert(FOwner <> nil);
      Assert(Self.FAlive);
    end;
  end else
  begin
    FOwner.releaseSendRequest(Self);
  end;
end;

procedure TIocpSendRequest.SetBuffer(buf: Pointer; len: Cardinal;
  pvBufReleaseType: TDataReleaseType);
begin
  CheckClearSendBuffer;
  FBuf := buf;
  FLen := len;
  FSendBufferReleaseType := pvBufReleaseType;
end;

procedure TIocpSendRequest.SetBuffer(buf: Pointer; len: Cardinal; pvCopyBuf: Boolean = true);
var
  lvBuf: PAnsiChar;
begin
  if pvCopyBuf then
  begin
    GetMem(lvBuf, len);
    Move(buf^, lvBuf^, len);
    SetBuffer(lvBuf, len, dtFreeMem);
  end else
  begin
    SetBuffer(buf, len, dtNone);
  end;

//
//  if pvCopyBuf then
//  begin
//    if FCopyBuf.len > 0 then FreeMem(FCopyBuf.buf);
//
//    FCopyBuf.len := len;
//    GetMem(FCopyBuf.buf, FCopyBuf.len);
//    Move(buf^, FCopyBuf.buf^, FCopyBuf.len);
//    FBuf := FCopyBuf.buf;
//    FLen := FCopyBuf.len;
//  end else
//  begin
//    FBuf := buf;
//    FLen := len;
//  end;
//  FPosition := 0;
end;

procedure TIocpSendRequest.UnBindingSendBuffer;
begin
  FBuf := nil;
  FLen := 0;
  FSendBufferReleaseType := dtNone;
end;

function TIocpSendRequest.GetStateINfo: String;
begin
  Result :=Format('%s %s', [Self.ClassName, self.Remark]);
  if FResponding then
  begin
    Result :=Result + sLineBreak + Format('start:%s, datalen:%d, max:%d',
      [FormatDateTime('MM-dd hh:nn:ss.zzz', FRespondStartTime), FWSABuf.len, FMaxSize]);
  end else
  begin
    Result :=Result + sLineBreak + Format('start:%s, end:%s, datalen:%d, max:%d',
      [FormatDateTime('MM-dd hh:nn:ss.zzz', FRespondStartTime),
        FormatDateTime('MM-dd hh:nn:ss.zzz', FRespondEndTime),
        FWSABuf.len, FMaxSize]);
  end;
end;

function TIocpSendRequest.GetWSABuf: PWsaBuf;
begin
  Result := @FWSABuf;
end;

procedure TIocpDataMonitor.Clear;
begin
  FLocker.Enter;
  try
    FSentSize:=0;
    FRecvSize:=0;
    FPostWSASendSize:=0;

    FContextCreateCounter := 0;
    FPostWSASendCounter:=0;
    FResponseWSASendCounter:=0;

    FSendRequestCreateCounter := 0;
    FPostWSARecvCounter:=0;
    FResponseWSARecvCounter:=0;

    FPushSendQueueCounter := 0;
    FResponseSendObjectCounter := 0;

    //FPostWSAAcceptExCounter:=0;
    //FResponseWSAAcceptExCounter:=0;
  finally
    FLocker.Leave;
  end;
end;

constructor TIocpDataMonitor.Create;
begin
  inherited Create;
  FLocker := TCriticalSection.Create();
end;



destructor TIocpDataMonitor.Destroy;
begin
  FLocker.Free;
  inherited Destroy;
end;

procedure TIocpDataMonitor.IncAcceptExObjectCounter;
begin
   InterlockedIncrement(FAcceptExObjectCounter); 
end;

procedure TIocpDataMonitor.incPushSendQueueCounter;
begin
  InterlockedIncrement(FPushSendQueueCounter);
end;

{$IFDEF SOCKET_REUSE}
procedure TIocpDataMonitor.incHandleCreateCounter;
begin
  InterlockedIncrement(FHandleCreateCounter);
end;

procedure TIocpDataMonitor.incHandleDestroyCounter;
begin
  InterlockedIncrement(FHandleDestroyCounter);
end;
{$ENDIF}

procedure TIocpDataMonitor.incPostSendObjectCounter;
begin
  InterlockedIncrement(FPostSendObjectCounter);
end;


procedure TIocpDataMonitor.IncPostWSARecvCounter;
begin
  InterlockedIncrement(FPostWSARecvCounter);
end;

procedure TIocpDataMonitor.incPostWSASendCounter;
begin
  InterlockedIncrement(FPostWSASendCounter);
end;

procedure TIocpDataMonitor.incPostWSASendSize(pvSize: Cardinal);
begin
  FLocker.Enter;
  try
    FPostWSASendSize := FPostWSASendSize + pvSize;
  finally
    FLocker.Leave;
  end;
end;

procedure TIocpDataMonitor.incRecvdSize(pvSize: Cardinal);
begin
  FLocker.Enter;
  try
    FRecvSize := FRecvSize + pvSize;
  finally
    FLocker.Leave;
  end;
end;

procedure TIocpDataMonitor.incResponseSendObjectCounter;
begin
  InterlockedIncrement(FResponseSendObjectCounter);
end;

procedure TIocpDataMonitor.IncResponseWSARecvCounter;
begin
  InterlockedIncrement(FResponseWSARecvCounter);
end;

procedure TIocpDataMonitor.incResponseWSASendCounter;
begin
  InterlockedIncrement(FResponseWSASendCounter);
end;

procedure TIocpDataMonitor.incSentSize(pvSize:Cardinal);
begin
  FLocker.Enter;
  try
    FSentSize := FSentSize + pvSize;
  finally
    FLocker.Leave;
  end;
end;

{ TIocpDisconnectExRequest }


function TIocpDisconnectExRequest.DirectlyPost: Boolean;
var
  lvErrorCode:Integer;
begin
  Result := IocpDisconnectEx(FContext.RawSocket.SocketHandle, @FOverlapped, TF_REUSE_SOCKET, 0);
  if not Result then
  begin
    lvErrorCode := WSAGetLastError;
    if lvErrorCode <> ERROR_IO_PENDING then
    begin
      // do normal close;
      FContext.RawSocket.close;
      {$IFDEF WRITE_LOG}
       FOwner.logMessage('TIocpDisconnectExRequest.PostRequest Error:%d',  [lvErrorCode]);
      {$ENDIF}

      // context may return to pool
      FContext.decReferenceCounter(
        Format('TIocpDisconnectExRequest.PostRequest Error: %d', [lvErrorCode]), Self
        );
      Result := false;
    end else
    begin
      Result := true;
    end;
  end;
end;

function TIocpDisconnectExRequest.PostRequest: Boolean;
var
  lvErrorCode:Integer;
begin
  Result := False;

  if FContext.incReferenceCounter('TIocpDisconnectExRequest.PostRequest', Self) then
  begin
    Result := IocpDisconnectEx(FContext.RawSocket.SocketHandle, @FOverlapped, TF_REUSE_SOCKET, 0);
    if not Result then
    begin
      lvErrorCode := WSAGetLastError;
      if lvErrorCode <> ERROR_IO_PENDING then
      begin
        // do normal close;
        FContext.RawSocket.close;
        {$IFDEF WRITE_LOG}
        FOwner.logMessage('TIocpDisconnectExRequest.PostRequest Error:%d',  [lvErrorCode]);
        {$ENDIF}

        // context may return to pool
        FContext.decReferenceCounter(
          Format('TIocpDisconnectExRequest.PostRequest Error: %d', [lvErrorCode]), Self
          );
        Result := false;
      end else
      begin
        Result := true;
      end;
    end;
  end;
end;


initialization
  __startTime :=  Now();



end.
