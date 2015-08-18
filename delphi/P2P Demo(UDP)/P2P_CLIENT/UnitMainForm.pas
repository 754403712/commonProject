unit UnitMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Protocol, WinSock2, ExtCtrls, IniFiles, Gauges, XPMan,
  MMSystem;

const
  WM_SOCKET = WM_USER + 200;

type
  TSendFileInfo = packed record
    FileName: string;
    FileSize: Integer;
    ID: Integer;
    size: Integer;
    BlockCount: Integer;
    position: Integer;
    LastTickCount: Integer;
    IsWorking: Boolean;
    progress: Integer;
    startTick: Integer;
  end;
  TRecvFileInfo = packed record
    FileName: string;
    FileSize: Integer;
    ID: Integer;
    size: Integer;
    BlockCount: Integer;
    position: Integer;
    IsWorking: Boolean;
    progress: Integer;
    startTick: Integer;
  end;

type
  TMainForm = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    EdtIP: TEdit;
    EdtPort: TEdit;
    EdtName: TEdit;
    btnConnect: TButton;
    ListBox1: TListBox;
    TimerMakeHole: TTimer;
    EdtMessage: TEdit;
    btnSend: TButton;
    Memo1: TMemo;
    EdtFile: TEdit;
    btnBrowse: TButton;
    btnSendFile: TButton;
    Gauge1: TGauge;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Label4: TLabel;
    btnClear: TButton;
    btnRefresh: TButton;
    Label5: TLabel;
    TimerKeepOnline: TTimer;
    CheckBox1: TCheckBox;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure TimerMakeHoleTimer(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnSendFileClick(Sender: TObject);
    procedure EdtMessageKeyPress(Sender: TObject; var Key: Char);
    procedure btnClearClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure TimerKeepOnlineTimer(Sender: TObject);
  private
    { Private declarations }
    sock: TSocket;
    LoginTickCount: Integer;//������֤��¼���Ƿ��ͳ�ʱ
    addrSrv :TSockAddrIn;//Server�ĵ�ַ
    addrP2P :TSockAddrIn;//�Է��ĵ�ַ
    sendInfo :TSendFileInfo;//�����ļ���״̬��Ϣ
    recvInfo :TRecvFileInfo;//�����ļ���״̬��Ϣ
    readfs,writefs: TFileStream;//��д�ļ���
    procedure WMSOCKET(var msg: TMessage);message WM_SOCKET;
    procedure SendBlock(var s: TSendFileInfo);
    procedure AcceptRecvFile(b: Boolean);//�����Ƿ���նԷ��ļ���Ϣ
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses CRC32;

{$R 'res\res.res' 'res\res.rc'}
{$R *.dfm}
function GetBlockCount(Size:Integer):Integer;
begin
  Result:=(Size div BlockSize);
  if (Size mod BlockSize) > 0 then
    Inc(Result);
end;

procedure OnCheckBlockRespPack();//���ظ����Ƿ�ʱ
begin
  if GetTickCount-MainForm.sendInfo.LastTickCount>1000 then
  begin
    if MainForm.CheckBox1.State=cbUnchecked then
      MainForm.Memo1.Lines.Add('�� '+IntToStr(MainForm.sendInfo.ID)+' ��ʧ��ʱ���ط�������'+#13);
    KillTimer(MainForm.Handle,1);
    MainForm.SendBlock(MainForm.sendInfo);
  end;
end;

procedure OnCheckLoginResp();//����Ƿ��¼�����ͳ�ʱ
begin
  if GetTickCount-MainForm.LoginTickCount>2000 then
  begin
    KillTimer(MainForm.Handle,2);
    ShowMessage('����������ʧ��');
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  pack: TP2PLogoutPack;
  pack2: TP2PCancelTransferPack;
  ini: TIniFile;
begin
  if sendInfo.IsWorking or recvInfo.IsWorking then
  begin
    pack2.head.Command:=cmdCancelTransfer;
    sendto(sock,pack2,sizeof(pack2),0,@addrP2P,sizeof(addrP2P));
  end;

  pack.head.Command:=cmdLogout;
  strpcopy(pack.body.name,EdtName.Text);
  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));

  closesocket(sock);
  WSACleanup;
  ini:=TIniFile.Create(ExtractFileDir(Application.ExeName)+'\config.ini');
  ini.WriteString('Config','Server',EdtIP.Text);
  ini.WriteString('Config','Name',EdtName.Text);
  ini.WriteString('Config','Port',EdtPort.Text);
  ini.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  aWSAData: TWSAData;
  addr: TSockAddrIn;
  //i: integer;
  ini: TIniFile;
