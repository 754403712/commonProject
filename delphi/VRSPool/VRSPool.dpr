program VRSPool;

{$APPTYPE CONSOLE}

uses
  FastMM4,
  FastMM4Messages,
  SysUtils,
  Classes,
  utils.safeLogger,
  diocp.tcp.server,
  diocp.sockets,
  udmService in 'udmService.pas' {dmService: TDataModule},
  LogFileAppender4SafeLogger in 'LogFileAppender4SafeLogger.pas',
  vrs_source in 'vrs_source.pas',
  NtripRequest in 'NtripRequest.pas',
  ntrip_tools in 'ntrip_tools.pas',
  DataCenter in 'DataCenter.pas';

var
  s, lvFile, lvHomeDir:String;
  procedure WriteHelpHint();
  begin
    Writeln('************************************************');
    Writeln('*  quit:�˳�                                   *');
    Writeln('*  help:����                                   *');
    Writeln('*  ������س�:VRS ������Ϣ                      *');
    Writeln('************************************************');
  end;
begin

  lvHomeDir := ExtractFilePath(ParamStr(0));

  sfLogger.setAppender(TLogFileAppender4SafeLogger.Create());
  TLogFileAppender4SafeLogger(sfLogger.Appender).OutputToConsole := true;
  TLogFileAppender4SafeLogger(sfLogger.Appender).FilePreFix := 'VRS_';
  TLogFileAppender4SafeLogger(sfLogger.Appender).BasePath := ExtractFilePath(ParamStr(0)) + 'log\';
  RegisterDiocpSvrLogger(sfLogger);
  RegisterDiocpLogger(sfLogger);

  WriteHelpHint();

  try

    dmService := TdmService.Create(nil);
    try
      dmService.Start;

      //sfLogger.logMessage(GetSourceTable('119.97.244.11', 2102));
      sfLogger.logMessage('�ڲ�����汾: 2016-03-18 11:13:27');
      sfLogger.logMessage('VRS.Pool �����Ѿ�����%s:%d', [dmService.TcpSvr.DefaultListenAddress,
        dmService.TcpSvr.Port]);
      while (True) do
      begin
        Readln(s);
        if SameStr(s,'quit') then
        begin
          Break;
        end else if SameStr(s,'help') then
        begin
          WriteHelpHint();
        end else if s = 'reload' then
        begin
                  
        end else if s='clear' then
        begin
         // ClearPackState();
        end else
        begin
          Writeln('���ڼ����ٶ���Ϣ, ���Ե�...');
          dmService.TcpSvr.DataMoniter.SpeedCalcuStart;
          dmService.VRSSource.DiocpTcpClient.DataMoniter.SpeedCalcuStart;
          Sleep(1000);
          dmService.TcpSvr.DataMoniter.SpeedCalcuEnd;
          dmService.VRSSource.DiocpTcpClient.DataMoniter.SpeedCalcuEnd;
          Writeln(dmService.TcpSvr.GetStateInfo);
          Writeln(dmService.VRSSource.DiocpTcpClient.GetStateInfo);


        end;
      end;
      writeln('����׼���˳�...');
      
      dmService.Stop;
    except
      on E:Exception do
        Writeln(E.Classname, ': ', E.Message);
    end;
  finally
    dmService.Free;
    Sleep(1000); 
  end;
end.
