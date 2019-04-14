unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.ExtCtrls, Vcl.Menus, Vcl.Clipbrd, Vcl.Touch.GestureMgr;

type
  TForm1 = class(TForm)
    hk1: THotKey;
    BtnActive: TButton;
    edtText: TEdit;
    lblShortcut: TLabel;
    lblText: TLabel;
    BtnAbout: TButton;
    BtnExpand: TButton;
    mmo1: TMemo;
    lbl1: TLabel;
    chk1: TCheckBox;
    TrayIcon1: TTrayIcon;
    pm1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    tmr1: TTimer;
    gstrmngr1: TGestureManager;
    chk2: TCheckBox;
    lbl2: TLabel;
    TrackBar1: TTrackBar;
    lbl3: TLabel;
    chk3: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnActiveClick(Sender: TObject);
    procedure BtnAboutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnExpandClick(Sender: TObject);
    procedure chk1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure FormGesture(Sender: TObject; const EventInfo: TGestureEventInfo;
      var Handled: Boolean);
    procedure chk2Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
  private
    { Private declarations }
    procedure ClipboardChangeCBChain(var message: TMessage);message WM_CHANGECBCHAIN;
    procedure ClipboardChanged(var message: TMessage);message WM_DRAWCLIPBOARD;
  public
    { Public declarations }
    myKeyAtom : ATOM;
    myState : Integer;
    InputExpand : BOOL;
    IsTopHide : BOOL;
    IsExit : BOOL;
    IsTiped : BOOL;
    hwndNextViewer : HWND;
    procedure hotykey(var msg:TMessage); message WM_HOTKEY;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Unit2;

procedure ShortCutToKey(ShortCut: TShortCut; var Key: Word; var Shift: TShiftState);
begin
  Key := ShortCut and not (scShift + scCtrl + scAlt);
  Shift := [];
  if ShortCut and scShift <> 0 then Include(Shift, ssShift);
  if ShortCut and scCtrl <> 0 then Include(Shift, ssCtrl);
  if ShortCut and scAlt <> 0 then Include(Shift, ssAlt);
end;

function ShiftStateToWord(TShift: TShiftState): Word;
begin
  Result := 0;
  if ssShift in TShift then Result := MOD_SHIFT;
  if ssCtrl in TShift then Result := Result or MOD_CONTROL;
  if ssAlt in TShift then Result:= Result or MOD_ALT;
end;

function RegKey(Name: LPCWSTR; aHandle: HWND; fsModifiers, vk: UINT): ATOM;
var
  FShowkeyid: ATOM;
  tmpResult: BOOL;
begin
  FShowkeyid := GlobalAddAtom(Name) - $C000;
  tmpResult := RegisterHotKey(aHandle, FShowkeyid, fsModifiers, vk);
  if tmpResult then
  begin
    Result := FShowkeyid;
  end
  else
  begin
    Result := 0;
  end;
end;

function RegFromHotKey(aHotKey: THotKey; aHandle: HWND; HotKeyID: LPCWSTR): ATOM;
var
  aKey : Word;
  aShift : TShiftState;
begin
  ShortCutToKey(aHotKey.HotKey, aKey, aShift);
  Result := RegKey(HotKeyID, aHandle, ShiftStateToWord(aShift), aKey);
end;

