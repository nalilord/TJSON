(******************************************************************************)
(*                                                                            *)
(*  Delphi JSON Parser Class                                                  *)
(*                                                                            *)
(*  Version     : 1.07 (2025-03-24)                                           *)
(*  License     : GPL v3.0                                                    *)
(*  Author      : NaliLord / DMA (Daniel M.)                                  *)
(*                                                                            *)
(*  Copyright (c) 2025                                                        *)
(*                                                                            *)
(*  History:                                                                  *)
(*  ========================================================================  *)
(*                                                                            *)
(*  - 1.07 [2025-03-24] DMA: Updated the Template System                      *)
(*    Renamed "Default" to "Empty"                                            *)
(*    Added "Default" to set template default values                          *)
(*                                                                            *)
(*    *Note* "Default" references the last added field                        *)
(*                                                                            *)
(*  - 1.06 [2025-02-19] DMA: Updated the Template System                      *)
(*    Added that template names can be used as a string value                 *)
(*    Added that templates can now be used nested by name                     *)
(*    Added new template flags to omit empty keys                             *)
(*    Changed that template "Fill" now supports nil and "TJSONObject"         *)
(*    Added "AssignTo" functionality to "TJSONValue"                          *)
(*    Added "ToString" functionality for "TJSONObject"                        *)
(*    Added "ToString" functionality for "TJSONArray"                         *)
(*                                                                            *)
(*    *Note* "ToString" will output a write mode condensed JSON string        *)
(*    *Note* Template name values must be ignored in "Fill" when using them   *)
(*                                                                            *)
(*  - 1.05 [2024-04-20] DMA: Parser now supports JSON5 files for reading      *)
(*                                                                            *)
(*  - 1.04 [2018-08-29] DMA: Parser now stops after string termination        *)
(*                                                                            *)
(*  - 1.03 [2016-11-23] DMA: Added support for parsing empty objects          *)
(*                           Added "IsEmpty" to check for empty values        *)
(*                                                                            *)
(*  - 1.02 [2016-07-13] DMA: Added "AddOrSet" to TJSONObject                  *)
(*                           Added "GetOrAddObject" to TJSONObject            *)
(*                                                                            *)
(*  - 1.01 [2015-10-08] DMA: Added "CreateFromFile" to TJSON                  *)
(*                                                                            *)
(*  - 1.00 [2014-04-30] DMA: Initial Version                                  *)
(*                                                                            *)
(******************************************************************************)

unit XENOME.JSON;

{$WARN DUPLICATE_CTOR_DTOR OFF} // <- fuck diz shit, does not help at all... disable the warning in project options to supress it or copy this to the .dpr!

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Registry, IniFiles, SyncObjs, Contnrs, System.Rtti;

type
  TJSONType = (jtNull, jtInteger, jtFloat, jtString, jtBoolean, jtObject, jtArray);
  TJSONTemplateType = (jttNull, jttInteger, jttFloat, jttString, jttBoolean, jttObject, jttArray, jttName, jttUnixTime, jttTemplate, jttCallback);
  TJSONTemplateFlag = (tfOmitEmpty);
  TJSONStringWriteMode = (jswmReadable, jswmCondensed);
  TJSONExtension = (jeDefault, jeJSON5);

  TJSONTemplateFlags = set of TJSONTemplateFlag;


  TJSONTemplate = class;
  TJSON = class;
  TJSONValue = class;
  TJSONNull = class;
  TJSONString = class;
  TJSONInteger = class;
  TJSONFloat = class;
  TJSONBoolean = class;
  TJSONObject = class;
  TJSONArray = class;

  TJSONClass = class of TJSONValue;

  TJSONTemplateFillCallback = procedure(ATemplateName, AKeyName: String; var AValue: TJSONValue) of object;

  EJSONException = class(Exception)
  private
    FMessage: String;
  public
    constructor Create(AMessage: String; ALine, ACol: Integer);
    property Message: String read FMessage;
  end;

  TJSONTemplateField = record
    Name: String;
    Typ: TJSONTemplateType;
    Nested: TJSONTemplate;
    Default: TJSONValue;
    Callback: TJSONTemplateFillCallback;
  end;

  TJSONTemplate = class(TPersistent)
  private
    FName: String;
    FFlags: TJSONTemplateFlags;
    FJSON: TJSON;
    FCritSec: TCriticalSection;
    FValues: Array of TJSONTemplateField;
    FLastAdded: Integer;
    FOnTemplateFillCallback: TJSONTemplateFillCallback;
  protected
    function GetTemplateFieldCount: Integer;
    function Add(AName: String; AType: TJSONTemplateType; ATemplate: TJSONTemplate; ACallback: TJSONTemplateFillCallback): TJSONTemplate; overload;
    procedure Cleanup;
    procedure DoTemplateFillCallback(ATemplateName, AKeyName: String; var AValue: TJSONValue);
  public
    constructor Create(AName: String);
    destructor Destroy; override;
    procedure Clear;
    function SetFlag(AFlag: TJSONTemplateFlag): TJSONTemplate;
    function SetFlags(AFlags: TJSONTemplateFlags): TJSONTemplate;
    function SetValue(AName: String; const AValue: Variant): Boolean;
    function Add(AName: String; AType: TJSONType): TJSONTemplate; overload;
    function Add(AName: String; AType: TJSONTemplateType): TJSONTemplate; overload;
    function Add(AName: String; ATemplate: TJSONTemplate): TJSONTemplate; overload;
    function Add(AName: String; ATemplateName: String): TJSONTemplate; overload;
    function Add(AName: String; ACallback: TJSONTemplateFillCallback): TJSONTemplate; overload;
    function Add(AField: TJSONTemplateField): TJSONTemplate; overload;
    function Default(AValue: TJSONValue): TJSONTemplate; overload;
    function Empty(AUseDefaults: Boolean = True): TJSON;
    function Fill(AValues: Array of const): TJSON;
    property Name: String read FName;
    property Flags: TJSONTemplateFlags read FFlags write FFlags;
    property JSON: TJSON read FJSON;
    property OnTemplateFillCallback: TJSONTemplateFillCallback read FOnTemplateFillCallback write FOnTemplateFillCallback;
  end;

  TJSON = class(TPersistent)
  private
    FExtension: TJSONExtension;
    FCritSec: TCriticalSection;
    FData: TStringStream;
    FRoot: TJSONValue;
    function GetIsObject: Boolean;
    function GetIsArray: Boolean;
    function GetAsArray: TJSONArray;
    function GetAsObject: TJSONObject;
    function GetObjectValue(Key: String): TJSONValue;
    function GetArrayValue(Index: Integer): TJSONValue;
  protected
    procedure Parse;
  public
    class function EncodeString(AString: String): String;
    class function CreateTemplate(AName: String): TJSONTemplate;
    class function Template(AName: String): TJSONTemplate;
    constructor Create;
    constructor CreateArrayRoot;
    constructor CreateObjectRoot;
    constructor CreateFromString(AJSON: String; AExtension: TJSONExtension = jeDefault);
    constructor CreateFromFile(AFile: String; AExtension: TJSONExtension = jeDefault);
    constructor CreateFromStream(AStream: TStream; AExtension: TJSONExtension = jeDefault);
    destructor Destroy; override;
    function IsEmpty: Boolean; virtual;
    function WriteToString(AWriteMode: TJSONStringWriteMode = jswmReadable): String; virtual;
    function WriteToFile(const AFileName: String; AWriteMode: TJSONStringWriteMode = jswmReadable): String; virtual;
    function RootNewArray: TJSONArray;
    function RootNewObject: TJSONObject;
    procedure Assign(ASource: TPersistent); override;
    procedure Clear; virtual;
    procedure LoadFromFile(const AFileName: String); virtual;
    procedure LoadFromStream(AStream: TStream); virtual;
    procedure ReadFromString(const AValue: String); virtual;
    procedure SaveToFile(const AFileName: String); virtual;
    procedure SaveToStream(AStream: TStream); virtual;
    property Parser: TJSONExtension                 read FExtension      write FExtension;
    property ObjectValue[Key: String]: TJSONValue   read GetObjectValue; default;
    property ArrayValue[Index: Integer]: TJSONValue read GetArrayValue;
    property Root: TJSONValue                       read FRoot;
    property IsObject: Boolean                      read GetIsObject;
    property IsArray: Boolean                       read GetIsArray;
    property AsObject: TJSONObject                  read GetAsObject;
    property AsArray: TJSONArray                    read GetAsArray;
  end;

  TJSONValue = class(TPersistent)
  private
    function GetIsArray: Boolean;
    function GetIsBoolean: Boolean;
    function GetIsFloat: Boolean;
    function GetIsInteger: Boolean;
    function GetIsNull: Boolean;
    function GetIsObject: Boolean;
    function GetIsString: Boolean;
    function GetTyp: TJSONType;
  protected
    function GetClass: TJSONClass; virtual;
    function GetAsValue: TValue; virtual;
    function GetAsArray: TJSONArray; virtual; abstract;
    function GetAsBoolean: Boolean; virtual; abstract;
    function GetAsFloat: Extended; virtual; abstract;
    function GetAsInteger: Int64; virtual; abstract;
    function GetAsObject: TJSONObject; virtual; abstract;
    function GetAsString: String; virtual; abstract;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; virtual;
    function IsEmpty: Boolean; virtual; abstract;
    function Copy: TJSONValue; virtual;
    property Typ: TJSONType        read GetTyp;
    property IsNull: Boolean       read GetIsNull;
    property IsString: Boolean     read GetIsString;
    property IsInteger: Boolean    read GetIsInteger;
    property IsFloat: Boolean      read GetIsFloat;
    property IsBoolean: Boolean    read GetIsBoolean;
    property IsObject: Boolean     read GetIsObject;
    property IsArray: Boolean      read GetIsArray;
    property AsString: String      read GetAsString;
    property AsInteger: Int64      read GetAsInteger;
    property AsFloat: Extended     read GetAsFloat;
    property AsBoolean: Boolean    read GetAsBoolean;
    property AsObject: TJSONObject read GetAsObject;
    property AsArray: TJSONArray   read GetAsArray;
  end;

  TJSONNull = class(TJSONValue)
  protected
    function GetClass: TJSONClass; override;
    function GetAsArray: TJSONArray; override;
    function GetAsBoolean: Boolean; override;
    function GetAsFloat: Extended; override;
    function GetAsInteger: Int64; override;
    function GetAsObject: TJSONObject; override;
    function GetAsString: String; override;
  public
    constructor Create; override;
    function IsEmpty: Boolean; override;
  end;

  TJSONString = class(TJSONValue)
  private
    FValue: String;
  protected
    function GetClass: TJSONClass; override;
    function GetAsValue: TValue; override;
    function GetAsArray: TJSONArray; override;
    function GetAsBoolean: Boolean; override;
    function GetAsFloat: Extended; override;
    function GetAsInteger: Int64; override;
    function GetAsObject: TJSONObject; override;
    function GetAsString: String; override;
  public
    constructor Create; override;
    constructor CreateFrom(AValue: String);
    function IsEmpty: Boolean; override;
  end;

  TJSONInteger = class(TJSONValue)
  private
    FValue: Int64;
  protected
    function GetClass: TJSONClass; override;
    function GetAsValue: TValue; override;
    function GetAsArray: TJSONArray; override;
    function GetAsBoolean: Boolean; override;
    function GetAsFloat: Extended; override;
    function GetAsInteger: Int64; override;
    function GetAsObject: TJSONObject; override;
    function GetAsString: String; override;
  public
    constructor Create; override;
    constructor CreateFrom(AValue: Int64);
    function IsEmpty: Boolean; override;
  end;

  TJSONFloat = class(TJSONValue)
  private
    FValue: Extended;
  protected
    function GetClass: TJSONClass; override;
    function GetAsValue: TValue; override;
    function GetAsArray: TJSONArray; override;
    function GetAsBoolean: Boolean; override;
    function GetAsFloat: Extended; override;
    function GetAsInteger: Int64; override;
    function GetAsObject: TJSONObject; override;
    function GetAsString: String; override;
  public
    constructor Create; override;
    constructor CreateFrom(AValue: Extended);
    function IsEmpty: Boolean; override;
  end;

  TJSONBoolean = class(TJSONValue)
  private
    FValue: Boolean;
  protected
    function GetClass: TJSONClass; override;
    function GetAsValue: TValue; override;
    function GetAsArray: TJSONArray; override;
    function GetAsBoolean: Boolean; override;
    function GetAsFloat: Extended; override;
    function GetAsInteger: Int64; override;
    function GetAsObject: TJSONObject; override;
    function GetAsString: String; override;
   public
    constructor Create; override;
    constructor CreateFrom(AValue: Boolean);
    function IsEmpty: Boolean; override;
  end;

  TJSONObject = class(TJSONValue)
  private
    FKeys: THashedStringList;
    function GetValue(Key: String): TJSONValue;
    function GetCount: Integer;
    function GetItem(Index: Integer): TJSONValue;
    function GetName(Index: Integer): String;
  protected
    function GetClass: TJSONClass; override;
    function GetAsArray: TJSONArray; override;
    function GetAsBoolean: Boolean; override;
    function GetAsFloat: Extended; override;
    function GetAsInteger: Int64; override;
    function GetAsObject: TJSONObject; override;
    function GetAsString: String; override;
  public
    constructor Create; override;
    constructor CreateFrom(AObject: TJSONObject);
    destructor Destroy; override;
    function ToString: String; override;
    procedure Clear;
    procedure Delete(AKey: String);
    function IsEmpty: Boolean; override;
    function HasKey(AKey: String): Boolean;
    procedure Add(AKey: String); overload;
    procedure Add(AKey: String; AValue: String); overload;
    procedure Add(AKey: String; AValue: Int64); overload;
    procedure Add(AKey: String; AValue: Extended); overload;
    procedure Add(AKey: String; AValue: Boolean); overload;
    procedure Add(AKey: String; AValue: TJSONValue); overload;
    procedure SetOrAdd(AKey: String; AValue: String); overload;
    procedure SetOrAdd(AKey: String; AValue: Int64); overload;
    procedure SetOrAdd(AKey: String; AValue: Extended); overload;
    procedure SetOrAdd(AKey: String; AValue: Boolean); overload;
    procedure SetOrAdd(AKey: String; AValue: TJSONValue); overload;
    procedure AddObject(AKey: String; AObject: TJSONObject); overload;
    procedure AddArray(AKey: String; AArray: TJSONArray); overload;
    function AddObject(AKey: String): TJSONObject; overload;
    function AddArray(AKey: String): TJSONArray; overload;
    function GetOrAdd(AKey: String; ADefault: String): String; overload;
    function GetOrAdd(AKey: String; ADefault: Int64): Int64; overload;
    function GetOrAdd(AKey: String; ADefault: Extended): Extended; overload;
    function GetOrAdd(AKey: String; ADefault: Boolean): Boolean; overload;
    function GetOrAddObject(AKey: String): TJSONObject;
    function GetOrAddArray(AKey: String): TJSONArray; overload;
    function GetOrAddArray<T>(AKey: String; ADefault: TArray<T>): TArray<T>; overload;
    property Count: Integer                   read GetCount;
    property Value[Key: String]: TJSONValue   read GetValue; default;
    property Item[Index: Integer]: TJSONValue read GetItem;
    property Name[Index: Integer]: String     read GetName;
  end;

  TJSONArray = class(TJSONValue)
  private
    FValues: TList;
    function GetItem(Index: Integer): TJSONValue;
    function GetCount: Integer;
  protected
    function GetClass: TJSONClass; override;
    function GetAsArray: TJSONArray; override;
    function GetAsBoolean: Boolean; override;
    function GetAsFloat: Extended; override;
    function GetAsInteger: Int64; override;
    function GetAsObject: TJSONObject; override;
    function GetAsString: String; override;
    procedure Add(AValue: TJSONValue); overload;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Clear;
    procedure Add; overload;
    procedure Add(AValue: String); overload;
    procedure Add(AValue: Int64); overload;
    procedure Add(AValue: Extended); overload;
    procedure Add(AValue: Boolean); overload;
    procedure AddObject(AObject: TJSONObject); overload;
    procedure AddArray(AArray: TJSONArray); overload;
    procedure Delete(AIndex: Integer);
    procedure Insert(AIndex: Integer; AValue: TJSONValue);
    procedure Move(ACurIndex, ANewIndex: Integer);
    procedure Exchange(AIndex1, AIndex2: Integer);
    procedure Replace(AIndex: Integer; AValue: TJSONValue);
    function IsEmpty: Boolean; override;
    function AddObject: TJSONObject; overload;
    function AddObject(AKey: String; AValue: TJSONValue): TJSONObject; overload;
    function AddArray: TJSONArray; overload;
    property Count: Integer                   read GetCount;
    property Item[Index: Integer]: TJSONValue read GetItem; default;
  end;

