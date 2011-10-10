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

unit MapClasses;

interface

uses Generics.Collections;

type
  TSymbolInfo = class
  public
    Name : string;
    Size,Address,Segment : integer;
  end;

  TUnitInfo = class
  public
    Symbols : TObjectList<TSymbolInfo>;
    Name : string;
    Size : integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TMapFile = class
  strict private
    procedure CleanUp;
  public
    UnitMap : TDictionary<string,TUnitInfo>;
    Units : TObjectList<TUnitInfo>;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(const Filename : string);
    procedure SortUnits(const SortIndex: integer);
  end;

implementation

uses System.StrUtils, System.Classes, System.SysUtils, Generics.Defaults,
  System.Types;

{ TMapFile }

constructor TMapFile.Create;
begin
  Units := TObjectList<TUnitInfo>.Create(True);
  UnitMap := TDictionary<string,TUnitInfo>.Create;
end;

destructor TMapFile.Destroy;
begin
  CleanUp;
  Units.Free;
  UnitMap.Free;
  inherited;
end;

procedure TMapFile.CleanUp;
begin
  Units.Clear;
  UnitMap.Clear;
end;

procedure TMapFile.SortUnits(const SortIndex : integer);
begin
  case SortIndex of
    0 :
      Units.Sort(
        //Sort on size
        TComparer<TUnitInfo>.Construct(function (const Item1, Item2: TUnitInfo): Integer
        begin
          Result := Item2.Size-Item1.Size;
        end
      ));
    1 :
      Units.Sort(
        //Sort on size
        TComparer<TUnitInfo>.Construct(function (const Item1, Item2: TUnitInfo): Integer
        begin
          Result := CompareText(Item1.Name,Item2.Name);
        end
      ));
  end;
end;

procedure TMapFile.LoadFromFile(const Filename: string);
var
  Lines : TStringList;
  I,LineNr : integer;
  Line,S,SegType,UnitName : string;
  U : TUnitInfo;
  PrevSym,Sym : TSymbolInfo;
  SkipSegs : TDictionary<string,boolean>;
begin
  CleanUp;
  Lines := TStringList.Create;
  SkipSegs := TDictionary<string,boolean>.Create;
  try
    Lines.LoadFromFile(Filename);

    //Read segments
    LineNr := Lines.IndexOf('Detailed map of segments');
    if LineNr=-1 then
      raise Exception.Create('Cannot find segment section in mapfile');
    Inc(LineNr,2);

    repeat
      Line := Lines[LineNr];
      if Length(Line)=0 then
        Break;
      Inc(LineNr);

      SegType := Trim( Copy(Line,27,9) );
      if (SegType='BSS') or (SegType='TLS') then
      begin
        //Skip segments that do not contribute to exe-size
        S := Copy(Line,2,4);
        if not SkipSegs.ContainsKey(S) then
          SkipSegs.Add(S,True);
        Continue;
      end;

      I := PosEx(' ',Line,60);
      if I=0 then
        I := Length(Line);
      UnitName := Trim(Copy(Line,60,I-60));

      if not UnitMap.TryGetValue(UnitName,U) then
      begin
        U := TUnitInfo.Create;
        Units.Add(U);
        U.Name := UnitName;
        UnitMap.Add(UnitName,U);
      end;

      S := Copy(Line,16,8);
      Inc(U.Size,StrToInt('$' + S));

    until False;

    SortUnits(0);

    //Read symbols
    LineNr := Lines.IndexOf('  Address             Publics by Value');
    if LineNr=-1 then
      raise Exception.Create('Cannot find publics by value in file');
    Inc(LineNr,2);

    PrevSym := nil;
    repeat
      Line := Lines[LineNr];
      if Length(Line)=0 then
        Break;
      Inc(LineNr);

      if SkipSegs.ContainsKey(Copy(Line,2,4)) then
        Continue; //this symbol is in a segment that we are not interested in

      S := Copy(Line,22,500);
      UnitName := S;
      U := nil;
      repeat
        if UnitMap.TryGetValue(UnitName,U) then
          Break;
        I := LastDelimiter('.',UnitName);
        if I=0 then
          Break;
        UnitName := Copy(UnitName,1,I-1);
      until False;
      if U=nil then
      begin
        U := TUnitInfo.Create;
        U.Name := '<unknown>';
        Units.Add(U);
      end;

      Sym := TSymbolInfo.Create;
      Sym.Name := Copy(S,Length(U.Name)+2,500);
      Sym.Segment := StrToInt('$' + Copy(Line,2,4));
      Sym.Address := StrToInt('$' + Copy(Line,7,8));
      U.Symbols.Add(Sym);

      if PrevSym<>nil then
      begin
        if Sym.Segment=PrevSym.Segment then
        begin
          PrevSym.Size := Sym.Address - PrevSym.Address;
        end else
        begin
          //todo: handle size on segment switch
          //PrevSym.Size := PrevU.Size - PrevSym.Address;
        end;
      end;
      PrevSym := Sym;

    until False;

    //Sort all symbols on size
    for U in Units do
      U.Symbols.Sort(
        TComparer<TSymbolInfo>.Construct(function (const Item1, Item2: TSymbolInfo): Integer
        begin
          Result := Item2.Size-Item1.Size;
        end
      ));

  finally
    Lines.Free;
    SkipSegs.Free;
  end;
end;

{ TUnitInfo }

constructor TUnitInfo.Create;
begin
  Symbols := TObjectList<TSymbolInfo>.Create;
end;

destructor TUnitInfo.Destroy;
begin
  Symbols.Free;
  inherited;
end;

end.
