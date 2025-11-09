Include %occIO

Class FastJsonSchema.Compiler Extends %RegisteredObject
{

Property Name As %String;

Property Schema As %DynamicAbstractObject;

Property ProcessesFields [ MultiDimensional ];

Property KeepSource As %Boolean [ InitialExpression = 0 ];

/// Holds the schema definition for each property when that property's code is generated.
Property PropertySchema As %DynamicObject;

ClassMethod Compile(pSchemaName = "", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 0) [ CodeMode = expression, Internal ]
{
..%New(pSchemaName, pSchema, pKeepSource).CompileInternal()
}

Method CompileInternal() As %Status [ Internal, Private ]
{
	d $SYSTEM.Process.Undefined(2)
	#dim sc As %Status

	k %fjscode
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
        s:..KeepSource %fjscode($i(%fjscode))=" ;validate "_prop_" schema propery"
        s:..KeepSource&&(PropertySchema.%IsDefined("description")) %fjscode($i(%fjscode))=" ;description given in schema: "_PropertySchema.description_" "
        s type=PropertySchema.type
        i isarrexecute s prop="%Get("_prop_")"
        i $iso(type){ ;array of types
            d ..MultiTypePropValidate(prop)
            s arriter = PropertySchema.type.iterator()
			while arriter.%GetNext(,.arrPropType) {
				s:..KeepSource %fjscode($i(%fjscode))=" ;property "_prop_" and it's "_arrPropType_" validation"
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
	set %fjscode($i(%fjscode))=$$$FormatText(" i '$find(%1,%JSON.%GetTypeCodeOf(""%2"")) q ""%3 datatype is should be %4""", c, prop, prop, $replace($e(dt,1,*-1),","," or "))
}

Method singleArr() [ Private ]
{
	s %fjscode($i(%fjscode))=" i '$iso(%JSON)||('%JSON.%IsA(""%DynamicArray"")) q ""given input is not array"""
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
	s:..KeepSource %fjscode($i(%fjscode))=" ;validate the required schema propery is are available"
	s %fjscode($i(%fjscode))=" s missing="""""
	while iter.%GetNext(,.val) {
		s %fjscode($i(%fjscode))=" s:'%JSON.%IsDefined("""_val_""") missing=missing_"""_val_","""
	}
	s %fjscode($i(%fjscode))=" q:missing'="""" ""Required properties missing: ""_$e(missing,1,*-1)_"""" "
	q
}

Method string(prop As %String = "", SkipGenerate = 0) [ Private ]
{
	s:'SkipGenerate %fjscode($i(%fjscode))=" i %JSON.%GetTypeCodeOf("""_$S(prop["%Get(":+$P(prop,"%Get(",2),1:prop)_""")'=6 q """_prop_" must be a string type"""
	d ..GenerateLengthCode(prop,"string")
	d ..GeneratePatternCode(prop)
	d ..GenerateEnumCode(prop)
	d ..GenerateFormatCode(prop)
	d ..GenerateConstCode(prop)
	d ..GeneateContentMediaTypeCode(prop)
}

/// TODO: additional checks for number
Method number(prop As %String, SkipGenerate = 0) [ Private ]
{
	d ..integer(prop, SkipGenerate)
}

Method integer(prop As %String, SkipGenerate = 0) [ Private ]
{
	s:'SkipGenerate %fjscode($i(%fjscode))=" i %JSON.%GetTypeCodeOf("""_$S(prop["%Get(":+$P(prop,"%Get(",2),1:prop)_""")'=9 q """_prop_" datatype not match with the json value"""
	d ..GenerateLengthCode(prop,"integer")
	d ..GenerateEnumCode(prop)
	d ..GenerateConstCode(prop)
	d ..GenerateMultipleOfCode(prop)
}

Method boolean(prop As %String, SkipGenerate = 0) [ Private ]
{
	i 'SkipGenerate{
		s %fjscode($i(%fjscode))=" i %JSON.%GetTypeCodeOf("""_prop_""")'=4 q """_prop_" datatype not match with the json value"""
		s %fjscode($i(%fjscode))=" s bv=%JSON."_prop_" if $c(0,1)'[$c(bv) q "" "_prop_" is not boolean value"""
	}
	d ..GenerateConstCode(prop)
	d ..GenerateEnumCode(prop)
	///TODO
	d ..GenerateIFThenElseCode()
}

Method null(prop As %String, SkipGenerate = 0) [ Private ]
{
	s PropertySchema=..PropertySchema
	s:'SkipGenerate %fjscode($i(%fjscode))=" i %JSON.%GetTypeCodeOf("""_prop_""")'=2 q """_prop_" datatype not match with the json value"""
	d ..GenerateEnumCode(prop)
	d ..GenerateConstCode(prop)
}

Method array(prop As %String, SkipGenerate = 0) [ Private ]
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
    i (min'="")!(max'="") {
        Set %fjscode($I(%fjscode)) = $$$FormatText(" i '$IsValidnum(%1,,%2,%3) q ""%4 length out of range""", lenExpr, +min, max, prop)
    }
}

