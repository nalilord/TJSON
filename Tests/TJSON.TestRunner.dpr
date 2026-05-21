program TJSONTestRunner;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.Variants, XENOME.JSON;

type
  TFixedIntArray = array[0..2] of Integer;
  TRttiDemoEnum = (rdeZero, rdeOne, rdeTwo, rdeDarkRed);
  TRttiDemoSet = set of TRttiDemoEnum;

  TRttiNestedObject = class
  public
    Value: String;
  end;

  TRttiDemoRecord = record
    RecText: String;
    RecNumber: Integer;
    RecInt64: Int64;
    RecByte: Byte;
    RecWord: Word;
    RecCardinal: Cardinal;
    RecDouble: Double;
    RecExtended: Extended;
    RecCurrency: Currency;
    RecDateTime: TDateTime;
    RecBoolean: Boolean;
    RecChar: Char;
    RecWideChar: WideChar;
    RecEnum: TRttiDemoEnum;
    RecSet: TRttiDemoSet;
    RecVariant: Variant;
    RecArray: TArray<Integer>;
    RecStringArray: TArray<String>;
    RecDoubleArray: TArray<Double>;
    RecBoolArray: TArray<Boolean>;
    RecFixed: TFixedIntArray;
  end;

  TRttiDemoObject = class
  private
    FPropText: String;
    FPropNumber: Integer;
    FPropInt64: Int64;
    FPropByte: Byte;
    FPropWord: Word;
    FPropCardinal: Cardinal;
    FPropDouble: Double;
    FPropExtended: Extended;
    FPropCurrency: Currency;
    FPropDateTime: TDateTime;
    FPropBoolean: Boolean;
    FPropChar: Char;
    FPropWideChar: WideChar;
    FPropEnum: TRttiDemoEnum;
    FPropSet: TRttiDemoSet;
    FPropVariant: Variant;
    FPropArray: TArray<Integer>;
    FPropStringArray: TArray<String>;
    FPropDoubleArray: TArray<Double>;
    FPropBoolArray: TArray<Boolean>;
    FPropChild: TRttiNestedObject;
  public
    FieldText: String;
    FieldNumber: Integer;
    FieldInt64: Int64;
    FieldByte: Byte;
    FieldWord: Word;
    FieldCardinal: Cardinal;
    FieldSingle: Single;
    FieldDouble: Double;
    FieldExtended: Extended;
    FieldCurrency: Currency;
    FieldDateTime: TDateTime;
    FieldBoolean: Boolean;
    FieldChar: Char;
    FieldWideChar: WideChar;
    FieldEnum: TRttiDemoEnum;
    FieldSet: TRttiDemoSet;
    FieldVariant: Variant;
    FieldArray: TArray<Integer>;
    FieldStringArray: TArray<String>;
    FieldDoubleArray: TArray<Double>;
    FieldBoolArray: TArray<Boolean>;
    FieldFixed: TFixedIntArray;
    FieldChild: TRttiNestedObject;

    destructor Destroy; override;
    property PropText: String read FPropText write FPropText;
    property PropNumber: Integer read FPropNumber write FPropNumber;
    property PropInt64: Int64 read FPropInt64 write FPropInt64;
    property PropByte: Byte read FPropByte write FPropByte;
    property PropWord: Word read FPropWord write FPropWord;
    property PropCardinal: Cardinal read FPropCardinal write FPropCardinal;
    property PropDouble: Double read FPropDouble write FPropDouble;
    property PropExtended: Extended read FPropExtended write FPropExtended;
    property PropCurrency: Currency read FPropCurrency write FPropCurrency;
    property PropDateTime: TDateTime read FPropDateTime write FPropDateTime;
    property PropBoolean: Boolean read FPropBoolean write FPropBoolean;
    property PropChar: Char read FPropChar write FPropChar;
    property PropWideChar: WideChar read FPropWideChar write FPropWideChar;
    property PropEnum: TRttiDemoEnum read FPropEnum write FPropEnum;
    property PropSet: TRttiDemoSet read FPropSet write FPropSet;
    property PropVariant: Variant read FPropVariant write FPropVariant;
    property PropArray: TArray<Integer> read FPropArray write FPropArray;
    property PropStringArray: TArray<String> read FPropStringArray write FPropStringArray;
    property PropDoubleArray: TArray<Double> read FPropDoubleArray write FPropDoubleArray;
    property PropBoolArray: TArray<Boolean> read FPropBoolArray write FPropBoolArray;
    property PropChild: TRttiNestedObject read FPropChild write FPropChild;
  end;

var
  TotalChecks: Integer = 0;
  PassedChecks: Integer = 0;
  FailedChecks: Integer = 0;

destructor TRttiDemoObject.Destroy;
begin
  FieldChild.Free;
  FPropChild.Free;
  inherited;
end;

procedure Expect(const ACondition: Boolean; const AName: String; const ADetails: String = '');
begin
  Inc(TotalChecks);

  if ACondition then
  begin
    Inc(PassedChecks);
    Writeln('[PASS] ', AName);
  end else
  begin
    Inc(FailedChecks);
    if ADetails = '' then
      Writeln('[FAIL] ', AName)
    else
      Writeln('[FAIL] ', AName, ' - ', ADetails);
  end;
end;

procedure ExpectEqInt(const AExpected: Int64; const AActual: Int64; const AName: String);
begin
  Expect(AExpected = AActual, AName, 'Expected ' + IntToStr(AExpected) + ', got ' + IntToStr(AActual));
end;

procedure ExpectEqString(const AExpected: String; const AActual: String; const AName: String);
begin
  Expect(AExpected = AActual, AName, 'Expected "' + AExpected + '", got "' + AActual + '"');
end;

procedure ExpectEqBool(const AExpected: Boolean; const AActual: Boolean; const AName: String);
begin
  Expect(AExpected = AActual, AName, 'Expected ' + BoolToStr(AExpected, True) + ', got ' + BoolToStr(AActual, True));
end;

procedure ExpectEqFloat(const AExpected: Extended; const AActual: Extended; const AName: String);
begin
  Expect(Abs(AExpected - AActual) < 0.000001, AName, 'Expected ' + FloatToStr(AExpected) + ', got ' + FloatToStr(AActual));
end;

procedure ExpectParseFails(const AJSON: String; const AName: String; const AExtension: TJSONExtension = jeDefault);
var
  JSON: TJSON;
begin
  JSON:=nil;
  try
    JSON:=TJSON.CreateFromString(AJSON, AExtension);
    Expect(False, AName, 'Parser accepted malformed input');
  except
    on E: EJSONException do
      Expect(True, AName, E.Message);
    on E: Exception do
      Expect(True, AName, E.Message);
  end;
  JSON.Free;