function ASCII2VKey(aChar: Byte):Byte;
begin
  Result := 32;
  case aChar of
   48..57  : Result := aChar - 48 + 48;   //0-9
   97..122 : Result := aChar - 97 + 65;   //a-z
   65..90  : Result := aChar - 65 + 65;   //A-Z
   32 : Result := 32;  //

   96 : Result := 192; //`
   126: Result := 192; //~

   33 : Result := 49;  //!在数字1上
   64 : Result := 50;  //@
   35 : Result := 51;  //#
   36 : Result := 52;  //$
   37 : Result := 53;  //%
   94 : Result := 54;  //^
   38 : Result := 55;  //&
   42 : Result := 56;  //*
   40 : Result := 57;  //(
   41 : Result := 48;  //)

   45 : Result := 189; //-
   95 : Result := 189; //_
   61 : Result := 187; //=
   43 : Result := 187; //+
   91 : Result := 219; //[
   123: Result := 219; //{
   93 : Result := 221; //]
   125: Result := 221; //}
   92 : Result := 220; //\
   124: Result := 220; //|
   59 : Result := 186; //;
   58 : Result := 186; //:
   39 : Result := 222; //'
   34 : Result := 222; //"
   44 : Result := 188; //,
   60 : Result := 188; //<
   46 : Result := 190; //.
   62 : Result := 190; //>
   47 : Result := 191; ///
   63 : Result := 191; //?
  end;
end;

function ASCII2VShift(aChar:Byte):Byte;
begin
  Result := 0;
  case aChar of
   48..57 : Result := 0;
   97..122 : Result := 0;
   65..90 : Result := VK_SHIFT;    //16
   32 : Result := 0;

   96 : Result := 0; //`
   126: Result := VK_SHIFT; //~

   33 : Result := VK_SHIFT;  //!     
   64 : Result := VK_SHIFT;  //@
   35 : Result := VK_SHIFT;  //#
   36 : Result := VK_SHIFT;  //$
   37 : Result := VK_SHIFT;  //%
   94 : Result := VK_SHIFT;  //^
   38 : Result := VK_SHIFT;  //&
   42 : Result := VK_SHIFT;  //*
   40 : Result := VK_SHIFT;  //(
   41 : Result := VK_SHIFT;  //)

   45 : Result := 0; //-
   95 : Result := VK_SHIFT; //_
   61 : Result := 0; //=
   43 : Result := VK_SHIFT; //+
   91 : Result := 0; //[
   123: Result := VK_SHIFT; //{
   93 : Result := 0; //]
   125: Result := VK_SHIFT; //}
   92 : Result := 0; //\
   124: Result := VK_SHIFT; //|
   59 : Result := 0; //;
   58 : Result := VK_SHIFT; //:
   39 : Result := 0; //'
   34 : Result := VK_SHIFT; //"
   44 : Result := 0; //,
   60 : Result := VK_SHIFT; //<
   46 : Result := 0; //.
   62 : Result := VK_SHIFT; //>
   47 : Result := 0; ///
   63 : Result := VK_SHIFT; //?
  end;
end;

{
procedure KeyPressA;
var
    Inputs : array [0..1] of TInput;
begin
  Sleep(1000);
    Inputs[0].Itype:=INPUT_KEYBOARD;
    with Inputs[0].ki do
    begin
        wVk:=$41;
        wScan:=0;
        dwFlags:=0;
        time:=GetTickCount;
        dwExtraInfo:=GetMessageExtraInfo;
    end;
    Inputs[1].Itype:=INPUT_KEYBOARD;
    with Inputs[1].ki do
    begin
        wVk:=$41;
        wScan:=0;
        dwFlags:=KEYEVENTF_KEYUP;
        time:=GetTickCount;
        dwExtraInfo:=GetMessageExtraInfo;
    end;
    //Sleep(100);
    SendInput(2,Inputs[0],SizeOf(TInput));
    Form1.Caption := IntToStr(StrToInt(Form1.Caption) + 1);
end;
}

procedure DrawText(aTextString: string; Speed: Integer);
var
  i : Integer;
  buf : TBytes;
  SleepTime : Integer;
