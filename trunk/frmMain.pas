{Copyright (c) 2011 Ville Krumlinde

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.}

unit frmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, MapClasses, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs, Data.Bind.Components,
  FMX.Grid, FMX.Layouts, FMX.Memo;

type
  TMainForm = class(TForm)
    UnitList: TStringGrid;
    StringColumn1: TStringColumn;
    StringColumn2: TStringColumn;
    SymbolList: TStringGrid;
    StringColumn3: TStringColumn;
    StringColumn4: TStringColumn;
    ToolBar1: TToolBar;
    OpenButton: TButton;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure UnitListClick(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
  private
    { Private declarations }
    Map : TMapFile;
    procedure LoadFromFile(const Filename: string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Map := TMapFile.Create;
  if ParamCount>0 then
    LoadFromFile(ParamStr(1));
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Map.Free;
end;

procedure TMainForm.LoadFromFile(const Filename: string);
var
  U : TUnitInfo;
  Row : integer;
begin
  Map.LoadFromFile(Filename);

  UnitList.Selected := -1;

  UnitList.BeginUpdate;
  try
    UnitList.RowCount := Map.Units.Count;
    SymbolList.RowCount := 0;
    Row := 0;
    for U in Map.Units do
    begin
      UnitList.Cells[0,Row] := U.Name;
      UnitList.Cells[1,Row] := IntToStr(U.Size);
      Inc(Row);
    end;
  finally
    UnitList.EndUpdate;
  end;
end;

procedure TMainForm.UnitListClick(Sender: TObject);
var
  Row : integer;
  U : TUnitInfo;
  Sym : TSymbolInfo;
begin
  SymbolList.RowCount := 0;

  Row := UnitList.Selected;
  if Row=-1 then
    Exit;

  if not Map.UnitMap.TryGetValue(UnitList.Cells[0,Row],U) then
    Exit;

  SymbolList.BeginUpdate;
  try
    Row := 0;
    SymbolList.RowCount := U.Symbols.Count;
    for Sym in U.Symbols do
    begin
      SymbolList.Cells[0,Row] := Sym.Name;
      SymbolList.Cells[1,Row] := IntToStr(Sym.Size);
      Inc(Row);
    end;
  finally
    SymbolList.EndUpdate;
  end;
end;

procedure TMainForm.OpenButtonClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    LoadFromFile(OpenDialog1.FileName);
  end;
end;

end.
