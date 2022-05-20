object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Native PIF Viewer'
  ClientHeight = 550
  ClientWidth = 765
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object scrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 765
    Height = 528
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 0
    ExplicitLeft = 160
    ExplicitTop = 96
    ExplicitWidth = 385
    ExplicitHeight = 265
    object previewImage: TImage
      Left = 144
      Top = 56
      Width = 513
      Height = 417
      AutoSize = True
      Center = True
    end
  end
  object statusMain: TStatusBar
    Left = 0
    Top = 528
    Width = 765
    Height = 22
    Panels = <
      item
        Width = 200
      end
      item
        Width = 250
      end
      item
        Width = 500
      end>
  end
  object MainMenu1: TMainMenu
    Left = 272
    Top = 208
    object mnuFile: TMenuItem
      Caption = 'File'
      object mnuOpen: TMenuItem
        Caption = 'Open image...'
        OnClick = mnuOpenClick
      end
      object mnuExport: TMenuItem
        Caption = 'Export image'
        Enabled = False
        OnClick = mnuExportClick
      end
      object mnuSep1: TMenuItem
        Caption = '-'
      end
      object mnuExit: TMenuItem
        Caption = 'Exit'
        OnClick = mnuExitClick
      end
    end
  end
  object dlgSave: TSaveDialog
    DefaultExt = '.bmp'
    Filter = 
      'Bitmap Image (*.bmp)|.bmp|JPEG Image (*.jpg)|.jpg|PNG Image (*.p' +
      'ng)|.png|All file formats|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Export image...'
    Left = 488
    Top = 208
  end
  object dlgOpenImage: TOpenDialog
    DefaultExt = '.pif'
    Filter = 'Portable Image File (*.pif)|.pif|All file formats|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Title = 'Open Portable Image File...'
    Left = 384
    Top = 208
  end
end
