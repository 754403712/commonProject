unit UnitMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Winsock2, ComCtrls, ExtCtrls, IniFiles;

const
  WM_SOCKET = WM_USER+300;

type
  TMainForm = class(TForm)
    ListView1: TListView;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    sock: TSocket;
    clientList: TList;

    procedure WMSOCKET(var msg: TMessage);message WM_SOCKET;
    procedure UpdateOnlines;//�����������Ա����
    procedure UpdateOnlinesClient;//�㲥�ͻ����������
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses Protocol;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
var
  aWSAData: TWSAData;
  addr: TSockAddrIn;
  ini: TIniFile;
  serverPort: Integer;
begin
  ini:=TIniFile.Create(ExtractFileDir(Application.ExeName)+'\server.ini');
  serverPort:=ini.ReadInteger('Config','Port',SERVER_PORT);
  clientList:=TList.Create;
  if WSAStartup($0101,aWSAData) <> 0 then
    showmessage('Winsock Version Error');

  sock:=Socket(AF_INET,SOCK_DGRAM,0);

  addr.sin_family:=AF_INET;
  addr.sin_port:=htons(serverPort);
  addr.sin_addr.S_addr:=INADDR_ANY;
  if bind(sock,@addr,sizeof(addr))=SOCKET_ERROR then
  begin
    ShowMessage('��'+inttostr(serverPort)+'�˿�ʧ�ܣ����޸�server.ini������������');
    closesocket(sock);
    ini.Free;
    Exit;
  end;

  if SOCKET_ERROR=WSAAsyncSelect(sock,Handle,WM_SOCKET,FD_READ) then
    showmessage('WM_SOCKET Error');
  ini.Free;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
   i:Integer;
begin
  for i:=0 to clientList.Count-1 do
      FreeMem(PClientInfo(clientList.Items[i]));
  clientList.Free;

  closesocket(sock);
  WSACleanup;
end;

procedure TMainForm.UpdateOnlines;
var
  i: Integer;
  lsv:TListItem;
  tmp:TInAddr;
begin
  ListView1.Clear;
  for i:=0 to clientList.Count-1 do
  begin
    tmp.S_addr:=PClientInfo(clientList.Items[i]).ip;
    lsv:=ListView1.Items.Add;
    lsv.Caption:=PClientInfo(clientList.Items[i]).name;
    lsv.SubItems.Add(inet_ntoa(tmp));
    lsv.SubItems.Add(inttostr(ntohs(PClientInfo(clientList.Items[i]).port)));
   end;
end;

procedure TMainForm.WMSOCKET(var msg: TMessage);
var
  addr: TSockAddrIn;//���յ���������Ϣ
  addrTo: TSockAddrIn;//֪ͨ�򶴷���������ַ��Ϣ
  addrlen,addrTolen: Integer;
  i: Integer;
  pCInfo: PClientInfo;
  buffer: array [0..1500] of byte;
  head: TP2PHead;//��ͷ
  iP2PLogin: TP2PLogin;
  oP2PLoginRespPack: TP2PLoginRespPack;
  iP2PLogout: TP2PLogout;
  iP2PUserInfo: TP2PUserInfo;
  oP2PUserInfoRespPack: TP2PUserInfoRespPack;
  oP2PMakeHolePack: TP2PMakeHolePack;
  iP2POnline: TP2POnline;