end;

procedure TestBasicConstructorsAndPrimitives;
var
  JSON: TJSON;
  ArrayPayload: TJSONArray;
  Text: String;
  List: TArray<Integer>;
begin
  JSON:=TJSON.Create;
  try
    Expect(JSON.IsEmpty, 'Create() returns empty JSON');
  finally
    JSON.Free;
  end;

  JSON:=TJSON.CreateArrayRoot;
  try
    Expect(JSON.IsArray, 'CreateArrayRoot() creates array root');
    JSON.AsArray.Add('value');
    JSON.AsArray.AddObject.Add('nested', True);
    ExpectEqInt(2, JSON.AsArray.Count, 'Array root accepts Add/Object');
    Text:=JSON.WriteToString(jswmReadable);
    Expect(Pos('value', Text) > 0, 'Array readable write contains items');
  finally
    JSON.Free;
  end;

  JSON:=TJSON.CreateObjectRoot;
  try
    JSON.AsObject.Add('name', 'demo');
    JSON.AsObject.Add('count', 7);
    JSON.AsObject.Add('pi', 3.1415);
    JSON.AsObject.Add('alive', True);
    JSON.AsObject.Add('nothing');

    SetLength(List, 3);
    List[0]:=1;
    List[1]:=2;
    List[2]:=3;
    ArrayPayload:=JSON.AsObject.AddArray('items');
    ArrayPayload.Add(List[0]);
    ArrayPayload.Add(List[1]);
    ArrayPayload.Add(List[2]);

    ExpectEqInt(6, JSON.AsObject.Count, 'Object root key count');
    ExpectEqString('demo', JSON.AsObject['name'].AsString, 'Object Add/Get string');
    ExpectEqInt(7, JSON.AsObject['count'].AsInteger, 'Object Add/Get int');
    ExpectEqFloat(3.1415, JSON.AsObject['pi'].AsFloat, 'Object Add/Get float');
    ExpectEqBool(True, JSON.AsObject['alive'].AsBoolean, 'Object Add/Get bool');
    ExpectEqBool(True, JSON.AsObject['nothing'].IsNull, 'Object Add(null)');
    ExpectEqInt(3, JSON.AsObject['items'].AsArray.Count, 'Object AddArray() size');

    Text:=JSON.WriteToString(jswmReadable);
    Expect(Pos('"demo"', Text) > 0, 'Readable object write contains string literal');
    Text:=JSON.WriteToString(jswmCondensed);
    Expect(Not (Pos(sLineBreak, Text) > 0), 'Condensed write has no line breaks');
  finally
    JSON.Free;
  end;
end;

procedure TestReadWriteAndPath;
var
  JSON: TJSON;
  JSONOut: TJSON;
  Stream: TMemoryStream;
  TmpFile: String;