begin
  ini:=TIniFile.Create(ExtractFileDir(Application.ExeName)+'\config.ini');
  EdtIP.Text:=ini.ReadString('Config','Server','127.0.0.1');
  EdtPort.Text:=IntToStr(SERVER_PORT);
  EdtName.Text:=ini.ReadString('Config','Name','');
  EdtPort.Text:=ini.ReadString('Config','Port',IntToStr(SERVER_PORT));
  ini.Free;

  sendInfo.IsWorking:=False;
  recvInfo.IsWorking:=False;

  if WSAStartup($0101, aWSAData) <> 0 then
    ShowMessage('Winsock Version Error');

  sock:=Socket(AF_INET,SOCK_DGRAM,0);

  addr.sin_family:=AF_INET;
  addr.sin_addr.S_addr:=INADDR_ANY;
  {for i:=0 to 200 do//����˿ڰ�ʧ�ܣ��˿ڽ�����������200��
  begin
    addr.sin_port:=htons(CLIENT_PORT+i);
    if bind(sock,@addr,sizeof(addr))<>SOCKET_ERROR then
      break;
  end;}

  if SOCKET_ERROR=WSAAsyncSelect(sock,Handle,WM_SOCKET,FD_READ) then
    ShowMessage('WM_SOCKET Error');
end;

procedure TMainForm.btnConnectClick(Sender: TObject);
var
  pack: TP2PLoginPack;
begin
  if EdtName.Text='' then
  begin
    ShowMessage('����������');
    EdtName.SetFocus;
    Exit;
  end;

  addrSrv.sin_addr.S_addr:=inet_addr(pChar(EdtIP.Text));
  addrSrv.sin_family:=AF_INET;
  addrSrv.sin_port:=htons(StrToInt(EdtPort.Text));

  pack.head.Command:=cmdLogin;
  strpcopy(pack.body.name,EdtName.Text);

  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));
  LoginTickCount:=GetTickCount;
  SetTimer(Handle,2,200,@OnCheckLoginResp);
end;

procedure TMainForm.WMSOCKET(var msg: TMessage);
var
  addr: TSockAddrIn;//���յ���������Ϣ
  addrlen: Integer;//��ַ�ṹ����
  i: Integer;//forѭ��ר��
  buffer: array [0..1500] of byte;//���ݰ�
  head: TP2PHead;//��ͷ
  {i��ͷ���ǽ��յ���Ϣ�ṹ��o��ͷ���Ƿ�������Ϣ�ṹ}
  iP2PLoginResp: TP2PLoginResp;//server��¼��Ӧ
  oP2PUserListPack: TP2PUserListPack;//�����û��б�
  users: TStrings;//�����û���Ϣ��ʱ���������ڷָ��ַ�
  iP2PUserListResp: TP2PUserListResp;//server���ص������û���Ϣ
  iP2PUserInfoResp: TP2PUserInfoResp;//server���ص�ָ���û���Ϣ
  iP2PMakeHole: TP2PMakeHole;//serverҪ����򶴣������Է���������Ϣ
  iP2PMessage: TP2PMessage;//p2p֮���������Ϣ
  iP2PInquireAcceptFile: TP2PInquireAcceptFile;//ѯ���Ƿ�����ļ�
  iP2PInquireAcceptFileResp: TP2PInquireAcceptFileResp;//ͬ�ϣ�ֻ�Ƿ���ͬ
  fileBuffer: PChar;//����Ԥ�ȷ���Ӳ�̿ռ䣬������һ���ļ�
  iP2PSendBlock: TP2PSendBlock;//���յ����ļ����ݿ�
  oP2PSendBlockRespPack: TP2PSendBlockRespPack;//���� ���յ����ļ����ݿ� ��Ϣ
  iP2PSendBlockResp: TP2PSendBlockResp;//�����û��ļ����յ���ķ���
  crc32: DWORD;
  reshwnd: THandle;
  p: Pointer;
