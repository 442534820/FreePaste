unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm2 = class(TForm)
    mmo1: TMemo;
    BtnOK: TButton;
    procedure BtnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

uses Unit1;

procedure TForm2.BtnOKClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  Self.FormStyle := Form1.FormStyle;
end;

end.
