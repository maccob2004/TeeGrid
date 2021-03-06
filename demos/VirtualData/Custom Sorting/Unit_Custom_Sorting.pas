unit Unit_Custom_Sorting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VCLTee.Control, VCLTee.Grid,

  Tee.Grid.Header, Tee.Grid.Columns, System.Generics.Defaults, System.Generics.Collections,
  Math, Tee.GridData.Rtti, Unit_MyData;

type
  TForm1 = class(TForm)
    TeeGrid1: TTeeGrid;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    function CreateSortable:TSortableHeader;
    procedure HeaderCanSortBy(const AColumn: TColumn; var CanSort: Boolean);
    procedure HeaderSortBy(Sender: TObject; const AColumn: TColumn);
    procedure HeaderSortState(const AColumn:TColumn; var State:TSortState);
    procedure SortData(const AColumn:Integer; const Ascending:Boolean); overload;
    procedure SortData(const AColumn:TColumn; const Ascending:Boolean); overload;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ Data }
type
  TPersonField=(Name,Street,Number,BirthDate,Children,Height);

  TPersonComparer=class(TComparer<TPerson>)
  public
    Ascending : Boolean;
    PersonField : TPersonField;

    function Compare(const Left, Right: TPerson): Integer; override;
  end;

{ Form1 }
var Persons : TArray<TPerson>;
    SortColumn, SortSubColumn: Integer;
    SortAsc: Boolean;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SetLength(Persons,10);
  FillMyData(Persons);
  SortColumn:=-1;
  SortSubColumn:=-1;

  TeeGrid1.Data:=TVirtualData<TArray<TPerson>>.Create(Persons);

  TeeGrid1.Header.SortRender:=CreateSortable;
end;

function TForm1.CreateSortable:TSortableHeader;
begin
  result:=TSortableHeader.Create(TeeGrid1.Header.Changed);

  // Set custom events
  result.OnCanSort:=HeaderCanSortBy;
  result.OnSortBy:=HeaderSortBy;
  result.OnSortState:=HeaderSortState;
end;

procedure TForm1.HeaderCanSortBy(const AColumn: TColumn; var CanSort: Boolean);
begin
  CanSort:=(AColumn<>nil) and (AColumn.Index<>4);
end;

function ParentColumn(AGrid: TTeeGrid; AColumn: TColumn): TColumn;
var i: Integer;
begin
  Result:=nil;
  if AColumn.Parent<>nil then
     for i:=0 to AGrid.Columns.Count-1 do
         if AColumn.Parent = AGrid.Columns[i] then
         begin
           Result:=AGrid.Columns[i];
           Exit;
         end;
end;

procedure TForm1.HeaderSortBy(Sender:TObject; const AColumn:TColumn);
var ParentCol: TColumn;
begin
  ParentCol:=ParentColumn(TeeGrid1, AColumn);
  if ParentCol<>nil then
  begin
    if (SortColumn=ParentCol.Index) and (SortSubColumn=AColumn.Index) then
        SortAsc:=not SortAsc;

    SortColumn:=ParentCol.Index;
    SortSubColumn:=AColumn.Index;

    if (SortColumn=1) and (SortSubColumn=0) then
       SortAsc:=True
    else
       SortAsc:=False;
  end
  else
  begin
    if SortColumn=AColumn.Index then
       SortAsc:=not SortAsc
    else
    begin
      SortColumn:=AColumn.Index;

      if SortColumn=0 then
         SortAsc:=True
      else
         SortAsc:=False;
    end;
  end;

  SortData(AColumn,SortAsc);
end;

procedure TForm1.SortData(const AColumn:Integer; const Ascending:Boolean);
begin
  SortData(TeeGrid1.Columns[AColumn], Ascending);
end;

procedure TForm1.SortData(const AColumn:TColumn; const Ascending:Boolean);
var Comparer : TPersonComparer;
begin
  Comparer:=TPersonComparer.Create;
  try
    Comparer.Ascending:=Ascending;

    if AColumn.Header.Text='Name' then
       Comparer.PersonField:=TPersonField.Name
    else if AColumn.Header.Text='Street' then
       Comparer.PersonField:=TPersonField.Street
    else if AColumn.Header.Text='Number' then
       Comparer.PersonField:=TPersonField.Number
    else if AColumn.Header.Text='BirthDate' then
       Comparer.PersonField:=TPersonField.BirthDate
    else if AColumn.Header.Text='Children' then
       Comparer.PersonField:=TPersonField.Children
    else
       Comparer.PersonField:=TPersonField.Height;

    TArray.Sort<TPerson>(Persons,Comparer);
  finally
    Comparer.Free;
  end;
end;

procedure TForm1.HeaderSortState(const AColumn:TColumn; var State:TSortState);
var ParentCol: TColumn;
begin
  if AColumn.HasItems then
  begin
     State:=TSortState.None;
     Exit;
  end;

  ParentCol:=ParentColumn(TeeGrid1,AColumn);

  if (ParentCol<>nil) then
  begin
     if (ParentCol.Index=SortColumn) and (AColumn.Index=SortSubColumn) then
        if SortAsc then
           State:=Descending
        else
           State:=Ascending
     else
        State:=TSortState.None;
  end
  else
    if SortColumn=AColumn.Index then
       if SortAsc then
          State:=Descending
       else
          State:=Ascending
    else
       State:=TSortState.None;
end;

function TPersonComparer.Compare(const Left, Right: TPerson): Integer;
var AString, BString: String;
    AInteger, BInteger: Integer;
    ASingle, BSingle: Single;
    APerson, BPerson: TPerson;
begin
  if Ascending then
  begin
    APerson:=Left;
    BPerson:=Right;
  end
  else
  begin
    APerson:=Right;
    BPerson:=Left;
  end;

  if (PersonField=Name) then
     result:=CompareText(APerson.Name,BPerson.Name)
  else if (PersonField=Street) then
     result:=CompareText(APerson.Address.Street, BPerson.Address.Street)
  else if (PersonField=Number) then
     result:=CompareValue(APerson.Address.Number, BPerson.Address.Number)
  else if (PersonField=BirthDate) then
     result:=CompareValue(APerson.BirthDate, BPerson.BirthDate)
  else if (PersonField=Children) then
     result:=CompareValue(APerson.Children, BPerson.Children)
  else if (PersonField=Height) then
     result:=CompareValue(APerson.Height, BPerson.Height);
end;

end.