Method GenerateuniqueItemsCode(prop As %String = "", type As %String = "")
{
	q:'..Schema.uniqueItems
	s %uniquecheck=1
	s:..KeepSource %fjscode($i(%fjscode))=" ;validate uniqueItems check"
	s %fjscode($i(%fjscode)) = " i '$$unqiueItemsCheck() return """""
	q
}

Method UniqueCheck()
{
	s %fjscode($i(%fjscode))="unqiueItemsCheck(){"
	s %fjscode($i(%fjscode))="}"
}

Method GenerateEnumCode(prop As %String = "") [ Internal ]
{
	s PropertySchema = ..PropertySchema
	q:'PropertySchema.%IsDefined("enum")
	s:..KeepSource %fjscode($i(%fjscode))=" ; enum check"
	s iter = PropertySchema.enum.%GetIterator()
	s c="$lb(" while iter.%GetNext(,.v) {s c=c_$case($isvalidnum(v),1:v,:""""_v_"""")_","} s c=$E(c,1,*-1)_")"
	i prop'="",(prop'["%Get") {
		s %fjscode($i(%fjscode))=" i '$lf("_c_",%JSON."_prop_") q ""enum not match with "_prop_" json data"" "
	}
	else{
		s %fjscode($i(%fjscode))=" i %JSON.%IsA(""%DynamicArray"") s enumsval="_c_" s iter=%JSON.%GetIterator() while iter.%GetNext(,.v){ i '$lf(enumsval,v) ret ""input not match with the schema enum values"" }"
	}
}

Method GeneratePatternCode(prop As %String = "") [ Internal ]
{
	s PropertySchema = ..PropertySchema
	q:'PropertySchema.%IsDefined("pattern")
	s pat = PropertySchema.pattern
	s:..KeepSource %fjscode($i(%fjscode))=" ; pattern check"
	s %fjscode($i(%fjscode))=$$$FormatText(" i '$match(%JSON.%1,""%2"") q ""pattern not match with %3 json data""", prop, pat, prop)
}

Method GenerateFormatCode(prop As %String) [ Internal ]
{
	q:'..PropertySchema.%IsDefined("format")
	s format = ..PropertySchema.format
	s:..KeepSource %fjscode($i(%fjscode))=" ; "_format_" format check"
	s regex = ..RegexFormats(format)
	s:regex'="" %fjscode($i(%fjscode))=" i '$match(%JSON."_prop_","""_regex_""") q """_format_" format not matched"" "
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
	s %fjscode($i(%fjscode))=$$$FormatText(" i %JSON.%1'=""%2"" q ""%3 value must be %4""", prop, const, prop, mustbe)
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

Method CodeType(datatype) [ CodeMode = expression ]
{
$case(datatype,"string":6,"integer":9,"number":9,"boolean":4,"null":2,:"")
}

ClassMethod RegexFormats(format) As %String [ CodeMode = expression ]
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
	s %fjscode($i(%fjscode))="%validate(%JSON)"
	s %fjscode($i(%fjscode))=" n (%JSON)"
	s %fjscode($i(%fjscode))=" s $et=""q $ze"""
	s %fjscode($i(%fjscode))=" s:'$iso(%JSON) %JSON={}.%FromJSON(%JSON)"
}

Method basicinfo() [ Internal, Private ]
{
	q:'..KeepSource
	s %fjscode($i(%fjscode))=" ;Generated by "_$classname()
	s %fjscode($i(%fjscode))=" ;$schema: "_..Schema."$schema"
	s %fjscode($i(%fjscode))=" ;$id: "_..Schema."$id"
	s %fjscode($i(%fjscode))=" ;title: "_..Schema.title
	s %fjscode($i(%fjscode))=" ;description: "_..Schema.description
}

Method Savefjs()
{
	s %fjscode($i(%fjscode))=" q 1"
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
		
		s rtn=$COMPILE(%fjscode,0,errs,,,,"aaschema."_..Name)
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

}
