unit PageSQLMaker;

interface

uses
  utils.strings, SysUtils, Classes;



type
  TPageSQLMaker = class(TObject)
  private
    FPageSize: Integer;
    FTemplateSQL: String;
  public
    function GetRecordCounterSQL: string; virtual;
    function GetPageSQL(pvPageIndex:Integer): String; virtual;
    property PageSize: Integer read FPageSize write FPageSize;
    property TemplateSQL: String read FTemplateSQL write FTemplateSQL;
  end;

  TPageMySQLMaker = class(TPageSQLMaker)
  public
    function GetRecordCounterSQL: string; override;

    /// <summary>
    ///   ���ɻ�ȡ�ڼ�ҳ�����ݵ�SQL���
    ///   pageIndex��0��ʼ
    /// </summary>
    function GetPageSQL(pvPageIndex:Integer): String; override;
  end;



implementation

function StringReplaceArea(s, pvStart, pvEnd, pvNewStr: string; pvIgnoreCase:
    Boolean): string;
var
  lvStr, lvStr2:String;
  lvSearchPtr, lvStartPtr:PChar;
  lvSB:TDStringBuilder;
  iStart, iEnd:Integer;
begin
  iStart := Length(pvStart);
  iEnd := Length(pvEnd);
  
  lvSB:= TDStringBuilder.Create;
  try
    lvSearchPtr := PChar(s);
    while True do
    begin
      lvStartPtr := lvSearchPtr;
      lvStr := LeftUntilStr(lvSearchPtr,PChar(pvStart), pvIgnoreCase);      
      if lvStr = ''  then
      begin     // û��
        lvSB.Append(lvStartPtr);
        Break;
      end;
      // skip start
      Inc(lvSearchPtr, iStart);
      lvStr2 := LeftUntilStr(lvSearchPtr,PChar(pvEnd), pvIgnoreCase);
      if lvStr2 = '' then
      begin  
        // û����������
        lvSB.Append(lvStartPtr);
        Break;
      end;          
      Inc(lvSearchPtr, iEnd);

      lvSB.Append(lvStr);
      lvSB.Append(pvNewStr);   

    end;
    Result := lvSB.ToString;
  finally
    lvSB.Free;
  end;
  
end;

function TPageSQLMaker.GetPageSQL(pvPageIndex:Integer): String;
begin
  Result := '';
end;

function TPageSQLMaker.GetRecordCounterSQL: string;
begin
  Result := '';
end;

function TPageMySQLMaker.GetPageSQL(pvPageIndex:Integer): String;
var
  lvSQL, lvPageStr:String;
begin
  lvSQL := FTemplateSQL;
//  [selectlist][/selectlist] �����ڽ���countͳ�Ƽ�¼ʱ������滻 ��count(1) as RecordCount
//  [countIgnore][/countIgnore] �����ڽ���countͳ�Ƽ�¼ʱ�ᱻ�滻�ɿ��ַ���
//  [page][/page]   ��ҳ��� limit 0, 10
  lvSQL := StringReplace(lvSQL, '[selectlist]', '', [rfReplaceAll]);
  lvSQL := StringReplace(lvSQL, '[/selectlist]', '', [rfReplaceAll]);
  lvSQL := StringReplace(lvSQL, '[countIgnore]', '', [rfReplaceAll]);
  lvSQL := StringReplace(lvSQL, '[/countIgnore]', '', [rfReplaceAll]);
  lvPageStr := Format(' limit %d, %d ', [pvPageIndex * FPageSize, FPageSize]);
  lvSQL := StringReplace(lvSQL, '[page]', lvPageStr,  [rfReplaceAll]);
  Result := lvSQL;

end;

function TPageMySQLMaker.GetRecordCounterSQL: string;
var
  lvSQL:String;
begin
  lvSQL := FTemplateSQL;
//  [selectlist][/selectlist] �����ڽ���countͳ�Ƽ�¼ʱ������滻 ��count(1) as RecordCount
//  [countIgnore][/countIgnore] �����ڽ���countͳ�Ƽ�¼ʱ�ᱻ�滻�ɿ��ַ���
//  [page][/page]   ��ҳ��� limit 0, 10
  lvSQL := StringReplaceArea(lvSQL, '[selectlist]', '[/selectlist]', 'COUNT(1) AS RecordCount', True);
  lvSQL := StringReplaceArea(lvSQL, '[countIgnore]', '[/countIgnore]', '', True);
  lvSQL := StringReplace(lvSQL, '[page]', '',  [rfReplaceAll]);
  Result := lvSQL;

end;

end.
