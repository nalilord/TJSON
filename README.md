# TJSON

A lightweight Delphi JSON / JSON5 parser and writer with an object model, templates, path lookup, merge support, and optional RTTI-based object/record serialization.

## Features

- Parse and write JSON object and array roots.
- Read JSON5 input, including comments, single quoted strings, unquoted keys, hex escapes, multiline string continuations, `Infinity`, `-Infinity`, and `NaN`.
- Write readable or condensed/minified JSON.
- UTF-8 stream/file output.
- Escape strings for JSON output with `TJSON.EncodeString`.
- Object model with `TJSONObject`, `TJSONArray`, and typed value classes.
- Duplicate object keys are rejected.
- Dotted path lookup with object keys and array indexes.
- Deep object merge support.
- Template system for repeated object generation.
- Optional RTTI conversion for Delphi objects and records with `JSON_USE_RTTI`.
- Configurable RTTI enum serialization rules through `TJSON.SerializerRules`.
- Console test runner covering parser, writer, templates, JSON5, and RTTI conversion.

## Basic usage

```delphi
var
  JSON: TJSON;
begin
  JSON := TJSON.CreateObjectRoot;
  try
    JSON.AsObject.Add('name', 'TJSON');
    JSON.AsObject.Add('version', 109);
    JSON.AsObject.Add('active', True);
    JSON.AsObject.AddObject('meta').Add('format', 'json');
    JSON.AsObject.AddArray('items').Add(42);

    JSON.SaveToFile('data.json');
  finally
    JSON.Free;
  end;
end;
```

## Reading values

```delphi
var
  JSON: TJSON;
  Name: String;
  Count: Int64;
begin
  JSON := TJSON.CreateFromFile('data.json');
  try
    if JSON.IsObject then
    begin
      Name := JSON.AsObject.GetOrAdd('name', 'unknown');
      Count := JSON.AsObject.GetOrAdd('count', 0);
    end;
  finally
    JSON.Free;
  end;
end;
```

## Path lookup

`Path` supports dotted object keys and numeric array indexes.

```delphi
var
  JSON: TJSON;
  Value: TJSONValue;
begin
  JSON := TJSON.CreateFromString('{"user":{"scores":[10,20,30]}}');
  try
    Value := JSON.Path('user.scores.1');
    // Value.AsInteger = 20
  finally
    JSON.Free;
  end;
end;
```

## JSON5 input

Use `jeJSON5` when reading JSON5-style documents.

```delphi
var
  JSON: TJSON;
begin
  JSON := TJSON.CreateFromString(
    '{ name: ''demo'', nums: [1, 2, 3], /* comment */ enabled: true }',
    jeJSON5
  );
  try
    // JSON.AsObject['name'].AsString = 'demo'
  finally
    JSON.Free;
  end;
end;
```

## Condensed output

```delphi
var
  Text: String;
begin
  Text := JSON.WriteToString(jswmCondensed);
end;
```

`TJSONObject.ToString` and `TJSONArray.ToString` also return condensed JSON.

## Merge objects

`TJSONObject.Merge` recursively merges object values. Non-object source values replace destination values.

```delphi
var
  LeftJSON, RightJSON: TJSON;
begin
  LeftJSON := TJSON.CreateFromString('{"a":1,"nested":{"x":1}}');
  RightJSON := TJSON.CreateFromString('{"b":2,"nested":{"y":2}}');
  try
    LeftJSON.AsObject.Merge(RightJSON.AsObject);
    // {"a":1,"nested":{"x":1,"y":2},"b":2}
  finally
    RightJSON.Free;
    LeftJSON.Free;
  end;
end;
```

## Templates

Templates are useful for repeated object generation with defaults and auto-filled values.

```delphi
initialization
  TJSON.CreateTemplate('status')
    .Add('time', jttUnixTime)
    .Add('code', jttInteger).Default(TJSONInteger.CreateFrom(200))
    .Add('message', jttString)
    .Add('payload', jttObject)
    .SetFlag(tfOmitEmpty);
```

```delphi
var
  Tpl: TJSONTemplate;
  JsonStr: String;
begin
  Tpl := TJSON.Template('status');
  Tpl.Empty;
  Tpl.SetValue('message', 'Hello World');
  JsonStr := Tpl.JSON.WriteToString;
end;
```

Template field types include normal JSON types plus `jttName`, `jttUnixTime`, nested templates, and callbacks.

## RTTI object and record conversion

RTTI conversion is opt-in. Define `JSON_USE_RTTI` in your project to enable:

- `TJSON.CreateFromObject`
- `TJSON.CreateFromRecord<T>`
- `TJSON.LoadFromObject`
- `TJSON.AssignToObject`
- `TJSON.AssignToRecord<T>`

```delphi
{$DEFINE JSON_USE_RTTI}
```

Example:

```delphi
type
  TPlayer = class
  public
    Name: String;
    Level: Integer;
    Tags: TArray<String>;
  end;

var
  Player, Copy: TPlayer;
  JSON: TJSON;
begin
  Player := TPlayer.Create;
  Copy := TPlayer.Create;
  try
    Player.Name := 'Ada';
    Player.Level := 12;
    Player.Tags := TArray<String>.Create('mage', 'debugger');

    JSON := TJSON.CreateFromObject(Player);
    try
      JSON.AssignToObject(Copy);
    finally
      JSON.Free;
    end;
  finally
    Copy.Free;
    Player.Free;
  end;
end;
```

### RTTI-supported data types

The test suite covers RTTI serialization/deserialization for:

- strings
- signed and unsigned ordinal values such as `Integer`, `Int64`, `Byte`, `Word`, and `Cardinal`
- `Single`, `Double`, `Extended`, `Currency`, and `TDateTime`
- booleans
- `Char` and `WideChar`
- enums
- sets
- variants
- fixed arrays
- dynamic arrays of integers, strings, floats, and booleans
- nested class/object fields and properties
- records and classes

RTTI conversion uses public/published accessible fields and readable/writable properties where applicable.

## Serializer rules

`TJSON.SerializerRules` controls RTTI serialization policy. Defaults are backward-compatible:

- enums write as ordinal integers
- enum reads accept ordinal values
- enum reads accept raw Delphi enum names

Use `TJSON.DefaultSerializerRules` as a starting point.

```delphi
var
  Rules: TJSONSerializerRules;
begin
  Rules := TJSON.DefaultSerializerRules;
  Rules.EnumMode := jemName;
  Rules.EnumStripPrefixes := TArray<String>.Create('cl');
  Rules.EnumNameCase := jncSnake;

  TJSON.SerializerRules := Rules;
end;
```

With those rules:

```delphi
clDarkRed -> "dark_red"
```

Available enum name cases:

- `jncPreserve`
- `jncLower`
- `jncUpper`
- `jncPascal`
- `jncCamel`
- `jncSnake`
- `jncScreamingSnake`

Useful examples:

```delphi
Rules.EnumStripPrefixes := TArray<String>.Create('rde');
Rules.EnumNameCase := jncSnake;
// rdeDarkRed -> "dark_red"

Rules.EnumNameCase := jncScreamingSnake;
// rdeDarkRed -> "DARK_RED"
```

Enum read behavior can also be configured:

```delphi
Rules.EnumAcceptOrdinalOnRead := True;
Rules.EnumAcceptRawNameOnRead := True;
Rules.EnumUnknownRead := jurIgnore; // jurIgnore, jurDefaultFirst, jurRaise
```

## License

GPL v3.0
