(*
 *	 Unit owner: d10.�����
 *	       blog: http://www.cnblogs.com/dksoft
 *     homePage: www.diocp.org
 *
 *   2015-03-05 12:53:38
 *     �޸�URLEncode��URLDecode��Anddriod��UNICODE�µ��쳣
 *
 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
 *   2015-04-02 12:52:43
 *     �޸�SplitStrings,�ָ������һ���ַ���û�м����bug  abcd&33&eef
 *       ��л(Xjumping  990669769)����bug
 *
 *)
 
unit utils.strings;

interface

uses
  Classes, SysUtils
  {$IFDEF MSWINDOWS}
    , windows
{$ENDIF}
{$IF (RTLVersion>=26) and (not Defined(NEXTGEN))}
    , AnsiStrings
{$IFEND >=XE5}
  ;

type
{$IFDEF MSWINDOWS}  // Windowsƽ̨�������ʹ��AnsiString
  URLString = AnsiString;
  URLChar = AnsiChar;
{$ELSE}
  // andriod����ʹ��
  URLString = String;
  URLChar = Char;
  {$DEFINE UNICODE_URL}
{$ENDIF}

{$IFDEF UNICODE}
WChar = Char;
PWChar = PChar;
{$ELSE}
WChar = WideChar;
PWChar = PWideChar;
IntPtr = Integer;
{$ENDIF}


/// <summary>
///   �����ַ�
/// </summary>
/// <returns>
///   �����������ַ�
/// </returns>
/// <param name="p"> ��ʼ���λ�� </param>
/// <param name="pvChars"> ������Щ�ַ���ֹͣ��Ȼ�󷵻� </param>
function SkipUntil(var p:PChar; pvChars: TSysCharSet): Integer;


/// <summary>
///   �����ַ�
/// </summary>
/// <returns>
///   �����������ַ�����
/// </returns>
/// <param name="p"> Դ(�ַ���)λ�� </param>
/// <param name="pvChars"> (TSysCharSet) </param>
function SkipChars(var p:PChar; pvChars: TSysCharSet): Integer;


/// <summary>
///   ����߿�ʼ��ȡ�ַ�
/// </summary>
/// <returns>
///   ���ؽ�ȡ�����ַ���
/// </returns>
/// <param name="p"> Դ(�ַ���)��ʼ��λ��, ƥ��ɹ��������pvSpliter���״γ���λ��, ���򲻻�����ƶ�</param>
/// <param name="pvChars"> (TSysCharSet) </param>
function LeftUntil(var p:PChar; pvChars: TSysCharSet): string;


/// <summary>
///   ����߿�ʼ��ȡ�ַ���
/// </summary>
/// <returns>
///   ���ؽ�ȡ�����ַ���
/// </returns>
/// <param name="p"> Դ(�ַ���), ƥ��ɹ��������pvSpliter���״γ���λ��, ���򲻻�����ƶ� </param>
/// <param name="pvSpliter"> �ָ�(�ַ���) </param>
function LeftUntilStr(var P: PChar; pvSpliter: PChar; pvIgnoreCase: Boolean =
    true): string;

/// <summary>
///   ����SpliterChars���ṩ���ַ������зָ��ַ��������뵽Strings��
///     * �����ַ�ǰ��Ŀո�
/// </summary>
/// <returns>
///   ���طָ�ĸ���
/// </returns>
/// <param name="s"> Դ�ַ��� </param>
/// <param name="pvStrings"> ��������ַ����б� </param>
/// <param name="pvSpliterChars"> �ָ��� </param>
function SplitStrings(s:String; pvStrings:TStrings; pvSpliterChars
    :TSysCharSet): Integer;

/// <summary>
///   URL���ݽ���,
///    Get��Post�����ݶ�������url����
/// </summary>
/// <returns>
///   ���ؽ�����URL����
/// </returns>
/// <param name="ASrc"> ԭʼ���� </param>
/// <param name="pvIsPostData"> Post��ԭʼ������ԭʼ�Ŀո񾭹�UrlEncode����+�� </param>
function URLDecode(const ASrc: URLString; pvIsPostData: Boolean = true):URLString;

