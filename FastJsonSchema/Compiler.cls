Include %occIO

Class FastJsonSchema.Compiler Extends %RegisteredObject
{

Property Name As %String;

Property Schema As %DynamicAbstractObject;

Property KeepSource As %Boolean [ InitialExpression = 0, Internal ];

Property Optimize As %Boolean;

/// Holds the schema definition for each property when that property's code is generated.
Property PropertySchema As %DynamicObject [ Internal ];

ClassMethod Compile(pSchemaName = "", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 0)
{
	d ..OnBeforeCompile()
	s %keepsource=pKeepSource
	s st=..%New(pSchemaName, pSchema, pKeepSource).CompileInternal()
	d ..OnAfterCompile()
	q st
}

Method CompileInternal() As %Status [ Internal, Private ]
{
	d $SYSTEM.Process.Undefined(2)
	#dim sc As %Status

	k %fjscode,%uniquecheck,%keepsource,%patternsExist
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
    $$$CWriteLine(" ; schema type is "_ schema.type,..KeepSource)
    d ..CheckRequiredProps(schema)
    s isarrexecute=0
    i schema.type="array" {
	    q:'schema.%IsDefined("items")
	    $$$CWriteLine(" ;validate array items schema",..KeepSource)
	    if 'schema.items.%IsA("%DynamicArray") { ;single object in array
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
        $$$CWriteLine(" ;validate "_prop_" schema propery",%keepsource)
        $$$CWriteLine(" ;Property "_prop_" description is "_PropertySchema.description,..KeepSource)
        ;
        s type=PropertySchema.type
        i isarrexecute s prop="%Get("_prop_")"
        #;array - multi types
        i $iso(type) {
            d ..MultiTypePropValidate(prop)
            s arriter = PropertySchema.type.iterator()
			while arriter.%GetNext(,.arrPropType) {
				$$$CWriteLine(" ;property "_prop_" and it's "_arrPropType_" validation",..KeepSource)
				i (arrPropType="object") ||( arrPropType="array") {
	            	d $method(,$$$CurrentMethod, PropertySchema)
            	}
            	else{
            		d:arrPropType'="" $method(, arrPropType, prop, 1)
            	}
			}
        }
        else {
	        /// TODO: Correct the code logic for oneOf,anyOf,allOf
	       	if PropertySchema.%IsDefined("oneOf") {
		       	d ..GenerateOneOfCode(prop)
		       	s subIter=..PropertySchema.oneOf.%GetIterator()
			    while subIter.%GetNext(,.subSchema) {
			        continue:'subSchema.%IsDefined("type")
		            s subType = subSchema.type
		            i (subType="object") ||( subType="array") {
            			d $method(,$$$CurrentMethod, subSchema)
        			}
        			else{
	        			//s ..PropertySchema=subSchema
        				//d:subType'="" $method(, subType, prop, 1)
        			}
			    }
            }
            elseif PropertySchema.%IsDefined("anyOf") {
		       	d ..GenerateAnyOfCode(prop)
		       	s subIter=..PropertySchema.anyOf.%GetIterator()
		       	while subIter.%GetNext(,.subSchema) {
			        continue:'subSchema.%IsDefined("type")
		            s subType = subSchema.type
		            i (subType="object") ||(subType="array") {
            			d $method(,$$$CurrentMethod, subSchema)
        			}
        			else{
        				d:subType'="" $method(, subType, prop, 1)
        			}
		       	}
            }
            elseif PropertySchema.%IsDefined("allOf") {
		       	d ..GenerateAllOfCode(prop)
		       	s subIter=..PropertySchema.allOf.%GetIterator()
				while subIter.%GetNext(,.subSchema) {
			        continue:'subSchema.%IsDefined("type")
		            s subType = subSchema.type
		            i (subType="object")||(subType="array") {
            			d $method(,$$$CurrentMethod, subSchema)
        			}
        			else{
        				d:subType'="" $method(, subType, prop, 1)
        			}
		       	}
            }
            elseif (type="object")||(type="array") {
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
	$$$WriteLine($$$FormatText(" i '$find(%1,%JSON.%GetTypeCodeOf(""%2"")) q $$Error^%apiOBJ(5001,""Data type validation failed for property """"%3"""". Valid types are: %4"")", c, prop, prop, $replace($e(dt,1,*-1),","," or ")))
}

/// Need to fix this singleArr method to ensure it works properly for "oneof" properly. Use SampleSchema1 for that testing.
/// Genreal testning use SampleSchema 5 for testing
/// 2. use SampleSchema1 for testing
Method singleArr() [ Private ]
{
	$$$WriteLine(" i '$iso(%JSON)||('%JSON.%IsA(""%DynamicArray"")) q $$Error^%apiOBJ(5001,""given input is not array"")")
	d ..GenerateLengthCode()
	s PropertySchema=..PropertySchema
	s type =PropertySchema.items.type
	Set ..PropertySchema =PropertySchema.items
	d ..GenerateuniqueItemsCode()
	;
	if (type="object")||(type="array") {
		d $method(,"GenerateCode", ..PropertySchema)
	}
    else{
	    d:type'="" $method(,type, "%Get(0)")
     }
     q
	
	//s ..PropertySchema=PropertySchema
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
	$$$CWriteLine(" ;integer method validation for "_prop,%keepsource)
	$$$CWriteLine(" i %JSON.%GetTypeCodeOf("""_$S(prop["%Get(":+$P(prop,"%Get(",2),1:prop)_""")'=9 q $$Error^%apiOBJ(5001,""Data type of property "_$S(prop["%Get(":"",1:prop)_" does not match with the JSON value"")",'SkipGenerate)
	d ..GenerateLengthCode(prop, $$$CurrentMethod)
	d ..GenerateEnumCode(prop)
	d ..GenerateConstCode(prop)
	d ..GenerateMultipleOfCode(prop)
}

Method boolean(prop As %String, SkipGenerate = 0)
{
	i 'SkipGenerate {
		$$$WriteLine(" i %JSON.%GetTypeCodeOf("""_prop_""")'=4 q $$Error^%apiOBJ(5001,""Data type of property """""_prop_""""" does not match with the JSON value"")")
		$$$WriteLine(" s bv=%JSON."_prop_" if $c(0,1)'[$c(bv) q $$Error^%apiOBJ(5001,""proeprty """""_prop_""""" is not a boolean value"")")
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

Method GenerateuniqueItemsCode(prop As %String = "", type As %String = "")
{
	q:'..Schema.uniqueItems
	s %uniquecheck=1
	$$$CWriteLine(" ;validate uniqueItems check",%keepsource)
	$$$WriteLine(" s st=$$unqiueItemsCheck(%JSON) i 'st return st")
	q
}

Method UniqueCheck() [ Internal ]
{
	$$$WriteLine("unqiueItemsCheck(%JSON){")
	$$$WriteLine(" s iter=%JSON.%GetIterator()")
	$$$WriteLine(" while iter.%GetNext(,.val) {")
	$$$WriteLine("	i $d(uniqueCheck(val)) ret $$Error^%apiOBJ(5001,""Each value must be unique. Duplicate found for ""_val)")
	$$$WriteLine("	s uniqueCheck(val)=""""")
	$$$WriteLine(" }")
	$$$WriteLine(" q 1")
	$$$WriteLine("}")
}

Method GenerateLengthCodeForOneOf(prop As %String = "", type As %String = "", PropertySchema)
{
    s (min,amx,lenExpr)=""
	s PropertySchema = $S(PropertySchema'="":PropertySchema,1:..PropertySchema)
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
        q ""
    }
    s:prop["%Get" prop=""
    i (min'=""),(max'="") {
	    s code = $$$FormatText(" s len=%1 i (len<%2)||(len>%3)", lenExpr, +min, max)
        
    }
    elseif min'=""&&(max=""){
	    s code = $$$FormatText(" i %1<%2", lenExpr, +min)
        
    }
    elseif min=""&&(max'=""){
	    s code = $$$FormatText(" i '%1>%2", lenExpr, max)
       
    }
    if PropertySchema'="" ret code
}

/// Proeprty max,min and additional length checks
/// type - is mainly used for multi types e.g "type":["string","integer"]
Method GenerateLengthCode(prop As %String = "", type As %String = "", PropertySchema = "")
{
    s (min,amx,lenExpr)=""
	s PropertySchema = $S(PropertySchema'="":PropertySchema,1:..PropertySchema)
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
        s lenExpr = "%JSON."_prop
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
        q ""
    }
    s:prop["%Get" prop=""
    i (min'=""),(max'="") {
	    s code = $$$FormatText(" s len=%1 i (len<%2)||(len>%3) q $$Error^%apiOBJ(5001,""Property %4 has an invalid length: Value must be between %5 to %6"")", lenExpr, +min, max, prop, +min, max)
        $$$WriteLine(code)
    }
    elseif min'=""&&(max=""){
	    s code = $$$FormatText(" i %1<%2 q $$Error^%apiOBJ(5001,""Property %3 has an invalid length: value must be greater than or equal to %4"")", lenExpr, +min, prop, +min)
        $$$WriteLine(code)
    }
    elseif min=""&&(max'=""){
	    s code = $$$FormatText(" i '%1>%2 q $$Error^%apiOBJ(5001,""Property %3 has an invalid length: value must be less than or equal to %4"")", lenExpr, max, prop, max)
       $$$WriteLine(code)
    }
    if PropertySchema'="" ret code
}

Method GenerateEnumCode(prop As %String = "") [ Internal ]
{
	s PropertySchema=..PropertySchema
	q:'PropertySchema.%IsDefined("enum")
	$$$CWriteLine(" ; enum check",..KeepSource)
	s iter = PropertySchema.enum.%GetIterator()
	s c="$lb(" while iter.%GetNext(,.v) {s c=c_$case($isvalidnum(v),1:v,:""""_v_"""")_","} s c=$E(c,1,*-1)_")"
	i prop'="",(prop'["%Get") {
		$$$WriteLine(" i '$lf("_c_",%JSON."_prop_") q $$Error^%apiOBJ(5001,""Invalid value of property "_prop_". Value must match one of the allowed enum items."")")
	}
	else{
		$$$WriteLine(" i %JSON.%IsA(""%DynamicArray"") {s enumsval="_c_"  ")
		$$$WriteLine(" s iter=%JSON.%GetIterator() while iter.%GetNext(,.v){ i '$lf(enumsval,v) ret ""Invalid value. Value must match one of the allowed enum items."" }}")
	}
}

Method GeneratePatternCode(prop As %String = "")
{
	s PropertySchema=..PropertySchema
	q:'PropertySchema.%IsDefined("pattern")
	s pat = PropertySchema.pattern
	$$$CWriteLine(" ; pattern check",..KeepSource)
	$$$WriteLine($$$FormatText(" i '$match(%JSON.%1,""%2"") q $$Error^%apiOBJ(5001,""Property %3 does not match required pattern."")", prop, pat, prop))
}

Method GenerateFormatCode(prop As %String)
{
	q:'..PropertySchema.%IsDefined("format")
	s format = ..PropertySchema.format
	$$$CWriteLine(" ; "_format_" format check",..KeepSource)
	s regex = ..RegexFormats(format)
	$$$CWriteLine(" i '$match(%JSON."_prop_","""_regex_""") q $$Error^%apiOBJ(5001,""Property "_prop_" does not match the expected "_format_" format"")",(regex'=""))
}

// TODO: implement multipleOf

Method GenerateMultipleOfCode(prop)
{
	s propertySchema=..PropertySchema
	q:'propertySchema.%IsDefined("multipleOf")
	$$$CWriteLine(" ; multipleOf check",..KeepSource)
	$$$WriteLine(" i (%JSON."_prop_"/"_propertySchema.multipleOf_") q $$Error^%apiOBJ(5001,""Property "_prop_" does not match the expected multipleOf "_propertySchema.multipleOf_""")")
}

Method GenerateConstCode(prop)
{
	q:'..PropertySchema.%IsDefined("const")
	$$$CWriteLine(" ; const check",..KeepSource)
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

ClassMethod %INCLUDE(pCode As %String)
{
	#define CWriteLine(%code,%s)	s:%s %fjscode($i(%fjscode))=%code
	#define WriteLine(%code)		s %fjscode($i(%fjscode))=%code
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

/// TODO: Need to work on this properly
Method GenerateOneOfCode(prop As %String)
{
	$$$CWriteLine(" ;----------------------",..KeepSource)
	$$$CWriteLine(" ;oneOf Check",..KeepSource)
	s iterOne = ..PropertySchema.oneOf.%GetIterator()
	d ..CheckTypes("oneOf", prop)
}

/// TODO:
Method GenerateAnyOfCode(prop As %String)
{
	$$$CWriteLine(" ;anyOf Check",..KeepSource)
	
	s iterAny = ..PropertySchema.anyOf.%GetIterator()
	d ..CheckTypes("anyOf", prop)
}

/// TODO:
Method GenerateAllOfCode(prop As %String)
{
	$$$CWriteLine(" ;allOf Check",..KeepSource)
	s iterAny = ..PropertySchema.allOf.%GetIterator()
	d ..CheckTypes("allOf", prop)
}

/// TODO: implement additional propertis such as "enum" etc..
Method CheckTypes(iter, prop)
{
	d ..GenerateCombinatorValidation(iter, prop)
	q
    s c="",dt="",const="",mustbe="",enum="",pattern="",lck=0
    // 1. ANALYZE AND AGGREGATE CONSTRAINTS
    while iter.%GetNext(,.subSchema) {
        i subSchema.%IsDefined("type") {
            s subType = subSchema.type
            s dt=dt_subType
            s c=c_..CodeType(subType)
        }
        s lengthCheckCode=..GenerateLengthCodeForOneOf(prop,subType,subSchema)
        s:lengthCheckCode'="" lengthCheck($i(lck))= lengthCheckCode
        if subSchema.%IsDefined("const") {
	        s mustbe=mustbe_subSchema.const_","
	        s const=const_""""_subSchema.const_""""_","
        }
        if subSchema.%IsDefined("enum") {
            // Logic to merge enum values into constValueList
            s enumIter = subSchema.enum.%GetIterator()
            while enumIter.%GetNext(,.enumValue) {
                s enum=enum_""""_enumValue_""""_","
            }
        }
        if subSchema.%IsDefined("pattern") {
            s pattern=pattern_(""""_subSchema.pattern_""",")
        }
    }
    $$$WriteLine($$$FormatText(" i '$find(%1,%JSON.%GetTypeCodeOf(""%2"")) q $$Error^%apiOBJ(5001,""Data type validation failed for property """"%3"""". Valid types are: %4"")", c, prop, prop, subType))
   
   	if enum'="" {
	   	s enum="$lb("_$e(enum,1,*-1)_")"
	   	$$$WriteLine($$$FormatText(" i '$lf(%1,%JSON.%2) q $$Error^%apiOBJ(5001,""Invalid value of property %3 Value must match one of the allowed enum items"")",  enum, prop, prop))
   	}
    if const'="" {
	    s const="$lb("_$e(const,1,*-1)_")"
	    $$$WriteLine($$$FormatText(" i '$lf(%1,%JSON.%2) q $$Error^%apiOBJ(5001,""Property %3 value must be %4"")",  const, prop, prop, $e(mustbe,1,*-1)))
    }
    i pattern'="" {
	    i $l(pattern,",")<=2 {
		    s:$e(pattern,*)="," pattern=$e(pattern,1,*-1)
		    $$$WriteLine($$$FormatText(" i '$match(%JSON.%1,%2) q $$Error^%apiOBJ(5001,""Property %3 does not match required pattern."")", prop, pattern, prop))
	    }
	    else{
		    s %patternsExist=1
	    	s pattern="$lb("_$e(pattern,1,*-1)_")"
	    	$$$WriteLine(" s rtn=$$ValidatePatternsExist("_pattern_",%JSON."_prop_") i 'rtn q rtn")
	    }
    }
    if $D(lengthCheck)>1 {
	    f i=1:1:$O(lengthCheck(""),-1){
		    $$$WriteLine(lengthCheck(i))
	    }
    }
}

Method PatternCheckP()
{
	$$$WriteLine("ValidatePatternsExist(patterns,data) {")
	$$$WriteLine("  s ptr=0,match=0")
	$$$WriteLine("  while $listNext(pattens,ptr,pattern) {i $match(inp,pattern) s match=1}")
	$$$WriteLine("  i 'match q $$Error^%apiOBJ(5001,""does not match required patterns."")")
	$$$WriteLine("  q 1}")
}

/// this method is used for "allOf","oneOf","anyOf" logic
Method GenerateCombinatorValidationOld(alloneAnyOf, prop)
{
	s c="",dt="",const="",mustbe="",enum="",pattern="",lck=0,oneof=1
    // 1. ANALYZE AND AGGREGATE CONSTRAINTS
    
    s iter = ..PropertySchema.%Get(alloneAnyOf)
    if '$iso(iter) q
    s alloneAnysize=iter.size()+1
    s iter = iter.%GetIterator()
    while iter.%GetNext(,.subSchema) {
	    s:subSchema.%IsDefined("type") type=subSchema.type
	    ; this object and array handled by GeneratedCode
	    continue:(type="object"!(type="array"))
	    s ssvar=prop_"oneOf"_oneof
	    if $i(oneof)<=alloneAnysize {
		    s ssvarnext="g "_prop_"oneOf"_oneof
	    }
	    else {
		    s ssvarnext=""
	    }
	    $$$CWriteLine(" ; started validating oneOf for the property "_prop_" and it type is "_subSchema.type,..KeepSource)
        s c=..CodeType(subSchema.type)
        s lengthCheckCode=..GenerateLengthCodeForOneOf(prop,subSchema.type,subSchema)
        s:subSchema.%IsDefined("const") const=""""_subSchema.const_""""
        if subSchema.%IsDefined("enum") {
            s enumIter = subSchema.enum.%GetIterator()
            while enumIter.%GetNext(,.enumValue) {
                s enum=enum_""""_enumValue_""""_","
            }
        }
        s:subSchema.%IsDefined("pattern") pattern=subSchema.pattern
        $$$WriteLine(ssvar)
    	s svv=$S(ssvarnext'="":ssvarnext,1:"")
       	$$$WriteLine($$$FormatText(" i '$find(%1,%JSON.%GetTypeCodeOf(""%2"")) s oneOf(""%3"")=0 %4", c, prop,ssvar,svv))
       	
       	if enum'="" {
	   		s enum="$lb("_$e(enum,1,*-1)_")"
	   		$$$WriteLine($$$FormatText(" i '$lf(%1,%JSON.%2) s oneOf(""%3"")=0 %4",  enum, prop, ssvar,svv))
   		}
    	if const'="" {
	    	$$$WriteLine($$$FormatText(" i %1'=%JSON.%2 s oneOf(""%3"")=0 %4",  const, prop, ssvar,svv))
    	}
    	if lengthCheckCode'="" {
	    	$$$WriteLine(lengthCheckCode_" "_$$$FormatText("s oneOf(""%1"")=0 %2",ssvar,svv))
    	}
    	$$$WriteLine($$$FormatText(" s oneOf(""%1"")=1 ",ssvar))
    	//$$$WriteLine(" g oneOf"_alloneAnysize)
    } 
    $$$CWriteLine(" ; final validate whether oneOf available",..KeepSource)
    $$$WriteLine(prop_"oneOf"_alloneAnysize_" s sub="""",oneOfPasses=0 f {s sub=$o(oneOf(sub),1,d) q:sub=""""  s oneOfPasses= oneOfPasses+d }")
    $$$WriteLine(" i oneOfPasses'=1 q $$Error^%apiOBJ(5001,""Property must match exactly one sub-schema defined in """"oneOf"""""")")
}

/// this method is used for "allOf","oneOf","anyOf" logic
Method GenerateCombinatorValidation(alloneAnyOf, prop)
{
	s c="",dt="",const="",mustbe="",enum="",pattern="",lck=0,oneof=1

    s iter = ..PropertySchema.%Get(alloneAnyOf)
    if '$iso(iter) q
    s alloneAnysize=iter.size()+1
    s iter = iter.%GetIterator()
    
    s ssvar=prop_"onfOf"
    $$$WriteLine($$$FormatText(" s oneOf(""%1"")=1 ",ssvar))
    while iter.%GetNext(,.subSchema) {
	    s:subSchema.%IsDefined("type") type=subSchema.type
	    
	    ; this object and array handled by GeneratedCode
	    continue:(type="object"!(type="array"))
	    
	    
	    
	    
	    $$$CWriteLine(" ; started validating oneOf for the property "_prop_" and it type is "_subSchema.type,..KeepSource)
        s c=..CodeType(subSchema.type)
        s lengthCheckCode=..GenerateLengthCodeForOneOf(prop,subSchema.type,subSchema)
        s:subSchema.%IsDefined("const") const=""""_subSchema.const_""""
        if subSchema.%IsDefined("enum") {
            s enumIter = subSchema.enum.%GetIterator()
            while enumIter.%GetNext(,.enumValue) {
                s enum=enum_""""_enumValue_""""_","
            }
        }
        s:subSchema.%IsDefined("pattern") pattern=subSchema.pattern
        
        //$$$WriteLine(ssvar)
       	$$$WriteLine($$$FormatText(" i %1'=%JSON.%GetTypeCodeOf(""%2"") s oneOf(""%3"")=0", c, prop,ssvar))
       	
       	if enum'="" {
	   		s enum="$lb("_$e(enum,1,*-1)_")"
	   		$$$WriteLine($$$FormatText(" i '$lf(%1,%JSON.%2) s oneOf(""%3"")=0",  enum, prop, ssvar))
   		}
    	if const'="" {
	    	$$$WriteLine($$$FormatText(" i %1'=%JSON.%2 s oneOf(""%3"")=0",  const, prop, ssvar))
    	}
    	if lengthCheckCode'="" {
	    	$$$WriteLine(lengthCheckCode_" "_$$$FormatText("s oneOf(""%1"")=0",ssvar))
    	}
    	$$$WriteLine(" ; ---------------------------")
    	
    	//$$$WriteLine(" g oneOf"_alloneAnysize)
    } 
    $$$CWriteLine(" ; final validate whether oneOf available",..KeepSource)
    $$$WriteLine(" s sub="""",oneOfPasses=0 f {s sub=$o(oneOf(sub),1,d) q:sub=""""  s oneOfPasses= oneOfPasses+d }")
    $$$WriteLine(" i oneOfPasses'=1 q $$Error^%apiOBJ(5001,""Property must match exactly one sub-schema defined in """"oneOf"""""")")
    $$$WriteLine(" k oneOf")
}

Method GetDTInts()
{
#If $$$CacheVersionMajor >=2024
	try{s dt =..PropertySchema.apply("$.type") }catch ex {}
#endif
	return ""
}

/// TODO:
Method GeneateContentMediaTypeCode(prop As %String) [ Internal, Private ]
{
	q:'..PropertySchema.%IsDefined("contentMediaType")
}

/// TODO:
Method GenerateContentEncodingCode(prop As %String) [ Internal, Private ]
{
	q:'..PropertySchema.%IsDefined("contentMediaType")
}

Method configfunc() [ Internal, Private ]
{
	$$$WriteLine("%validate(%JSON)")
	$$$WriteLine(" n (%JSON)")
	$$$WriteLine(" s $et=""q $ze""")
	$$$WriteLine(" s:'$iso(%JSON) %JSON={}.%FromJSON(%JSON)")
	$$$WriteLine(" i '$iso(%JSON)||('%JSON.%IsA(""%DynamicAbstractObject"")) q $$Error^%apiOBJ(16002)")
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
	d:%patternsExist ..PatternCheckP()
	s rot="fjsschema."_..Name
	i ..KeepSource {
		//do:##class(%Routine).%Exists($lb(rot)) ##class(%Routine).%Delete($lb(rot))
		s routine = ##class(%Routine).%New(rot_".int")
		s routine.Generated=1
		i $iso(routine) f i=1:1:%fjscode d routine.WriteLine(%fjscode(i))
		s rtn=routine.%Save()
		d routine.Compile()
	}
	else {
		s %fjscode(0)=%fjscode
		s rtn=$COMPILE(%fjscode,0,errs,,,,rot)
    	i rtn=0 {w "Schema """_..Name_""" compiled successfully",! s rtn=1}
    	else {w "Schema compilation failred return code: ",rtn,! zw errs s rtn=0}
	}
	ret rtn
}

Method %OnNew(pSchemaName As %String, pSchema As %DynamicAbstractObject, pKeepSource As %Boolean = 0) As %Status
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
