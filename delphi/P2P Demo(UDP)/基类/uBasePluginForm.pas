unit uBasePluginForm;

interface

uses
  Forms, uIUIForm, uIModuleINfo, Classes, superobject, uIMainForm, ComObj,
  SysUtils, uICMDExecuter, uIRelationObject, uKeyInterface, uIFreeObject,
  uIValueGSetter, uIPrepare, Windows, Messages, DBGridEh;

type
  TBasePluginForm = class(TForm, IUIForm, IModuleINfo,
    ICMDExecuter,
    IFreeObject,
    IRelationObject,
    IPrepareForCreate,
    IStringValueGetter,
    IStringValueSetter)
  private
    FChildObjectList: TKeyInterface;
    FInstanceID: Integer;
    FInstanceKey: string;
    FInstanceName: String;
    /// <summary>
    ///   �Ƴ����е��Ӷ��������Owner����Owner���Ƴ����Լ�
    /// </summary>
    procedure freeRelationChildren;
    Procedure DoEnterAsTab(var Msg:Tmsg; var Handle:boolean);
  protected
    FRelationOwner: IRelationObject;
    FConfig: ISuperObject;
    FJSonPass: ISuperObject;

    FJSonData: ISuperObject;

    FModuleFuncIndex:Integer;
    procedure DoClose(var Action: TCloseAction); override;



    ////===========================================
    /// <summary>
    ///  ���ô������ ��IModuleINfo �ӿ�)
    /// </summary>
    procedure setCaption(pvCaption: string); stdcall;

    /// <summary>
    ///  ��ȡ������� ��IModuleINfo �ӿ�)
    /// </summary>
    function getCaption: string; stdcall;

    /// <summary>
    ///   �������� ��IModuleINfo �ӿ�)
    /// </summary>
    procedure setConfig(pvConfig: ISuperObject); virtual; stdcall;

    /// <summary>
    ///   ��ȡ���� ��IModuleINfo �ӿ�)
    /// </summary>
    function getConfig: ISuperObject; stdcall;

    /// <summary>
    ///   ���ô���Ĳ�����Ϣ ��IModuleINfo �ӿ�)
    /// </summary>
    procedure setJSonPass(pvData: ISuperObject); virtual; stdcall;

    /// <summary>
    ///   ��ȡ����Ĳ�����Ϣ ��IModuleINfo �ӿ�)
    /// </summary>
    function getJSonPass: ISuperObject; stdcall;

    /// <summary>
    ///   ��ȡģ��ʵ������ ��IModuleINfo �ӿ�)
    /// </summary>
    function getInstanceKey: string; stdcall;

    /// <summary>
    ///   ��ȡģ��ģ���� ��IModuleINfo �ӿ�)
    /// </summary>
    function getModuleFuncIndex: Integer; stdcall;

    /// <summary>
    ///   ����ģ��ʹ�ñ�� ��IModuleINfo �ӿ�)
    /// </summary>
    procedure setModuleFuncIndex(const Value: Integer); stdcall;

    /// <summary>
    ///   ִ�з��� ��IModuleINfo �ӿ�)
    ///   ����ȥ��д�÷�����һ�������������һЩ������ִ��
    /// </summary>
    procedure PrepareForCreate; virtual; stdcall;
    ////////////////////////=============================


    //��ȡģ���Data����
    function getJSonData():ISuperObject; stdcall;

    ///////////////===========================================
    /// <summary>
    ///   ��ΪMDIģʽ��ʾ (IUIForm�ӿ�)
    /// </summary>
    procedure showAsMDI; stdcall;

    /// <summary>
    ///   ��Ϊģ̬ģʽ��ʾ (IUIForm�ӿ�)
    /// </summary>
    function showAsModal: Integer; stdcall;

    /// <summary>
    ///   ��ȡ������� ��IUIForm �ӿ�)
    /// </summary>
    function getObject: TWinControl; stdcall;

    /// <summary>
    ///  �رմ���  (IUIForm�ӿ�)
    /// </summary>
    procedure UIFormClose; stdcall;

    //
    /// <summary>
    ///  �ͷŴ���  (IUIForm�ӿ�)
    /// </summary>
    procedure UIFormFree; stdcall;

    /// <summary>
    ///  ��ȡʵ��ID  (IUIForm�ӿ�)
    /// </summary>     
    function getInstanceID: Integer; stdcall;
    /////////////////////////////////////////////////////

    /// <summary>
    ///   ִ������(ICMDExecuter�� �ӿ�)
    ///   ������ȥ����pvCMDIndexʵ�ָ��ֹ��ܡ�
    /// </summary>
    function DoExecuteCMD(pvCMDIndex:Integer; pvPass:ISuperObject): Integer; virtual;
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
    procedure FreeObject; stdcall;

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

uses
  mBeanFrameVars, mBeanModuleTools, uMainFormTools, uRelationObjectWrapper;

procedure TBasePluginForm.addChildObject(pvInstanceID: PAnsiChar;
  pvChild: IInterface);
begin
  FChildObjectList.put(pvInstanceID, pvChild);
end;

constructor TBasePluginForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChildObjectList := TKeyInterface.Create;
  FJSonData := SO();
  
  FInstanceKey := CreateClassID;
  Randomize;
  
  FInstanceID :=
    StrToInt(intToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    );

  application.OnMessage := DoEnterAsTab;
end;

