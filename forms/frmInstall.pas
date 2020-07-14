unit frmInstall;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.StrUtils, PythonVersions,
  Console, Vcl.ComCtrls, Vcl.ExtActns, System.Actions, Vcl.ActnList, SynEdit,
  SynMemo, SynEditHighlighter, SynHighlighterJSON, Vcl.CheckLst, Winapi.UxTheme, System.ImageList,
  Vcl.ImgList, dxGDIPlusClasses, Vcl.Grids, Data.Bind.Components, Data.Bind.ObjectScope,
  System.Generics.Collections, Data.Bind.EngExt, Vcl.Bind.DBEngExt, Vcl.Bind.Grid, System.Rtti,
  System.Bindings.Outputs, Vcl.Bind.Editors, Data.Bind.Grid, Data.Bind.Controls, Vcl.Buttons,
  Vcl.Bind.Navigator, Data.Bind.GenData, Data.DB, Vcl.DBGrids, Vcl.DBCtrls, Vcl.Mask, Vcl.DBCGrids,
  Datasnap.DBClient, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxCustomData,
  cxStyles, cxTL, cxTextEdit, cxCheckBox, cxTLdxBarBuiltInMenu, cxInplaceContainer, cxEdit,
  Winapi.ShlObj, cxShellCommon, dxBreadcrumbEdit, dxShellBreadcrumbEdit, cxContainer, cxMaskEdit,
  cxDropDownEdit, cxShellComboBox;

type
  TfmInstall = class(TForm)
    btnNext: TButton;
    btnBack: TButton;
    Panel1: TPanel;
    imgHeader: TImage;
    pcWizard: TPageControl;
    tabPython: TTabSheet;
    btnInstall: TButton;
    mmInfo: TMemo;
    ActionList1: TActionList;
    acBack: TPreviousTab;
    acNext: TNextTab;
    tabNodes: TTabSheet;
    Button1: TButton;
    acFinish: TAction;
    TabSheet1: TTabSheet;
    SynMemo1: TSynMemo;
    SynJSONSyn1: TSynJSONSyn;
    tlNodes: TcxTreeList;
    tlcHost: TcxTreeListColumn;
    tlcDatabase: TcxTreeListColumn;
    tlcEtcd: TcxTreeListColumn;
    tlcFailover: TcxTreeListColumn;
    edClusterName: TEdit;
    lbClusterName: TLabel;
    lbNodes: TLabel;
    tlcName: TcxTreeListColumn;
    cbBinDir: TcxShellComboBox;
    lbBinDir: TLabel;
    procedure UpdateInfo(Sender: TObject);
    procedure acFinishUpdate(Sender: TObject);
    procedure tlcEtcdPropertiesValidate(Sender: TObject; var DisplayValue: Variant;
      var ErrorText: TCaption; var Error: Boolean);
    procedure tlNodesNodeChanged(Sender: TcxCustomTreeList; ANode: TcxTreeListNode;
      AColumn: TcxTreeListColumn);
  private
  public
    { Public declarations }
  end;

  TNode = class(TPersistent)
  private
    FIP: string;
    FHasEtcd: boolean;
    FNoFailover: boolean;
    FHasDatabase: boolean;
  published
    property IP: string read FIP write FIP;
    property HasDatabase: boolean read FHasDatabase write FHasDatabase;
    property HasEtcd: boolean read FHasEtcd write FHasEtcd;
    property NoFailover: boolean read FNoFailover write FNoFailover;
  end;

var
  fmInstall: TfmInstall;
  Nodes: TObjectList<TNode>;

const
  PYTHON_VERSION: string = '3.7.5';

implementation

uses Math;

{$R *.dfm}

procedure TfmInstall.acFinishUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := pcWizard.ActivePageIndex = pcWizard.PageCount - 1;
end;

procedure TfmInstall.tlcEtcdPropertiesValidate(Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
var
  I, N: Integer;
begin
  N := 0;
  for I := 0 to tlNodes.Count - 1 do
  begin
    if tlNodes.Items[I].Values[tlcEtcd.ItemIndex] = True then
      inc(N)
  end;
  Error := N in [1,3,5,7];
  ErrorText := Format('Etcd cluster size %d not supported, use odd number of nodes up to 7', [N+1]);
end;

procedure TfmInstall.tlNodesNodeChanged(Sender: TcxCustomTreeList; ANode: TcxTreeListNode;
  AColumn: TcxTreeListColumn);
var
  I: Integer;
begin
  for I := tlcDatabase.ItemIndex to tlcFailover.ItemIndex do
    if ANode.Values[I] = Null then
      ANode.Values[I] := True;
end;

procedure TfmInstall.UpdateInfo(Sender: TObject);
var
    v:  TPythonVersion;
    vv: TPythonVersions;
begin
  mmInfo.Clear;
  mmInfo.Lines.Add('Default Python version in system:');
  mmInfo.Lines.Add('---------------------------------');
  mmInfo.Lines.Add(GetDosOutput('python.exe -c "import sys; print(sys.version)" '));
  mmInfo.Lines.Add('');
  mmInfo.Lines.Add('Installed Python versions in system:');
  mmInfo.Lines.Add('---------------------------------');
  vv := GetRegisteredPythonVersions();
  if Length(vv) > 0 then
    btnInstall.Caption := ifthen(Length(vv) > 0, 'Upgrade Python', 'Install Python');

  for v in vv do
  with mmInfo.Lines do
  begin
    btnInstall.Enabled := btnInstall.Enabled and (CompareVersions(v.Version, PYTHON_VERSION) > 0);
    Add(Format('Name: %s', [v.DisplayName]));
    Add(Format('Installation: %s', [v.InstallPath]));
    Add(Format('Executable: %s', [v.PythonExecutable]));
    Add('');
  end;

end;

{ TNode }


end.
