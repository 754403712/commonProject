unit posix_serialPort;

interface

uses
  SysUtils,
  Posix.Base, Posix.Dirent, Posix.Errno, Posix.Fnmatch,
  Posix.Langinfo, Posix.Locale, Posix.Pthread, Posix.Stdio, Posix.Stdlib,
  Posix.String_, Posix.SysSysctl, Posix.Time, Posix.Unistd, Posix.Utime,
  Posix.Wordexp, Posix.Pwd, Posix.Signal,
  Posix.Termios,
  Posix.Dlfcn, Posix.Fcntl, Posix.SysStat, Posix.SysTime, Posix.SysTypes;

type
  TSerialBaudRate = (br28800, br115200, br19200, br9600, br4800, br2400, br1200, br300);
  TSerialParity = (spNone, spOdd, spEven, spSpace);
  TSerialDataBits = (db5Bits, db6Bits, db7Bits, db8Bits);
  TSerialStopBits = (sb1, sb2);
  TSerialFlowControl = (fcNone, fcXonXoff, fcHardware);

function OpenPort(pvPort:string): Integer;

function ReadBuffer(pvHandle:Integer; vBuf:Pointer; pvLength:Integer): Integer;

function ConfigSerialPort(fd: Integer; baudrate: TSerialBaudRate; flow_ctrl:
    TSerialFlowControl; databits: TSerialDataBits; stopbits: TSerialStopBits;
    parity: TSerialParity): Integer;

implementation

const
  BaudRatesValue: array [TSerialBaudRate] of Integer = (B4000000,
    B115200, B19200, B9600, B4800, B2400, B1200,	B300);

function OpenPort(pvPort:string): Integer;
var
  M:TMarshaller;
begin
  Result := __open(M.AsAnsi(pvPort, CP_UTF8).ToPointer, O_RDWR OR O_NOCTTY);
end;

function ReadBuffer(pvHandle:Integer; vBuf:Pointer; pvLength:Integer): Integer;
begin
  Result := __read(pvHandle, vBuf, pvLength);
end;

function ConfigSerialPort(fd: Integer; baudrate: TSerialBaudRate; flow_ctrl:
    TSerialFlowControl; databits: TSerialDataBits; stopbits: TSerialStopBits;
    parity: TSerialParity): Integer;
var
  lvOptions:termios;
  r:Integer;
begin
  r := tcgetattr(fd, lvOptions);
  if r <> 0 then
  begin
    Exit(r);

  end;

  cfsetispeed(lvOptions, BaudRatesValue[baudrate]);
  cfsetospeed(lvOptions, BaudRatesValue[baudrate]);

	//�޸Ŀ���ģʽ����֤���򲻻�ռ�ô���
	lvOptions.c_cflag := lvOptions.c_cflag OR CLOCAL;
	//�޸Ŀ���ģʽ��ʹ���ܹ��Ӵ����ж�ȡ��������
	lvOptions.c_cflag := lvOptions.c_cflag OR CREAD;

  case flow_ctrl of
    fcNone:      //��ʹ��������
      begin
        lvOptions.c_cflag := lvOptions.c_cflag and (not CRTSCTS);
      end;
    fcHardware:      //ʹ��Ӳ��������
      begin
        lvOptions.c_cflag := lvOptions.c_cflag OR CRTSCTS;
      end;
    fcXonXoff:     //ʹ�����������
      begin
        lvOptions.c_cflag := lvOptions.c_cflag OR IXON OR IXOFF OR IXANY;
      end;
  end;


  lvOptions.c_cflag := lvOptions.c_cflag and (not CSIZE);

  case databits of
    db5Bits:
     begin
       lvOptions.c_cflag := lvOptions.c_cflag OR CS5;
     end;
    db6Bits:
     begin
       lvOptions.c_cflag := lvOptions.c_cflag OR CS6;
     end;
    db7Bits:
     begin
       lvOptions.c_cflag := lvOptions.c_cflag OR CS7;
     end;
    db8Bits:
     begin
       lvOptions.c_cflag := lvOptions.c_cflag OR CS8;
     end;
  end;

  case parity of
    spNone:      //����żУ��λ��
      begin
        lvOptions.c_cflag := lvOptions.c_cflag AND (not PARENB);
        lvOptions.c_iflag := lvOptions.c_iflag AND (not INPCK);
      end;
    spOdd:       //����Ϊ��У��
      begin
        lvOptions.c_cflag := lvOptions.c_cflag OR (PARODD OR PARENB);
        lvOptions.c_iflag := lvOptions.c_iflag OR INPCK;
      end;
    spEven:   //����ΪżУ��
      begin
        lvOptions.c_cflag := lvOptions.c_cflag OR PARENB;
        lvOptions.c_cflag := lvOptions.c_cflag AND (NOT PARODD);
        lvOptions.c_iflag := lvOptions.c_iflag OR INPCK;
      end;
    spSpace:
      begin
        lvOptions.c_cflag := lvOptions.c_cflag AND (NOT PARENB);
        lvOptions.c_cflag := lvOptions.c_cflag AND (NOT CSTOPB);
      end;
  end;

  // ֹͣλ
  case stopbits of
    sb1:
      lvOptions.c_cflag := lvOptions.c_cflag AND (NOT CSTOPB);
    sb2:
      lvOptions.c_cflag := lvOptions.c_cflag OR CSTOPB;
  end;

  //���õȴ�ʱ�����С�����ַ�
	lvOptions.c_cc[VTIME] = 150; ///* ��ȡһ���ַ��ȴ�1*(1/10)s */
	lvOptions.c_cc[VMIN] = 0; ///* ��ȡ�ַ������ٸ���Ϊ1 */

	//�����������������������ݣ����ǲ��ٶ�ȡ ˢ���յ������ݵ��ǲ���
	tcflush(fd, TCIFLUSH);

	//�������� (���޸ĺ��termios�������õ������У�
	r := tcsetattr(fd, TCSANOW, lvOptions);
  if r <> 0 then Exit(r);

  Result := 0;
end;

end.