destructor TBasePluginForm.Destroy;
begin
  FConfig := nil;
  FJSonData := nil;
  
  //֪ͨ�����������Ƴ��������
  TMainFormTools.removePlugin(self.FInstanceID);

  //�����������д��ڸĽӿ�������Ƴ�(���������Ƴ�)
  TmBeanFrameVars.removeObject(IntToStr(FInstanceID));

  freeRelationChildren;
  FChildObjectList.clear;
  FChildObjectList.Free;

  inherited Destroy;
end;

procedure TBasePluginForm.DoClose(var Action: TCloseAction);
begin
  if not (fsModal in self.FFormState) then action := caFree;
  inherited DoClose(Action);
end;

procedure TBasePluginForm.DoEnterAsTab(var Msg: Tmsg; var Handle: boolean);
begin
  if  Msg.message = WM_KEYDOWN then
  begin
    if ((Msg.wParam = VK_RETURN) and (not (Screen.ActiveForm.ActiveControl is TDBGridEh))) then
      Keybd_event(VK_TAB,0,0,0);
  end;
end;

function TBasePluginForm.DoExecuteCMD(pvCMDIndex: Integer;
  pvPass: ISuperObject): Integer;
begin
  ;
end;

function TBasePluginForm.existsChildObject(pvInstanceID: PAnsiChar): Boolean;
begin
  Result := FChildObjectList.exists(pvInstanceID);  
end;

function TBasePluginForm.findChildObject(pvInstanceID: PAnsiChar): IInterface;
begin
  Result := FChildObjectList.find(pvInstanceID);
end;

function TBasePluginForm.getCaption: string;
begin
  Result := self.Caption;
end;

function TBasePluginForm.getChildObjectItems(pvIndex:Integer): IInterface;
begin
  Result := FChildObjectList.Values[pvIndex];
end;

function TBasePluginForm.getConfig: ISuperObject;
begin
  Result := FConfig;   
end;

function TBasePluginForm.getCount: Integer;
begin
  Result := FChildObjectList.count;
end;

function TBasePluginForm.getInstanceID: Integer;
begin
  Result := FInstanceID;
end;

function TBasePluginForm.getInstanceKey: string;
begin

end;

function TBasePluginForm.getJSonData: ISuperObject;
begin
  Result := FJSonData;
end;

function TBasePluginForm.getJSonPass: ISuperObject;
begin
  Result := FJSonPass;
end;

function TBasePluginForm.getModuleFuncIndex: Integer;
begin
  Result := FModuleFuncIndex;
end;

function TBasePluginForm.getObject: TObject;
begin
  Result := Self;
end;

function TBasePluginForm.GetOwnerObject: IRelationObject;
begin
  Result := FRelationOwner;
end;

function TBasePluginForm.getValueAsString(pvValueID: string): String;
begin
  Result := '';
end;

procedure TBasePluginForm.PrepareForCreate;
begin
  if FConfig <> nil then
  begin
    //����
    if FConfig.S['editor.Caption'] <> '' then
    begin
      self.Caption := FConfig.S['editor.Caption'];
    end else if FConfig.S['list.Caption'] <> '' then
    begin
      self.Caption := FConfig.S['list.Caption'];
    end else if FConfig.S['editor.Caption'] <> '' then
    begin
      self.Caption := FConfig.S['editor.Caption'];
    end else if FConfig.S['__config.caption'] <> '' then
    begin
      self.Caption := FConfig.S['__config.caption'];
    end;
  end;
end;

procedure TBasePluginForm.DeleteChildObject(pvIndex:Integer);
begin
  FChildObjectList.Delete(pvIndex);
end;

procedure TBasePluginForm.FreeObject;
begin
  Self.Free;
end;

procedure TBasePluginForm.removeChildObject(pvInstanceID: PAnsiChar);
begin
  FChildObjectList.remove(pvInstanceID);
end;

procedure TBasePluginForm.freeRelationChildren;
begin
  try
    if FRelationOwner <> nil then
    begin
      FRelationOwner.removeChildObject(PAnsiChar(AnsiString(FInstanceName)));
    end;
    TRelationObjectWrapper.RemoveAndFreeChilds(Self);
  except
  end;   
end;

procedure TBasePluginForm.setCaption(pvCaption: string);
begin
  self.Caption := pvCaption;
end;

procedure TBasePluginForm.setConfig(pvConfig: ISuperObject);
begin
  FConfig := pvConfig;
end;

procedure TBasePluginForm.setJSonPass(pvData: ISuperObject);
begin
  FJSonPass := pvData;
end;

procedure TBasePluginForm.setModuleFuncIndex(const Value: Integer);
begin
  FModuleFuncIndex := Value;  
end;

procedure TBasePluginForm.setOwnerObject(pvOwnerObject: IRelationObject);
begin
  FRelationOwner := pvOwnerObject;
end;

procedure TBasePluginForm.setStringValue(pvValueID, pvValue: String);
begin
  
end;

procedure TBasePluginForm.showAsMDI;
begin
  self.FormStyle := fsMDIChild;
  self.WindowState := wsMaximized;
  self.Show;
end;

function TBasePluginForm.showAsModal: Integer;
begin
  Result := ShowModal();
end;

{ TBasePluginForm }

procedure TBasePluginForm.UIFormClose;
begin
  Self.Close;
end;

procedure TBasePluginForm.UIFormFree;
begin
  Self.Free;
end;

end.