function JsonGetValue(const AName: String; const ADefault: String; const AJSON: String): String;

implementation

uses
  System.Math, System.DateUtils, System.StrUtils, System.TypInfo;

{ Global }

resourcestring
  RCS_JSON_PARSER_EXCEPTION     = 'JSON Parser Exception at Line: %d Col: %d';
  RCS_INVALID_IDENTIFIER        = 'Invalid identifier found. Expected: true, false or null!';
  RCS_INVALID_CHARACTER         = 'Invalid or unexpected character found! (%s)';
  RCS_INVALID_NUMERIC_VALUE     = 'Invalid numeric value!';
  RCS_INVALID_JSON              = 'Invalid or malformed JSON data!';
  RCS_INVALID_JSON_UNEXPECTED   = 'Unexpected character found! (%s)';
  RCS_INVALID_ESCAPE_CHARACTER  = 'Invalid escape char!';
  RCS_INVALID_UNICODE_CHARACTER = 'Invalid or malformed unicode character';
  RCS_UNEXPECTED_END_OF_FILE    = 'Unexpected end of file or malformed JSON';
  RCS_FIELD_VALUE_TYPE_MISMATCH = 'Field value type mismatch, declaration differs! (%s <> %s)';
  RCS_FIELD_COUNT_MISMATCH      = 'Fields and value count mismatch!';
  RCS_FIELD_NAME_ALREADY_EXISTS = 'A field with this name already exists!';
  RCS_TEMPLATE_NAME_REQUIRED    = 'Error creating template "%s", nested name is required!';
  RCS_TEMPLATE_NAME_NOT_FOUND   = 'Template with name "%s" not found!';
  RCS_TEMPLATE_REQUIRED         = 'A template object is required!';

resourcestring
  RCS_INVALID_JSON5_INVALID_IDENTIFIER = 'Invalid identifier found, unexpected character! (%s)';
  RCS_INVALID_JSON5_MULTILINE_STRING   = 'Invalid multiline string found!';

type
  TJSONChar = (jcLeftBrace, jcRightBrace, jcColon, jcComma, jcLeftBracket, jcRightBracket, jcDoubleQuote);
  TJSON5Char = (jc5LeftBrace, jc5RightBrace, jc5Colon, jc5Comma, jc5LeftBracket, jc5RightBracket, jc5DoubleQuote, jc5SingleQuote, jc5Identifier, jc5Escape, jc5Comment);
  TJSONChars = set of TJSONChar;
  TJSON5Chars = set of TJSON5Char;

const // Template type classification for internal handling of TJSONTemplate.Default and TJSONTemplate.Fill
  JSON_ADVANCED_TEMPLATE_TYPES: set of TJSONTemplateType = [jttName, jttUnixTime, jttTemplate, jttCallback];
  JSON_AUTOFILL_TEMPLATE_TYPES: set of TJSONTemplateType = [jttName, jttUnixTime, jttCallback];

const
  JSON_TYPE_STRINGS: Array[TJSONType] of String = ('Null', 'Integer', 'Float', 'String', 'Boolean', 'Object', 'Array');
  JSON_TYPE_TO_TEMPLATE_TYPE: Array[TJSONType] of TJSONTemplateType = (jttNull, jttInteger, jttFloat, jttString, jttBoolean, jttObject, jttArray);
  JSON_TEMPLATE_TYPE_STRINGS: Array[TJSONTemplateType] of String = ('Null', 'Integer', 'Float', 'String', 'Boolean', 'Object', 'Array', '<Name>', '<UnixTime>', '<Template>', '<Callback>');

const // Values
  JSON_NULL_VALUE  = 'null';
  JSON_FALSE_VALUE = 'false';
  JSON_TRUE_VALUE  = 'true';

const // Coding related
  JSON_DEFAULT_LOCALE = 'en-US';

const // Output formating
  JSON_IDENT_COUNT = 2;
  JSON_SPACER_CHAR = #32;
  JSON_IDENT_CHAR  = #32;
  JSON_LINE_FEED   = #13#10;

