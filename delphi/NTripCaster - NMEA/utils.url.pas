unit utils.url;

interface

uses
  utils.strings;


type
  TURL = class(TObject)
  private
    FHost: string;
    FUser: String;
    FPassword: String;
    FParamStr: String;
    FPort: string;
    FProtocol: string;
    /// <summary>
    ///   ����·������
    ///   127.0.0.1:9983
    ///   user:password@127.0.0.1:9983/diocp/a.html
    /// </summary>
    procedure InnerParseUrlPath(const pvPath:String);
  public
    procedure SetURL(pvURL:String);

    /// <summary>
    ///   Э��, http, https, ftp
    /// </summary>
    property Protocol: string read FProtocol write FProtocol;

    /// <summary>
    ///   ������ַ
    /// </summary>
    property Host: string read FHost write FHost;

    /// <summary>
    ///   �˿�
    /// </summary>
    property Port: string read FPort write FPort;

    /// <summary>
    ///   ����
    /// </summary>
    property ParamStr: String read FParamStr write FParamStr;




  end;

implementation

{ TURL }

procedure TURL.InnerParseUrlPath(const pvPath: String);
var
  lvP, lvTempP:PChar;
  lvTempStr:String;
begin
  if length(pvPath) = 0 then Exit;

  lvP := PChar(pvPath);
  /// user:password
  lvTempStr := LeftUntil(lvP, ['@']);

  if lvTempStr <> '' then
  begin  // �����û���������
    lvTempP := PChar(lvTempStr);

    FUser := LeftUntil(lvTempP, [':']);
    if FUser <> '' then
    begin
      SkipChars(lvTempP, [':']);
      FPassword := lvTempP;
    end else
    begin
      // ������
      FUser := lvTempStr;
    end;
    SkipChars(lvP, ['@']);
  end;


end;

procedure TURL.SetURL(pvURL: String);
var
  lvPSave, lvPUrl:PChar;
  lvTempStr:String;
begin
  FProtocol := '';
  FHost := '';
  FPort := '';
  FPassword := '';
  FUser := '';

  lvPUrl := PChar(pvURL);

  if (lvPUrl = nil) or (lvPUrl^ = #0) then Exit;

  // http, ftp... or none
  FProtocol := LeftUntilStr(lvPUrl, '://');
  if FProtocol <> '' then lvPUrl := lvPUrl + 3; // ���� ://

  lvPSave := lvPUrl;  // ����λ��

  ///  ·���Ͳ���
  ///  www.diocp.org/image/xxx.asp
  lvTempStr := LeftUntil(lvPUrl, ['?']);

  // ���û�в���
  if lvTempStr = '' then
  begin
    /// ·������ǩ
    lvTempStr := LeftUntil(lvPUrl, ['#']);
  end;


  





  


end;

end.