begin
  SleepTime := 1000 div Speed;
  buf := BytesOf(aTextString);
  for i := 0 to Length(aTextString)-1 do
  begin
    Sleep(SleepTime);
    if ASCII2VShift(buf[i]) = VK_SHIFT then
    begin
      keybd_event(VK_SHIFT,0,0,0);
      keybd_event(ASCII2VKey(buf[i]),0,0,0);
      keybd_event(ASCII2VKey(buf[i]),0,KEYEVENTF_KEYUP,0);
      keybd_event(VK_SHIFT,0,KEYEVENTF_KEYUP,0);
    end
    else
    begin
      keybd_event(ASCII2VKey(buf[i]),0,0,0);
      keybd_event(ASCII2VKey(buf[i]),0,KEYEVENTF_KEYUP,0);
    end;
  end;
end;

procedure DrawEnter;
begin
  keybd_event(VK_RETURN,0,0,0);
  keybd_event(VK_RETURN,0,KEYEVENTF_KEYUP,0);
end;

procedure DrawHome;
begin
  keybd_event(VK_HOME,0,0,0);
  keybd_event(VK_HOME,0,KEYEVENTF_KEYUP,0);
end;

function CapsLockDetected:BOOL;
var
  keystates: TKeyboardState;
begin
  GetKeyboardState(keystates);
  if odd(keystates[VK_CAPITAL]) then
  begin
    Result := True;
  end
  else
  begin
    Result := False;
  end;
end;

procedure CapsLockDisable;
begin
  keybd_event(VK_CAPITAL,0,0,0);
  keybd_event(VK_CAPITAL,0,KEYEVENTF_KEYUP,0);
end;

procedure CapsLockEnable;
begin
  keybd_event(VK_CAPITAL,0,0,0);
  keybd_event(VK_CAPITAL,0,KEYEVENTF_KEYUP,0);
end;


{ TForm1 }

procedure TForm1.BtnAboutClick(Sender: TObject);
var
  AboutFrm : TForm2;
begin
  AboutFrm:= TForm2.Create(Self);
  AboutFrm.ShowModal;
end;

procedure TForm1.BtnActiveClick(Sender: TObject);
begin
  if myState <> 1 then
  begin
    myKeyAtom := RegFromHotKey(hk1, Handle, 'newkey1');
    if myKeyAtom <> 0 then
    begin
      myState := 1;
      BtnActive.Caption := '热键待命中，去目标窗口粘贴，点我取消';
      hk1.Enabled := False;
    end
    else
    begin
      BtnActive.Caption := '该热键无效，点击重试';
    end;
  end
  else
  begin
    UnregisterHotKey(Handle, myKeyAtom);
    myState := 0;
    BtnActive.Caption := '激活热键';
    hk1.Enabled := True;
  end;
end;

procedure TForm1.BtnExpandClick(Sender: TObject);
begin
  if InputExpand then
  begin
    Form1.Width := 255;
    InputExpand := False;
    BtnExpand.Caption := '点击扩展→';
    edtText.Enabled := True;
    mmo1.Enabled := False;
  end
  else
  begin
    Form1.Width := 550;
    InputExpand := True;
    BtnExpand.Caption := '点击收起←';
    edtText.Enabled := False;
    mmo1.Enabled := True;
  end;
end;

procedure TForm1.chk1Click(Sender: TObject);
begin
  if chk1.Checked then
  begin
    Form1.FormStyle := fsStayOnTop;
  end
  else
  begin
    Form1.FormStyle := fsNormal;
  end;
end;

procedure TForm1.chk2Click(Sender: TObject);
begin
  if chk2.Checked then
  begin
    //现在激活剪贴板监视功能
    hwndNextViewer := SetClipboardViewer(Handle);
  end
  else
  begin
    //现在取消剪贴板监视功能
    ChangeClipboardChain(Handle, hwndNextViewer);
    SendMessage(hwndNextViewer, WM_CHANGECBCHAIN, Handle, hwndNextViewer);
  end;
end;

procedure TForm1.ClipboardChangeCBChain(var message: TMessage);
begin
  with message do
  begin
    if WPARAM = hwndNextViewer then
      hwndNextViewer := LPARAM
    else if hwndNextViewer <> Null then
      SendMessage(hwndNextViewer, Msg, WPARAM, LPARAM);
  end;