const // Parser related
  JSON_CHARS: Array[TJSONChar] of AnsiChar = ('{', '}', ':', ',', '[', ']', '"');
  JSON5_CHARS: Array[TJSON5Char] of AnsiChar = ('{', '}', ':', ',', '[', ']', '"', '''', '_', '\', '/');

{ Helper Functions }

function JsonGetValue(const AName: String; const ADefault: String; const AJSON: String): String;
var
  JSON: TJSON;
begin
  Result:=ADefault;

  try
    JSON:=TJSON.CreateFromString(AJSON);

    if JSON.IsObject then
    begin
      Result:=JSON.AsObject.GetOrAdd(AName, ADefault);
    end;
  finally
    FreeAndNil(JSON);
  end;
end;

{ Parser }

type
  TJSONParserClass = class of TJSONParser;

  TJSONParser = class
  private
    FData: TStringStream;
    FBuffer: AnsiChar;
    FLineCount: Integer;
    FCharCount: Integer;
  strict private
    FNextExpected: AnsiString;
    procedure Expect(AChar: TJSONChar); overload; inline;
    procedure Expect(AChars: TJSONChars); overload; inline;
    procedure IsExpected; inline;
  protected
    procedure Next; inline;
    procedure Rollback; inline;
    function HasData: Boolean; inline;
    procedure ParseArray(AArr: TJSONArray); virtual;
    procedure ParseObject(AObj: TJSONObject); virtual;
    function ParseString: String; virtual;
    function ParseValue: TJSONValue; virtual;
    procedure InternalParse(AJSON: TJSON); virtual;
  public
    class procedure Parse(AJSON: TJSON; AParserClass: TJSONParserClass);
  end;

  TJSON5Parser = class(TJSONParser)
  strict private
    FNextExpected: TJSON5Chars;
    procedure Expect(AChar: TJSON5Char); overload; inline;
    procedure Expect(AChars: TJSON5Chars); overload; inline;
    procedure ExpectNext(AChar: TJSON5Char); inline;
    procedure IsExpected; inline;
  protected
    procedure ParseArray(AArr: TJSONArray); override;
    procedure ParseObject(AObj: TJSONObject); override;
    function ParseString: String; override;
    function ParseIdentifier: String; virtual;
    function ParseValue: TJSONValue; override;
    procedure InternalParse(AJSON: TJSON); override;
  end;

  TJSONWriter = class
  private
    FWriteMode: TJSONStringWriteMode;
    FOutput: TStringStream;
  protected
    procedure WriteLineFeed;
    procedure WriteSpacer;
    procedure WriteChar(AChar: TJSONChar);
    procedure WriteChars(AChars: AnsiString);
    procedure WriteIdent(ALevel: Integer);
    procedure WriteNull;
    procedure WriteInteger(AValue: Int64);
    procedure WriteFloat(AValue: Extended);
    procedure WriteString(AValue: String);
    procedure WriteBoolean(AValue: Boolean);
    procedure WriteObject(AValue: TJSONObject; AIdentLevel: Integer);
    procedure WriteArray(AValue: TJSONArray; AIdentLevel: Integer);
    function InternalWrite(AJSON: TJSON): String; overload; inline;
    function InternalWrite(AJSON: TJSONObject): String; overload; inline;
    function InternalWrite(AJSON: TJSONArray): String; overload; inline;
  public
    constructor Create(AWriteMode: TJSONStringWriteMode);
    destructor Destroy; override;
    class function Write(AJSON: TJSON; AWriteMode: TJSONStringWriteMode): String; overload;
    class function Write(AJSONObject: TJSONObject; AWriteMode: TJSONStringWriteMode): String; overload;
    class function Write(AJSONArray: TJSONArray; AWriteMode: TJSONStringWriteMode): String; overload;
  end;

  TJSONTemplatesList = class(THashedStringList)
  private
    function GetTemplate(Name: String): TJSONTemplate;
  public
    constructor Create;
    destructor Destroy; override;
    function AddTemplates(AName: String; ATemplate: TJSONTemplate): Integer;
    property Templates[Name: String]: TJSONTemplate read GetTemplate; default;
  end;

var
  GlobTemplates: TJSONTemplatesList = nil;

{ TJSONParser }

procedure TJSONParser.Next;
begin
  Inc(FCharCount);
  FData.Read(FBuffer, 1);
end;

procedure TJSONParser.Rollback;
begin
  FData.Position:=FData.Position - 1;
end;

function TJSONParser.HasData: Boolean;
begin
  Result:=FData.Position < FData.Size;
end;

procedure TJSONParser.IsExpected;
begin
  // Look for the FBuffer in the FNextExpected string, if not found (0) raise parser exception
  if AnsiPos(String(FBuffer), String(FNextExpected)) = 0 then
    raise EJSONException.Create(Format(RCS_INVALID_CHARACTER, [FBuffer]), FLineCount, FCharCount);
end;

procedure TJSONParser.Expect(AChar: TJSONChar);
begin
  FNextExpected:=JSON_CHARS[AChar];
end;

procedure TJSONParser.Expect(AChars: TJSONChars);
var
  I: TJSONChar;
begin
  FNextExpected:='';

  for I:=Low(TJSONChar) to High(TJSONChar) do
    if I IN AChars then
      FNextExpected:=FNextExpected + JSON_CHARS[I];
end;

function TJSONParser.ParseString: String;
var
  I: Integer;
  Unicode: String;
begin
  Result:='';

  while HasData do
  begin
    Next;

    case FBuffer of
      '"':
      begin
        Break;
      end;
      '\':
      begin
        if HasData then
        begin
          Next;

          case FBuffer of
            '"', '\', '/': Result:=Result + Char(FBuffer);
            'b': Result:=Result + #8;
            'f': Result:=Result + #12;
            'n': Result:=Result + #10;
            'r': Result:=Result + #13;
            't': Result:=Result + #9;
            'u':
            begin
              Unicode:='';

              for I:=0 to 3 do
              begin
                if HasData then
                begin
                  Next;

                  Unicode:=Unicode + Char(FBuffer);
                end;
              end;

              if Length(Unicode) = 4 then
              begin
                Result:=Result + Char(StrToIntDef('$' + Unicode, 63));
              end else
              begin
                raise EJSONException.Create(RCS_INVALID_UNICODE_CHARACTER, FLineCount, FCharCount);
              end;
            end;
            else
            begin
              raise EJSONException.Create(RCS_INVALID_ESCAPE_CHARACTER, FLineCount, FCharCount);
            end;
          end;
        end else
        begin
          raise EJSONException.Create(RCS_UNEXPECTED_END_OF_FILE, FLineCount, FCharCount);
        end;
      end;
      else
      begin
        Result:=Result + Char(FBuffer);
      end;
    end;
  end;
end;

procedure TJSONParser.ParseObject(AObj: TJSONObject);
var
  Key: String;
begin
  Expect([jcDoubleQuote, jcRightBrace]);

  while HasData do
  begin
    Next;

    case FBuffer of
      '"': // Key string
      begin
        IsExpected;
        Key:=ParseString;
        Expect(jcColon);
      end;
      ':': // Value colon
      begin
        IsExpected;
        AObj.Add(Key, ParseValue);
        Expect([jcComma, jcRightBrace]);
      end;
      ',': // Next pair
      begin
        IsExpected;
        Expect(jcDoubleQuote);
        Continue;
      end;
      '}': // End of object
      begin
        IsExpected;
        Exit;
      end;
      #10:
      begin
        Inc(FLineCount);
        FCharCount:=0;
        Continue;
      end;
      #9, #13, #32:
      begin
        Continue;
      end
      else
      begin
        raise EJSONException.Create(Format(RCS_INVALID_CHARACTER, [FBuffer]), FLineCount, FCharCount);
      end;
    end;
  end;
end;

procedure TJSONParser.ParseArray(AArr: TJSONArray);
begin
  Expect([jcRightBracket]);

  while HasData do
  begin
    Next;

    case FBuffer of
      ']':
      begin
        IsExpected;
        Break;
      end;
      ',':
      begin
        IsExpected;
        Expect([]);
        Continue;
      end;
      #10:
      begin
        Inc(FLineCount);
        FCharCount:=0;
        Continue;
      end;
      #9, #13, #32:
      begin
        Continue
      end;
      else
      begin
        Rollback;
        AArr.Add(ParseValue);
        Expect([jcComma, jcRightBracket]);
      end;
    end;
  end;
end;

function TJSONParser.ParseValue: TJSONValue;
var
  I: Integer;
  Value: String;
  Typ: TJSONType;
  Obj: TJSONObject;
  Arr: TJSONArray;
begin
  Result:=nil;
  Value:='';

  if HasData then
  repeat
    Next;

    case FBuffer of
      '{': // Object begin
      begin
        Obj:=TJSONObject.Create;
        ParseObject(Obj);
        Result:=Obj;
        Break;
      end;
      '[': // Array begin
      begin
        Arr:=TJSONArray.Create;
        ParseArray(Arr);
        Result:=Arr;
        Break;
      end;
      '"': // String
      begin
        Result:=TJSONString.CreateFrom(ParseString);
        Break;
      end;
      '-', '0'..'9': // Numeric value
      begin
        Value:=Char(FBuffer);
        Typ:=jtInteger;

        while HasData do
        begin
          Next;

          case FBuffer of
            '0'..'9':
            begin
              Value:=Value + Char(FBuffer);
            end;
            '.':
            begin
              if Typ = jtInteger then
              begin
                Value:=Value + Char(FBuffer);
                Typ:=jtFloat;
              end else
              begin
                raise EJSONException.Create(RCS_INVALID_NUMERIC_VALUE, FLineCount, FCharCount);
              end;
            end;
            else
            begin
              Rollback;
              Break;
            end;
          end;
        end;

        case Typ of
          jtInteger: Result:=TJSONInteger.CreateFrom(StrToInt64Def(Value, 0));
          jtFloat: Result:=TJSONFloat.CreateFrom(StrToFloatDef(Value, 0, TFormatSettings.Create(JSON_DEFAULT_LOCALE)));
        end;

        Break;
      end;
      't', 'T': // Boolean (True)
      begin
        Value:=Char(FBuffer);

        for I:=0 to Length(JSON_TRUE_VALUE) - 2 do
        begin
          Next;

          Value:=Value + Char(FBuffer);
        end;

        if AnsiSameText(Value, JSON_TRUE_VALUE) then
        begin
          Result:=TJSONBoolean.CreateFrom(True);
        end else
        begin
          raise EJSONException.Create(RCS_INVALID_IDENTIFIER, FLineCount, FCharCount);
        end;

        Break;
      end;
      'f', 'F': // Boolean (False)
      begin
        Value:=Char(FBuffer);

        for I:=0 to Length(JSON_FALSE_VALUE) - 2 do
        begin
          Next;

          Value:=Value + Char(FBuffer);
        end;

        if AnsiSameText(Value, JSON_FALSE_VALUE) then
        begin
          Result:=TJSONBoolean.CreateFrom(False);
        end else
        begin
          raise EJSONException.Create(RCS_INVALID_IDENTIFIER, FLineCount, FCharCount);
        end;

        Break;
      end;
      'n', 'N': // Null
      begin
        Value:=Char(FBuffer);

        for I:=0 to Length(JSON_NULL_VALUE) - 2 do
        begin
          Next;

          Value:=Value + Char(FBuffer);
        end;

        if AnsiSameText(Value, JSON_NULL_VALUE) then
        begin
          Result:=TJSONNull.Create;
        end else
        begin
          raise EJSONException.Create(RCS_INVALID_IDENTIFIER, FLineCount, FCharCount);
        end;

        Break;
      end;
      #10:
      begin
        Inc(FLineCount);
        FCharCount:=0;
        Continue;
      end;
      #9, #13, #32: // Tab or space, ignore...
      begin
        Continue;
      end;
      else // Unknown char, break
      begin
        Break;
      end;
    end;
  until NOT HasData;
end;

procedure TJSONParser.InternalParse(AJSON: TJSON);
var
  Obj: TJSONObject;
  Arr: TJSONArray;
begin
  FData:=AJSON.FData;
  FData.Position:=0;

  FLineCount:=0;
  FCharCount:=0;

  Expect([jcLeftBrace, jcLeftBracket]);

  while HasData do
  begin
    Next;

    case FBuffer of
      '{':
      begin
        IsExpected;
        Obj:=TJSONObject.Create;
        ParseObject(Obj);
        AJSON.FRoot:=Obj;
      end;
      '[':
      begin
        IsExpected;
        Arr:=TJSONArray.Create;
        ParseArray(Arr);
        AJSON.FRoot:=Arr;
      end;
      #10:
      begin
        Inc(FLineCount);
        FCharCount:=0;
        Continue;
      end;
      #9, #13, #32:
      begin
        Continue;
      end;
      #0:
      begin
        Exit;
      end
      else
      begin
        raise EJSONException.Create(Format(RCS_INVALID_JSON_UNEXPECTED, [FBuffer]), FLineCount, FCharCount);
      end;
    end;
  end;
end;

class procedure TJSONParser.Parse(AJSON: TJSON; AParserClass: TJSONParserClass);
var
  Parser: TJSONParser;
begin
  Parser:=AParserClass.Create;
  try
    Parser.InternalParse(AJSON);
  finally
    Parser.Free;
  end;
end;

{ TJSON5Parser }

procedure TJSON5Parser.Expect(AChars: TJSON5Chars);
begin
  FNextExpected:=AChars;
end;

procedure TJSON5Parser.Expect(AChar: TJSON5Char);
begin
  FNextExpected:=[AChar];
end;

procedure TJSON5Parser.ExpectNext(AChar: TJSON5Char);
begin
  if HasData then
  begin
    Next;
    if JSON5_CHARS[AChar] <> FBuffer then
      raise EJSONException.Create(Format(RCS_INVALID_CHARACTER, [FBuffer]), FLineCount, FCharCount);
  end else
  begin
    raise EJSONException.Create(RCS_UNEXPECTED_END_OF_FILE, FLineCount, FCharCount);
  end;
end;

procedure TJSON5Parser.InternalParse(AJSON: TJSON);
var
  Obj: TJSONObject;
  Arr: TJSONArray;
begin
  FData:=AJSON.FData;
  FData.Position:=0;

  FLineCount:=0;
  FCharCount:=0;

  Expect([jc5LeftBrace, jc5LeftBracket]);

  while HasData do
  begin
    Next;

    case FBuffer of
      '{':
      begin
        IsExpected;
        Obj:=TJSONObject.Create;
        ParseObject(Obj);
        AJSON.FRoot:=Obj;
      end;
      '[':
      begin
        IsExpected;
        Arr:=TJSONArray.Create;
        ParseArray(Arr);
        AJSON.FRoot:=Arr;
      end;
      #10:
      begin
        Inc(FLineCount);
        FCharCount:=0;
        Continue;
      end;
      #9, #13, #32:
      begin
        Continue;
      end;
      #0:
      begin
        Exit;
      end
      else
      begin
        raise EJSONException.Create(Format(RCS_INVALID_JSON_UNEXPECTED, [FBuffer]), FLineCount, FCharCount);
      end;
    end;
  end;
end;

procedure TJSON5Parser.IsExpected;
var
  I: TJSON5Char;
begin
  for I:=Low(TJSON5Char) to High(TJSON5Char) do
  begin
    if I IN FNextExpected then
    begin
      case I of
        jc5Identifier:
        begin
          if CharInSet(FBuffer, ['_', 'a'..'z', 'A'..'Z']) then
            Exit
        end
        else
        begin
          if FBuffer = JSON5_CHARS[I] then
            Exit;
        end;
      end;
    end;
  end;

  raise EJSONException.Create(Format(RCS_INVALID_JSON_UNEXPECTED, [FBuffer]), FLineCount, FCharCount);
end;

procedure TJSON5Parser.ParseArray(AArr: TJSONArray);
begin
  Expect([jc5RightBracket]);

  while HasData do
  begin
    Next;

    case FBuffer of
      ']':
      begin
        IsExpected;
        Break;
      end;
      ',':
      begin
        IsExpected;
        Expect([jc5RightBracket]);
        Continue;
      end;
      #10:
      begin
        Inc(FLineCount);
        FCharCount:=0;
        Continue;
      end;
      #9, #13, #32:
      begin
        Continue
      end;
      else
      begin
        Rollback;
        AArr.Add(ParseValue);
        Expect([jc5Comma, jc5RightBracket]);
      end;
    end;
  end;
end;

function TJSON5Parser.ParseIdentifier: String;
begin
  Result:=Char(FBuffer);

  while HasData do
  begin
    Next;

    case FBuffer of
      '_',
      'a'..'z',
      'A'..'Z',
      '0'..'9':
      begin
        Result:=Result + Char(FBuffer);
      end;
      else
      begin
        Rollback;
        Exit;
      end;
    end;
  end;
end;

procedure TJSON5Parser.ParseObject(AObj: TJSONObject);
var
  Key: String;
  IsComment: Boolean;
begin
  IsComment:=False;

  Expect([jc5DoubleQuote, jc5SingleQuote, jc5RightBrace, jc5Comment, jc5SingleQuote, jc5Identifier]);

  while HasData do
  begin
    Next;

    case FBuffer of
      '/': // Comment
      begin
        IsExpected;
        ExpectNext(jc5Comment);
        IsComment:=True;
      end;
      '"', '''': // Key string
      begin
        if IsComment then Continue;
        IsExpected;
        Key:=ParseString;
        Expect(jc5Colon);
      end;
      '_', 'a'..'z', 'A'..'Z': // Identifier
      begin
        if IsComment then Continue;
        IsExpected;
        Key:=ParseIdentifier;
        Expect(jc5Colon);
      end;
      ':': // Value colon
      begin
        if IsComment then Continue;
        IsExpected;
        AObj.Add(Key, ParseValue);
        Expect([jc5Comma, jc5RightBrace]);
      end;
      ',': // Next pair
      begin
        if IsComment then Continue;
        IsExpected;
        Expect([jc5DoubleQuote, jc5Identifier, jc5RightBrace]);
        Continue;
      end;
      '}': // End of object
      begin
        if IsComment then Continue;
        IsExpected;
        Exit;
      end;
      #10:
      begin
        Inc(FLineCount);
        FCharCount:=0;
        IsComment:=False;
        Continue;
      end;
      #9, #13, #32:
      begin
        Continue;
      end
      else
      begin
        if IsComment then Continue;
        raise EJSONException.Create(Format(RCS_INVALID_CHARACTER, [FBuffer]), FLineCount, FCharCount);
      end;
    end;
  end;
end;

function TJSON5Parser.ParseString: String;
var
  I: Integer;
  Unicode: String;
  SingleQuoted: Boolean;
begin
  Result:='';

  SingleQuoted:=FBuffer = JSON5_CHARS[jc5SingleQuote];

  while HasData do
  begin
    Next;

    case FBuffer of
      '"', '''':
      begin
        if SingleQuoted AND (FBuffer = JSON5_CHARS[jc5SingleQuote]) then
          Break;

        if NOT SingleQuoted AND (FBuffer = JSON5_CHARS[jc5DoubleQuote]) then
          Break;

        Result:=Result + Char(FBuffer);
      end;
      '\':
      begin
        if HasData then
        begin
          Next;

          case FBuffer of
            '"', '\', '/', '''': Result:=Result + Char(FBuffer);
            'b': Result:=Result + #8;
            'f': Result:=Result + #12;
            'n': Result:=Result + #10;
            'r': Result:=Result + #13;
            't': Result:=Result + #9;
            #10, #13:
            begin
              if FBuffer = #13 then
              begin
                Next;
                if HasData AND (FBuffer = #10) then
                  Result:=Result + #13#10
                else
                  raise EJSONException.Create(RCS_INVALID_JSON5_MULTILINE_STRING, FLineCount, FCharCount);
              end else
                Result:=Result + Char(FBuffer);

              Inc(FLineCount);
            end;
            'u':
            begin
              Unicode:='';

              for I:=0 to 3 do
              begin
                if HasData then
                begin
                  Next;

                  Unicode:=Unicode + Char(FBuffer);
                end;
              end;

              if Length(Unicode) = 4 then
              begin
                Result:=Result + Char(StrToIntDef('$' + Unicode, 63));
              end else
              begin
                raise EJSONException.Create(RCS_INVALID_UNICODE_CHARACTER, FLineCount, FCharCount);
              end;
            end;
            else
            begin
              raise EJSONException.Create(RCS_INVALID_ESCAPE_CHARACTER, FLineCount, FCharCount);
            end;
          end;
        end else
        begin
          raise EJSONException.Create(RCS_UNEXPECTED_END_OF_FILE, FLineCount, FCharCount);
        end;
      end;
      else
      begin
        Result:=Result + Char(FBuffer);
      end;
    end;
  end;
end;

function TJSON5Parser.ParseValue: TJSONValue;
var
  I: Integer;
  Value: String;
  Typ: TJSONType;
  Obj: TJSONObject;
  Arr: TJSONArray;
begin
  Result:=nil;
  Value:='';

  if HasData then
  repeat
    Next;

    case FBuffer of
      '{': // Object begin
      begin
        Obj:=TJSONObject.Create;
        ParseObject(Obj);
        Result:=Obj;
        Break;
      end;
      '[': // Array begin
      begin
        Arr:=TJSONArray.Create;
        ParseArray(Arr);
        Result:=Arr;
        Break;
      end;
      '"', '''': // String
      begin
        Result:=TJSONString.CreateFrom(ParseString);
        Break;
      end;
      '.', '+', '-', '0'..'9': // Numeric value
      begin
        Value:=Char(FBuffer);
        Typ:=jtInteger;

        while HasData do
        begin
          Next;

          case FBuffer of
            '0'..'9':
            begin
              Value:=Value + Char(FBuffer);
            end;
            'x': // Hex Value
            begin
              Value:='$';

              while HasData do
              begin
                Next;

                if CharInSet(FBuffer, ['0'..'9', 'a'..'f', 'A'..'F']) then
                begin
                  Value:=Value + Char(FBuffer)
                end else
                begin
                  Rollback;
                  Break
                end;
              end;
            end;
            '.':
            begin
              if Typ = jtInteger then
              begin
                Value:=Value + Char(FBuffer);
                Typ:=jtFloat;
              end else
              begin
                raise EJSONException.Create(RCS_INVALID_NUMERIC_VALUE, FLineCount, FCharCount);
              end;
            end;
            else
            begin
              Rollback;
              Break;
            end;
          end;
        end;

        case Typ of
          jtInteger: Result:=TJSONInteger.CreateFrom(StrToInt64Def(Value, 0));
          jtFloat: Result:=TJSONFloat.CreateFrom(StrToFloatDef(Value, 0, TFormatSettings.Create(JSON_DEFAULT_LOCALE)));
        end;

        Break;
      end;
      't', 'T': // Boolean (True)
      begin
        Value:=Char(FBuffer);

        for I:=0 to Length(JSON_TRUE_VALUE) - 2 do
        begin
          Next;

          Value:=Value + Char(FBuffer);
        end;

        if AnsiSameText(Value, JSON_TRUE_VALUE) then
        begin
          Result:=TJSONBoolean.CreateFrom(True);
        end else
        begin
          raise EJSONException.Create(RCS_INVALID_IDENTIFIER, FLineCount, FCharCount);
        end;

        Break;
      end;
      'f', 'F': // Boolean (False)
      begin
        Value:=Char(FBuffer);

        for I:=0 to Length(JSON_FALSE_VALUE) - 2 do
        begin
          Next;

          Value:=Value + Char(FBuffer);
        end;

        if AnsiSameText(Value, JSON_FALSE_VALUE) then
        begin
          Result:=TJSONBoolean.CreateFrom(False);
        end else
        begin
          raise EJSONException.Create(RCS_INVALID_IDENTIFIER, FLineCount, FCharCount);
        end;

        Break;
      end;
      'n', 'N': // Null
      begin
        Value:=Char(FBuffer);

        for I:=0 to Length(JSON_NULL_VALUE) - 2 do
        begin
          Next;

          Value:=Value + Char(FBuffer);
        end;

        if AnsiSameText(Value, JSON_NULL_VALUE) then
        begin
          Result:=TJSONNull.Create;
        end else
        begin
          raise EJSONException.Create(RCS_INVALID_IDENTIFIER, FLineCount, FCharCount);
        end;

        Break;
      end;
      #10:
      begin
        Inc(FLineCount);
        FCharCount:=0;
        Continue;
      end;
      #9, #13, #32: // Tab or space, ignore...
      begin
        Continue;
      end;
      else // Unknown char, break
      begin
        Break;
      end;
    end;
  until NOT HasData;
end;

{ TJSONWriter }

constructor TJSONWriter.Create(AWriteMode: TJSONStringWriteMode);
begin
  inherited Create;

  FWriteMode:=AWriteMode;
  FOutput:=TStringStream.Create('', TEncoding.ASCII, False);
end;

destructor TJSONWriter.Destroy;
begin
  FreeAndNil(FOutput);

  inherited;
end;

function TJSONWriter.InternalWrite(AJSON: TJSON): String;
begin
  Result:='';

  if NOT AJSON.IsEmpty then
  begin
    if AJSON.IsObject then
    begin
      Result:=InternalWrite(AJSON.AsObject);
    end else
    if AJSON.IsArray then
    begin
      Result:=InternalWrite(AJSON.AsArray);
    end;
  end;
end;

function TJSONWriter.InternalWrite(AJSON: TJSONObject): String;
begin
  FOutput.Clear;
  WriteObject(AJSON.AsObject, 0);
  Result:=FOutput.DataString;
end;

function TJSONWriter.InternalWrite(AJSON: TJSONArray): String;
begin
  FOutput.Clear;
  WriteArray(AJSON.AsArray, 0);
  Result:=FOutput.DataString;
end;

class function TJSONWriter.Write(AJSON: TJSON; AWriteMode: TJSONStringWriteMode): String;
var
  Writer: TJSONWriter;
begin
  Writer:=TJSONWriter.Create(AWriteMode);
  try
    Result:=Writer.InternalWrite(AJSON);
  finally
    Writer.Free;
  end;
end;

class function TJSONWriter.Write(AJSONArray: TJSONArray; AWriteMode: TJSONStringWriteMode): String;
var
  Writer: TJSONWriter;
begin
  Writer:=TJSONWriter.Create(AWriteMode);
  try
    Result:=Writer.InternalWrite(AJSONArray);
  finally
    Writer.Free;
  end;
end;

class function TJSONWriter.Write(AJSONObject: TJSONObject; AWriteMode: TJSONStringWriteMode): String;
var
  Writer: TJSONWriter;
begin
  Writer:=TJSONWriter.Create(AWriteMode);
  try
    Result:=Writer.InternalWrite(AJSONObject);
  finally
    Writer.Free;
  end;
end;

procedure TJSONWriter.WriteChar(AChar: TJSONChar);
begin
  FOutput.WriteString(String(JSON_CHARS[AChar]));
end;

procedure TJSONWriter.WriteChars(AChars: AnsiString);
begin
  FOutput.WriteString(String(AChars));
end;

procedure TJSONWriter.WriteLineFeed;
begin
  if FWriteMode = jswmReadable then
    FOutput.WriteString(JSON_LINE_FEED);
end;

procedure TJSONWriter.WriteFloat(AValue: Extended);
begin
  FOutput.WriteString(FloatToStr(AValue, TFormatSettings.Create(JSON_DEFAULT_LOCALE)));
end;

procedure TJSONWriter.WriteIdent(ALevel: Integer);
begin
  if FWriteMode = jswmReadable then
    FOutput.WriteString(StringOfChar(JSON_IDENT_CHAR, ALevel * JSON_IDENT_COUNT));
end;

procedure TJSONWriter.WriteInteger(AValue: Int64);
begin
  FOutput.WriteString(IntToStr(AValue));
end;

procedure TJSONWriter.WriteNull;
begin
  FOutput.WriteString(JSON_NULL_VALUE);
end;

procedure TJSONWriter.WriteArray(AValue: TJSONArray; AIdentLevel: Integer);
var
  I: Integer;
begin
  WriteChar(jcLeftBracket);
  WriteLineFeed;

  for I:=0 to AValue.Count - 1 do
  begin
    WriteIdent(AIdentLevel + 1);

    case AValue.Item[I].Typ of
      jtNull: WriteNull;
      jtInteger: WriteInteger(AValue.Item[I].AsInteger);
      jtFloat: WriteFloat(AValue.Item[I].AsFloat);
      jtString: WriteString(AValue.Item[I].AsString);
      jtBoolean: WriteBoolean(AValue.Item[I].AsBoolean);
      jtObject: WriteObject(AValue.Item[I].AsObject, AIdentLevel + 1);
      jtArray: WriteArray(AValue.Item[I].AsArray, AIdentLevel + 1);
    end;

    if I < AValue.Count - 1 then
      WriteChar(jcComma);

    WriteLineFeed;
  end;

  WriteIdent(AIdentLevel);
  WriteChar(jcRightBracket);
end;

procedure TJSONWriter.WriteBoolean(AValue: Boolean);
begin
  FOutput.WriteString(IfThen(AValue, JSON_TRUE_VALUE, JSON_FALSE_VALUE));
end;

procedure TJSONWriter.WriteObject(AValue: TJSONObject; AIdentLevel: Integer);
var
  I: Integer;
begin
  WriteChar(jcLeftBrace);
  WriteLineFeed;

  for I:=0 to AValue.Count - 1 do
  begin
    WriteIdent(AIdentLevel + 1);
    WriteString(AValue.Name[I]);
    WriteChar(jcColon);
    WriteSpacer;

    case AValue.Item[I].Typ of
      jtNull: WriteNull;
      jtInteger: WriteInteger(AValue.Item[I].AsInteger);
      jtFloat: WriteFloat(AValue.Item[I].AsFloat);
      jtString: WriteString(AValue.Item[I].AsString);
      jtBoolean: WriteBoolean(AValue.Item[I].AsBoolean);
      jtObject: WriteObject(AValue.Item[I].AsObject, AIdentLevel + 1);
      jtArray: WriteArray(AValue.Item[I].AsArray, AIdentLevel + 1);
    end;

    if I < AValue.Count - 1 then
      WriteChar(jcComma);

    WriteLineFeed;
  end;

  WriteIdent(AIdentLevel);
  WriteChar(jcRightBrace);
end;

procedure TJSONWriter.WriteSpacer;
begin
  if FWriteMode = jswmReadable then
    FOutput.WriteString(JSON_SPACER_CHAR);
end;

procedure TJSONWriter.WriteString(AValue: String);
begin
  FOutput.WriteString(String(JSON_CHARS[jcDoubleQuote]));
  FOutput.WriteString(TJSON.EncodeString(AValue));
  FOutput.WriteString(String(JSON_CHARS[jcDoubleQuote]));
end;

{ EJSONException }

constructor EJSONException.Create(AMessage: String; ALine, ACol: Integer);
begin
  inherited Create(Format(RCS_JSON_PARSER_EXCEPTION, [ALine + 1, ACol])); // +1 bcuz we start counting lines at zero!

  FMessage:=AMessage;
end;

{ TJSON }

class function TJSON.EncodeString(AString: String): String;
var
  I: Integer;
begin
  Result:='';

  for I:=1 to Length(AString) do
  begin
    case Ord(AString[I]) of
      $0..$1F:
      begin
        case AString[I] of
          #8: Result:=Result + '\b';
          #9: Result:=Result + '\t';
          #10: Result:=Result + '\n';
          #12: Result:=Result + '\f';
          #13: Result:=Result + '\r';
        end;
      end;
      $22: Result:=Result + '\"';
      $2F: Result:=Result + '\/';
      $5C: Result:=Result + '\\';
      $100..$FFFF:
      begin
        Result:=Result + '\u' + AnsiLowerCase(IntToHex(Ord(AString[I]), 4));
      end
      else
      begin
        Result:=Result + AString[I];
      end;
    end;
  end;
end;

class function TJSON.CreateTemplate(AName: String): TJSONTemplate;
begin
  Result:=TJSONTemplate.Create(AName);
  GlobTemplates.AddTemplates(AName, Result);
end;

constructor TJSON.Create;
begin
  inherited Create;

  FCritSec:=TCriticalSection.Create;
  FData:=TStringStream.Create(EmptyStr, TEncoding.ASCII, False);
end;

constructor TJSON.CreateArrayRoot;
begin
  Create;

  FRoot:=TJSONArray.Create;
end;

constructor TJSON.CreateFromFile(AFile: String; AExtension: TJSONExtension = jeDefault);
begin
  Create;

  FExtension:=AExtension;

  LoadFromFile(AFile);
end;

constructor TJSON.CreateFromStream(AStream: TStream; AExtension: TJSONExtension = jeDefault);
begin
  Create;

  FExtension:=AExtension;

  LoadFromStream(AStream);
end;

constructor TJSON.CreateFromString(AJSON: String; AExtension: TJSONExtension = jeDefault);
begin
  Create;

  FExtension:=AExtension;

  ReadFromString(AJSON);
end;

constructor TJSON.CreateObjectRoot;
begin
  Create;

  FRoot:=TJSONObject.Create;
end;

destructor TJSON.Destroy;
begin
  Clear;

  FreeAndNil(FData);
  FreeAndNil(FCritSec);

  inherited;
end;

function TJSON.GetArrayValue(Index: Integer): TJSONValue;
begin
  Result:=nil;

  if IsArray then
    if (Index >=0) AND (Index < AsArray.Count) then
      Result:=AsArray[Index];
end;

function TJSON.GetAsArray: TJSONArray;
begin
  Result:=TJSONArray(FRoot);
end;

function TJSON.GetAsObject: TJSONObject;
begin
  Result:=TJSONObject(FRoot);
end;

function TJSON.GetIsArray: Boolean;
begin
  Result:=FRoot IS TJSONArray;
end;

function TJSON.GetIsObject: Boolean;
begin
  Result:=FRoot IS TJSONObject;
end;

function TJSON.GetObjectValue(Key: String): TJSONValue;
begin
  Result:=nil;

  if IsObject then
    Result:=AsObject[Key];
end;

procedure TJSON.Assign(ASource: TPersistent);
begin
  inherited;
end;

procedure TJSON.Clear;
begin
  FCritSec.Enter;
  try
    FData.Clear;

    FreeAndNil(FRoot);
  finally
    FCritSec.Leave;
  end;
end;

function TJSON.IsEmpty: Boolean;
begin
  Result:=(FRoot = nil) AND (FData.Size = 0);
end;

procedure TJSON.LoadFromFile(const AFileName: String);
begin
  Clear;

  FCritSec.Enter;
  try
    if FileExists(AFileName) then
    begin
      try
        FData.LoadFromFile(AFileName);
      except
        on E: Exception do
        begin
          Clear;
        end;
      end;

      Parse;
    end;
  finally
    FCritSec.Leave;
  end;
end;

procedure TJSON.LoadFromStream(AStream: TStream);
begin
  Clear;

  FCritSec.Enter;
  try
    FData.LoadFromStream(AStream);

    Parse;
  finally
    FCritSec.Leave;
  end;
end;

procedure TJSON.Parse;
begin
  case FExtension of
    jeDefault: TJSONParser.Parse(Self, TJSONParser);
    jeJSON5: TJSONParser.Parse(Self, TJSON5Parser);
  end;
end;

procedure TJSON.ReadFromString(const AValue: String);
begin
  Clear;

  FCritSec.Enter;
  try
    FData.WriteString(AValue);

    Parse;
  finally
    FCritSec.Leave;
  end;
end;

function TJSON.RootNewArray: TJSONArray;
begin
  Clear;

  Result:=TJSONArray.Create;

  FRoot:=Result;
end;

function TJSON.RootNewObject: TJSONObject;
begin
  Clear;

  Result:=TJSONObject.Create;

  FRoot:=Result;
end;

procedure TJSON.SaveToFile(const AFileName: String);
begin
  WriteToFile(AFileName);
end;

procedure TJSON.SaveToStream(AStream: TStream);
var
  OutStream: TStringStream;
begin
  OutStream:=TStringStream.Create('', TEncoding.ASCII);
  try
    OutStream.WriteString(WriteToString);
    OutStream.Position:=0;
    OutStream.SaveToStream(AStream);
  finally
    FreeAndNil(OutStream);
  end;
end;

class function TJSON.Template(AName: String): TJSONTemplate;
begin
  Result:=GlobTemplates[AName];
end;

function TJSON.WriteToString(AWriteMode: TJSONStringWriteMode = jswmReadable): String;
begin
  FCritSec.Enter;
  try
    Result:=TJSONWriter.Write(Self, AWriteMode);
  finally
    FCritSec.Leave;
  end;
end;

function TJSON.WriteToFile(const AFileName: String; AWriteMode: TJSONStringWriteMode = jswmReadable): String;
var
  OutStream: TStringStream;
begin
  OutStream:=TStringStream.Create('', TEncoding.ASCII);
  try
    OutStream.WriteString(WriteToString(AWriteMode));
    OutStream.Position:=0;
    OutStream.SaveToFile(AFileName);
  finally
    FreeAndNil(OutStream);
  end;
end;

{ TJSONValue }

constructor TJSONValue.Create;
begin
  inherited Create;
end;

function TJSONValue.Copy: TJSONValue;
begin
  Result:=GetClass.Create;
  AssignTo(Result);
end;

function TJSONValue.GetAsValue: TValue;
begin
  Result:=TValue.Empty;
end;

function TJSONValue.GetClass: TJSONClass;
begin
  Result:=TJSONValue;
end;

function TJSONValue.GetIsArray: Boolean;
begin
  Result:=Self IS TJSONArray;
end;

function TJSONValue.GetIsBoolean: Boolean;
begin
  Result:=Self IS TJSONBoolean;
end;

function TJSONValue.GetIsFloat: Boolean;
begin
  Result:=Self IS TJSONFloat;
end;

function TJSONValue.GetIsInteger: Boolean;
begin
  Result:=Self IS TJSONInteger;
end;

function TJSONValue.GetIsNull: Boolean;
begin
  Result:=Self IS TJSONNull;
end;

function TJSONValue.GetIsObject: Boolean;
begin
  Result:=Self IS TJSONObject;
end;

function TJSONValue.GetIsString: Boolean;
begin
  Result:=Self IS TJSONString;
end;

function TJSONValue.GetTyp: TJSONType;
begin
  Result:=jtNull;

  if GetIsInteger then
    Result:=jtInteger
  else if GetIsFloat then
    Result:=jtFloat
  else if GetIsString then
    Result:=jtString
  else if GetIsBoolean then
    Result:=jtBoolean
  else if GetIsObject then
    Result:=jtObject
  else if GetIsArray then
    Result:=jtArray;
end;

procedure TJSONValue.AssignTo(Dest: TPersistent);
var
  I: Integer;
begin
  if (Dest IS TJSONValue) AND (GetTyp = TJSONValue(Dest).GetTyp) then
  begin
    if GetIsInteger then
      TJSONInteger(Dest).FValue:=TJSONInteger(Self).FValue
    else if GetIsFloat then
      TJSONFloat(Dest).FValue:=TJSONFloat(Self).FValue
    else if GetIsString then
      TJSONString(Dest).FValue:=TJSONString(Self).FValue
    else if GetIsBoolean then
      TJSONBoolean(Dest).FValue:=TJSONBoolean(Self).FValue
    else if GetIsObject then
      for I:=0 to TJSONObject(Self).FKeys.Count - 1 do
        TJSONObject(Dest).FKeys.AddObject(TJSONObject(Self).FKeys[I], TJSONValue(TJSONObject(Self).FKeys.Objects[I]).Copy)
    else if GetIsArray then
      for I:=0 to TJSONArray(Self).FValues.Count - 1 do
        TJSONArray(Dest).FValues.Add(TJSONValue(TJSONArray(Self).FValues[I]).Copy);
  end;
end;

{ TJSONNull }

constructor TJSONNull.Create;
begin
  inherited Create;
end;

function TJSONNull.GetAsArray: TJSONArray;
begin
  Result:=nil;
end;

function TJSONNull.GetAsBoolean: Boolean;
begin
  Result:=False;
end;

function TJSONNull.GetAsFloat: Extended;
begin
  Result:=0.0;
end;

function TJSONNull.GetAsInteger: Int64;
begin
  Result:=0;
end;

function TJSONNull.GetAsObject: TJSONObject;
begin
  Result:=nil;
end;

function TJSONNull.GetAsString: String;
begin
  Result:='';
end;

function TJSONNull.GetClass: TJSONClass;
begin
  Result:=TJSONNull;
end;

function TJSONNull.IsEmpty: Boolean;
begin
  Result:=True;
end;

{ TJSONString }

constructor TJSONString.Create;
begin
  inherited Create;
end;

constructor TJSONString.CreateFrom(AValue: String);
begin
  Create;

  FValue:=AValue;
end;

function TJSONString.GetAsArray: TJSONArray;
begin
  Result:=nil;
end;

function TJSONString.GetAsBoolean: Boolean;
begin
  Result:=StrToBoolDef(FValue, False);
end;

function TJSONString.GetAsFloat: Extended;
begin
  Result:=StrToFloatDef(FValue, 0.0, TFormatSettings.Create(JSON_DEFAULT_LOCALE));
end;

function TJSONString.GetAsInteger: Int64;
begin
  Result:=StrToInt64Def(FValue, 0);
end;

function TJSONString.GetAsObject: TJSONObject;
begin
  Result:=nil;
end;

function TJSONString.GetAsString: String;
begin
  Result:=FValue;
end;

function TJSONString.GetAsValue: TValue;
begin
  Result:=FValue;
end;

function TJSONString.GetClass: TJSONClass;
begin
  Result:=TJSONString;
end;

function TJSONString.IsEmpty: Boolean;
begin
  Result:=FValue = '';
end;

{ TJSONInteger }

constructor TJSONInteger.Create;
begin
  inherited Create;
end;

constructor TJSONInteger.CreateFrom(AValue: Int64);
begin
  Create;

  FValue:=AValue;
end;

function TJSONInteger.GetAsArray: TJSONArray;
begin
  Result:=nil;
end;

function TJSONInteger.GetAsBoolean: Boolean;
begin
  Result:=FValue <> 0;
end;

function TJSONInteger.GetAsFloat: Extended;
begin
  Result:=FValue;
end;

function TJSONInteger.GetAsInteger: Int64;
begin
  Result:=FValue;
end;

function TJSONInteger.GetAsObject: TJSONObject;
begin
  Result:=nil;
end;

function TJSONInteger.GetAsString: String;
begin
  Result:=IntToStr(FValue);
end;

function TJSONInteger.GetAsValue: TValue;
begin
  Result:=FValue;
end;

function TJSONInteger.GetClass: TJSONClass;
begin
  Result:=TJSONInteger;
end;

function TJSONInteger.IsEmpty: Boolean;
begin
  Result:=FValue = 0;
end;

{ TJSONFloat }

constructor TJSONFloat.Create;
begin
  inherited Create;
end;

constructor TJSONFloat.CreateFrom(AValue: Extended);
begin
  Create;

  FValue:=AValue;
end;

function TJSONFloat.GetAsArray: TJSONArray;
begin
  Result:=nil;
end;

function TJSONFloat.GetAsBoolean: Boolean;
begin
  Result:=FValue <> 0;
end;

function TJSONFloat.GetAsFloat: Extended;
begin
  Result:=FValue;
end;

function TJSONFloat.GetAsInteger: Int64;
begin
  Result:=Trunc(FValue);
end;

function TJSONFloat.GetAsObject: TJSONObject;
begin
  Result:=nil;
end;

function TJSONFloat.GetAsString: String;
begin
  Result:=FloatToStr(FValue);
end;

function TJSONFloat.GetAsValue: TValue;
begin
  Result:=FValue;
end;

function TJSONFloat.GetClass: TJSONClass;
begin
  Result:=TJSONFloat;
end;

function TJSONFloat.IsEmpty: Boolean;
begin
  Result:=FValue = 0.0;
end;

{ TJSONBoolean }

constructor TJSONBoolean.Create;
begin
  inherited Create;
end;

constructor TJSONBoolean.CreateFrom(AValue: Boolean);
begin
  Create;

  FValue:=AValue;
end;

function TJSONBoolean.GetAsArray: TJSONArray;
begin
  Result:=nil;
end;

function TJSONBoolean.GetAsBoolean: Boolean;
begin
  Result:=FValue;
end;

function TJSONBoolean.GetAsFloat: Extended;
begin
  Result:=IfThen(FValue, 1, 0);
end;

function TJSONBoolean.GetAsInteger: Int64;
begin
  Result:=IfThen(FValue, 1, 0);
end;

function TJSONBoolean.GetAsObject: TJSONObject;
begin
  Result:=nil;
end;

function TJSONBoolean.GetAsString: String;
begin
  Result:=BoolToStr(FValue, True);
end;

function TJSONBoolean.GetAsValue: TValue;
begin
  Result:=FValue;
end;

function TJSONBoolean.GetClass: TJSONClass;
begin
  Result:=TJSONBoolean;
end;

function TJSONBoolean.IsEmpty: Boolean;
begin
  Result:=NOT FValue;
end;

{ TJSONObject }

constructor TJSONObject.Create;
begin
  inherited Create;

  FKeys:=THashedStringList.Create;
end;

constructor TJSONObject.CreateFrom(AObject: TJSONObject);
begin
  Create;

  AObject.AssignTo(Self);
end;

destructor TJSONObject.Destroy;
begin
  Clear;

  FreeAndNil(FKeys);

  inherited;
end;

procedure TJSONObject.Clear;
var
  I: Integer;
begin
  try
    for I:=0 to FKeys.Count - 1 do
    begin
      FKeys.Objects[I].Free;
    end;
  finally
    FKeys.Clear;
  end;
end;

function TJSONObject.GetAsArray: TJSONArray;
begin
  Result:=nil;
end;

function TJSONObject.GetAsBoolean: Boolean;
begin
  Result:=False;
end;

function TJSONObject.GetAsFloat: Extended;
begin
  Result:=0.0;
end;

function TJSONObject.GetAsInteger: Int64;
begin
  Result:=0;
end;

function TJSONObject.GetAsObject: TJSONObject;
begin
  Result:=Self;
end;

function TJSONObject.GetAsString: String;
begin
  Result:='';
end;

function TJSONObject.GetClass: TJSONClass;
begin
  Result:=TJSONObject;
end;

function TJSONObject.GetCount: Integer;
begin
  Result:=FKeys.Count;
end;

function TJSONObject.GetItem(Index: Integer): TJSONValue;
begin
  Result:=nil;

  if (Index >= 0) AND (Index < FKeys.Count) then
  begin
    Result:=TJSONValue(FKeys.Objects[Index]);
  end;
end;

function TJSONObject.GetName(Index: Integer): String;
begin
  Result:='';

  if (Index >= 0) AND (Index < FKeys.Count) then
  begin
    Result:=FKeys[Index];
  end;
end;

function TJSONObject.GetOrAdd(AKey: String; ADefault: Int64): Int64;
begin
  Result:=ADefault;

  if HasKey(AKey) then
    Result:=GetValue(AKey).AsInteger
  else
    SetOrAdd(AKey, ADefault);
end;

function TJSONObject.GetOrAdd(AKey, ADefault: String): String;
begin
  Result:=ADefault;

  if HasKey(AKey) then
    Result:=GetValue(AKey).AsString
  else
    SetOrAdd(AKey, ADefault);
end;

function TJSONObject.GetOrAdd(AKey: String; ADefault: Boolean): Boolean;
begin
  Result:=ADefault;

  if HasKey(AKey) then
    Result:=GetValue(AKey).AsBoolean
  else
    SetOrAdd(AKey, ADefault);
end;

function TJSONObject.GetOrAdd(AKey: String; ADefault: Extended): Extended;
begin
  Result:=ADefault;

  if HasKey(AKey) then
    Result:=GetValue(AKey).AsFloat
  else
    SetOrAdd(AKey, ADefault);
end;

function TJSONObject.GetOrAddArray(AKey: String): TJSONArray;
var
  Value: TJSONValue;
begin
  Value:=GetValue(AKey);
  if Assigned(Value) AND (Value IS TJSONArray) then
  begin
    Result:=TJSONArray(Value);
  end else
  begin
    Delete(AKey);

    Result:=AddArray(AKey);
  end;
end;

function TJSONObject.GetOrAddArray<T>(AKey: String; ADefault: TArray<T>): TArray<T>;
var
  I: Integer;
begin
  SetLength(Result, 0);

  with GetOrAddArray(AKey) do
  begin
    SetLength(Result, Max(Count, Length(ADefault)));
    for I:=0 to Length(Result) - 1 do
    begin
      if Count - 1 >= I then
      begin
        Result[I]:=Item[I].GetAsValue.AsType<T>;
      end else
        Result[I]:=ADefault[I];
    end;
  end;
end;

function TJSONObject.GetOrAddObject(AKey: String): TJSONObject;
var
  Value: TJSONValue;
begin
  Value:=GetValue(AKey);
  if Assigned(Value) AND (Value IS TJSONObject) then
  begin
    Result:=TJSONObject(Value);
  end else
  begin
    Delete(AKey);

    Result:=AddObject(AKey);
  end;
end;

function TJSONObject.GetValue(Key: String): TJSONValue;
var
  Idx: Integer;
begin
  Result:=nil;

  Idx:=FKeys.IndexOf(Key);
  if Idx >= 0 then
  begin
    Result:=TJSONValue(FKeys.Objects[Idx]);
  end;
end;

function TJSONObject.HasKey(AKey: String): Boolean;
begin
  Result:=FKeys.IndexOf(AKey) >= 0;
end;

function TJSONObject.IsEmpty: Boolean;
begin
  Result:=FKeys.Count = 0;
end;

procedure TJSONObject.Delete(AKey: String);
var
  Idx: Integer;
begin
  Idx:=FKeys.IndexOf(AKey);
  if Idx >= 0 then
  begin
    FKeys.Objects[Idx].Free;
    FKeys.Delete(Idx);
  end;
end;

procedure TJSONObject.SetOrAdd(AKey: String; AValue: Int64);
var
  Idx: Integer;
begin
  Idx:=FKeys.IndexOf(AKey);
  if Idx >= 0 then
  begin
    if FKeys.Objects[Idx] IS TJSONInteger then
    begin
      TJSONInteger(FKeys.Objects[Idx]).FValue:=AValue;
    end else
    begin
      FKeys.Objects[Idx].Free;
      FKeys.Objects[Idx]:=TJSONInteger.CreateFrom(AValue);
    end;
  end else
  begin
    Add(AKey, AValue);
  end;
end;

procedure TJSONObject.SetOrAdd(AKey, AValue: String);
var
  Idx: Integer;
begin
  Idx:=FKeys.IndexOf(AKey);
  if Idx >= 0 then
  begin
    if FKeys.Objects[Idx] IS TJSONString then
    begin
      TJSONString(FKeys.Objects[Idx]).FValue:=AValue;
    end else
    begin
      FKeys.Objects[Idx].Free;
      FKeys.Objects[Idx]:=TJSONString.CreateFrom(AValue);
    end;
  end else
  begin
    Add(AKey, AValue);
  end;
end;

procedure TJSONObject.SetOrAdd(AKey: String; AValue: Boolean);
var
  Idx: Integer;
begin
  Idx:=FKeys.IndexOf(AKey);
  if Idx >= 0 then
  begin
    if FKeys.Objects[Idx] IS TJSONBoolean then
    begin
      TJSONBoolean(FKeys.Objects[Idx]).FValue:=AValue;
    end else
    begin
      FKeys.Objects[Idx].Free;
      FKeys.Objects[Idx]:=TJSONBoolean.CreateFrom(AValue);
    end;
  end else
  begin
    Add(AKey, AValue);
  end;
end;

procedure TJSONObject.SetOrAdd(AKey: String; AValue: Extended);
var
  Idx: Integer;
begin
  Idx:=FKeys.IndexOf(AKey);
  if Idx >= 0 then
  begin
    if FKeys.Objects[Idx] IS TJSONFloat then
    begin
      TJSONFloat(FKeys.Objects[Idx]).FValue:=AValue;
    end else
    begin
      FKeys.Objects[Idx].Free;
      FKeys.Objects[Idx]:=TJSONFloat.CreateFrom(AValue);
    end;
  end else
  begin
    Add(AKey, AValue);
  end;
end;

procedure TJSONObject.SetOrAdd(AKey: String; AValue: TJSONValue);
var
  Idx: Integer;
begin
  Idx:=FKeys.IndexOf(AKey);
  if Idx >= 0 then
  begin
    FKeys.Objects[Idx].Free;
    FKeys.Objects[Idx]:=AValue;
  end else
  begin
    Add(AKey, AValue);
  end;
end;

function TJSONObject.ToString: String;
begin
  Result:=TJSONWriter.Write(Self, jswmCondensed);
end;

procedure TJSONObject.Add(AKey: String; AValue: TJSONValue);
begin
  FKeys.AddObject(AKey, AValue);
end;

procedure TJSONObject.Add(AKey: String);
begin
  Add(AKey, TJSONNull.Create);
end;

procedure TJSONObject.Add(AKey: String; AValue: Int64);
begin
  Add(AKey, TJSONInteger.CreateFrom(AValue));
end;

procedure TJSONObject.Add(AKey, AValue: String);
begin
  Add(AKey, TJSONString.CreateFrom(AValue));
end;

procedure TJSONObject.Add(AKey: String; AValue: Boolean);
begin
  Add(AKey, TJSONBoolean.CreateFrom(AValue));
end;

procedure TJSONObject.AddArray(AKey: String; AArray: TJSONArray);
begin
  Add(AKey, AArray);
end;

function TJSONObject.AddArray(AKey: String): TJSONArray;
begin
  Result:=TJSONArray.Create;
  Add(AKey, Result);
end;

procedure TJSONObject.AddObject(AKey: String; AObject: TJSONObject);
begin
  Add(AKey, AObject);
end;

function TJSONObject.AddObject(AKey: String): TJSONObject;
begin
  Result:=TJSONObject.Create;
  Add(AKey, Result);
end;

procedure TJSONObject.Add(AKey: String; AValue: Extended);
begin
  Add(AKey, TJSONFloat.CreateFrom(AValue));
end;

{ TJSONArray }

constructor TJSONArray.Create;
begin
  inherited Create;

  FValues:=TList.Create;
end;

procedure TJSONArray.Delete(AIndex: Integer);
begin
  if (AIndex >= 0) AND (AIndex < FValues.Count) then
  begin
    TObject(FValues[AIndex]).Free;
    FValues.Delete(AIndex);
  end;
end;

destructor TJSONArray.Destroy;
begin
  Clear;

  FreeAndNil(FValues);

  inherited;
end;

procedure TJSONArray.Exchange(AIndex1, AIndex2: Integer);
begin
  FValues.Exchange(AIndex1, AIndex2);
end;

procedure TJSONArray.Clear;
var
  I: Integer;
begin
  try
    for I:=0 to FValues.Count - 1 do
    begin
      TObject(FValues[I]).Free;
    end;
  finally
    FValues.Clear;
  end;
end;

procedure TJSONArray.Add(AValue: TJSONValue);
begin
  FValues.Add(AValue);
end;

procedure TJSONArray.Add;
begin
  Add(TJSONNull.Create);
end;

procedure TJSONArray.Add(AValue: String);
begin
  Add(TJSONString.CreateFrom(AValue));
end;

procedure TJSONArray.Add(AValue: Int64);
begin
  Add(TJSONInteger.CreateFrom(AValue));
end;

procedure TJSONArray.Add(AValue: Boolean);
begin
  Add(TJSONBoolean.CreateFrom(AValue));
end;

procedure TJSONArray.AddArray(AArray: TJSONArray);
begin
  if Assigned(AArray) then
    Add(AArray);
end;

function TJSONArray.AddArray: TJSONArray;
begin
  Result:=TJSONArray.Create;
  Add(Result);
end;

procedure TJSONArray.AddObject(AObject: TJSONObject);
begin
  if Assigned(AObject) then
    Add(AObject);
end;

function TJSONArray.AddObject: TJSONObject;
begin
  Result:=TJSONObject.Create;
  Add(Result);
end;

function TJSONArray.AddObject(AKey: String; AValue: TJSONValue): TJSONObject;
begin
  Result:=TJSONObject.Create;
  Result.Add(AKey, AValue);
  Add(Result);
end;

procedure TJSONArray.Add(AValue: Extended);
begin
  Add(TJSONFloat.CreateFrom(AValue));
end;

function TJSONArray.GetAsArray: TJSONArray;
begin
  Result:=Self;
end;

function TJSONArray.GetAsBoolean: Boolean;
begin
  Result:=False;
end;

function TJSONArray.GetAsFloat: Extended;
begin
  Result:=0.0;
end;

function TJSONArray.GetAsInteger: Int64;
begin
  Result:=0;
end;

function TJSONArray.GetAsObject: TJSONObject;
begin
  Result:=nil;
end;

function TJSONArray.GetAsString: String;
begin
  Result:='';
end;

function TJSONArray.GetClass: TJSONClass;
begin
  Result:=TJSONArray;
end;

function TJSONArray.GetCount: Integer;
begin
  Result:=FValues.Count;
end;

function TJSONArray.GetItem(Index: Integer): TJSONValue;
begin
  Result:=nil;

  if (Index >= 0) AND (Index < FValues.Count) then
  begin
    Result:=TJSONValue(FValues[Index]);
  end;
end;

procedure TJSONArray.Insert(AIndex: Integer; AValue: TJSONValue);
begin
  if Assigned(AValue) then
  begin
    FValues.Insert(AIndex, AValue);
  end;
end;

function TJSONArray.IsEmpty: Boolean;
begin
  Result:=FValues.Count = 0;
end;

procedure TJSONArray.Move(ACurIndex, ANewIndex: Integer);
begin
  FValues.Move(ACurIndex, ANewIndex);
end;

procedure TJSONArray.Replace(AIndex: Integer; AValue: TJSONValue);
begin
  if Assigned(AValue) AND (AIndex >= 0) AND (AIndex < FValues.Count) then
  begin
    TObject(FValues[AIndex]).Free;
    FValues[AIndex]:=AValue;
  end;
end;

{ TJSONTemplatesList }

constructor TJSONTemplatesList.Create;
begin
  inherited Create;
end;

destructor TJSONTemplatesList.Destroy;
var
  I: Integer;
begin
  for I:=0 to Count - 1 do
    Objects[I].Free;

  inherited;
end;

function TJSONTemplatesList.GetTemplate(Name: String): TJSONTemplate;
var
  Idx: Integer;
begin
  Result:=nil;

  Idx:=IndexOf(AnsiLowerCase(Name));
  if Idx >= 0 then
    Result:=TJSONTemplate(Objects[Idx]);
end;

function TJSONTemplatesList.AddTemplates(AName: String; ATemplate: TJSONTemplate): Integer;
begin
  Result:=AddObject(AnsiLowerCase(AName), ATemplate);
end;

{ TJSONTemplate }

constructor TJSONTemplate.Create(AName: String);
begin
  inherited Create;

  FName:=AName;
  FJSON:=TJSON.CreateObjectRoot;
  FCritSec:=TCriticalSection.Create;
  FLastAdded:=-1;

  SetLength(FValues, 0);
end;

destructor TJSONTemplate.Destroy;
begin
  Cleanup;

  FreeAndNil(FJSON);
  FreeAndNil(FCritSec);

  inherited;
end;

procedure TJSONTemplate.DoTemplateFillCallback(ATemplateName, AKeyName: String; var AValue: TJSONValue);
begin
  if Assigned(FOnTemplateFillCallback) then
    FOnTemplateFillCallback(ATemplateName, AKeyName, AValue);
end;

function TJSONTemplate.Empty(AUseDefaults: Boolean = True): TJSON;
var
  I: Integer;
  V: TJSONValue;
begin
  FCritSec.Enter;
  try
    FJSON.RootNewObject;
    try
      for I:=Low(FValues) to High(FValues) do
      begin
        V:=nil;

        if ((tfOmitEmpty IN FFlags) AND NOT (AUseDefaults AND Assigned(FValues[I].Default))) AND NOT (FValues[I].Typ IN JSON_ADVANCED_TEMPLATE_TYPES) then
        begin
          Continue;
        end else
        begin
          if AUseDefaults AND Assigned(FValues[I].Default) then
          begin
            V:=FValues[I].Default.Copy;
          end else
          case FValues[I].Typ of
            jttNull: V:=TJSONNull.Create;
            jttInteger: V:=TJSONInteger.CreateFrom(0);
            jttFloat: V:=TJSONFloat.CreateFrom(0.0);
            jttString: V:=TJSONString.CreateFrom('');
            jttBoolean: V:=TJSONBoolean.CreateFrom(False);
            jttObject: V:=TJSONObject.Create;
            jttArray: V:=TJSONArray.Create;
          end;
        end;

        if Assigned(V) then
        begin
          if (JSON_TYPE_TO_TEMPLATE_TYPE[V.Typ] = FValues[I].Typ) then
            FJSON.AsObject.Add(FValues[I].Name, V)
          else
            raise Exception.Create(Format(RCS_FIELD_VALUE_TYPE_MISMATCH, [JSON_TEMPLATE_TYPE_STRINGS[FValues[I].Typ], JSON_TYPE_STRINGS[V.Typ]]));
        end else
        begin
          case FValues[I].Typ of
            jttName: FJSON.AsObject.Add(FValues[I].Name, TJSONString.CreateFrom(FName));
            jttUnixTime: FJSON.AsObject.Add(FValues[I].Name, TJSONInteger.CreateFrom(DateTimeToUnix(Now)));
            jttTemplate: FJSON.AsObject.Add(FValues[I].Name, TJSONObject.CreateFrom(FValues[I].Nested.Empty.AsObject));
            else FJSON.AsObject.Add(FValues[I].Name, TJSONNull.Create);
          end;
        end;
      end;
    finally
      Result:=FJSON;
    end;
  finally
    FCritSec.Leave;
  end;
end;

function TJSONTemplate.Add(AName: String; AType: TJSONTemplateType; ATemplate: TJSONTemplate; ACallback: TJSONTemplateFillCallback): TJSONTemplate;
var
  I: Integer;
begin
  Result:=Self;

  FCritSec.Enter;
  try
    SetLength(FValues, Length(FValues) + 1);
    FLastAdded:=High(FValues);

    for I:=Low(FValues) to High(FValues) do
      if SameText(AName, FValues[I].Name) then
         raise Exception.Create(RCS_FIELD_NAME_ALREADY_EXISTS);

    FValues[High(FValues)].Name:=AName;
    FValues[High(FValues)].Typ:=AType;
    FValues[High(FValues)].Nested:=ATemplate;
    FValues[High(FValues)].Callback:=ACallback;
  finally
    FCritSec.Leave;
  end;
end;

function TJSONTemplate.Add(AName: String; AType: TJSONType): TJSONTemplate;
begin
  Result:=Add(AName, JSON_TYPE_TO_TEMPLATE_TYPE[AType], nil, nil);
end;

function TJSONTemplate.Add(AName: String; AType: TJSONTemplateType): TJSONTemplate;
begin
  Result:=Add(AName, AType, nil, nil);
end;

function TJSONTemplate.Add(AName: String; ATemplate: TJSONTemplate): TJSONTemplate;
begin
  if Assigned(ATemplate) then
    Result:=Add(AName, jttTemplate, ATemplate, nil)
  else
    raise Exception.Create(RCS_TEMPLATE_REQUIRED);
end;

function TJSONTemplate.Add(AName: String; ATemplateName: String): TJSONTemplate;
begin
  if Length(Trim(ATemplateName)) = 0 then
    raise Exception.Create(Format(RCS_TEMPLATE_NAME_REQUIRED, [AName]));

  if NOT Assigned(TJSON.Template(ATemplateName)) then
    raise Exception.Create(Format(RCS_TEMPLATE_NAME_NOT_FOUND, [ATemplateName]));

  Result:=Add(AName, jttTemplate, TJSON.Template(ATemplateName), nil);
end;

function TJSONTemplate.Add(AName: String; ACallback: TJSONTemplateFillCallback): TJSONTemplate;
begin
  Result:=Add(AName, jttCallback, nil, ACallback);
end;

function TJSONTemplate.Add(AField: TJSONTemplateField): TJSONTemplate;
begin
  Result:=Add(AField.Name, AField.Typ, AField.Nested, AField.Callback);
end;

function TJSONTemplate.Default(AValue: TJSONValue): TJSONTemplate;
begin
  Result:=Self;

  if FLastAdded >= 0 then
  begin
    if Assigned(FValues[FLastAdded].Default) then
      FValues[FLastAdded].Default.Free;
    FValues[FLastAdded].Default:=AValue;
  end;
end;

procedure TJSONTemplate.Cleanup;
var
  I: Integer;
begin
  for I:=Low(FValues) to High(FValues) do
    if Assigned(FValues[I].Default) then
      FreeAndNil(FValues[I].Default);
end;

procedure TJSONTemplate.Clear;
begin
  FJSON.RootNewObject;
end;

function TJSONTemplate.Fill(AValues: Array of const): TJSON;
var
  I, Skipped: Integer;
  V: TJSONValue;
begin
  FCritSec.Enter;
  try
    FJSON.RootNewObject;
    try
      if GetTemplateFieldCount <> Length(AValues) then
        raise Exception.Create(RCS_FIELD_COUNT_MISMATCH);

      Skipped:=0;
      for I:=Low(FValues) to High(FValues) do
      begin
        V:=nil;

        if FValues[I].Typ IN JSON_AUTOFILL_TEMPLATE_TYPES then
        begin
          Inc(Skipped);

          if FValues[I].Typ = jttCallback then
          begin
            if Assigned(FValues[I].Callback) then
              FValues[I].Callback(FName, FValues[I].Name, V)
            else
              DoTemplateFillCallback(FName, FValues[I].Name, V);
          end;
        end else
        case AValues[I - Skipped].VType of
          vtInteger: V:=TJSONInteger.CreateFrom(AValues[I - Skipped].VInteger);
          vtBoolean: V:=TJSONBoolean.CreateFrom(AValues[I - Skipped].VBoolean);
          vtChar: V:=TJSONString.CreateFrom(String(AValues[I - Skipped].VChar));
          vtExtended: V:=TJSONFloat.CreateFrom(AValues[I - Skipped].VExtended^);
          vtString: V:=TJSONString.CreateFrom(String(AValues[I - Skipped].VString^));
          vtPointer:
          begin
            if Assigned(AValues[I - Skipped].VPointer) then
              V:=TJSONNull.Create;
          end;
          vtPChar: V:=TJSONString.CreateFrom(String(AnsiString(AValues[I - Skipped].VPChar^)));
          vtObject:
          begin
            if Assigned(AValues[I - Skipped].VObject) AND (AValues[I - Skipped].VObject IS TJSON) AND (TJSON(AValues[I - Skipped].VObject).IsObject) then
              V:=TJSONObject.CreateFrom(TJSON(AValues[I - Skipped].VObject).AsObject)
            else
              V:=TJSONNull.Create;
          end;
          vtClass: V:=TJSONNull.Create;
          vtWideChar: V:=TJSONString.CreateFrom(AValues[I - Skipped].VWideChar);
          vtPWideChar: V:=TJSONString.CreateFrom(String(AValues[I - Skipped].VPWideChar));
          vtAnsiString: V:=TJSONString.CreateFrom(String(AnsiString(AValues[I - Skipped].VAnsiString)));
          vtCurrency: V:=TJSONFloat.CreateFrom(AValues[I - Skipped].VCurrency^);
          vtVariant: V:=TJSONNull.Create;
          vtInterface: V:=TJSONNull.Create;
          vtWideString: V:=TJSONString.CreateFrom(String(PWideChar(AValues[I - Skipped].VWideString)));
          vtInt64: V:=TJSONInteger.CreateFrom(AValues[I - Skipped].VInt64^);
          vtUnicodeString: V:=TJSONString.CreateFrom(String(AValues[I - Skipped].VUnicodeString));
        end;

        if Assigned(V) then
        begin
          if (JSON_TYPE_TO_TEMPLATE_TYPE[V.Typ] = FValues[I].Typ) OR (V.Typ = jtNull) OR (FValues[I].Typ IN [jttTemplate, jttCallback]) then
            FJSON.AsObject.Add(FValues[I].Name, V)
          else
            raise Exception.Create(Format(RCS_FIELD_VALUE_TYPE_MISMATCH, [JSON_TEMPLATE_TYPE_STRINGS[FValues[I].Typ], JSON_TYPE_STRINGS[V.Typ]]));
        end else
        begin
          if NOT (tfOmitEmpty IN FFlags) then
          case FValues[I].Typ of
            jttName: FJSON.AsObject.Add(FValues[I].Name, TJSONString.CreateFrom(FName));
            jttUnixTime: FJSON.AsObject.Add(FValues[I].Name, TJSONInteger.CreateFrom(DateTimeToUnix(Now)));
            jttTemplate: FJSON.AsObject.Add(FValues[I].Name, TJSONObject.CreateFrom(FValues[I].Nested.Empty.AsObject));
            else FJSON.AsObject.Add(FValues[I].Name, TJSONNull.Create);
          end;
        end;
      end;
    finally
      Result:=FJSON;
    end;
  finally
    FCritSec.Leave;
  end;
end;

function TJSONTemplate.SetFlag(AFlag: TJSONTemplateFlag): TJSONTemplate;
begin
  Result:=Self;

  FFlags:=FFlags + [AFlag];
end;

function TJSONTemplate.GetTemplateFieldCount: Integer;
var
  I: Integer;
begin
  Result:=0;

  for I:=Low(FValues) to High(FValues) do
    if NOT (FValues[I].Typ IN JSON_AUTOFILL_TEMPLATE_TYPES) then
      Inc(Result);
end;

function TJSONTemplate.SetFlags(AFlags: TJSONTemplateFlags): TJSONTemplate;
begin
  Result:=Self;

  FFlags:=AFlags;
end;

function TJSONTemplate.SetValue(AName: String; const AValue: Variant): Boolean;
var
  V: TJSONValue;
  I: Integer;
begin
  Result:=False;

  case VarType(AValue) of
    varSmallInt,
    varShortInt,
    varInteger,
    varByte,
    varWord,
    varLongWord,
    varInt64,
    varUInt64: V:=TJSONInteger.CreateFrom(AValue);

    varSingle,
    varDouble,
    varCurrency,
    varDate: V:=TJSONFloat.CreateFrom(AValue);

    varBoolean: V:=TJSONBoolean.CreateFrom(AValue);

    varOleStr,
    varString,
    varUString: V:=TJSONString.CreateFrom(AValue);

    else
      V:=TJSONNull.Create;
  end;

  for I:=0 to High(FValues) do
  begin
    if AnsiSameText(FValues[I].Name, AName) AND (FValues[I].Typ = JSON_TYPE_TO_TEMPLATE_TYPE[V.Typ]) then
    begin
      FJSON.AsObject.SetOrAdd(AName, V);
      Result:=True;
      Break;
    end;
  end;
end;

initialization
  GlobTemplates:=TJSONTemplatesList.Create;

finalization
  FreeAndNil(GlobTemplates);

end.
