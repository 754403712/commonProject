unit uBasePluginFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, uICMDExecuter, superobject, uIJSonConfig, uIUIChild, uIPrepare,
  uIRelationObject, uKeyInterface, uIFreeObject, uRelationObjectWrapper,
  uIValueGSetter;

type
  TBasePluginFrame = class(TFrame, IUIChild,
    ICMDExecuter,
    IJSonConfig,
    IPrepareForCreate,
    IFreeObject,
    IRelationObject,
    IStringValueGetter,
    IStringValueSetter)
  private
    FChildObjectList: TKeyInterface;

    FInstanceID: Integer;
    
    FInstanceName: String;

    procedure freeRelationChildren;
  protected
    FRelationOwner:IRelationObject;  
    FJSonData: ISuperObject;
    
    FConfig: ISuperObject;

    /// <summary>
    ///   ִ������(ICMDExecuter�� �ӿ�)
    ///   ������ȥ����pvCMDIndexʵ�ָ��ֹ��ܡ�
    /// </summary>
    function DoExecuteCMD(pvCMDIndex:Integer; pvPass:ISuperObject): Integer; virtual;

    /// <summary>
    ///   ��ȡJson������(IJSonConfig �ӿ�)
    /// </summary>
    function getJSonConfig: ISuperObject; stdcall;

    /// <summary>
    ///   ����Json������(IJSonConfig �ӿ�)
    /// </summary>
    procedure setJSonConfig(const pvConfig: ISuperObject); virtual; stdcall;

    /// <summary>
    ///   ��ȡʵ����ID ��IUIChild �ӿ�)
    /// </summary>
    function getInstanceID: Integer; stdcall;

    /// <summary>
    ///   ��ȡʵ������ ��IUIChild �ӿ�)
    /// </summary>
    function getInstanceName: string; stdcall;

    /// <summary>
    ///   ����ʵ������ ��IUIChild �ӿ�)
    /// </summary>
    procedure setInstanceName(const pvValue: string); stdcall;

    /// <summary>
    ///   ��������Free���� ��IUIChild �ӿ�)
    /// </summary>
    procedure UIFree; stdcall;

    /// <summary>
    ///   ����岼����һ��Parent���� ��IUIChild �ӿ�)
    /// </summary>
    procedure ExecuteLayout(pvParent:TWinControl); stdcall;

    /// <summary>
    ///   ִ�з��� ��IPrepareForCreate �ӿ�)
    ///   ����ȥ��д�÷�����һ�������������һЩ������ִ��
    /// </summary>
    procedure PrepareForCreate; virtual; stdcall;

    /// <summary>
    ///   ����ʵ������ ��IUIChild �ӿ�)
    /// </summary>
    function getObject: TWinControl; stdcall;

    /// <summary>
    ///   ��������Free���� ��IFreeObject �ӿ�)
    /// </summary>
    procedure FreeObject; stdcall;

  protected

    /// <summary>
    ///   ���һ���Ӷ��� ��IRelationObject �ӿ�)
    /// </summary>
    procedure addChildObject(pvInstanceID:PAnsiChar; pvChild:IInterface); stdcall;

    /// <summary>
    ///   ����InstanceID����һ���Ӷ��� ��IRelationObject �ӿ�)
    /// </summary>
    function findChildObject(pvInstanceID: PAnsiChar): IInterface; stdcall;

    /// <summary>
    ///   ����InstanceID�Ƴ�һ���Ӷ��� ��IRelationObject �ӿ�)
    /// </summary>
    procedure removeChildObject(pvInstanceID:PAnsiChar); stdcall;

    /// <summary>
    ///   ������������Ƴ�һ���Ӷ��� ��IRelationObject �ӿ�)
    /// </summary>
    procedure DeleteChildObject(pvIndex:Integer); stdcall;

    /// <summary>
    ///   ���ø����� ��IRelationObject �ӿ�)
    /// </summary>
    procedure setOwnerObject(pvOwnerObject: IRelationObject); stdcall;

    /// <summary>
    ///   ����InstanceID�ж��Ƿ�����Ӷ��� ��IRelationObject �ӿ�)
    /// </summary>
    function existsChildObject(pvInstanceID: PAnsiChar):Boolean;stdcall;

    /// <summary>
    ///   �Ӷ������ ��IRelationObject �ӿ�)
    /// </summary>
    function getCount():Integer; stdcall;

    /// <summary>
    ///   ����������Ų���һ���Ӷ��� ��IRelationObject �ӿ�)
    /// </summary>
    function getChildObjectItems(pvIndex:Integer): IInterface; stdcall;

    /// <summary>
    ///    ��ȡ������ӿ�
    /// </summary>
    /// <returns>
    ///    ���ظ�����Ľӿ�,���������ΪNil
    /// </returns>
    function GetOwnerObject: IRelationObject; stdcall;
  protected
    /// <summary>
    ///   ����һ���ַ���ֵ ��IStringValueSetter�ӿ�)
    /// </summary>
    procedure setStringValue(pvValueID, pvValue: String); virtual; stdcall;

    /// <summary>
    ///   ��ȡһ���ַ���ֵ ��IStringValueGetter�ӿ�)
    /// </summary>
    function getValueAsString(pvValueID:string): String; virtual; stdcall;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

