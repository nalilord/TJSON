unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmMain = class(TForm)
    btnTest: TButton;
    mTestOutput: TMemo;
    btnTestJson5: TButton;
    mJson5TestOutput: TMemo;
    procedure btnTestClick(Sender: TObject);
    procedure btnTestJson5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  XENOME.JSON;

{$R *.dfm}

procedure TfrmMain.btnTestClick(Sender: TObject);
var
  JSON: TJSON;
  Arr: TArray<Integer>;
begin
  mTestOutput.Clear;

  Arr:=[1, 2, 3, 4];

  mTestOutput.Lines.Text:=TJSON.Template('template').Fill([1337, 3.14, 'fooBar', True, Arr]).WriteToString;

  JSON:=TJSON.CreateFromString(mTestOutput.Lines.Text);
  try
    mTestOutput.Lines.Add('----------');

    mTestOutput.Lines.Add('Count: ' + IntToStr(JSON.AsObject.Count));

    mTestOutput.Lines.Add('  int: ' + IntToStr(JSON.AsObject['int'].AsInteger));
    mTestOutput.Lines.Add('  float: ' + FloatToStr(JSON.AsObject['float'].AsFloat));
    mTestOutput.Lines.Add('  str: ' + JSON.AsObject['str'].AsString);
    mTestOutput.Lines.Add('  bool: ' + BoolToStr(JSON.AsObject['bool'].AsBoolean, True));
  finally
    FreeAndNil(JSON);
  end;
end;

procedure TfrmMain.btnTestJson5Click(Sender: TObject);
var
  JSON: TJSON;
begin
  JSON:=TJSON.CreateFromFile('.\test.json5', jeJSON5);
  try
  finally
    FreeAndNil(JSON);
  end;
end;

initialization
  TJSON.CreateTemplate('template')
    .Add('int', jtInteger)
    .Add('float', jtFloat)
    .Add('str', jtString)
    .Add('bool', jtBoolean)
    .Add('arr', jtArray);

end.
