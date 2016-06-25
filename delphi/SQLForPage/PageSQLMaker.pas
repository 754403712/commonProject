unit PageSQLMaker;

interface

uses
  utils_strings, SysUtils, Classes, StrUtils;



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

  /// <summary>
  ///  ʹ��ģ��sql
  ///  limit ���з�ҳ
  /// </summary>
  TPageMySQLMaker = class(TPageSQLMaker)
  public
    function GetRecordCounterSQL: string; override;

    /// <summary>
    ///   ���ɻ�ȡ�ڼ�ҳ�����ݵ�SQL���
    ///   pageIndex��0��ʼ
    /// </summary>
    function GetPageSQL(pvPageIndex:Integer): String; override;
  end;


  TPageMSSQLMakerTemplate2012 = class(TPageSQLMaker)
  public
    function GetRecordCounterSQL: string; override;

    /// <summary>
    ///   ���ɻ�ȡ�ڼ�ҳ�����ݵ�SQL���
    ///   pageIndex��0��ʼ
    /// </summary>
    function GetPageSQL(pvPageIndex:Integer): String; override;
  end;

  /// <summary>
  ///   ֻ֧��2012���ϵ�mssqlserver
  ///   ʹ��fetch next
  /// </summary>
  TPageMSSQLMaker2012 = class(TPageSQLMaker)
  private
    FOrderBy: String;
    FPrimaryKey: String;
    FSelectFields: String;
    FSortType: Integer;
    FTableName: String;
    FWhereSection: String;
  public
    function GetRecordCounterSQL: string; override;

    /// <summary>
    ///   ���ɻ�ȡ�ڼ�ҳ�����ݵ�SQL���
    ///   pageIndex��1��ʼ
    /// </summary>
    function GetPageSQL(pvPageIndex:Integer): String; override;
  public
    property OrderBy: String read FOrderBy write FOrderBy;
    property PrimaryKey: String read FPrimaryKey write FPrimaryKey;
    property SelectFields: String read FSelectFields write FSelectFields;
    property SortType: Integer read FSortType write FSortType;
    property TableName: String read FTableName write FTableName;
    property WhereSection: String read FWhereSection write FWhereSection;
  end;


  /// <summary>
  ///   ֻ֧��2005���ϵ�mssqlserver
  ///   ʹ��rownumber���з�ҳ
  /// </summary>
  TPageMSSQLMaker2005 = class(TPageSQLMaker)
  private
    FOrderBy: String;
    FPrimaryKey: String;
    FSelectFields: String;
    FSortType: Integer;
    FTableName: String;
    FWhereSection: String;
  public
    function GetRecordCounterSQL: string; override;

    /// <summary>
    ///   ���ɻ�ȡ�ڼ�ҳ�����ݵ�SQL���
    ///   pageIndex��0��ʼ
    /// </summary>
    function GetPageSQL(pvPageIndex:Integer): String; override;
  public
    property OrderBy: String read FOrderBy write FOrderBy;
    property PrimaryKey: String read FPrimaryKey write FPrimaryKey;
    property SelectFields: String read FSelectFields write FSelectFields;
    property SortType: Integer read FSortType write FSortType;
    property TableName: String read FTableName write FTableName;
    property WhereSection: String read FWhereSection write FWhereSection;
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

{ TPageMSSQLMaker2012 }

function TPageMSSQLMaker2012.GetPageSQL(pvPageIndex: Integer): String;
var
  lvSQL:String;
begin
  lvSQL := 'SELECT '+FSelectFields+' FROM '+FTableName;
  if Length(FWhereSection) <> 0 then
    lvSQL := lvSQL + ' WHERE '+ FWhereSection;
    
  lvSQL := lvSQL + ' Order By ';
  if (FOrderBy='') then
    lvSQL := lvSQL + FPrimaryKey
  Else
    lvSQL := lvSQL + FOrderBy;

  if (SortType =2) then  lvSQL := lvSQL +' desc ';

  if (pvPageIndex<=1) then
    lvSQL := lvSQL + ' OFFSET 0 ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY'
  Else
    lvSQL := lvSQL + ' OFFSET '+Inttostr((pvPageIndex - 1) * PageSize + 1)+' ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY';
  Result := lvSQL;
end;

function TPageMSSQLMaker2012.GetRecordCounterSQL: string;
var
  lvSQL:String;
begin
  lvSQL := 'SELECT COUNT(' + FPrimaryKey + ') FROM '+FTableName;
  if Length(FWhereSection) <> 0 then
    lvSQL := lvSQL + ' WHERE '+ FWhereSection;
  Result := lvSQL;

end;

{ TPageMSSQLMaker2005 }

function TPageMSSQLMaker2005.GetPageSQL(pvPageIndex: Integer): String;
var
  lvSQL:String;
  lvBuilder:TDStringBuilder;