/// <summary>
///  �����ݽ���URL����
/// </summary>
/// <returns>
///   ����URL����õ�����
/// </returns>
/// <param name="S"> ��Ҫ��������� </param>
/// <param name="pvIsPostData"> Post��ԭʼ������ԭʼ�Ŀո񾭹�UrlEncode����+�� </param>
function URLEncode(S: string; pvIsPostData: Boolean = true): URLString;


/// <summary>
///  ��Strings�и�����������ֵ
/// </summary>
/// <returns> String
/// </returns>
/// <param name="pvStrings"> (TStrings) </param>
/// <param name="pvName"> (string) </param>
/// <param name="pvSpliters"> ���ֺ�ֵ�ķָ�� </param>
function StringsValueOfName(pvStrings: TStrings; const pvName: string;
    pvSpliters: TSysCharSet; pvTrim: Boolean): String;


/// <summary>
///   ����PSub��P�г��ֵĵ�һ��λ��
///   ��ȷ����
///   ���PSubΪ���ַ���(#0, nil)��ֱ�ӷ���P
/// </summary>
/// <returns>
///   ����ҵ�, ���ص�һ���ַ���λ��
///   �Ҳ�������False
///   * ����qdac.qstrings
/// </returns>
/// <param name="P"> Ҫ��ʼ����(�ַ���) </param>
/// <param name="PSub"> Ҫ��(�ַ���) </param>
function StrStr(P:PChar; PSub:PChar): PChar;

/// <summary>
///   ����PSub��P�г��ֵĵ�һ��λ��
///   ���Դ�Сд
///   ���PSubΪ���ַ���(#0, nil)��ֱ�ӷ���P
/// </summary>
/// <returns>
///   ����ҵ�, ���ص�һ���ַ���λ��
///   �Ҳ�������nil
///   * ����qdac.qstrings
/// </returns>
/// <param name="P"> Ҫ��ʼ����(�ַ���) </param>
/// <param name="PSub"> Ҫ��(�ַ���) </param>
function StrStrIgnoreCase(P, PSub: PChar): PChar;


/// <summary>
///  �ַ�ת��д
///  * ����qdac.qstrings
/// </summary>
function UpperChar(c: Char): Char;

/// <summary>
///  aStr�Ƿ���Strs�б���
/// </summary>
/// <returns>
///   ������б��з���true
/// </returns>
/// <param name="pvStr"> sensors,1,3.1415926,1.1,1.2,1.3 </param>
/// <param name="pvStringList"> (array of string) </param>
function StrIndexOf(const pvStr: string; const pvStringList: array of string):
    Integer;

/// <summary>
///   ����PSub��P�г��ֵĵ�һ��λ��
/// </summary>
/// <returns>
///   ����ҵ�, ����ָ���һ��pvSub��λ��
///   �Ҳ������� Nil
/// </returns>
/// <param name="pvSource"> ���� </param>
/// <param name="pvSourceLen"> ���ݳ��� </param>
/// <param name="pvSub"> ���ҵ����� </param>
/// <param name="pvSubLen"> ���ҵ����ݳ��� </param>
function SearchPointer(pvSource: Pointer; pvSourceLen, pvStartIndex: Integer;
    pvSub: Pointer; pvSubLen: Integer): Pointer;


/// <summary>procedure DeleteChars
/// </summary>
/// <returns> string
/// </returns>
/// <param name="s"> (string) </param>
/// <param name="pvCharSets"> (TSysCharSet) </param>
function DeleteChars(const s: string; pvCharSets: TSysCharSet): string;


implementation



{$IFDEF MSWINDOWS}
type
  TMSVCStrStr = function(s1, s2: PAnsiChar): PAnsiChar; cdecl;
  TMSVCStrStrW = function(s1, s2: PWChar): PWChar; cdecl;
  TMSVCMemCmp = function(s1, s2: Pointer; len: Integer): Integer; cdecl;

var
  hMsvcrtl: HMODULE;
  VCStrStr: TMSVCStrStr;
  VCStrStrW: TMSVCStrStrW;
  VCMemCmp: TMSVCMemCmp;
{$ENDIF}

{$if CompilerVersion < 20}
function CharInSet(C: Char; const CharSet: TSysCharSet): Boolean;
begin
  Result := C in CharSet;
end;
{$ifend}


function DeleteChars(const s: string; pvCharSets: TSysCharSet): string;
var
  i, l, times: Integer;
  lvStr: string;