end;

procedure TForm1.ClipboardChanged(var message: TMessage);
var
  s : string;
  opr : Boolean;
  fc : Integer;
begin
  //判断剪贴板内容是否为文本
  if Clipboard.HasFormat(CF_TEXT) then
  begin
    //获取剪贴板文本内容
    opr := False;
    fc := 0;
    while not opr do
    begin
      try
        s := Clipboard.AsText;
        mmo1.Clear;
        mmo1.Lines.Add(s);
        opr := True;
      except
        Inc(fc);
        if fc >= 10 then
          Break;
      end;
    end;
  end;
  //向下一链传递消息
  if hwndNextViewer <> Null then
  begin
    with message do
      SendMessage(hwndNextViewer, Msg, WPARAM, LPARAM);
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  UnregisterHotKey(Handle, myKeyAtom);

  //现在取消剪贴板监视功能
  ChangeClipboardChain(Handle, hwndNextViewer);
  SendMessage(hwndNextViewer, WM_CHANGECBCHAIN, Handle, hwndNextViewer);
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if IsExit then
  begin
    IsExit := False;
    CanClose := True;
  end
  else
  begin
    Form1.Hide;
    CanClose := False;
    if not IsTiped then
    begin
      TrayIcon1.BalloonHint := '隐藏到这里了哦';         
      TrayIcon1.BalloonTimeout := 2000;
      TrayIcon1.ShowBalloonHint;
      IsTiped := True;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InputExpand := False;
  IsTopHide := False;
  IsExit := False;
  Form1.Width := 255;
  IsTiped := False;

  SetWindowLong(self.Handle,GWL_EXSTYLE,WS_EX_TOOLWINDOW);
end;

procedure TForm1.FormGesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  case EventInfo.GestureID of
    sgiTriangle :
    begin
      WinExec('cmd.exe /c shutdown -s -t 100', SW_SHOW);
      ShowMessage('叫你乱动，赶紧画个圈！！！';
    end;
    sgiCircle :
    begin
      WinExec('cmd.exe /c shutdown -a', SW_SHOW);
    end;
  end;
end;

procedure TForm1.hotykey(var msg: TMessage);
var
  i : Integer;
  TextLines : Integer;
  tmpStr : string;
  CapState : BOOL;
begin
  //if (msg.LParamLo = hk1.Modifiers) and (msg.LParamHi = VK_F12) then    //just one hotkey in this system
  CapState := CapsLockDetected;
  if CapState then
  begin
    CapsLockDisable;
    Sleep(100);
  end;

  if InputExpand then
  begin
    Sleep(500);
    TextLines := mmo1.Lines.Count;
    for i := 0 to TextLines -1 do
    begin
      tmpStr := mmo1.Lines[i];
      DrawText(tmpStr, TrackBar1.Position);
      if i < TextLines-1 then
      begin
        DrawEnter();
        if chk3.Checked then
        begin
          DrawHome;
        end;
      end;
    end;
  end
  else
  begin
    Sleep(500);
    DrawText(edtText.Text, TrackBar1.Position);
  end;

  if CapState then
  begin
    CapsLockEnable;
  end;
end;



procedure TForm1.N1Click(Sender: TObject);
begin
  Form1.Show;
end;

procedure TForm1.N3Click(Sender: TObject);
begin
  IsExit := True;
  Form1.Close;
end;

procedure TForm1.N5Click(Sender: TObject);
begin
  BtnActive.OnClick(Sender);
  N5.Caption := BtnActive.Caption;
end;

procedure TForm1.N6Click(Sender: TObject);
var
  arr : array [0..4095] of WideChar;
begin
  Clipboard.GetTextBuf(arr, 4096);
  mmo1.Lines.Clear;
  mmo1.Lines.Add(arr);
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  lbl3.Caption := IntToStr(TrackBar1.Position) + '字/秒';
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  Form1.Show;
end;

end.