begin
  lvBuilder := TDStringBuilder.Create;
  try
    lvBuilder.AppendLine(';WITH __table AS (');
    lvBuilder.Append(' SELECT TOP (').Append(pvPageIndex + 1 * FPageSize).AppendLine(')');
    lvBuilder.AppendLine(FSelectFields);
    // ���(____sn)
    lvBuilder.Append(' , ROW_NUMBER() OVER(ORDER BY ');
    if Length(FOrderBy)=0 then
      lvBuilder.Append(FPrimaryKey)
    Else
      lvBuilder.Append(FOrderBy);
    if (SortType =2) then  lvBuilder.Append(' DESC ');
    lvBuilder.AppendLine(') AS ____sn');

    lvBuilder.Append('FROM ').AppendLine(FTableName);
    if Length(FWhereSection) <> 0 then
      lvBuilder.Append('WHERE ').AppendLine(FWhereSection);

    lvBuilder.Append('ORDER BY ');
    if Length(FOrderBy)=0 then
      lvBuilder.Append(FPrimaryKey)
    Else
      lvBuilder.Append(FOrderBy);
    if (SortType =2) then  lvBuilder.AppendLine(' DESC ');
    lvBuilder.AppendLine(') ');  // end with __table
    lvBuilder.AppendLine('SELECT ');
    lvBuilder.AppendLine(FSelectFields);
    lvBuilder.AppendLine('FROM __table');
    lvBuilder.Append('WHERE ____sn BETWEEN ').Append(pvPageIndex * FPageSize + 1).Append(' AND ').Append((pvPageIndex + 1) * FPageSize).Append(sLineBreak);
    lvBuilder.AppendLine('ORDER BY ____sn');
    Result := lvBuilder.ToString;
  finally
    lvBuilder.Free;
  end;
//;WITH cte AS (
//SELECT TOP (@page * @size)
//CustomerID,
//CustomerNumber,
//CustomerName,
//CustomerCity,
//ROW_NUMBER() OVER(ORDER BY CustomerName ) AS Seq --,COUNT(*) OVER(PARTITION BY '') AS Total
//FROM Customers
//WHERE CustomerCity IN ('A-City','B-City')
//ORDER BY CustomerName ASC
//)
//SELECT CustomerID,CustomerNumber,CustomerName,CustomerCity,@Total
//FROM cte
//WHERE seq BETWEEN (@page - 1 ) * @size + 1 AND @page * @size
//ORDER BY seq;

end;

function TPageMSSQLMaker2005.GetRecordCounterSQL: string;
var
  lvSQL:String;
begin
  lvSQL := 'SELECT COUNT(' + FPrimaryKey + ') FROM '+FTableName;
  if Length(FWhereSection) <> 0 then
    lvSQL := lvSQL + ' WHERE '+ FWhereSection;
  Result := lvSQL;

end;

{ TPageMSSQLMakerTemplate2012 }

function TPageMSSQLMakerTemplate2012.GetPageSQL(pvPageIndex: Integer): String;
var
  ok: boolean;
  DatabaseId, SQLStr, FetchSQL: AnsiString;
  TmpSqlComm, TopSqlComm, TableName, TopFieldName:String;
  SqlCommand: string;
  PoolId,ConnectionId,j, StrI, TableSize: integer;
  CurPage, totalRecords, TotalPages:Integer;
  EnableBCD, CompSQLComm: boolean;
  IsUnicode:Boolean;
  Err:String;
begin
  SqlCommand:=FTemplateSQL;
  CurPage := pvPageIndex;


  SqlCommand := AnsiLowerCase(AnsiReplaceStr(SqlCommand,'  ',' '));
  CompSQLComm := (Pos(' from ',SqlCommand)>0);      //�ж��Ƿ�Ϊ����SQL���
  if not CompSQLComm then
  begin
    raise Exception.Create('��������SQL���,���ܽ��з�ҳSQL�����ȡ!');
  end;

  //==============
  if (CurPage<=1) then
  Begin
    FetchSQL := ' OFFSET 0 ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY'
  End
  Else
  Begin
    FetchSQL := ' OFFSET '+Inttostr((CurPage -1 ) * PageSize + 1)+' ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY'
  End;  

  if (Pos('order by', SqlCommand)>0) And (AnsiPos(' top ', SqlCommand)<1) then
  Begin          //�ж��Ƿ��������﷨ �� Top �﷨
    sqlStr := SqlCommand + FetchSQL;
  End Else
  Begin    // ���û��OrderBy �����ҳ���һ���ֶ�
    raise Exception.Create('��ҳ����б���Ҫ�������趨');
  End;

  Result := SqlStr;
end;

function TPageMSSQLMakerTemplate2012.GetRecordCounterSQL: string;
var
  TmpSqlComm, TopSqlComm, TableName, TopFieldName:String;
  SqlCommand, OlsSQL: string;
  StrI: integer;
  CompSQLComm: boolean;
begin
  SqlCommand:=FTemplateSQL;

  SqlCommand := AnsiLowerCase(AnsiReplaceStr(SqlCommand,'  ',' '));
  CompSQLComm := (Pos(' from ',SqlCommand)>0);      //�ж��Ƿ�Ϊ����SQL���

  if not CompSQLComm then
  begin
    raise Exception.Create('��������SQL���,���ܽ���ͳ�Ƽ�¼��SQL���!');
  end;

  if (AnsiPos('group by',SqlCommand)>0) then             //�ж��Ƿ�Ϊ�����ѯ���
  Begin
    StrI := AnsiPos('order by', SqlCommand);
    if (StrI>0) then
      SqlCommand := 'select Count(*) as RecordCount From ('+Copy(SqlCommand,0,StrI -1)+') as a'
    Else
      SqlCommand := 'select Count(*) as RecordCount From ('+SqlCommand+') as a';
  end
  else
  Begin                                                 //�Ƿ����ѯ���
    strI := AnsiPos(' from', SqlCommand) + 1;
    TmpSqlComm := Trim(Copy(SqlCommand, strI, StrLen(PChar(SqlCommand))));
    if (AnsiPos('order by', SqlCommand)>0) then
    begin
      strI := AnsiPos('order by', TmpSqlComm);
      TmpSqlComm := Copy(TmpSqlComm,0,StrI - 1);
    End;
    SqlCommand := 'select count(*) AS RecordCount '+ TmpSqlComm;
  End;
  // sqlCommand Ϊͳ��RecordCount
  Result := SqlCommand;


end;

end.
