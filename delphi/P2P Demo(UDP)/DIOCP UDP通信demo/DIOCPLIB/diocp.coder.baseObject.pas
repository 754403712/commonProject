(*
 *	 Unit owner: d10.�����
 *	       blog: http://www.cnblogs.com/dksoft
 *     homePage: www.diocp.org
 *
 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
 *)
 
unit diocp.coder.baseObject;

interface

uses
  diocp.tcp.server, utils.buffer;

type
{$if CompilerVersion< 18.5}
  TBytes = array of Byte;
{$IFEND}

  TIOCPDecoder = class(TObject)
  public
    /// <summary>
    ///   �����յ�������,����н��յ�����,���ø÷���,���н���
    /// </summary>
    /// <returns>
    ///   ���ؽ���õĶ���
    /// </returns>
    /// <param name="inBuf"> ���յ��������� </param>
    function Decode(const inBuf: TBufferLink; pvContext: TObject): TObject;
        virtual; abstract;
  end;

  TIOCPDecoderClass = class of TIOCPDecoder;

  TIOCPEncoder = class(TObject)
  public
    /// <summary>
    ///   ����Ҫ���͵Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="ouBuf"> ����õ����� </param>
    procedure Encode(pvDataObject: TObject; const ouBuf: TBufferLink); virtual;
        abstract;
  end;

  TIOCPEncoderClass = class of TIOCPEncoder;

implementation

end.