begin
  JSON:=TJSON.CreateFromString('{"user":{"name":"Alice","scores":[10,20,30]},"active":true,"root":{"child":false}}');
  try
    Expect(JSON.IsObject, 'CreateFromString() parses JSON');
    ExpectEqString('Alice', JSON.AsObject.Path('user.name').AsString, 'Path() nested object');
    ExpectEqInt(20, JSON.AsObject.Path('user.scores.1').AsInteger, 'Path() nested array index');
    Expect(JSON.AsObject.Path('missing') = nil, 'Path() missing key returns nil');
  finally
    JSON.Free;
  end;

  JSON:=TJSON.CreateFromString('{' + sLineBreak + '''user'': ''x'', active: false, nums: [1,2,3], // comment' + sLineBreak + 'text: ''json5''}', jeJSON5);
  try
    Expect(JSON.IsObject, 'CreateFromString(JSON5) parses object');
    ExpectEqString('x', JSON.AsObject['user'].AsString, 'JSON5 single quoted string');
    ExpectEqBool(False, JSON.AsObject['active'].AsBoolean, 'JSON5 false literal');
    ExpectEqInt(3, JSON.AsObject['nums'].AsArray.Count, 'JSON5 array parsing');
    ExpectEqString('json5', JSON.AsObject['text'].AsString, 'JSON5 unquoted keys');
  finally
    JSON.Free;
  end;

  JSON:=TJSON.CreateFromString('{"a":1}');
  try
    Stream:=TMemoryStream.Create;
    try
      JSON.SaveToStream(Stream);
      Stream.Position:=0;
      JSONOut:=TJSON.CreateFromStream(Stream);
      try
        ExpectEqInt(1, JSONOut.AsObject['a'].AsInteger, 'SaveToStream + CreateFromStream');
      finally
        JSONOut.Free;
      end;
    finally
      Stream.Free;
    end;
  finally
    JSON.Free;
  end;

  TmpFile:='tjson_test_file.tmp';
  JSON:=TJSON.CreateFromString('{"a":true}');
  try
    JSON.WriteToFile(TmpFile);
    JSONOut:=TJSON.CreateFromFile(TmpFile);
    try
      ExpectEqBool(True, JSONOut.AsObject['a'].AsBoolean, 'WriteToFile + CreateFromFile');
    finally
      JSONOut.Free;
    end;
  finally
    JSON.Free;
    DeleteFile(TmpFile);
  end;

  ExpectParseFails('{"open":"value"', 'Malformed object fails on missing closing brace');
  ExpectParseFails('["open"', 'Malformed array fails on missing closing bracket');
  ExpectParseFails('{"bad":"unterminated}', 'Malformed string fails on missing quote');
  ExpectParseFails('{"bad":1.2.3}', 'Malformed number fails instead of becoming zero');
  ExpectParseFails('{bad: "unterminated}', 'Malformed JSON5 string fails on missing quote', jeJSON5);
  ExpectParseFails('{bad: 1.2.3}', 'Malformed JSON5 number fails instead of becoming zero', jeJSON5);
end;

procedure TestObjectLifecycle;
var
  JSON: TJSON;
  JSONCopy: TJSON;
begin
  JSON:=TJSON.CreateObjectRoot;
  try
    JSON.AsObject.Add('value', 123);
    ExpectEqInt(1, JSON.AsObject.Count, 'CreateObjectRoot() has expected key count');

    JSON.ReadFromString('{"value":999}');
    ExpectEqInt(1, JSON.AsObject.Count, 'ReadFromString() repopulates current instance');
    ExpectEqInt(999, JSON.AsObject['value'].AsInteger, 'ReadFromString() updates value');
  finally
    JSON.Free;
  end;

  JSON:=TJSON.CreateFromString('{"keep":1}');
  JSONCopy:=TJSON.Create;
  try
    JSONCopy.Assign(JSON);
    ExpectEqInt(1, JSONCopy.AsObject['keep'].AsInteger, 'Assign() copies source values');
  finally
    JSONCopy.Free;
    JSON.Free;
  end;
end;

procedure TestObjectOperations;
var
  JSON: TJSON;
  Defaults: TArray<Integer>;
  Snapshot: TArray<Integer>;
  ValueInt: Int64;
  ValueBool: Boolean;
  NestedObj: TJSONObject;
begin
  JSON:=TJSON.CreateObjectRoot;
  try
    ValueInt:=JSON.AsObject.GetOrAdd('answer', 42);
    ExpectEqInt(42, ValueInt, 'GetOrAdd(int) inserts default when missing');
    ValueInt:=JSON.AsObject.GetOrAdd('answer', 99);
    ExpectEqInt(42, ValueInt, 'GetOrAdd(int) returns existing value');

    ValueBool:=JSON.AsObject.GetOrAdd('flag', True);
    ExpectEqBool(True, ValueBool, 'GetOrAdd(bool) inserts default');
    JSON.AsObject.SetOrAdd('answer', 43);
    ExpectEqInt(43, JSON.AsObject['answer'].AsInteger, 'SetOrAdd(int) updates existing');

    SetLength(Defaults, 2);
    Defaults[0]:=7;
    Defaults[1]:=8;
    Snapshot:=JSON.AsObject.GetOrAddArray<Integer>('fallback', Defaults);
    ExpectEqInt(2, Length(Snapshot), 'GetOrAddArray<T>() returns default array length');
    ExpectEqInt(8, Snapshot[1], 'GetOrAddArray<T>() returns default content');

    try
      JSON.AsObject.Add('duplicate', 1);
      JSON.AsObject.Add('duplicate', 2);
      Expect(False, 'Add() rejects duplicate key');
    except
      on E: Exception do
        Expect(True, 'Add() rejects duplicate key', E.Message);
    end;

    NestedObj:=JSON.AsObject.GetOrAddObject('nested');
    NestedObj.Add('ok', True);
    ExpectEqBool(True, JSON.AsObject.Path('nested.ok').AsBoolean, 'GetOrAddObject() creates nested object');

    JSON.AsObject.Delete('duplicate');
    Expect(NOT JSON.AsObject.HasKey('duplicate'), 'Delete() removes key');
  finally
    JSON.Free;
  end;
end;

procedure TestMerge;
var
  LeftJSON: TJSON;
  RightJSON: TJSON;
begin
  LeftJSON:=TJSON.CreateFromString('{"a":1,"nested":{"x":1},"arr":[1]}');
  RightJSON:=TJSON.CreateFromString('{"b":2,"nested":{"y":2},"arr":[2]}');
  try
    LeftJSON.AsObject.Merge(RightJSON.AsObject);

    ExpectEqInt(1, LeftJSON.AsObject['a'].AsInteger, 'Merge keeps destination scalar');
    ExpectEqInt(2, LeftJSON.AsObject['b'].AsInteger, 'Merge adds source scalar');
    Expect(LeftJSON.AsObject['nested'].IsObject, 'Merge preserves nested object');
    if LeftJSON.AsObject['nested'].IsObject then
    begin
      ExpectEqInt(1, LeftJSON.AsObject['nested'].AsObject['x'].AsInteger, 'Merge keeps nested x');
      ExpectEqInt(2, LeftJSON.AsObject['nested'].AsObject['y'].AsInteger, 'Merge adds nested y');
    end;
    ExpectEqInt(1, LeftJSON.AsObject['arr'].AsArray.Count, 'Merge replaces destination array');
    ExpectEqInt(2, LeftJSON.AsObject['arr'].AsArray[0].AsInteger, 'Merge uses source array value');
  finally
    RightJSON.Free;
    LeftJSON.Free;
  end;
end;

procedure TestArrayOperations;
var
  Arr: TJSONArray;
  ChildObj: TJSONObject;
begin
  Arr:=TJSONArray.Create;
  try
  Arr.Add(1);
  Arr.Add(2);
  Arr.Add(3);
  Arr.Insert(1, TJSONString.CreateFrom('x'));
  ExpectEqInt(4, Arr.Count, 'TJSONArray.Insert() updates count');
  ExpectEqString('x', Arr[1].AsString, 'TJSONArray.Insert() stores element');

  Arr.Move(0, 3);
  ExpectEqInt(2, Arr[1].AsInteger, 'TJSONArray.Move() shifts first element');
  ExpectEqInt(1, Arr[3].AsInteger, 'TJSONArray.Move() places moved element at end');

  Arr.Exchange(0, 3);
  ExpectEqInt(1, Arr[0].AsInteger, 'TJSONArray.Exchange() swaps');
  ExpectEqString('x', Arr[3].AsString, 'TJSONArray.Exchange() swaps second element');

    Arr.Replace(2, TJSONBoolean.CreateFrom(True));
    Expect(Arr[2] IS TJSONBoolean, 'TJSONArray.Replace() changes type');

    Arr.Delete(1);
    ExpectEqInt(3, Arr.Count, 'TJSONArray.Delete() reduces count');

    ChildObj:=Arr.AddObject;
    ChildObj.Add('k', 'v');
    ExpectEqString('v', Arr[3].AsObject['k'].AsString, 'TJSONArray.AddObject() appends JSON object');
  finally
    Arr.Free;
  end;
end;

procedure TestTemplateEngine;
var
  BaseTpl: TJSONTemplate;
  NestedTpl: TJSONTemplate;
  FillTpl: TJSONTemplate;
  NestedPayload: TJSON;
  Output: TJSON;
begin
  NestedTpl:=TJSON.CreateTemplate('tpl_nested');
  NestedTpl.Add('value', jtInteger).Default(TJSONInteger.CreateFrom(9));

  BaseTpl:=TJSON.CreateTemplate('tpl_base');
  BaseTpl.Add('id', jtInteger).Default(TJSONInteger.CreateFrom(1));
  BaseTpl.Add('name', jtString);
  BaseTpl.Add('created', jttUnixTime);
  BaseTpl.Add('source', jttName);
  BaseTpl.Add('payload', 'tpl_nested');

  Output:=BaseTpl.Empty;
  if Output.AsObject.Path('payload.value') <> nil then
    ExpectEqInt(9, Output.AsObject.Path('payload.value').AsInteger, 'Template.Empty() applies nested template defaults')
  else
    Expect(False, 'Template.Empty() applies nested template defaults');
  Expect(Output.AsObject['created'].IsInteger, 'Template.Empty() applies unix time');
  ExpectEqString('tpl_base', Output.AsObject['source'].AsString, 'Template.Empty() applies template name');

  Expect(NOT BaseTpl.SetValue('payload', 'wrong type'), 'Template.SetValue() rejects wrong type');
  Expect(NOT BaseTpl.SetValue('missing', 1), 'Template.SetValue() ignores unknown fields');
  Expect(BaseTpl.SetValue('id', 55), 'Template.SetValue() updates typed field');
  ExpectEqInt(55, BaseTpl.JSON.AsObject['id'].AsInteger, 'Template.SetValue() updates template JSON cache');

  BaseTpl.SetFlags([tfOmitEmpty]);
  BaseTpl.Clear;
  BaseTpl.Add('only_default', jtInteger).Default(TJSONInteger.CreateFrom(99));
  BaseTpl.Add('empty_name', jtString);
  Output:=BaseTpl.Empty;
  ExpectEqInt(99, Output.AsObject['only_default'].AsInteger, 'tfOmitEmpty keeps declared defaults');
  Expect(NOT Output.AsObject.HasKey('empty_name'), 'tfOmitEmpty omits undeclared empty fields');

  BaseTpl.SetFlags([]);
  FillTpl:=TJSON.CreateTemplate('tpl_fill');
  FillTpl.Add('id', jtInteger);
  FillTpl.Add('name', jtString);
  FillTpl.Add('payload', jttObject);
  NestedPayload:=TJSON.CreateObjectRoot;
  NestedPayload.AsObject.Add('value', 77);
  Output:=FillTpl.Fill([77, 'from_fill', NestedPayload.AsObject]);
  ExpectEqInt(77, Output.AsObject['id'].AsInteger, 'Fill() provides first field value');
  ExpectEqString('from_fill', Output.AsObject['name'].AsString, 'Fill() provides second field value');
  Expect(Output.AsObject['payload'].IsObject, 'Fill() fills object field');
  if Output.AsObject['payload'].IsObject then
    ExpectEqInt(77, Output.AsObject['payload'].AsObject['value'].AsInteger, 'Fill() stores payload object');

  NestedPayload.Free;
end;

procedure TestJsonGetValue;
var
  Value: String;
begin
  Value:=JsonGetValue('x', 'fallback', '{"x":"found"}');
  ExpectEqString('found', Value, 'JsonGetValue() returns found value');

  Value:=JsonGetValue('missing', 'fallback', '{"x":"found"}');
  ExpectEqString('fallback', Value, 'JsonGetValue() returns fallback');
end;

procedure TestMutabilityAndCopy;
var
  JSON: TJSON;
  CopyValue: TJSONValue;
  SourceObj: TJSONObject;
  CopiedObj: TJSONObject;
begin
  JSON:=TJSON.CreateFromString('{"x":12}');
  try
    CopyValue:=JSON.AsObject['x'].Copy;
    try
      Expect(CopyValue IS TJSONInteger, 'TJSONValue.Copy() preserves type');
      ExpectEqInt(12, CopyValue.AsInteger, 'TJSONValue.Copy() preserves value');
    finally
      CopyValue.Free;
    end;
  finally
    JSON.Free;
  end;

  SourceObj:=TJSONObject.Create;
  try
    SourceObj.Add('a', 1);
    SourceObj.Add('b', 'x');
    SourceObj.AddArray('arr').Add(True);

    CopyValue:=SourceObj.Copy;
    try
      Expect(CopyValue IS TJSONObject, 'TJSONObject.Copy() returns object');
      CopiedObj:=TJSONObject(CopyValue);
      ExpectEqInt(3, CopiedObj.Count, 'TJSONObject.Copy() duplicates children count');
      ExpectEqString('x', CopiedObj['b'].AsString, 'TJSONObject.Copy() duplicates string field');
    finally
      CopyValue.Free;
    end;
  finally
    SourceObj.Free;
  end;
end;

{$IFDEF JSON_USE_RTTI}
procedure FillArray(var AValues: TArray<Integer>; const AValue0, AValue1, AValue2: Integer);
begin
  SetLength(AValues, 3);
  AValues[0]:=AValue0;
  AValues[1]:=AValue1;
  AValues[2]:=AValue2;
end;

procedure TestRTTIFeatures;
  var
    DemoObj: TRttiDemoObject;
    DemoObj2: TRttiDemoObject;
    JsonObj: TJSON;
    SourceRec: TRttiDemoRecord;
    DestRec: TRttiDemoRecord;
    RecJSON: TJSON;
    I: Integer;
    PropArrayValues: TArray<Integer>;
    SavedRules: TJSONSerializerRules;
    Rules: TJSONSerializerRules;
  begin
  SavedRules:=TJSON.SerializerRules;
  DemoObj:=TRttiDemoObject.Create;
  try
    DemoObj.FieldText:='field_text';
    DemoObj.FieldNumber:=10;
    DemoObj.FieldInt64:=1234567890123;
    DemoObj.FieldByte:=250;
    DemoObj.FieldWord:=65000;
    DemoObj.FieldCardinal:=4000000000;
    DemoObj.FieldSingle:=1.5;
    DemoObj.FieldDouble:=2.5;
    DemoObj.FieldExtended:=3.5;
    DemoObj.FieldCurrency:=4.25;
    DemoObj.FieldDateTime:=45678.75;
    DemoObj.FieldBoolean:=True;
    DemoObj.FieldChar:='A';
    DemoObj.FieldWideChar:='W';
    DemoObj.FieldEnum:=rdeTwo;
    DemoObj.FieldSet:=[rdeZero, rdeTwo];
    DemoObj.FieldVariant:='variant_field';
    FillArray(DemoObj.FieldArray, 1, 2, 3);
    DemoObj.FieldStringArray:=TArray<String>.Create('one', 'two');
    DemoObj.FieldDoubleArray:=TArray<Double>.Create(1.25, 2.5);
    DemoObj.FieldBoolArray:=TArray<Boolean>.Create(True, False);
    DemoObj.FieldFixed[0]:=11;
    DemoObj.FieldFixed[1]:=22;
    DemoObj.FieldFixed[2]:=33;
    DemoObj.FieldChild:=TRttiNestedObject.Create;
    DemoObj.FieldChild.Value:='field_child';
    DemoObj.PropText:='prop_text';
    DemoObj.PropNumber:=5;
    DemoObj.PropInt64:=2234567890123;
    DemoObj.PropByte:=251;
    DemoObj.PropWord:=65001;
    DemoObj.PropCardinal:=4000000001;
    DemoObj.PropDouble:=6.25;
    DemoObj.PropExtended:=7.5;
    DemoObj.PropCurrency:=8.75;
    DemoObj.PropDateTime:=45679.25;
    DemoObj.PropBoolean:=True;
    DemoObj.PropChar:='B';
    DemoObj.PropWideChar:='X';
    DemoObj.PropEnum:=rdeOne;
    DemoObj.PropSet:=[rdeOne, rdeTwo];
    DemoObj.PropVariant:='variant_prop';
    SetLength(PropArrayValues, 3);
    PropArrayValues[0]:=10;
    PropArrayValues[1]:=20;
    PropArrayValues[2]:=30;
    DemoObj.PropArray:=PropArrayValues;
    DemoObj.PropStringArray:=TArray<String>.Create('alpha', 'beta');
    DemoObj.PropDoubleArray:=TArray<Double>.Create(6.5, 7.75);
    DemoObj.PropBoolArray:=TArray<Boolean>.Create(False, True);
    DemoObj.PropChild:=TRttiNestedObject.Create;
    DemoObj.PropChild.Value:='prop_child';

    JsonObj:=TJSON.CreateFromObject(DemoObj);
    try
      Expect(JsonObj.IsObject, 'CreateFromObject() with JSON_USE_RTTI');
      ExpectEqString('field_text', JsonObj.AsObject['FieldText'].AsString, 'RTTI object field text');
      ExpectEqString('prop_text', JsonObj.AsObject['PropText'].AsString, 'RTTI object property text');
      ExpectEqInt(1234567890123, JsonObj.AsObject['FieldInt64'].AsInteger, 'RTTI object field int64');
      ExpectEqInt(250, JsonObj.AsObject['FieldByte'].AsInteger, 'RTTI object field byte');
      ExpectEqInt(65000, JsonObj.AsObject['FieldWord'].AsInteger, 'RTTI object field word');
      ExpectEqInt(4000000000, JsonObj.AsObject['FieldCardinal'].AsInteger, 'RTTI object field cardinal');
      ExpectEqFloat(1.5, JsonObj.AsObject['FieldSingle'].AsFloat, 'RTTI object field single');
      ExpectEqFloat(2.5, JsonObj.AsObject['FieldDouble'].AsFloat, 'RTTI object field double');
      ExpectEqFloat(3.5, JsonObj.AsObject['FieldExtended'].AsFloat, 'RTTI object field extended');
      ExpectEqFloat(4.25, JsonObj.AsObject['FieldCurrency'].AsFloat, 'RTTI object field currency');
      ExpectEqFloat(45678.75, JsonObj.AsObject['FieldDateTime'].AsFloat, 'RTTI object field datetime');
      ExpectEqBool(True, JsonObj.AsObject['FieldBoolean'].AsBoolean, 'RTTI object field boolean');
      ExpectEqString('A', JsonObj.AsObject['FieldChar'].AsString, 'RTTI object field char');
      ExpectEqString('W', JsonObj.AsObject['FieldWideChar'].AsString, 'RTTI object field widechar');
      ExpectEqInt(Ord(rdeTwo), JsonObj.AsObject['FieldEnum'].AsInteger, 'RTTI object field enum');
      ExpectEqInt(5, JsonObj.AsObject['FieldSet'].AsInteger, 'RTTI object field set');
      ExpectEqString('variant_field', JsonObj.AsObject['FieldVariant'].AsString, 'RTTI object field variant');
      ExpectEqFloat(6.25, JsonObj.AsObject['PropDouble'].AsFloat, 'RTTI object property double');
      ExpectEqFloat(7.5, JsonObj.AsObject['PropExtended'].AsFloat, 'RTTI object property extended');
      ExpectEqFloat(8.75, JsonObj.AsObject['PropCurrency'].AsFloat, 'RTTI object property currency');
      ExpectEqFloat(45679.25, JsonObj.AsObject['PropDateTime'].AsFloat, 'RTTI object property datetime');
      ExpectEqBool(True, JsonObj.AsObject['PropBoolean'].AsBoolean, 'RTTI object property boolean');
      ExpectEqString('B', JsonObj.AsObject['PropChar'].AsString, 'RTTI object property char');
      ExpectEqString('X', JsonObj.AsObject['PropWideChar'].AsString, 'RTTI object property widechar');
      ExpectEqInt(Ord(rdeOne), JsonObj.AsObject['PropEnum'].AsInteger, 'RTTI object property enum');
      ExpectEqInt(6, JsonObj.AsObject['PropSet'].AsInteger, 'RTTI object property set');
      ExpectEqString('variant_prop', JsonObj.AsObject['PropVariant'].AsString, 'RTTI object property variant');
      ExpectEqInt(3, JsonObj.AsObject['FieldArray'].AsArray.Count, 'RTTI object field array count');
      ExpectEqString('two', JsonObj.AsObject['FieldStringArray'].AsArray[1].AsString, 'RTTI object field string array');
      ExpectEqFloat(2.5, JsonObj.AsObject['FieldDoubleArray'].AsArray[1].AsFloat, 'RTTI object field double array');
      ExpectEqBool(False, JsonObj.AsObject['FieldBoolArray'].AsArray[1].AsBoolean, 'RTTI object field boolean array');
      ExpectEqInt(3, JsonObj.AsObject['PropArray'].AsArray.Count, 'RTTI object property array count');
      ExpectEqString('beta', JsonObj.AsObject['PropStringArray'].AsArray[1].AsString, 'RTTI object property string array');
      ExpectEqFloat(7.75, JsonObj.AsObject['PropDoubleArray'].AsArray[1].AsFloat, 'RTTI object property double array');
      ExpectEqBool(True, JsonObj.AsObject['PropBoolArray'].AsArray[1].AsBoolean, 'RTTI object property boolean array');
      ExpectEqInt(3, JsonObj.AsObject['FieldFixed'].AsArray.Count, 'RTTI object fixed array count');
      ExpectEqInt(22, JsonObj.AsObject['FieldFixed'].AsArray[1].AsInteger, 'RTTI object fixed array value');
      ExpectEqString('field_child', JsonObj.AsObject.Path('FieldChild.Value').AsString, 'RTTI object nested field object');
      ExpectEqString('prop_child', JsonObj.AsObject.Path('PropChild.Value').AsString, 'RTTI object nested property object');
    finally
      JsonObj.Free;
    end;

    Rules:=TJSON.DefaultSerializerRules;
    Rules.EnumMode:=jemName;
    Rules.EnumStripPrefixes:=TArray<String>.Create('rde');
    Rules.EnumNameCase:=jncSnake;
    TJSON.SerializerRules:=Rules;
    DemoObj.FieldEnum:=rdeDarkRed;
    JsonObj:=TJSON.CreateFromObject(DemoObj);
    try
      ExpectEqString('dark_red', JsonObj.AsObject['FieldEnum'].AsString, 'SerializerRules writes enum as snake_case string');
    finally
      JsonObj.Free;
    end;

    Rules.EnumNameCase:=jncScreamingSnake;
    TJSON.SerializerRules:=Rules;
    JsonObj:=TJSON.CreateFromObject(DemoObj);
    try
      ExpectEqString('DARK_RED', JsonObj.AsObject['FieldEnum'].AsString, 'SerializerRules writes enum as SNAKE_CASE string');
    finally
      JsonObj.Free;
    end;

    Rules.EnumNameCase:=jncSnake;
    TJSON.SerializerRules:=Rules;
    JsonObj:=TJSON.CreateFromString('{"FieldEnum":"dark_red","PropEnum":"dark_red"}');
    try
      DemoObj2:=TRttiDemoObject.Create;
      try
        JsonObj.AssignToObject(DemoObj2);
        Expect(DemoObj2.FieldEnum = rdeDarkRed, 'SerializerRules reads enum from snake_case string');
        Expect(DemoObj2.PropEnum = rdeDarkRed, 'SerializerRules reads property enum from snake_case string');
      finally
        DemoObj2.Free;
      end;
    finally
      JsonObj.Free;
    end;

    TJSON.SerializerRules:=SavedRules;

    JsonObj:=TJSON.CreateFromString('{"FieldText":"F2","FieldNumber":21,"FieldInt64":1234567890124,"FieldByte":42,"FieldWord":4242,"FieldCardinal":3000000000,"FieldSingle":3.5,"FieldDouble":4.5,"FieldExtended":5.5,"FieldCurrency":6.5,"FieldDateTime":45680.5,"FieldBoolean":true,"FieldChar":"C","FieldWideChar":"Y","FieldEnum":1,"FieldSet":3,"FieldVariant":"json_variant","FieldArray":[4,5],"FieldStringArray":["red","blue"],"FieldDoubleArray":[9.25,10.5],"FieldBoolArray":[false,true],"FieldFixed":[1,2,3],"FieldChild":{"Value":"json_field_child"},"PropText":"P2","PropNumber":31,"PropInt64":2234567890124,"PropByte":43,"PropWord":4343,"PropCardinal":3000000001,"PropDouble":7.75,"PropExtended":8.5,"PropCurrency":9.5,"PropDateTime":45681.5,"PropBoolean":true,"PropChar":"D","PropWideChar":"Z","PropEnum":"rdeTwo","PropSet":5,"PropVariant":123,"PropArray":[7,8],"PropStringArray":["sun","moon"],"PropDoubleArray":[11.25,12.5],"PropBoolArray":[true,false],"PropChild":{"Value":"json_prop_child"}}');
    try
      DemoObj2:=TRttiDemoObject.Create;
      try
        JsonObj.AssignToObject(DemoObj2);
        ExpectEqString('F2', DemoObj2.FieldText, 'AssignToObject() writes field string');
        ExpectEqInt(21, DemoObj2.FieldNumber, 'AssignToObject() writes field int');
        ExpectEqInt(1234567890124, DemoObj2.FieldInt64, 'AssignToObject() writes field int64');
        ExpectEqInt(42, DemoObj2.FieldByte, 'AssignToObject() writes field byte');
        ExpectEqInt(4242, DemoObj2.FieldWord, 'AssignToObject() writes field word');
        ExpectEqInt(3000000000, DemoObj2.FieldCardinal, 'AssignToObject() writes field cardinal');
        ExpectEqFloat(3.5, DemoObj2.FieldSingle, 'AssignToObject() writes field single');
        ExpectEqFloat(4.5, DemoObj2.FieldDouble, 'AssignToObject() writes field double');
        ExpectEqFloat(5.5, DemoObj2.FieldExtended, 'AssignToObject() writes field extended');
        ExpectEqFloat(6.5, DemoObj2.FieldCurrency, 'AssignToObject() writes field currency');
        ExpectEqFloat(45680.5, DemoObj2.FieldDateTime, 'AssignToObject() writes field datetime');
        ExpectEqBool(True, DemoObj2.FieldBoolean, 'AssignToObject() writes field boolean');
        ExpectEqString('C', DemoObj2.FieldChar, 'AssignToObject() writes field char');
        ExpectEqString('Y', DemoObj2.FieldWideChar, 'AssignToObject() writes field widechar');
        Expect(DemoObj2.FieldEnum = rdeOne, 'AssignToObject() writes field enum');
        Expect(DemoObj2.FieldSet = [rdeZero, rdeOne], 'AssignToObject() writes field set');
        ExpectEqString('json_variant', VarToStr(DemoObj2.FieldVariant), 'AssignToObject() writes field variant');
        ExpectEqInt(2, Length(DemoObj2.FieldArray), 'AssignToObject() writes dynamic field array length');
        if Length(DemoObj2.FieldArray) >= 2 then
        begin
          ExpectEqInt(4, DemoObj2.FieldArray[0], 'AssignToObject() writes dynamic field value 0');
          ExpectEqInt(5, DemoObj2.FieldArray[1], 'AssignToObject() writes dynamic field value 1');
        end;
        ExpectEqInt(2, Length(DemoObj2.FieldStringArray), 'AssignToObject() writes string field array length');
        if Length(DemoObj2.FieldStringArray) >= 2 then
          ExpectEqString('blue', DemoObj2.FieldStringArray[1], 'AssignToObject() writes string field array');
        ExpectEqInt(2, Length(DemoObj2.FieldDoubleArray), 'AssignToObject() writes double field array length');
        if Length(DemoObj2.FieldDoubleArray) >= 2 then
          ExpectEqFloat(10.5, DemoObj2.FieldDoubleArray[1], 'AssignToObject() writes double field array');
        ExpectEqInt(2, Length(DemoObj2.FieldBoolArray), 'AssignToObject() writes boolean field array length');
        if Length(DemoObj2.FieldBoolArray) >= 2 then
          ExpectEqBool(True, DemoObj2.FieldBoolArray[1], 'AssignToObject() writes boolean field array');
        Expect(Assigned(DemoObj2.FieldChild), 'AssignToObject() creates field child object');
        if Assigned(DemoObj2.FieldChild) then
          ExpectEqString('json_field_child', DemoObj2.FieldChild.Value, 'AssignToObject() writes nested field object');
        ExpectEqString('P2', DemoObj2.PropText, 'AssignToObject() writes property string');
        ExpectEqInt(31, DemoObj2.PropNumber, 'AssignToObject() writes property int');
        ExpectEqInt(2234567890124, DemoObj2.PropInt64, 'AssignToObject() writes property int64');
        ExpectEqInt(43, DemoObj2.PropByte, 'AssignToObject() writes property byte');
        ExpectEqInt(4343, DemoObj2.PropWord, 'AssignToObject() writes property word');
        ExpectEqInt(3000000001, DemoObj2.PropCardinal, 'AssignToObject() writes property cardinal');
        ExpectEqFloat(7.75, DemoObj2.PropDouble, 'AssignToObject() writes property double');
        ExpectEqFloat(8.5, DemoObj2.PropExtended, 'AssignToObject() writes property extended');
        ExpectEqFloat(9.5, DemoObj2.PropCurrency, 'AssignToObject() writes property currency');
        ExpectEqFloat(45681.5, DemoObj2.PropDateTime, 'AssignToObject() writes property datetime');
        ExpectEqBool(True, DemoObj2.PropBoolean, 'AssignToObject() writes property boolean');
        ExpectEqString('D', DemoObj2.PropChar, 'AssignToObject() writes property char');
        ExpectEqString('Z', DemoObj2.PropWideChar, 'AssignToObject() writes property widechar');
        Expect(DemoObj2.PropEnum = rdeTwo, 'AssignToObject() writes property enum from string');
        Expect(DemoObj2.PropSet = [rdeZero, rdeTwo], 'AssignToObject() writes property set');
        ExpectEqString('123', VarToStr(DemoObj2.PropVariant), 'AssignToObject() writes property variant');
        ExpectEqInt(2, Length(DemoObj2.PropArray), 'AssignToObject() writes dynamic property array length');
        if Length(DemoObj2.PropArray) >= 2 then
          ExpectEqInt(8, DemoObj2.PropArray[1], 'AssignToObject() writes property value');
        ExpectEqInt(2, Length(DemoObj2.PropStringArray), 'AssignToObject() writes string property array length');
        if Length(DemoObj2.PropStringArray) >= 2 then
          ExpectEqString('moon', DemoObj2.PropStringArray[1], 'AssignToObject() writes string property array');
        ExpectEqInt(2, Length(DemoObj2.PropDoubleArray), 'AssignToObject() writes double property array length');
        if Length(DemoObj2.PropDoubleArray) >= 2 then
          ExpectEqFloat(12.5, DemoObj2.PropDoubleArray[1], 'AssignToObject() writes double property array');
        ExpectEqInt(2, Length(DemoObj2.PropBoolArray), 'AssignToObject() writes boolean property array length');
        if Length(DemoObj2.PropBoolArray) >= 2 then
          ExpectEqBool(False, DemoObj2.PropBoolArray[1], 'AssignToObject() writes boolean property array');
        Expect(Assigned(DemoObj2.PropChild), 'AssignToObject() creates property child object');
        if Assigned(DemoObj2.PropChild) then
          ExpectEqString('json_prop_child', DemoObj2.PropChild.Value, 'AssignToObject() writes nested property object');
      finally
        DemoObj2.Free;
      end;
    finally
      JsonObj.Free;
    end;

    FillArray(SourceRec.RecArray, 9, 9, 9);
    SourceRec.RecStringArray:=TArray<String>.Create('record_one', 'record_two');
    SourceRec.RecDoubleArray:=TArray<Double>.Create(13.25, 14.5);
    SourceRec.RecBoolArray:=TArray<Boolean>.Create(True, False);
    SourceRec.RecText:='record';
    SourceRec.RecNumber:=42;
    SourceRec.RecInt64:=3234567890123;
    SourceRec.RecByte:=44;
    SourceRec.RecWord:=4444;
    SourceRec.RecCardinal:=3000000002;
    SourceRec.RecDouble:=12.5;
    SourceRec.RecExtended:=13.5;
    SourceRec.RecCurrency:=14.75;
    SourceRec.RecDateTime:=45682.5;
    SourceRec.RecBoolean:=True;
    SourceRec.RecChar:='E';
    SourceRec.RecWideChar:='Q';
    SourceRec.RecEnum:=rdeOne;
    SourceRec.RecSet:=[rdeZero, rdeTwo];
    SourceRec.RecVariant:='variant_record';
    SourceRec.RecFixed[0]:=100;
    SourceRec.RecFixed[1]:=200;
    SourceRec.RecFixed[2]:=300;

    RecJSON:=TJSON.CreateFromRecord<TRttiDemoRecord>(SourceRec);
    try
      Expect(RecJSON.IsObject, 'CreateFromRecord() with JSON_USE_RTTI');
      ExpectEqString('record', RecJSON.AsObject['RecText'].AsString, 'Record to JSON string field');
      ExpectEqInt(42, RecJSON.AsObject['RecNumber'].AsInteger, 'Record to JSON int field');
      ExpectEqInt(3234567890123, RecJSON.AsObject['RecInt64'].AsInteger, 'Record to JSON int64 field');
      ExpectEqInt(44, RecJSON.AsObject['RecByte'].AsInteger, 'Record to JSON byte field');
      ExpectEqInt(4444, RecJSON.AsObject['RecWord'].AsInteger, 'Record to JSON word field');
      ExpectEqInt(3000000002, RecJSON.AsObject['RecCardinal'].AsInteger, 'Record to JSON cardinal field');
      ExpectEqFloat(12.5, RecJSON.AsObject['RecDouble'].AsFloat, 'Record to JSON double field');
      ExpectEqFloat(13.5, RecJSON.AsObject['RecExtended'].AsFloat, 'Record to JSON extended field');
      ExpectEqFloat(14.75, RecJSON.AsObject['RecCurrency'].AsFloat, 'Record to JSON currency field');
      ExpectEqFloat(45682.5, RecJSON.AsObject['RecDateTime'].AsFloat, 'Record to JSON datetime field');
      ExpectEqBool(True, RecJSON.AsObject['RecBoolean'].AsBoolean, 'Record to JSON boolean field');
      ExpectEqString('E', RecJSON.AsObject['RecChar'].AsString, 'Record to JSON char field');
      ExpectEqString('Q', RecJSON.AsObject['RecWideChar'].AsString, 'Record to JSON widechar field');
      ExpectEqInt(Ord(rdeOne), RecJSON.AsObject['RecEnum'].AsInteger, 'Record to JSON enum field');
      ExpectEqInt(5, RecJSON.AsObject['RecSet'].AsInteger, 'Record to JSON set field');
      ExpectEqString('variant_record', RecJSON.AsObject['RecVariant'].AsString, 'Record to JSON variant field');
      ExpectEqInt(3, RecJSON.AsObject['RecArray'].AsArray.Count, 'Record to JSON array length');
      ExpectEqString('record_two', RecJSON.AsObject['RecStringArray'].AsArray[1].AsString, 'Record to JSON string array');
      ExpectEqFloat(14.5, RecJSON.AsObject['RecDoubleArray'].AsArray[1].AsFloat, 'Record to JSON double array');
      ExpectEqBool(False, RecJSON.AsObject['RecBoolArray'].AsArray[1].AsBoolean, 'Record to JSON boolean array');
      ExpectEqInt(3, RecJSON.AsObject['RecFixed'].AsArray.Count, 'Record to JSON fixed array length');
      ExpectEqInt(200, RecJSON.AsObject['RecFixed'].AsArray[1].AsInteger, 'Record to JSON fixed array value');
    finally
      RecJSON.Free;
    end;

    RecJSON:=TJSON.CreateFromString('{"RecText":"r2","RecNumber":77,"RecInt64":4234567890123,"RecByte":45,"RecWord":4545,"RecCardinal":3000000003,"RecDouble":18.75,"RecExtended":19.5,"RecCurrency":20.25,"RecDateTime":45683.5,"RecBoolean":true,"RecChar":"F","RecWideChar":"R","RecEnum":"rdeTwo","RecSet":6,"RecVariant":456,"RecArray":[1,2,3],"RecStringArray":["north","south"],"RecDoubleArray":[21.25,22.5],"RecBoolArray":[false,true],"RecFixed":[8,9,10]}');
    try
      DestRec:=Default(TRttiDemoRecord);
      for I:=Low(DestRec.RecFixed) to High(DestRec.RecFixed) do
        DestRec.RecFixed[I]:=0;

      RecJSON.AssignToRecord<TRttiDemoRecord>(DestRec);
      ExpectEqString('r2', DestRec.RecText, 'AssignToRecord() writes string');
      ExpectEqInt(77, DestRec.RecNumber, 'AssignToRecord() writes int');
      ExpectEqInt(4234567890123, DestRec.RecInt64, 'AssignToRecord() writes int64');
      ExpectEqInt(45, DestRec.RecByte, 'AssignToRecord() writes byte');
      ExpectEqInt(4545, DestRec.RecWord, 'AssignToRecord() writes word');
      ExpectEqInt(3000000003, DestRec.RecCardinal, 'AssignToRecord() writes cardinal');
      ExpectEqFloat(18.75, DestRec.RecDouble, 'AssignToRecord() writes double');
      ExpectEqFloat(19.5, DestRec.RecExtended, 'AssignToRecord() writes extended');
      ExpectEqFloat(20.25, DestRec.RecCurrency, 'AssignToRecord() writes currency');
      ExpectEqFloat(45683.5, DestRec.RecDateTime, 'AssignToRecord() writes datetime');
      ExpectEqBool(True, DestRec.RecBoolean, 'AssignToRecord() writes boolean');
      ExpectEqString('F', DestRec.RecChar, 'AssignToRecord() writes char');
      ExpectEqString('R', DestRec.RecWideChar, 'AssignToRecord() writes widechar');
      Expect(DestRec.RecEnum = rdeTwo, 'AssignToRecord() writes enum from string');
      Expect(DestRec.RecSet = [rdeOne, rdeTwo], 'AssignToRecord() writes set');
      ExpectEqString('456', VarToStr(DestRec.RecVariant), 'AssignToRecord() writes variant');
      ExpectEqInt(3, Length(DestRec.RecArray), 'AssignToRecord() writes dynamic array length');
      if Length(DestRec.RecArray) >= 3 then
      begin
        ExpectEqInt(1, DestRec.RecArray[0], 'AssignToRecord() writes array value 0');
        ExpectEqInt(3, DestRec.RecArray[2], 'AssignToRecord() writes array value 2');
      end;
      ExpectEqInt(2, Length(DestRec.RecStringArray), 'AssignToRecord() writes string array length');
      if Length(DestRec.RecStringArray) >= 2 then
        ExpectEqString('south', DestRec.RecStringArray[1], 'AssignToRecord() writes string array');
      ExpectEqInt(2, Length(DestRec.RecDoubleArray), 'AssignToRecord() writes double array length');
      if Length(DestRec.RecDoubleArray) >= 2 then
        ExpectEqFloat(22.5, DestRec.RecDoubleArray[1], 'AssignToRecord() writes double array');
      ExpectEqInt(2, Length(DestRec.RecBoolArray), 'AssignToRecord() writes boolean array length');
      if Length(DestRec.RecBoolArray) >= 2 then
        ExpectEqBool(True, DestRec.RecBoolArray[1], 'AssignToRecord() writes boolean array');
      ExpectEqInt(8, DestRec.RecFixed[0], 'AssignToRecord() writes fixed value 0');
      ExpectEqInt(10, DestRec.RecFixed[2], 'AssignToRecord() writes fixed value 2');
    finally
      RecJSON.Free;
    end;
  finally
    TJSON.SerializerRules:=SavedRules;
    DemoObj.Free;
  end;
end;
{$ENDIF}

begin
  try
    TestBasicConstructorsAndPrimitives;
    TestReadWriteAndPath;
    TestObjectLifecycle;
    TestObjectOperations;
    TestMerge;
    TestArrayOperations;
    TestTemplateEngine;
    TestJsonGetValue;
    TestMutabilityAndCopy;
    {$IFDEF JSON_USE_RTTI}
    TestRTTIFeatures;
    {$ENDIF}

    Writeln('---------------------------------------------');
    Writeln('Checks: ', TotalChecks);
    Writeln('Passed: ', PassedChecks);
    Writeln('Failed: ', FailedChecks);

    if FailedChecks <> 0 then
    begin
      Writeln('Result: FAILED');
      ExitCode:=1;
    end else
      Writeln('Result: PASSED');
  except
    on E: Exception do
    begin
      Writeln('[EXCEPTION] ', E.ClassName, ': ', E.Message);
      ExitCode:=2;
    end;
  end;
end.
