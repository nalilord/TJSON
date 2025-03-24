# TJSON
A Json Parser for Delphi

- Object Model
- Json minified/condensed write Support
- Template system for easy and repeated record generation
- Json5 read Support

### Create an empty JSON, fill it with values and save to file
```delphi
var
  JSON: TJSON;
begin
  JSON:=TJSON.CreateObjectRoot;
  try
    with JSON.AsObject do
    begin
      Add('string', 'yes');
      Add('integer', 1234);
      Add('float', 12.34);
      Add('bool', True);
      AddObject('object').Add('anotherString', 'cool!');
      AddArray('arr').Add(1337);
    end;
    JSON.SaveToFile('data.json');
  finally
    JSON.Free;
  end;
end;
```

### Load a JSON file and it's values into variables
```delphi
var
  JSON: TJSON;
  MyStr: String;
  MyInt: Int64;
  MyFloat: Extended;
  MyBool: Boolean;
  MyObj: TJSONObject;
  MyArr: TJSONArray;
begin
  JSON:=TJSON.CreateFromFile('data.json');
  try
    if JSON.IsObject then
    begin
      with JSON.AsObject do
      begin
        MyStr:=GetOrAdd('string', 'yes');
        MyInt:=GetOrAdd('integer', 1234);
        MyFloat:=GetOrAdd('float', 12.34);
        MyBool:=GetOrAdd('bool', True);
        MyObj:=GetOrAddObject('obj');
        MyArr:=GetOrAddArray('arr');
      end;
    end;
  finally
    JSON.Free;
  end;
end;
```

### Create a template for later use
```delphi
initialization
  TJSON.CreateTemplate('status')                                    // Create a template with the name status
    .Add('time', jttUnixTime)                                       // Add an auto fill filed with the name time, the value will be set on "Empty" or "Fill" calls
    .Add('code', jttInteger).Default(TJSONInteger.CreateFrom(200))  // Add a code filed with a default value of 200
    .Add('message', jttString)                                      // Add a message field of string type
    .Add('payload', jttObject)                                      // Add a payload field of object type
    .SetFlag(tfOmitEmpty);                                          // Set the flag that all fields will be omited that have no user value set
```

### Fill template data and write it to a string
```delphi
  var
    Tpl: TJSONTemplate;
    JsonStr: String;
  begin
    Tpl:=TJSON.Template('status');                         // Get the template named status
    Tpl.Empty;                                             // Resets and clears the template to all default values
    Tpl.SetValue('message', 'Hello World from Template');  // Set the message key
    JsonStr:=Tpl.JSON.WriteToString;                       // Write the current template to a string
  end;
```
