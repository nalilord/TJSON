object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'JSON Test Application'
  ClientHeight = 355
  ClientWidth = 774
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object btnTest: TButton
    Left = 8
    Top = 200
    Width = 97
    Height = 25
    Caption = 'Run Test'
    TabOrder = 0
    OnClick = btnTestClick
  end
  object mTestOutput: TMemo
    Left = 8
    Top = 8
    Width = 361
    Height = 186
    TabOrder = 1
  end
  object btnTestJson5: TButton
    Left = 375
    Top = 200
    Width = 97
    Height = 25
    Caption = 'Run Json5 Test'
    TabOrder = 2
    OnClick = btnTestJson5Click
  end
  object mJson5TestOutput: TMemo
    Left = 375
    Top = 8
    Width = 361
    Height = 186
    TabOrder = 3
  end
end
