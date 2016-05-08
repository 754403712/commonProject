unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, utils_DValue, utils.strings, ComCtrls,
  utils_dvalue_multiparts, utils_dvalue_msgpack, utils_base64;

type
  TForm1 = class(TForm)
    pnlTop: TPanel;
    mmoData: TMemo;
    btnParseJSON: TButton;
    btnEncodeJSON: TButton;
    btnClear: TButton;
    btnObjectTester: TButton;
    pgcMain: TPageControl;
    tsJSON: TTabSheet;
    tsMultiParts: TTabSheet;
    btnSave: TButton;
    btnParse: TButton;
    tsMsgPack: TTabSheet;
    btnMsgPackTester: TButton;
    btnParseAFile: TButton;
    dlgOpenFile: TOpenDialog;
    tsDValue: TTabSheet;
    btnDValue: TButton;
    btnBase64: TButton;
    Button1: TButton;
    btnDValueCloneFrom: TButton;
    procedure btnBase64Click(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnDValueClick(Sender: TObject);
    procedure btnDValueCloneFromClick(Sender: TObject);
    procedure btnEncodeJSONClick(Sender: TObject);
    procedure btnMsgPackTesterClick(Sender: TObject);
    procedure btnObjectTesterClick(Sender: TObject);
    procedure btnParseAFileClick(Sender: TObject);
    procedure btnParseClick(Sender: TObject);
    procedure btnParseJSONClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  utils_DValue_JSON;

{$R *.dfm}

procedure TForm1.btnBase64Click(Sender: TObject);
var
  lvDValue:TDValue;
begin
  lvDValue:= TDValue.Create();
  lvDValue.Base64LoadFromFile(ParamStr(0));
  lvDValue.Base64SaveToFile('base64OK.exe');
  lvDValue.Free;
end;

procedure TForm1.btnClearClick(Sender: TObject);
begin
  mmoData.Clear;
end;

procedure TForm1.btnDValueClick(Sender: TObject);
var
  lvDValue, lvDValue2:TDValue;

begin
  lvDValue := TDValue.Create();
  lvDValue.AddArrayChild.AsString := 'abc';
  ShowMessage(JSONEncode(lvDValue));
  lvDValue.Delete(0);
  ShowMessage(JSONEncode(lvDValue));
  lvDValue.AddArrayChild.AsString := 'efg';

  // ���봦��
  lvDValue2 := lvDValue.UnAttach(0);
  ShowMessage(JSONEncode(lvDValue2));

  lvDValue.Free;

  lvDValue2.Free;


end;

procedure TForm1.btnDValueCloneFromClick(Sender: TObject);
var
  lvDValue, lvDValue2:TDValue;
begin
  lvDValue := TDValue.Create();
  lvDValue2 := TDValue.Create();
  lvDValue.ForceByName('a').AsInteger := 1;
  lvDValue2.CloneFrom(lvDValue);
  ShowMessage(Format('%d -> %d', [lvDValue.ForceByName('a').AsInteger, lvDValue2.ForceByName('a').AsInteger]));
  lvDValue2.ForceByName('a').AsInteger := 3;
  ShowMessage(Format('%d -> %d', [lvDValue.ForceByName('a').AsInteger, lvDValue2.ForceByName('a').AsInteger]));
  lvDValue.Free;
  lvDValue2.Free;
end;

procedure TForm1.btnEncodeJSONClick(Sender: TObject);
var
  lvDValue, lvItem:TDValue;
  lvValue:Integer;
  lvSB:TDStringBuilder;
  s:String;
begin
  lvDValue := TDValue.Create();
  lvDValue.ForceByPath('p2.obj').BindObject(Self, faNone);
  lvDValue.ForceByPath('p2.n').AsInteger := 3;
  lvDValue.ForceByName('name').AsString := '����abc';
  lvDValue.ForceByName('__msgid').AsInteger := 1001;
  lvDValue.ForceByPath('p1.name').AsString := 'D10.�����';
  lvDValue.ForceByPath('p2.p2_1.name').AsString := 'D10.�����';
  lvDValue.ForceByPath('p2.num').AsInteger := 1;


  lvItem := lvDValue.ForceByName('array').AddArrayChild;
  lvItem.ForceByName('key1').AsString := '����Ԫ��1';
  lvDValue.ForceByName('array').AddArrayChild.AsString := '����Ԫ��2';

  s :=JSONEncode(lvDValue, true, False, [vdtObject]);
  if trim(mmoData.Lines.Text) = '' then
  begin
    mmoData.Lines.Add(s);
  end;

  lvDValue.Free;

  ShowMessage(s);
end;

procedure TForm1.btnMsgPackTesterClick(Sender: TObject);
var
  lvFileStream:TFileStream;
  lvDValue:TDValue;
  lvFileName:String;
begin
  lvFileName := ExtractFilePath(ParamStr(0)) + 'dvalue_msgpack.dat';
  DeleteFile(lvFileName);

  lvFileStream := TFileStream.Create(lvFileName, fmCreate);
  try
    lvDValue := TDValue.Create();
    lvDValue.ForceByPath('hello.��ע').AsString:= 'HELLO�й�' + sLineBreak + 'World ���';
    lvDValue.ForceByName('fileID').AsString:= ExtractFileName(ParamStr(0));
    lvDValue.ForceByName('data').AsStream.LoadFromFile(ParamStr(0));
    MsgPackEncode(lvDValue, lvFileStream);
    lvDValue.Free;
  finally
    lvFileStream.Free;
  end;

  lvDValue := TDValue.Create();
  MsgPackParseFromFile(lvFileName, lvDValue);
  ShowMessage(lvDValue.ForceByPath('hello.��ע').AsString);
  lvDValue.ForceByName('data').AsStream.SaveToFile('dvalue_parse.dat');
  lvDValue.Free;

end;

procedure TForm1.btnObjectTesterClick(Sender: TObject);
var
  lvDValue:TDValue;
begin
  lvDValue := TDValue.Create();

  // ����Ϊ����Ϊ3
  lvDValue.Value.SetArraySize(3);

  lvDValue.Value.Items[0].BindObject(TButton.Create(nil), faFree);
  lvDValue.Value.Items[1].BindObject(TButton.Create(nil), faFree);
  lvDValue.Value.Items[2].BindObject(TButton.Create(nil), faFree);

  // ����Ϊ����Ϊ2(���ͷ�һ��)
  lvDValue.Value.SetArraySize(2);
  
  lvDValue.Free;

end;

procedure TForm1.btnParseAFileClick(Sender: TObject);
var
  lvDVAlue:TDValue;
  lvTickCount:Cardinal;
begin
  if not dlgOpenFile.Execute then Exit;
  lvDVAlue := TDValue.Create();
  lvTickCount := GetTickCount;
  MultiPartsParseFromFile(lvDVAlue, dlgOpenFile.FileName);
  Self.Caption := Format('MultiPartsParseFromFile, time:%d ns', [GetTickCount - lvTickCount]);

  if lvDVAlue.Count > 0 then
  begin
    ShowMessage(
     Format('%s:%s', [lvDVAlue.Items[0].ForceByName('name').AsString,
            ExtractValueAsUtf8String(lvDVAlue, lvDVAlue.Items[0].ForceByName('name').AsString, '')]));
  end;

  ShowMessage(JSONEncode(lvDVAlue, false, True));
  lvDVAlue.Free;


end;

procedure TForm1.btnParseClick(Sender: TObject);
var
  lvDVAlue:TDValue;
  lvTickCount:Cardinal;
begin
  lvDVAlue := TDValue.Create();
  lvTickCount := GetTickCount;
  MultiPartsParseFromFile(lvDVAlue, 'dvalue_multparts.dat');
  Self.Caption := Format('MultiPartsParseFromFile, time:%d ns', [GetTickCount - lvTickCount]);
  SavePartValueToFile(lvDVAlue, 'data', 'abc.dat');
  ShowMessage(ExtractValueAsUtf8String(lvDVAlue, 'fileID', ''));
  lvDVAlue.Free;
end;

procedure TForm1.btnParseJSONClick(Sender: TObject);
var
  lvDValue, lvDValue2, lvAccountGroup:TDValue;
begin
  lvDValue := TDValue.Create();
  try
    JSONParser(mmoData.Lines.Text, lvDValue);
    ShowMessage(JSONEncode(lvDValue, False));
  finally
    lvDValue.Free;
  end;

end;

procedure TForm1.btnSaveClick(Sender: TObject);
var
  lvFileStream:TFileStream;

  lvDValue:TDValue;

  lvBuilder:TDBufferBuilder;
begin

  lvBuilder := TDBufferBuilder.Create;
  lvDValue := TDValue.Create();
  lvDValue.ForceByName('��ע').AsString:= 'HELLO�й�' + sLineBreak + 'World ���';
  lvDValue.ForceByName('fileID').AsString:= ExtractFileName(ParamStr(0));
  AddFieldValue(lvDValue, 'e����e', '�ܶ��ַ�abc');
  AddFilePart(lvDValue, 'data', ParamStr(0));

  MultiPartsEncode(lvDValue, lvBuilder, '');
  lvDValue.Free;

  lvBuilder.SaveToFile(ExtractFilePath(ParamStr(0)) + 'dvalue_multparts.dat');
  lvBuilder.Free;


end;

procedure TForm1.Button1Click(Sender: TObject);
var
  lvStream, lvStream2:TMemoryStream;
  lvStr1, lvStr2:string;
  l:Integer;

begin
  lvStream := TMemoryStream.Create();
  lvStream2 := TMemoryStream.Create();
  lvStream.LoadFromFile(ParamStr(0));
  lvStr1 := Base64Encode(lvStream);
  lvStr2 := Base64Encode(PByte(lvStream.Memory), lvStream.Size);
  if lvStr1 <> lvStr2 then
  begin
    ShowMessage('no');
  end;

  lvStream2.SetSize(Length(lvStr2));
  l:=Base64Decode(PByte(lvStr2), Length(lvStr2), PByte(lvStream2.Memory));
  lvStream2.SetSize(l);
  lvStream2.SaveToFile('base64_2.dat');

  lvStream2.Clear;
  Base64Decode(lvStr1, lvStream2);

  lvStream2.SaveToFile('base64.dat');


  lvStream.Free;
  lvStream2.Free;
  


end;

end.