constructor TBasePluginFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChildObjectList := TKeyInterface.Create();
  FJSonData := SO();
  Randomize;
  FInstanceID :=
    StrToInt(intToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    );

end;

destructor TBasePluginFrame.Destroy;
begin
  freeRelationChildren;
  FJSonData := nil;
  FConfig := nil;
  
  FChildObjectList.clear;
  FChildObjectList.Free;
  inherited Destroy;
end;

procedure TBasePluginFrame.addChildObject(pvInstanceID: PAnsiChar; pvChild:
    IInterface);
begin
  FChildObjectList.put(pvInstanceID, pvChild);
end;

procedure TBasePluginFrame.DeleteChildObject(pvIndex:Integer);
begin
  FChildObjectList.Delete(pvIndex);
end;

function TBasePluginFrame.DoExecuteCMD(pvCMDIndex: Integer; pvPass:
    ISuperObject): Integer;
begin
  ;
end;

procedure TBasePluginFrame.ExecuteLayout(pvParent: TWinControl);
begin
  Self.Parent := pvParent;
  if self.Parent <> nil then
  begin
    Align := alClient;
  end else
  begin
    Align := alNone;
  end;
end;

function TBasePluginFrame.existsChildObject(pvInstanceID: PAnsiChar): Boolean;
begin
  Result := FChildObjectList.exists(pvInstanceID);  
end;

function TBasePluginFrame.findChildObject(pvInstanceID: PAnsiChar): IInterface;
begin
  Result := FChildObjectList.find(pvInstanceID);
end;

procedure TBasePluginFrame.FreeObject;
begin
  Self.Free;
end;

procedure TBasePluginFrame.freeRelationChildren;
begin
  try
    if FRelationOwner <> nil then
    begin
      FRelationOwner.removeChildObject(PAnsiChar(AnsiString(FInstanceName)));
    end;
    TRelationObjectWrapper.RemoveAndFreeChilds(Self);

    FRelationOwner := nil;
  except
  end;   
end;

function TBasePluginFrame.getJSonConfig: ISuperObject;
begin
  Result := FConfig;   
end;

function TBasePluginFrame.getChildObjectItems(pvIndex:Integer): IInterface;
begin
  Result := FChildObjectList.Values[pvIndex];
end;

function TBasePluginFrame.getCount: Integer;
begin
  Result := FChildObjectList.count;
end;

function TBasePluginFrame.getInstanceID: Integer;
begin
  Result := FInstanceID;
end;

function TBasePluginFrame.getInstanceName: string;
begin
  Result := FInstanceName;  
end;

function TBasePluginFrame.getObject: TWinControl;
begin
  Result := Self;
end;

function TBasePluginFrame.GetOwnerObject: IRelationObject;
begin
  Result := FRelationOwner;
end;

function TBasePluginFrame.getValueAsString(pvValueID:string): String;
begin
  Result := '';
end;

procedure TBasePluginFrame.PrepareForCreate;
begin
  ;
end;

procedure TBasePluginFrame.removeChildObject(pvInstanceID: PAnsiChar);
begin
  FChildObjectList.remove(pvInstanceID);
end;

procedure TBasePluginFrame.setInstanceName(const pvValue: string);
begin
  FInstanceName := pvValue;
end;

procedure TBasePluginFrame.setJSonConfig(const pvConfig: ISuperObject);
begin
  FConfig := pvConfig;
end;

procedure TBasePluginFrame.setOwnerObject(pvOwnerObject: IRelationObject);
begin
  FRelationOwner := pvOwnerObject;
end;

procedure TBasePluginFrame.setStringValue(pvValueID, pvValue: String);
begin

end;

procedure TBasePluginFrame.UIFree;
begin
  FreeObject;
end;

end.
