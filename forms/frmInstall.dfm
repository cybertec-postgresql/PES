object fmInstall: TfmInstall
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Install Dependencies'
  ClientHeight = 309
  ClientWidth = 645
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    645
    309)
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 272
    Width = 645
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      645
      37)
    object Button2: TButton
      Left = 477
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object Button3: TButton
      Left = 564
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object mmInfo: TMemo
    Left = 16
    Top = 39
    Width = 609
    Height = 196
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object btnInstall: TButton
    Left = 16
    Top = 241
    Width = 129
    Height = 25
    Caption = 'Install Python'
    TabOrder = 2
  end
  object btnUpdateInfo: TButton
    Left = 16
    Top = 8
    Width = 129
    Height = 25
    Caption = 'Update Version Info'
    TabOrder = 3
    OnClick = btnUpdateInfoClick
  end
end
