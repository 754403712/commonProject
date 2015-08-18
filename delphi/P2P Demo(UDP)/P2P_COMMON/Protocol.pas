unit Protocol;

interface

uses
  Winsock2, Windows;

const
  SERVER_PORT = 5432;//Server�˿�
  
  BlockSize   = 1024;//�ļ����С
type

  PClientInfo = ^TClientInfo;//�û���Ϣ
  TClientInfo = packed record
    name: array [0..20] of char;
    ip: u_long;
    port: Integer;
    ticktime: Integer;
  end;

  {�������ݰ�ͷ��Command�ֶ�}
  TP2PCMD=(cmdLogin,cmdLoginResp,cmdLogout,cmdOnline,
      cmdUserList,cmdUserListResp,
      cmdUserInfo,cmdUserInfoResp,
      cmdMakeHole,cmdHole,
      cmdMessage,
      cmdInquireAcceptFile,cmdInquireAcceptFileResp,
      cmdSendBlock,cmdSendBlockResp,
      cmdCancelTransfer);

  TP2PHead = packed record//�������ݵİ�ͷ
    Command: TP2PCMD;
    Len: Integer;//����������Command�Ϳ����������ݰ��ˡ�
  end;

  //==============================================================
  TP2PLogin = packed record//��¼(c2s)
    name: array [0..20] of char;
  end;
  TP2PLoginPack = packed record
    head: TP2PHead;
    body: TP2PLogin;
  end;

  TP2PLoginResp = packed record//��¼�ظ�(s2c)
    res: Boolean;
  end;
  TP2PLoginRespPack = packed record
    head: TP2PHead;
    body: TP2PLoginResp;
  end;

  TP2PLogout = packed record//�ǳ�(c2s)
    name: array [0..20] of char;
  end;
  TP2PLogoutPack = packed record
    head: TP2PHead;
    body: TP2PLogout;
  end;


  TP2POnline = packed record//ά������
    name: array [0..20] of char;
  end;
  TP2POnlinePack = packed record
    head: TP2PHead;
    body: TP2POnline;
  end;


  TP2PUserInfo = packed record//PeerA������PeerB��Ϣ������(c2s)
    name1: array [0..20] of char;//�Է�
    name2: array [0..20] of char;//����
  end;
  TP2PUserInfoPack = packed record
    head: TP2PHead;
    body: TP2PUserInfo;
  end;


  TP2PUserInfoResp = packed record//server�����û���Ϣ(s2c)
    name: array [0..20] of char;
    ip: u_long;
    port: Integer;
  end;
  TP2PUserInfoRespPack = packed record
    head: TP2PHead;
    body: TP2PUserInfoResp;
  end;


  TP2PUserList = packed record//��������û��б�(c2s)
  end;
  TP2PUserListPack = packed record
    head: TP2PHead;
    body: TP2PUserList;
  end;


  TP2PUserListResp = packed record//�����û��б��û�����'|'�ָ�(s2c)
    users: array [0..1000] of char;
  end;
  TP2PUserListRespPack = packed record
    head: TP2PHead;
    body: TP2PUserListResp;
  end;


  TP2PMakeHole = packed record//Serverָ��PeerB��(s2c)
    name: array [0..20] of char;//PeerA����Ϣ
    ip: u_long;
    port: Integer;
  end;
  TP2PMakeHolePack = packed record
    head: TP2PHead;
    body: TP2PMakeHole;
  end;



  {����Ķ���P2P֮������ݰ��ṹ����������޹�}
  TP2PHole = packed record//P2P֮��Ĵ���Ϣ
  end;
  TP2PHolePack = packed record
    head: TP2PHead;
    body: TP2PHole;
  end;


  TP2PMessage = packed record//P2P֮����ı��������ݰ�
    name: array [0..20] of char;//������
    Text: array [0..1000] of char;
  end;
  TP2PMessagePack = packed record
    head: TP2PHead;
    body: TP2PMessage;
  end;


  TP2PInquireAcceptFile = packed record//P2P֮�䴫�ļ���ѯ����Ϣ
    name: array [0..20] of char;//������
    FileName: array [0..255] of char;
    FileSize: Integer;
  end;
  TP2PInquireAcceptFilePack = packed record
    head: TP2PHead;
    body: TP2PInquireAcceptFile;
  end;


  TP2PInquireAcceptFileResp = packed record//P2P֮�䴫�ļ���Ӧ���Ƿ����
    name: array [0..20] of char;
    Resp: Boolean;
  end;
  TP2PInquireAcceptFileRespPack = packed record
    head: TP2PHead;
    body: TP2PInquireAcceptFileResp;
  end;


  TP2PSendBlock = packed record//P2P�����ļ���
    position: Integer;//��ǰλ��
    ID: Integer;//���ݰ����飩��ʶ
    size: Integer;//�������͵��ֽ���
    Data: array [0..BlockSize-1] of byte;//����
    CRC32: DWORD;//CRC32������
    TimeTick: Integer;//ʱ���
  end;
  TP2PSendBlockPack = packed record
    head: TP2PHead;
    body: TP2PSendBlock;
  end;


  TP2PSendBlockResp = packed record//P2P�����ļ������ջظ�
    position: Integer;
    ID: integer;
    checkCRC: Boolean;
    TimeTick: Integer;//����ʱ���
  end;
  TP2PSendBlockRespPack = packed record
    head: TP2PHead;
    body: TP2PSendBlockResp
  end;


  TP2PCancelTransfer = packed record
  end;
  TP2PCancelTransferPack = packed record
    head: TP2PHead;
    body: TP2PCancelTransfer
  end;
implementation

end.
