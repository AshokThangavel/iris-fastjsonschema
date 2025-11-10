Include %occIO

Class FastJsonSchema.Compiler Extends %RegisteredObject
{

Property Name As %String;

Property Schema As %DynamicAbstractObject;

Property KeepSource As %Boolean [ InitialExpression = 0, Internal ];

/// Holds the schema definition for each property when that property's code is generated.
Property PropertySchema As %DynamicObject [ Internal ];

ClassMethod Compile(pSchemaName = "", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 0)
{
	d ..OnBeforeCompile()
	s st=..%New(pSchemaName, pSchema, pKeepSource).CompileInternal()
	d ..OnAfterCompile()
	q st
}

Method CompileInternal() As %Status [ Internal, Private ]
{
	d $SYSTEM.Process.Undefined(2)
	#dim sc As %Status

	k %fjscode,%uniquecheck
	try{
		d ..basicinfo()
		d ..configfunc()
		d ..GenerateCode()
		s sc= ..Savefjs()
	}
	catch ex{
		s sc=ex.AsStatus()
	}
	q sc
}

Method GenerateCode(pSchemaObj As %DynamicAbstractObject = "") [ Private ]
{
    s schema = $s(pSchemaObj'="": pSchemaObj, 1: ..Schema)
    d ..CheckRequiredProps(schema)
    s isarrexecute=0
    i schema.type="array" {
	    q:'schema.%IsDefined("items")
	    $$$CWriteLine(" ;validate array items schema",..KeepSource)
	    if 'schema.items.%IsA("%DynamicArray"){ ;single object in array
	   		s ..PropertySchema=schema
	   		d $method(,"singleArr")
    		q
    	}
	    s iter = schema.items.%GetIterator()
	    s isarrexecute=1
    }
    else {
	    s iter = schema.properties.%GetIterator()
    }
    while iter.%GetNext(.prop, .PropertySchema) {
	    Set ..PropertySchema = PropertySchema
        $$$CWriteLine(" ;validate "_prop_" schema propery",..KeepSource)
        $$$CWriteLine(" ;description given in schema: "_PropertySchema.description_" ",..KeepSource&&(PropertySchema.%IsDefined("description")))
        s type=PropertySchema.type
        i isarrexecute s prop="%Get("_prop_")"
        i $iso(type){ ;array of types
            d ..MultiTypePropValidate(prop)
            s arriter = PropertySchema.type.iterator()
			while arriter.%GetNext(,.arrPropType) {
				$$$CWriteLine(" ;property "_prop_" and it's "_arrPropType_" validation",..KeepSource)
				i arrPropType="object" {
                	d $method(,$$$CurrentMethod, PropertySchema)
            	}
            	elseif arrPropType="array" {
	            	d $method(,$$$CurrentMethod, PropertySchema)
            	}
            	else{
            		d:arrPropType'="" $method(, arrPropType, prop, 1)
            	}
			}
        }
        else {
            i type="object" {
                d $method(,$$$CurrentMethod, PropertySchema)
            }
            elseif type="array" {
	            d $method(,$$$CurrentMethod, PropertySchema)
            }
            else{
            	d:type'="" $method(,type, prop)
            }
        }
    }
}

Method MultiTypePropValidate(prop) [ Private ]
{
	s (c,dt)=""
	s iter = ..PropertySchema.type.iterator()
	while iter.%GetNext(,.val) {s c=c_..CodeType(val),dt=dt_val_","}
	$$$WriteLine($$$FormatText(" i '$find(%1,%JSON.%GetTypeCodeOf(""%2"")) q $$Error^%apiOBJ(5001,""%3 datatype is should be %4"")", c, prop, prop, $replace($e(dt,1,*-1),","," or ")))
}

Method singleArr() [ Private ]
{
	$$$WriteLine(" i '$iso(%JSON)||('%JSON.%IsA(""%DynamicArray"")) q $$Error^%apiOBJ(5001,""given input is not array"")")
	d ..GenerateLengthCode()
	s PropertySchema=..PropertySchema
	s type =PropertySchema.items.type
	Set ..PropertySchema =PropertySchema.items
	d ..GenerateuniqueItemsCode()
	d:type'="" $Method(,type,"%Get(0)")
	s ..PropertySchema=PropertySchema
}

Method CheckRequiredProps(pSchemaObj) [ Private ]
{
	s schema = $s(pSchemaObj'="": pSchemaObj, 1: ..Schema)
	ret:'schema.%IsDefined("required")
	s iter = schema.required.iterator()
	$$$CWriteLine(" ;validate the required schema propery is are available",..KeepSource)
	$$$WriteLine(" s missing=""""")
	while iter.%GetNext(,.val) {
		$$$WriteLine(" s:'%JSON.%IsDefined("""_val_""") missing=missing_"""_val_",""")
	}
	$$$WriteLine(" q:missing'="""" $$Error^%apiOBJ(5001,""Required properties missing: ""_$e(missing,1,*-1))")
	q
}

Method string(prop As %String = "", SkipGenerate = 0)
{
	$$$CWriteLine(" ;string method validation for "_prop,..KeepSource)
	$$$CWriteLine(" i %JSON.%GetTypeCodeOf("""_$S(prop["%Get(":+$P(prop,"%Get(",2),1:prop)_""")'=6 q $$Error^%apiOBJ(5001,"""_$S(prop["%Get(":"",1:prop)_" must be a string type"")",'SkipGenerate)
	d ..GenerateLengthCode(prop, $$$CurrentMethod)
	d ..GeneratePatternCode(prop)
	d ..GenerateEnumCode(prop)
	d ..GenerateFormatCode(prop)
	d ..GenerateConstCode(prop)
	d ..GeneateContentMediaTypeCode(prop)
}

/// TODO: additional checks for number
Method number(prop As %String, SkipGenerate = 0)
{
	d ..integer(prop, SkipGenerate)
}

Method integer(prop As %String, SkipGenerate = 0)
{
	$$$CWriteLine(" ;integer method validation for "_prop,..KeepSource)
	$$$CWriteLine(" i %JSON.%GetTypeCodeOf("""_$S(prop["%Get(":+$P(prop,"%Get(",2),1:prop)_""")'=9 q $$Error^%apiOBJ(5001,"""_$S(prop["%Get(":"",1:prop)_" datatype not match with the json value"")",'SkipGenerate)
	d ..GenerateLengthCode(prop, $$$CurrentMethod)
	d ..GenerateEnumCode(prop)
	d ..GenerateConstCode(prop)
	d ..GenerateMultipleOfCode(prop)
}

Method boolean(prop As %String, SkipGenerate = 0)
{
	i 'SkipGenerate{
		$$$WriteLine(" i %JSON.%GetTypeCodeOf("""_prop_""")'=4 q $$Error^%apiOBJ(5001,"""_prop_" datatype not match with the json value"")")
		$$$WriteLine(" s bv=%JSON."_prop_" if $c(0,1)'[$c(bv) q $$Error^%apiOBJ(5001,"""_prop_" is not boolean value"")")
	}
	d ..GenerateConstCode(prop)
	d ..GenerateEnumCode(prop)
	///TODO
	d ..GenerateIFThenElseCode()
}

Method null(prop As %String, SkipGenerate = 0)
{
	s PropertySchema=..PropertySchema
	$$$CWriteLine(" i %JSON.%GetTypeCodeOf("""_prop_""")'=2 q """_$S(prop["%Get(":"",1:prop)_" datatype not match with the json value""",'SkipGenerate)
	d ..GenerateEnumCode(prop)
	d ..GenerateConstCode(prop)
}

Method array(prop As %String, SkipGenerate = 0)
{
}

/// Proeprty max,min and additional length checks
/// type - is mainly used for multi types e.g "type":["string","integer"]
Method GenerateLengthCode(prop As %String = "", type As %String = "")
{
    s (min,amx,lenExpr)=""
	s PropertySchema = ..PropertySchema
	s type=$Select(type'="":type,1:PropertySchema.type)
    i type= "string" {
        s:PropertySchema.%IsDefined("minLength") min = PropertySchema.minLength
        s:PropertySchema.%IsDefined("maxLength") max = PropertySchema.maxLength
        s lenExpr = "$l(%JSON."_prop_")"
    }
    elseif type = "integer"!(PropertySchema.type="number") {
		s:PropertySchema.%IsDefined("exclusiveMinimum") emin = PropertySchema.exclusiveMinimum
		s:PropertySchema.%IsDefined("exclusiveMaximum") emax = PropertySchema.exclusiveMaximum
    	s min = $Select(emin'="": emin,1:PropertySchema.minimum)
		s max = $Select(emax'="":emax,1:PropertySchema.maximum)
        s lenExpr = "$l(%JSON."_prop_")"
    }
    elseif type = "array" {
        i PropertySchema.%IsDefined("minItems") s min = PropertySchema.minItems
        i PropertySchema.%IsDefined("maxItems") s max = PropertySchema.maxItems
        i prop'="" {
	        s lenExpr="%JSON."_prop_".%Size()"
        }
        else {
	        s lenExpr="%JSON.%Size()"
        }
    }
    elseif type = "object" {
        s:PropertySchema.%IsDefined("minProperties") min=PropertySchema.minProperties
        s:PropertySchema.%IsDefined("maxProperties") max=PropertySchema.maxProperties
        s lenExpr="%JSON."_prop_".%Size()"
    }
    else {
        q
    }
    s:prop["%Get" prop=""
    i (min'=""),(max'="") {
        $$$WriteLine($$$FormatText(" i '$IsValidnum(%1,,%2,%3) q $$Error^%apiOBJ(5001,""%4Invalid length: value must be between %5 to %6"")", lenExpr, +min, max, prop, +min, max))
    }
    elseif min'=""&&(max=""){
        $$$WriteLine($$$FormatText(" i '$IsValidnum(%1,,%2) q $$Error^%apiOBJ(5001,""%3Invalid length: value must be greater than or equal to %4"")", lenExpr, +min, prop, +min))
    }
    elseif min=""&&(max'=""){
       $$$WriteLine($$$FormatText(" i '$IsValidnum(%1,,0,%2) q $$Error^%apiOBJ(5001,""%3Invalid length: value must be less than or equal to %4"")", lenExpr, max, prop, max))
    }
}

Method GenerateuniqueItemsCode(prop As %String = "", type As %String = "")
{
	q:'..Schema.uniqueItems
	s %uniquecheck=1
	$$$CWriteLine(" ;validate uniqueItems check",..KeepSource)
	$$$WriteLine(" s st=$$unqiueItemsCheck(%JSON) i 'st return st")
	q
}

Method UniqueCheck() [ Internal ]
{
	$$$WriteLine("unqiueItemsCheck(%JSON){")
	$$$WriteLine(" s iter=%JSON.%GetIterator()")
	$$$WriteLine(" while iter.%GetNext(,.val) {")
	$$$WriteLine("	i $d(uniqueCheck(val)) ret ""Each value must be unique. Duplicate found for ""_val")
	$$$WriteLine("	s uniqueCheck(val)=""""")
	$$$WriteLine(" }")
	$$$WriteLine(" q 1")
	$$$WriteLine("}")
}

Method GenerateEnumCode(prop As %String = "") [ Internal ]
{
	s PropertySchema = ..PropertySchema
	q:'PropertySchema.%IsDefined("enum")
	$$$CWriteLine(" ; enum check",..KeepSource)
	s iter = PropertySchema.enum.%GetIterator()
	s c="$lb(" while iter.%GetNext(,.v) {s c=c_$case($isvalidnum(v),1:v,:""""_v_"""")_","} s c=$E(c,1,*-1)_")"
	i prop'="",(prop'["%Get") {
		$$$WriteLine(" i '$lf("_c_",%JSON."_prop_") q $$Error^%apiOBJ(5001,""enum not match with "_prop_" json data"")")
	}
	else{
		$$$WriteLine(" i %JSON.%IsA(""%DynamicArray"") s enumsval="_c_" s iter=%JSON.%GetIterator() while iter.%GetNext(,.v){ i '$lf(enumsval,v) ret ""input not match with the schema enum values"" }")
	}
}

Method GeneratePatternCode(prop As %String = "")
{
	s PropertySchema = ..PropertySchema
	q:'PropertySchema.%IsDefined("pattern")
	s pat = PropertySchema.pattern
	$$$CWriteLine(" ; pattern check",..KeepSource)
	$$$WriteLine($$$FormatText(" i '$match(%JSON.%1,""%2"") q $$Error^%apiOBJ(5001,""pattern not match with %3 json data"")", prop, pat, prop))
}

Method GenerateFormatCode(prop As %String)
{
	q:'..PropertySchema.%IsDefined("format")
	s format = ..PropertySchema.format
	$$$CWriteLine(" ; "_format_" format check",..KeepSource)
	s regex = ..RegexFormats(format)
	$$$CWriteLine(" i '$match(%JSON."_prop_","""_regex_""") q $$Error^%apiOBJ(5001,"""_format_" format not matched"")",(regex'=""))
}

// TODO: implement multipleOf

Method GenerateMultipleOfCode(prop)
{
	q:'..PropertySchema.%IsDefined("multipleOf")
}

Method GenerateConstCode(prop)
{
	q:'..PropertySchema.%IsDefined("const")
	s PropertySchema = ..PropertySchema
	s const = PropertySchema."const"
	i PropertySchema.type="boolean" {
		s mustbe=$case(const,1:"true",:"false")
	}
	elseif PropertySchema.type="null" {
		s mustbe=$Select(const="":"null",1:const)
	}
	else {
		s mustbe=const
	}
	$$$WriteLine($$$FormatText(" i %JSON.%1'=""%2"" q $$Error^%apiOBJ(5001,""%3 value must be %4"")", prop, const, prop, mustbe))
}

/// TODO:
Method GenerateIFThenElseCode()
{

	; need to work with conditional check in boolean
	/*
	"if": {
    "properties": { "isPremium": { "const": true } }
  },
  "then": {
    "required": ["planID", "billingCycle"]
  },
  "else": {
    "required": ["planID"]
  }
	*/
}

Method CodeType(datatype) [ CodeMode = expression, Internal ]
{
$case(datatype,"string":6,"integer":9,"number":9,"boolean":4,"null":2,:"")
}

ClassMethod RegexFormats(format) As %String [ CodeMode = expression, Internal ]
{
$case(format,
"email":"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$",
"uri":"^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$",
"date":"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$",
"datetime":"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):[0-5]\d:[0-5]\d(Z|[+-]([01]\d|2[0-3]):?[0-5]\d)?$",
"uuid":"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$",
"ipv4":"^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$",
"ipv6":"^(([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){1,7}:)|(([0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,5}(:[0-9A-Fa-f]{1,4}){1,2})|(([0-9A-Fa-f]{1,4}:){1,4}(:[0-9A-Fa-f]{1,4}){1,3})|(([0-9A-Fa-f]{1,4}:){1,3}(:[0-9A-Fa-f]{1,4}){1,4})|(([0-9A-Fa-f]{1,4}:){1,2}(:[0-9A-Fa-f]{1,4}){1,5})|([0-9A-Fa-f]{1,4}:((:[0-9A-Fa-f]{1,4}){1,6}))|(:((:[0-9A-Fa-f]{1,4}){1,7}|:))$",
"hostname":"^(?=.{1,253}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.(?!-)[A-Za-z0-9-]{1,63}(?<!-))*\.?$",
"base64":"(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$",
:"")
}

/// TODO:
Method oneOf(PropertySchema As %DynamicObject, prop As %String)
{
}

Method GeneateContentMediaTypeCode(PropertySchema As %DynamicObject, prop As %String) [ Internal, Private ]
{
	q:'..PropertySchema.%IsDefined("contentMediaType")
}

Method configfunc() [ Internal, Private ]
{
	$$$WriteLine("%validate(%JSON)")
	$$$WriteLine(" n (%JSON)")
	$$$WriteLine(" s $et=""q $ze""")
	$$$WriteLine(" s:'$iso(%JSON) %JSON={}.%FromJSON(%JSON)")
}

ClassMethod %INCLUDE(pCode As %String)
{
	#define CWriteLine(%code,%s)	s:%s %fjscode($i(%fjscode))=%code
	#define WriteLine(%code)	s %fjscode($i(%fjscode))=%code
}

Method basicinfo() [ Internal, Private ]
{
	q:'..KeepSource
	$$$WriteLine(" ;Generated by "_$classname())
	$$$WriteLine(" ;$schema: "_..Schema."$schema")
	$$$WriteLine(" ;$id: "_..Schema."$id")
	$$$WriteLine(" ;title: "_..Schema.title)
	$$$WriteLine(" ;description: "_..Schema.description)
}

Method Savefjs() [ Internal, Private ]
{
	$$$WriteLine(" q 1")
	d:%uniquecheck ..UniqueCheck()
	i ..KeepSource {
		s rot="fjsschema."_..Name_".int"
		//do:##class(%Routine).%Exists($lb(rot)) ##class(%Routine).%Delete($lb(rot))
		s routine = ##class(%Routine).%New(rot)
		s routine.Generated=1
		i $iso(routine) f i=1:1:%fjscode d routine.WriteLine(%fjscode(i))
		s rtn=routine.%Save()
		d routine.Compile()
	}
	else {
		s %fjscode(0)=%fjscode
		s rtn=$COMPILE(%fjscode,0,errs,,,,"fjsschema."_..Name)
    	i rtn=0 {w "compilation successfull",! s rtn=1}
    	else {w "compilation failred return code: ",rtn,! zw errs s rtn=0}
	}
	ret rtn
}

Method %OnNew(pSchemaName As %String, pSchema As %DynamicAbstractObject, pKeepSource As %Boolean) As %Status
{
	s ..Name = pSchemaName
	s ..Schema = pSchema
	s ..KeepSource = pKeepSource
	q 1
}

/// This callback method is invoked by the <METHOD>Compile</METHOD>
ClassMethod OnBeforeCompile()
{
}

/// This callback method is invoked by the <METHOD>Compile</METHOD>
ClassMethod OnAfterCompile()
{
}

}