begin
  l := Length(s);
  SetLength(lvStr, l);
  times := 0;
  for i := 1 to l do
  begin
    if not CharInSet(s[i], pvCharSets) then
    begin
      inc(times);
      lvStr[times] := s[i];
    end;
  end;
  SetLength(lvStr, times);
  Result := lvStr;
end;


function StrIndexOf(const pvStr: string; const pvStringList: array of string):
    Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := Low(pvStringList) to High(pvStringList) do
  begin
    if SameText(pvStringList[i], pvStr) then
    begin
      Result := i;
      Break;
    end;
  end;
end;


function UpperChar(c: Char): Char;
begin
  {$IFDEF UNICODE}
  if (c >= #$61) and (c <= #$7A) then
    Result := Char(PWord(@c)^ xor $20)
  else
    Result := c;
  {$ELSE}
  if (c >= #$61) and (c <= #$7A) then
    Result := Char(ord(c) xor $20)
  else
    Result := c;
  {$ENDIF}
end;


function SkipUntil(var p:PChar; pvChars: TSysCharSet): Integer;
var
  ps: PChar;
begin
  ps := p;
  while p^ <> #0 do
  begin
    if CharInSet(p^, pvChars) then
      Break
    else
      Inc(P);
  end;
  Result := p - ps;
end;

function LeftUntil(var p:PChar; pvChars: TSysCharSet): string;
var
  lvPTemp: PChar;
  l:Integer;
  lvMatched: Byte;
begin
  lvMatched := 0;
  lvPTemp := p;
  while lvPTemp^ <> #0 do
  begin
    if CharInSet(lvPTemp^, pvChars) then
    begin            // ƥ�䵽
      lvMatched := 1;
      Break;
    end else
      Inc(lvPTemp);
  end;
  if lvMatched = 0 then
  begin   // û��ƥ�䵽
    Result := '';
  end else
  begin   // ƥ�䵽
    l := lvPTemp-P;
    SetLength(Result, l);
    if SizeOf(Char) = 1 then
    begin
      Move(P^, PChar(Result)^, l);
    end else
    begin
      l := l shl 1;
      Move(P^, PChar(Result)^, l);
    end;
    P := lvPTemp;  // ��ת����λ��
  end;
end;

function SkipChars(var p:PChar; pvChars: TSysCharSet): Integer;
var
  ps: PChar;
begin
  ps := p;
  while p^ <> #0 do
  begin
    if CharInSet(p^, pvChars) then
      Inc(P)
    else
      Break;
  end;
  Result := p - ps;
end;


function SplitStrings(s:String; pvStrings:TStrings; pvSpliterChars
    :TSysCharSet): Integer;
var
  p:PChar;
  lvValue : String;
begin
  p := PChar(s);
  Result := 0;
  while True do
  begin
    // �����հ�
    SkipChars(p, [' ']);
    lvValue := LeftUntil(P, pvSpliterChars);

    if lvValue = '' then
    begin
      if P^ <> #0 then
      begin  // ���һ���ַ�
        // ��ӵ��б���
        pvStrings.Add(P);
        inc(Result);
      end;
      Exit;
    end else
    begin
      // �����ָ���
      SkipChars(p, pvSpliterChars);

      // ��ӵ��б���
      pvStrings.Add(lvValue);
      inc(Result);
    end;
  end;
end;


function URLDecode(const ASrc: URLString; pvIsPostData: Boolean = true): URLString;
var
  i, j: integer;
  {$IFDEF UNICODE_URL}
  lvRawBytes:TBytes;
  lvSrcBytes:TBytes;
  {$ENDIF}
begin

  {$IFDEF UNICODE_URL}
  SetLength(lvRawBytes, Length(ASrc));   // Ԥ������һ���ַ���������־
  lvSrcBytes := TEncoding.ANSI.GetBytes(ASrc);
  j := 0;  // ��0��ʼ
  i := 0;
  while i <= Length(ASrc) do
  begin
    if (pvIsPostData) and (lvSrcBytes[i] = 43) then   //43(+) �ű�ɿո�, Post��ԭʼ����������� �ո�ʱ���� +��
    begin
      lvRawBytes[j] := 32; // Ord(' ');
    end else if lvSrcBytes[i] <> 37 then      //'%' = 37
    begin
      lvRawBytes[j] :=lvSrcBytes[i];
    end else
    begin
      Inc(i); // skip the % char
      try
      lvRawBytes[j] := StrToInt('$' +URLChar(lvSrcBytes[i]) + URLChar(lvSrcBytes[i+1]));
      except end;
      Inc(i, 1);  // ������һ���ַ�.

    end;
    Inc(i);
    Inc(j);
  end;
  SetLength(lvRawBytes, j);
  Result := TEncoding.ANSI.GetString(lvRawBytes);
  {$ELSE}
  SetLength(Result, Length(ASrc));   // Ԥ������һ���ַ���������־
  j := 1;  // ��1��ʼ
  i := 1;
  while i <= Length(ASrc) do
  begin
    if (pvIsPostData) and (ASrc[i] = '+') then   // + �ű�ɿո�, Post��ԭʼ����������� �ո�ʱ���� +��
    begin
      Result[j] := ' ';
    end else if ASrc[i] <> '%' then
    begin
      Result[j] := ASrc[i];
    end else 
    begin
      Inc(i); // skip the % char
      try
      Result[j] := URLChar(StrToInt('$' + ASrc[i] + ASrc[i+1]));
      except end;
      Inc(i, 1);  // ������һ���ַ�.

    end;
    Inc(i);
    Inc(j);
  end;
  SetLength(Result, j - 1);
  {$ENDIF}

end;




function URLEncode(S: string; pvIsPostData: Boolean = true): URLString;
var
  i: Integer; // loops thru characters in string
  {$IFDEF UNICODE_URL}
  lvRawBytes:TBytes;
  {$ENDIF}
begin
  {$IFDEF UNICODE_URL}
  lvRawBytes := TEncoding.ANSI.GetBytes(S);
  for i := 0 to Length(lvRawBytes) - 1 do
  begin
    case lvRawBytes[i] of
      //'A' .. 'Z', 'a'.. 'z', '0' .. '9', '-', '_', '.':
      65..90, 97..122, 48..57, 45, 95, 46:
        Result := Result + URLChar(lvRawBytes[i]);
      //' ':
      32:
        if pvIsPostData then
        begin     // Post��������ǿո���Ҫ����� +
          Result := Result + '+';
        end else
        begin
          Result := Result + '%20';
        end
    else
      Result := Result + '%' + SysUtils.IntToHex(lvRawBytes[i], 2);
    end;
  end;
  {$ELSE}
  Result := '';
  for i := 1 to Length(S) do
  begin
    case S[i] of
      'A' .. 'Z', 'a' .. 'z', '0' .. '9', '-', '_', '.':
        Result := Result + S[i];
      ' ':
        if pvIsPostData then
        begin     // Post��������ǿո���Ҫ����� +
          Result := Result + '+';
        end else
        begin
          Result := Result + '%20';
        end
    else
      Result := Result + '%' + SysUtils.IntToHex(Ord(S[i]), 2);
    end;
  end;
  {$ENDIF}
end;

function StringsValueOfName(pvStrings: TStrings; const pvName: string;
    pvSpliters: TSysCharSet; pvTrim: Boolean): String;
var
  i : Integer;
  s : string;
  lvName: String;
  p : PChar;
  lvSpliters:TSysCharSet;
begin
  lvSpliters := pvSpliters;
  Result := '';

  // context-length : 256
  for i := 0 to pvStrings.Count -1 do
  begin
    s := pvStrings[i];
    p := PChar(s);

    // ��ȡ����
    lvName := LeftUntil(p, lvSpliters);

    if pvTrim then lvName := Trim(lvName);

    if CompareText(lvName, pvName) = 0 then
    begin
      // �����ָ���
      SkipChars(p, lvSpliters);

      // ��ȡֵ
      Result := P;

      // ��ȡֵ
      if pvTrim then Result := Trim(Result);

      Exit;
    end;
  end;

end;

function StrStrIgnoreCase(P, PSub: PChar): PChar;
var
  I: Integer;
  lvSubUP: String;
begin
  Result := nil;
  if (P = nil) or (PSub = nil) then
    Exit;
  lvSubUP := UpperCase(PSub);
  PSub := PChar(lvSubUP);
  while P^ <> #0 do
  begin
    if UpperChar(P^) = PSub^ then
    begin
      I := 1;
      while PSub[I] <> #0 do
      begin
        if UpperChar(P[I]) = PSub[I] then
          Inc(I)
        else
          Break;
      end;
      if PSub[I] = #0 then
      begin
        Result := P;
        Break;
      end;
    end;
    Inc(P);
  end;
end;

function StrStr(P: PChar; PSub: PChar): PChar;
var
  I: Integer;
begin
{$IFDEF MSWINDOWS}
{$IFDEF UNICODE}
  if Assigned(VCStrStrW) then
  begin
    Result := VCStrStrW(P, PSub);
    Exit;
  end;
{$ELSE}
  if Assigned(VCStrStr) then
  begin
    Result := VCStrStr(P, PSub);
    Exit;
  end;
{$ENDIF}
{$ENDIF}

  if (PSub = nil) or (PSub^ = #0) then
    Result := P
  else
  begin
    Result := nil;
    while P^ <> #0 do
    begin
      if P^ = PSub^ then
      begin
        I := 1;     // �Ӻ���ڶ����ַ���ʼ�Ա�
        while PSub[I] <> #0 do
        begin
          if P[I] = PSub[I] then
            Inc(I)
          else
            Break;
        end;

        if PSub[I] = #0 then
        begin  // P1��P2�Ѿ�ƥ�䵽��ĩβ(ƥ��ɹ�)
          Result := P;
          Break;
        end;
      end;
      Inc(P);
    end;
  end;
end;

function LeftUntilStr(var P: PChar; pvSpliter: PChar; pvIgnoreCase: Boolean =
    true): string;
var
  lvPUntil:PChar;
  l : Integer;
begin
  if pvIgnoreCase then
  begin
    lvPUntil := StrStrIgnoreCase(P, pvSpliter);
  end else
  begin
    lvPUntil := StrStr(P, pvSpliter);
  end;
  if lvPUntil = nil then
  begin
    Result := '';
    P := nil;
  end else
  begin
    l := lvPUntil-P;
    if l = 0 then
    begin
      Result := '';
    end else
    begin
      SetLength(Result, l);
      if SizeOf(Char) = 1 then
      begin
        Move(P^, PChar(Result)^, l);
      end else
      begin
        l := l shl 1;
        Move(P^, PChar(Result)^, l);
      end;
      P := lvPUntil;
    end;
  end;
  

end;

function SearchPointer(pvSource: Pointer; pvSourceLen, pvStartIndex: Integer;
    pvSub: Pointer; pvSubLen: Integer): Pointer;
var
  I, j, l: Integer;
  lvTempP, lvTempPSub, lvTempP2, lvTempPSub2:PByte;
begin
  if (pvSub = nil) then
    Result := nil
  else
  begin
    Result := nil;
    j := 0;
    lvTempP := PByte(pvSource);
    Inc(lvTempP, pvStartIndex);

    lvTempPSub := PByte(pvSub);
    while j<pvSourceLen do
    begin
      if lvTempP^ = lvTempPSub^ then
      begin
        I := 1;     // �Ӻ���ڶ����ַ���ʼ�Ա�
        lvTempP2 := lvTempP;
        Inc(lvTempP2);

        lvTempPSub2 := lvTempPSub;
        Inc(lvTempPSub2);
        while (I < pvSubLen) do
        begin
          if lvTempP2^ = lvTempPSub2^ then
            Inc(I)
          else
            Break;
        end;

        if I = pvSubLen then
        begin  // P1��P2�Ѿ�ƥ�䵽��ĩβ(ƥ��ɹ�)
          Result := lvTempP;
          Break;
        end;
      end;
      Inc(lvTempP);
      inc(j);
    end;
  end;
end;


initialization

{$IFDEF MSWINDOWS}
hMsvcrtl := LoadLibrary('msvcrt.dll');
if hMsvcrtl <> 0 then
begin
  VCStrStr := TMSVCStrStr(GetProcAddress(hMsvcrtl, 'strstr'));
  VCStrStrW := TMSVCStrStrW(GetProcAddress(hMsvcrtl, 'wcsstr'));
  VCMemCmp := TMSVCMemCmp(GetProcAddress(hMsvcrtl, 'memcmp'));
end
else
begin
  VCStrStr := nil;
  VCStrStrW := nil;
  VCMemCmp := nil;
end;
{$ENDIF}

finalization

{$IFDEF MSWINDOWS}
if hMsvcrtl <> 0 then
  FreeLibrary(hMsvcrtl);
{$ENDIF}

end.