begin
  case WSAGetSelectEvent(msg.LParam) of
    FD_READ:
    begin
      addrlen:=sizeof(addr);
      recvfrom(sock,buffer,1500,0,@addr,addrlen);
      Move(buffer,head,sizeof(head));//��buffer�з�������ݰ���ͷ
      case head.Command of
        cmdLoginResp://��¼��Ӧ
        begin
          //��buffer�з������ݰ����壬���涼�����
          KillTimer(MainForm.Handle,2);//�ӵ���¼��Ӧ���ˣ���ʱ��Ѽ���¼��Ӧ��ʱ���ص���
          move(buffer[sizeof(head)],iP2PLoginResp,sizeof(iP2PLoginResp));
          if iP2PLoginResp.res then
          begin
            //ShowMessage('��¼�ɹ�');
            TimerKeepOnline.Enabled:=True;
            EdtName.Enabled:=False;
            EdtIP.Enabled:=False;
            EdtPort.Enabled:=False;
            btnConnect.Enabled:=False;
            oP2PUserListPack.head.Command:=cmdUserList;//��¼��ˢ�������û���Ϣ
            sendto(sock,oP2PUserListPack,sizeof(oP2PUserListPack),0,@addr,sizeof(addr));
          end else
          begin
            ShowMessage('�����ظ��������');
            EdtName.SetFocus;
          end;
        end;


        cmdUserListResp://�������������û�����
        begin
          ListBox1.Clear;
          move(buffer[sizeof(head)],iP2PUserListResp,sizeof(iP2PUserListResp));
          users:=TStringList.Create;//����TStrings�ָ��ַ���
          users.Delimiter:='|';
          users.DelimitedText:=iP2PUserListResp.users;
          for i:=0 to users.Count-2 do//��ʾ���Լ��������������Ա
            if users[i]<>EdtName.Text then ListBox1.Items.Add(users[i]);
          users.Free;
        end;


        cmdUserInfoResp://���������Ի����û���Ϣ�����Խ���ȥ������
        begin
          move(buffer[sizeof(head)],iP2PUserInfoResp,sizeof(iP2PUserInfoResp));
          addrP2P.sin_family:=AF_INET;//�����ǶԼҵ�������Ϣ
          addrP2P.sin_port:=iP2PUserInfoResp.port;
          addrP2P.sin_addr.S_addr:=iP2PUserInfoResp.ip;

          {P2P֮��Ĵ򶴣��ͷ������޹أ������򶴣�ά������}
          TimerMakeHole.Enabled:=True;
        end;


        cmdMakeHole://�������Ĵ���������򶴣�
        begin
          move(buffer[sizeof(head)],iP2PMakeHole,sizeof(iP2PMakeHole));
          addrP2P.sin_family:=AF_INET;
          addrP2P.sin_port:=iP2PMakeHole.port;
          addrP2P.sin_addr.S_addr:=iP2PMakeHole.ip;
          //iP2PMakeHole.name�ֶα���

          TimerMakeHole.Enabled:=True;//ά�ִ�����
        end;


        cmdHole://����Ϣ��������
        begin
        end;


        cmdMessage://P2P������Ϣ
        begin
          move(buffer[sizeof(head)],iP2PMessage,sizeof(iP2PMessage));
          Memo1.Lines.Add(iP2PMessage.name + ' : '+iP2PMessage.Text+#13);
          reshwnd:=FindResource(hInstance,'msg','WAV');
          reshwnd:=LoadResource(hInstance,reshwnd);
          p:=LockResource(reshwnd);
          sndPlaySound(p,SND_MEMORY or SND_ASYNC);
          UnlockResource(reshwnd);
          FreeResource(reshwnd);
        end;


        cmdInquireAcceptFile://ѯ���Ƿ�����ļ�
        begin
          move(buffer[sizeof(head)],iP2PInquireAcceptFile,sizeof(iP2PInquireAcceptFile));
          reshwnd:=FindResource(hInstance,'ring','WAV');
          reshwnd:=LoadResource(hInstance,reshwnd);
          p:=LockResource(reshwnd);
          sndPlaySound(p,SND_MEMORY or SND_ASYNC);
          UnlockResource(reshwnd);
          FreeResource(reshwnd);
          memo1.Lines.Add('��'+iP2PInquireAcceptFile.name+'�������ļ���'+iP2PInquireAcceptFile.FileName
            +'������СΪ'+IntToStr(iP2PInquireAcceptFile.FileSize) + ' B('+
            IntToStr(Round(iP2PInquireAcceptFile.FileSize/1024))+' KB)'+#13);
          if IDYES = MessageBox(handle,PChar('�Ƿ�Ҫ���ո��ļ���'),
              PChar('P2P Transfer File'),MB_YESNO or MB_ICONQUESTION) then
          begin
            SaveDialog1.FileName:=iP2PInquireAcceptFile.FileName;
            if SaveDialog1.Execute then
            begin//ͬ������ļ�
              recvInfo.FileName:=SaveDialog1.FileName;
              recvInfo.FileSize:=iP2PInquireAcceptFile.FileSize;
              recvInfo.BlockCount:=GetBlockCount(recvInfo.FileSize);
              recvInfo.IsWorking:=True;
              {��Ӳ���ϴ���һ�����ļ�����С������ļ�һ��}
              Label5.Caption:='�����ļ�������';
              if FileExists(recvInfo.FileName) then
                  DeleteFile(recvInfo.FileName);
              writefs:=TFileStream.Create(recvInfo.FileName,fmCreate);
              GetMem(fileBuffer,recvInfo.FileSize);
              writefs.Write(fileBuffer^,recvInfo.FileSize);
              FreeMem(fileBuffer);//��ע��writefs�����ļ�ȫ�����������Free

              {���͡�ͬ������ļ�������Ϣ���Լң��ȴ��ļ����ĵ���}
              AcceptRecvFile(True);
              recvInfo.startTick:=GetTickCount;
            end else//�ܾ������ļ�(yes no ʱͬ�⣬��ѡ�����ļ���ȡ��)
              AcceptRecvFile(False);
          end else//�ܾ������ļ�(yes no ʱ�ܾ�)
            AcceptRecvFile(True);
        end;


        cmdInquireAcceptFileResp://���ضԷ��Ƿ�����ļ�
        begin
          move(buffer[sizeof(head)],iP2PInquireAcceptFileResp,sizeof(iP2PInquireAcceptFileResp));
          if iP2PInquireAcceptFileResp.Resp then
          begin
            Memo1.Lines.Add('��'+iP2PInquireAcceptFileResp.name+
                '��ͬ������ļ�'+#13);
            btnSendFile.Enabled:=False;

            sendInfo.startTick:=GetTickCount;
            sendInfo.IsWorking:=True;
            readfs:=TFileStream.Create(sendInfo.FileName,fmOpenRead);
            sendInfo.ID:=0;//���ݿ�IDͳһ����0��ʼ����
            sendInfo.position:=0;
            if sendInfo.FileSize <= BlockSize then
              sendInfo.size:=sendInfo.FileSize
            else
              sendInfo.size:=BlockSize;

            Gauge1.Progress:=Round(sendInfo.position/sendInfo.FileSize*100);

            SendBlock(sendInfo);

          end
          else
            Memo1.Lines.Add('��'+iP2PInquireAcceptFileResp.name+
                '���ܾ������ļ�'+#13);
        end;


        cmdSendBlock://�����ļ���
        begin
          move(buffer[sizeof(head)],iP2PSendBlock,sizeof(iP2PSendBlock));

          GetCrc32Byte(iP2PSendBlock.Data,iP2PSendBlock.size,crc32);

          if crc32=iP2PSendBlock.CRC32 then
          begin//crc������󣬷�����ȷ��Ϣ
            {if recvInfo.ID = recvInfo.BlockCount-1 then//���һ����
            begin
              FreeAndNil(writefs);
              //Memo1.Lines.Add('���ļ�'+recvInfo.FileName+'������ϡ�'+#13);
              Memo1.Lines.Add('���ļ� '+recvInfo.FileName +' ������ϡ�����ʱ'
              +IntToStr(Round((GetTickCount-recvInfo.startTick)/1000))+'�룬ƽ���ٶ�'
              +IntToStr(Round(recvInfo.BlockCount/(GetTickCount-recvInfo.startTick)*1000))
              +' KB/s'+#13);
              oP2PSendBlockRespPack.head.Command:=cmdSendBlockResp;
              oP2PSendBlockRespPack.body.position:=recvInfo.position;
              oP2PSendBlockRespPack.body.ID:=recvInfo.ID;
              oP2PSendBlockRespPack.body.checkCRC:=True;
              oP2PSendBlockRespPack.body.TimeTick:=iP2PSendBlock.TimeTick;
              sendto(sock,oP2PSendBlockRespPack,sizeof(oP2PSendBlockRespPack),
                  0,@addrP2P,sizeof(addrP2P));
              recvInfo.IsWorking:=False;

              Label5.Caption:='';
              Exit;
            end;}

            recvInfo.position:=iP2PSendBlock.position;
            recvInfo.ID:=iP2PSendBlock.ID;
            if writefs<> nil then
            begin
              writefs.Seek(recvInfo.position,soBeginning);
              writefs.Write(iP2PSendBlock.Data,iP2PSendBlock.size);
            end;

            oP2PSendBlockRespPack.head.Command:=cmdSendBlockResp;
            oP2PSendBlockRespPack.body.position:=recvInfo.position;
            oP2PSendBlockRespPack.body.ID:=recvInfo.ID;
            oP2PSendBlockRespPack.body.checkCRC:=True;
            oP2PSendBlockRespPack.body.TimeTick:=iP2PSendBlock.TimeTick;
            sendto(sock,oP2PSendBlockRespPack,sizeof(oP2PSendBlockRespPack),
                  0,@addrP2P,sizeof(addrP2P));

            if recvInfo.BlockCount=recvInfo.ID+1 then//���һ����
            begin
              FreeAndNil(writefs);
              Memo1.Lines.Add('�ļ���'+recvInfo.FileName +'��������ϣ���ʱ'
              +IntToStr(Round((GetTickCount-recvInfo.startTick)/1000))+'�룬ƽ���ٶ�'
              +IntToStr(Round(recvInfo.BlockCount/(GetTickCount-recvInfo.startTick)*1000))
              +' KB/s'+#13);
              {oP2PSendBlockRespPack.head.Command:=cmdSendBlockResp;
              oP2PSendBlockRespPack.body.position:=recvInfo.position;
              oP2PSendBlockRespPack.body.ID:=recvInfo.ID;
              oP2PSendBlockRespPack.body.checkCRC:=True;
              oP2PSendBlockRespPack.body.TimeTick:=iP2PSendBlock.TimeTick;
              sendto(sock,oP2PSendBlockRespPack,sizeof(oP2PSendBlockRespPack),
                  0,@addrP2P,sizeof(addrP2P));}
              recvInfo.IsWorking:=False;
              Label5.Caption:='';
            end;
          end else
          begin//crc������������ط��ð�
            oP2PSendBlockRespPack.head.Command:=cmdSendBlockResp;
            oP2PSendBlockRespPack.body.position:=recvInfo.position;
            oP2PSendBlockRespPack.body.ID:=recvInfo.ID;
            oP2PSendBlockRespPack.body.checkCRC:=False;
            oP2PSendBlockRespPack.body.TimeTick:=iP2PSendBlock.TimeTick;
            sendto(sock,oP2PSendBlockRespPack,sizeof(oP2PSendBlockRespPack),
                  0,@addrP2P,sizeof(addrP2P));
            Memo1.Lines.Add('CRC32 error'+ IntToStr(iP2PSendBlock.ID));
          end;
          Gauge1.Progress:=Round(recvInfo.ID/recvInfo.BlockCount*100);
        end;


        cmdSendBlockResp://���շ���������һ����
        begin
          move(buffer[sizeof(head)],iP2PSendBlockResp,sizeof(iP2PSendBlockResp));
          KillTimer(Handle,1);
          {if sendInfo.ID=sendInfo.BlockCount-1 then
          begin
            FreeAndNil(readfs);
            Memo1.Lines.Add('���ļ� '+sendInfo.FileName +' ������ϡ�����ʱ'
              +IntToStr(Round((GetTickCount-sendInfo.startTick)/1000))+'�룬ƽ���ٶ�'
              +IntToStr(Round(sendInfo.BlockCount/(GetTickCount-sendInfo.startTick)*1000))
              +' KB/s'+#13);
            btnSendFile.Enabled:=True;
            sendInfo.IsWorking:=False;
            Label5.Caption:='';
            Exit;
          end;}

          if (iP2PSendBlockResp.checkCRC) and
            (GetTickCount-iP2PSendBlockResp.TimeTick<1000)  then//CRC������� ��ʱ�������
          begin
            sendInfo.ID:=iP2PSendBlockResp.ID+1;
            sendInfo.position:=iP2PSendBlockResp.position+BlockSize;
          end else
          begin//CRC��������ʱ�����ʱ���ط�
            sendInfo.ID:=iP2PSendBlockResp.ID;
            sendInfo.position:=iP2PSendBlockResp.position;
            if MainForm.CheckBox1.State=cbUnchecked then
              Memo1.Lines.Add('��ʱ������ '+IntToStr(sendInfo.ID));
          end;

          if sendInfo.ID=sendInfo.BlockCount-1 then//���һ����
            sendInfo.size:=sendInfo.FileSize mod BlockSize
          else
            sendInfo.size:=BlockSize;

          if sendInfo.ID=sendInfo.BlockCount then
          begin
            FreeAndNil(readfs);
            Memo1.Lines.Add('�ļ���'+sendInfo.FileName +'��������ϣ���ʱ'
              +IntToStr(Round((GetTickCount-sendInfo.startTick)/1000))+'�룬ƽ���ٶ�'
              +IntToStr(Round(sendInfo.BlockCount/(GetTickCount-sendInfo.startTick)*1000))
              +' KB/s'+#13);
            btnSendFile.Enabled:=True;
            sendInfo.IsWorking:=False;
            Label5.Caption:='';
          end
          else
            SendBlock(sendInfo);

          Gauge1.Progress:=Round(sendInfo.position/sendInfo.FileSize*100);
        end;


        cmdCancelTransfer://ȡ�������ļ�
        begin
          if sendInfo.IsWorking then FreeAndNil(readfs);
          if recvInfo.IsWorking then FreeAndNil(writefs);
          Memo1.Lines.Add('���Է�ȡ���˴��䡿'+#13);
          sendInfo.IsWorking:=False;
          recvInfo.IsWorking:=False;
          Label5.Caption:='';
        end;

      end;

    end;
  end;
end;



procedure TMainForm.ListBox1Click(Sender: TObject);
var
  pack: TP2PUserInfoPack;
begin
  if ListBox1.ItemIndex<0 then Exit;
  pack.head.Command:=cmdUserInfo;
  StrPCopy(pack.body.name1,EdtName.Text);//�Լ�
  StrPCopy(pack.body.name2,ListBox1.Items[ListBox1.ItemIndex]);//�Է�
  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));
end;

procedure TMainForm.TimerMakeHoleTimer(Sender: TObject);
var
  pack: TP2PHolePack;
begin
  pack.head.Command:=cmdHole;
  sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));
  if recvInfo.IsWorking then
    Label5.Caption:=IntToStr(recvInfo.ID-recvInfo.progress)+'KB/s';
  if sendInfo.IsWorking then
    Label5.Caption:=IntToStr(sendInfo.ID-sendInfo.progress)+'KB/s';
  recvInfo.progress:=recvInfo.ID;
  sendInfo.progress:=sendInfo.ID;
end;

procedure TMainForm.btnSendClick(Sender: TObject);
var
  pack: TP2PMessagePack;
begin
  if EdtMessage.Text = '' then Exit;

  pack.head.Command:=cmdMessage;
  StrPCopy(pack.body.name,EdtName.Text);
  StrPCopy(pack.body.Text,EdtMessage.Text);
  sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));

  Memo1.Lines.Add(EdtName.Text + ' : '+EdtMessage.Text+#13);
  EdtMessage.Clear;
end;
procedure TMainForm.EdtMessageKeyPress(Sender: TObject; var Key: Char);
begin
   if Integer(key)=13 then btnSendClick(self);
end;


procedure TMainForm.btnBrowseClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    EdtFile.Text:=OpenDialog1.FileName;
end;

procedure TMainForm.btnSendFileClick(Sender: TObject);
var
  stream: TFileStream;
  pack: TP2PInquireAcceptFilePack;
begin
  if FileExists(EdtFile.Text) then
  begin
    stream:=TFileStream.Create(EdtFile.Text,fmOpenRead);
    sendInfo.FileName:=EdtFile.Text;
    sendInfo.FileSize:=stream.Size;
    sendInfo.BlockCount:=GetBlockCount(sendInfo.FileSize);//�ļ���Ϊ���ٿ�
    stream.Free;
    pack.head.Command:=cmdInquireAcceptFile;
    StrPCopy(pack.body.name,EdtName.Text);
    StrPCopy(pack.body.FileName,ExtractFileName(EdtFile.Text));
    pack.body.FileSize:=sendInfo.FileSize;
    sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));

  end else
    ShowMessage('��ȷ��Ҫ���͵��ļ�')
end;



procedure TMainForm.SendBlock(var s: TSendFileInfo);
var
  pack: TP2PSendBlockPack;
begin
  if sendInfo.IsWorking=False then
  begin
    KillTimer(Handle,1);
    Exit;
  end;
  pack.head.Command:=cmdSendBlock;
  pack.body.position:=s.position;
  pack.body.ID:=s.ID;
  pack.body.size:=s.size;
  readfs.Seek(s.position,soBeginning);
  readfs.Read(pack.body.Data,pack.body.size);
  GetCrc32Byte(pack.body.Data,pack.body.size,pack.body.CRC32);
  sendInfo.LastTickCount:=GetTickCount;
  pack.body.TimeTick:=sendInfo.LastTickCount;
  sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));
  SetTimer(Handle,1,100,@OnCheckBlockRespPack);
end;

procedure TMainForm.btnClearClick(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TMainForm.btnRefreshClick(Sender: TObject);
var
  pack: TP2PUserListPack;
begin
  pack.head.Command:=cmdUserList;
  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));
end;

procedure TMainForm.TimerKeepOnlineTimer(Sender: TObject);
var
  pack: TP2POnlinePack;
begin
  pack.head.Command:=cmdOnline;
  StrPCopy(pack.body.name,EdtName.Text);
  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));
end;

procedure TMainForm.AcceptRecvFile(b: Boolean);
var
  pack: TP2PInquireAcceptFileRespPack;
begin
  pack.head.Command:=cmdInquireAcceptFileResp;
  StrPCopy(pack.body.name,EdtName.Text);
  pack.body.Resp:=b;
  sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));
end;

end.