begin
  case WSAGetSelectEvent(msg.LParam) of
    FD_READ:
    begin
      addrlen:=sizeof(addr);
      addrTolen:=sizeof(addrTo);
      recvfrom(sock,buffer,1500,0,@addr,addrlen);
      Move(buffer,head,sizeof(head));//��buffer�з������ͷ
      case head.Command of
        cmdLogin:
        begin
          move(buffer[sizeof(head)],iP2PLogin,sizeof(iP2PLogin));
          for i:=0 to clientList.Count-1 do
          begin
            if StrComp(PClientInfo(clientList.Items[i]).name,iP2PLogin.name)=0 then
            begin
              {���͵�¼ʧ�ܵ���Ϣ}
              oP2PLoginRespPack.head.Command:=cmdLoginResp;
              oP2PLoginRespPack.body.res:=False;//��¼ʧ�ܣ��������ظ�
              sendto(sock,oP2PLoginRespPack,sizeof(oP2PLoginRespPack),0,@addr,addrlen);
              Exit;
            end;
          end;
          {����Client��Ϣ}
          GetMem(pCInfo,sizeof(TClientInfo));
          StrCopy(pCInfo^.name,iP2PLogin.name);
          pCInfo^.ip:=addr.sin_addr.S_addr;
          pCInfo^.port:=addr.sin_port;
          pCInfo^.ticktime:=GetTickCount;
          clientList.Add(pCInfo);

          UpdateOnlines;
          {���͵�¼�ɹ�����Ϣ}
          oP2PLoginRespPack.head.Command:=cmdLoginResp;
          oP2PLoginRespPack.body.res:=True;//��¼�ɹ�
          sendto(sock,oP2PLoginRespPack,sizeof(oP2PLoginRespPack),0,@addr,addrlen);
        end;

        cmdLogout:{�˳�}
        begin
          move(buffer[sizeof(head)],ip2plogout,sizeof(iP2PLogout));
          for i:=clientList.Count-1 downto 0 do
          begin
            if StrComp(PClientInfo(clientList.Items[i]).name,ip2plogout.name)=0 then
            begin
              FreeMem(PClientInfo(clientList.Items[i]));
              clientList.Delete(i);
            end
          end;

          UpdateOnlines;
          UpdateOnlinesClient;
        end;


        cmdOnline://�ͻ��˱�������
        begin
          move(buffer[sizeof(head)],iP2POnline,sizeof(iP2POnline));
          for i:=0 to clientList.Count-1 do
          begin
            if StrComp(PClientInfo(clientList.Items[i]).name,iP2POnline.name)=0 then
              PClientInfo(clientList.Items[i]).ticktime:=GetTickCount;
          end;
        end;


        cmdUserList://�û������û��б�
        begin
          UpdateOnlinesClient;
        end;


        cmdUserInfo://�û���͸ǰ�����öԷ�����IP port��Ϣ
        begin
          move(buffer[sizeof(head)],ip2puserinfo,sizeof(ip2puserinfo));
          for i:=0 to clientList.Count-1 do
          begin
            if StrComp(PClientInfo(clientList.Items[i]).name,iP2PUserInfo.name2)=0 then
            begin
              {����clientA����һ��clientB��������Ϣ}
              oP2PUserInfoRespPack.head.Command:=cmdUserInfoResp;
              StrPCopy(oP2PUserInfoRespPack.body.name,PClientInfo(clientList.Items[i]).name);
              oP2PUserInfoRespPack.body.ip:=PClientInfo(clientList.Items[i]).ip;
              oP2PUserInfoRespPack.body.port:=PClientInfo(clientList.Items[i]).port;
              sendto(sock,oP2PUserInfoRespPack,sizeof(oP2PUserInfoRespPack),0,
                @addr,addrlen);

              {����һ��clientB������clientA�Ĵ�����}
              addrTo.sin_family:=AF_INET;
              addrTo.sin_addr.S_addr:=PClientInfo(clientList.Items[i]).ip;
              addrTo.sin_port:=PClientInfo(clientList.Items[i]).port;

              oP2PMakeHolePack.head.Command:=cmdMakeHole;
              StrPCopy(oP2PMakeHolePack.body.name,ip2puserinfo.name1);
              oP2PMakeHolePack.body.ip:=addr.sin_addr.S_addr;
              oP2PMakeHolePack.body.port:=addr.sin_port;

              sendto(sock,oP2PMakeHolePack,sizeof(oP2PMakeHolePack),0,
                @addrTo,addrTolen);

              break;
            end;

          end;
        end;
      end;
    end;
  end;

end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  NowTick: Integer;
  i: Integer;
begin
  NowTick:=GetTickCount;
  for i:=0 to clientList.Count-1 do
  begin
    if NowTick-PClientInfo(clientList[i]).ticktime>30000 then
    begin
      FreeMem(PClientInfo(clientList.Items[i]));
      clientList.Delete(i);
      UpdateOnlines;
      UpdateOnlinesClient;
    end;
  end;
end;

procedure TMainForm.UpdateOnlinesClient;
var
  addrTo: TSockAddrIn;
  addrTolen: Integer;
  i: Integer;
  s: string;
  pack: TP2PUserListRespPack;
begin
  addrTolen:=sizeof(addrTo);
  s:='';
  for i:=clientList.Count-1 downto 0 do
    s:=s+PClientInfo(clientList.Items[i]).name+'|';
  pack.head.Command:=cmdUserListResp;
  StrPCopy(pack.body.users,s);

  for i:=0 to clientList.Count-1 do{�㲥�����û�}
  begin
    addrTo.sin_family:=AF_INET;
    addrTo.sin_port:=PClientInfo(clientList.Items[i]).port;
    addrTo.sin_addr.S_addr:=PClientInfo(clientList.Items[i]).ip;
    sendto(sock,pack,sizeof(pack),0,@addrTo,addrTolen);
  end;
end;

end.
