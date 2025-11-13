Include %occIO

Class FastJsonSchema.Compile1 Extends %RegisteredObject
{

Property Name As %String;

Property KeepSource As %Boolean [ InitialExpression = 0, Internal ];

ClassMethod Compile(pSchemaName = "", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 0)
{
	d ..OnBeforeCompile()
	s st=..%New(pSchemaName, pKeepSource).CompileToInternal(pSchema)
	d ..OnAfterCompile()
	q st
}

Method CompileToInternal(pSchema) As %Status [ Internal, Private ]
{
	d $SYSTEM.Process.Undefined(2)
	#dim sc As %Status

	k %fjscode
	try{
		d ..GenerateValidator(pSchema)
		s sc= ..Savefjs()
	}
	catch ex{
		s sc=ex.AsStatus()
	}
	q sc
}

Method GenerateValidator(pRootSchema)
{
 	S pContext = ..CreateContext(pRootSchema)
 	d ..basicinfo(pContext)
	d ..configfunc(pContext)
    d ..GenerateCode(pContext)
}

Method GenerateCode(pContext As %DynamicAbstractObject = "") [ Private ]
{
	s schema = pContext.Schema
	s FunctionName = pContext.TargetFunc

	#;Handle root level combinators (allOf, oneOf, anyOf)
	#; These checks run first against the entire current object/dataRef.
	if schema.%IsDefined("allOf") {
		d ..GenerateCombinatorValidation("allOf", pContext)
	}
	if schema.%IsDefined("oneOf") {
		d ..GenerateCombinatorValidation("oneOf", pContext)
	}
	if schema.%IsDefined("anyOf") {
		d ..GenerateCombinatorValidation("anyOf", pContext)
	}

	$$$CWriteLine(" ; schema type is "_ schema.type,FunctionName)

	d ..CheckRequiredProps(pContext)

	#;Determine Iteration Source (Array or Object)
	if schema.type = "array" || (schema.%IsDefined("items")) {
		q:'schema.%IsDefined("items") ; Quit if array is defined but items are not
		$$$CWriteLine(" ;validate array items schema",FunctionName)

		if 'schema.items.%IsA("%DynamicArray") { ; Single item schema in array
			d $method(,"singleArr",pContext)
			q
		}
		#; If items is an array of schemas (tuple validation)
		s iter = schema.items.%GetIterator()
	} else {
		#;Standard object property iteration
		q:'schema.%IsDefined("properties")
		s iter = schema.properties.%GetIterator()
	}

	#;Iterate Properties/Items
	while iter.%GetNext(.prop, .PropertySchema) {

        s dataRef = pContext.DataRef_ "."_$Select(prop["_":""""_prop_"""",1:prop)
        s contextObj = ..CreateContext(PropertySchema, dataRef, pContext.FailureMode, pContext.TargetFunc)

        $$$WriteLine(" ;Started generating code for property "_prop_" full json path is "_contextObj.DataRef,contextObj.TargetFunc)

        s type = PropertySchema.type
        $$$WriteLine(" ;Type : "_type,contextObj.TargetFunc)

		#; Property level dispatch

        #;Combinators (Highest Priority) - Uses the unified method
        if PropertySchema.%IsDefined("oneOf") {
            d ..GenerateCombinatorValidation("oneOf", contextObj)
        } elseif PropertySchema.%IsDefined("anyOf") {
            d ..GenerateCombinatorValidation("anyOf", contextObj)
        } elseif PropertySchema.%IsDefined("allOf") {
            d ..GenerateCombinatorValidation("allOf", contextObj)
        }

        #; Multi-Type(Second Highest Priority: type is an array of types)
        elseif $iso(PropertySchema.type) {
            s arriter = PropertySchema.type.iterator()
            while arriter.%GetNext(,.arrPropType) {
                if (arrPropType="object") || (arrPropType="array") {
                    s recursiveContext = ..CreateContext(PropertySchema, contextObj.DataRef, contextObj.FailureMode, contextObj.TargetFunc)
                    d $method(,"GenerateCode", recursiveContext)
                } else {
                    s contextObj.SkipGenerate=1
                    d:arrPropType'="" $method(, arrPropType, contextObj)
                }
            }
        }

        #; Complex single type(Object/Array)
        elseif (type="object")||(type="array") {
            d $method(, "GenerateCode", contextObj)
        }

        #; Primitive Single types (Catch-all for 'string', 'integer', 'boolean', etc.)
        else {
            d:type'="" $method(,type, contextObj)
        }
	}
}

Method CreateContext(pRootSchema = "", DataRef = "", FailureMode = "", TargetFunc = "", PrimitiveVar = 0) As %DynamicObject
{
	s pContext = {}
	s pContext.Schema = pRootSchema
    s pContext.DataRef = $Select(DataRef'="":DataRef,1:"%JSON")
	s pContext.TargetFunc = $Select(TargetFunc'="":TargetFunc,1:"0fjs")
	s pContext.IsPrimitiveVar=PrimitiveVar
    s pContext.FailureMode = $Select(FailureMode'="":FailureMode,1:"q")
    Return pContext
}

Method singleArr(pContext As %DynamicAbstractObject) [ Private ]
{
    s FunctionName = pContext.TargetFunc
    s arrayDataRef = pContext.DataRef ; e.g., "%JSON.roles"
    s itemSchema = pContext.Schema.items
    s code = $$$FormatText(" i '(%1.%IsA(""%DynamicArray"")) q $$Error^%apiOBJ(5001,""given input is not array"")", arrayDataRef)
    $$$WriteLine(code, FunctionName)
    $$$WriteLine(" k seenItems", FunctionName)
    d ..GenerateLenCode(pContext)
    s loopVar = "singleArrIterValue" ; Simple example: a generic name like '$list(%val, i)' or a dynamic one

    $$$WriteLine(" s singleArrIter = "_arrayDataRef_".%GetIterator()", FunctionName)
    $$$WriteLine(" while singleArrIter.%GetNext(, .singleArrIterValue) {", FunctionName)
    ; handel uniqueItems
    $$$WriteLine("  if $d(seenItems(singleArrIterValue)) ret $$Error^%apiOBJ(5001,""Array items must be unique."")",FunctionName)
    $$$WriteLine("  s seenItems(singleArrIterValue)=""""",FunctionName)

    s newContext = ..CreateContext(itemSchema,loopVar,"ret",pContext.TargetFunc,1)

    s type = itemSchema.type
    if (type="object")||(type="array") {
        ; Recursive call for nested objects/arrays in the item
        d $method(,"GenerateCode", newContext)
    } else {
        ; Call the primitive method (e.g., 'string', 'integer')
        d:type'="" $method(,type, newContext)
    }

    $$$WriteLine(" } ; End array loop", FunctionName)
    $$$WriteLine(" k seenItems", FunctionName)
    q
}

Method CheckRequiredProps(pContext) [ Private ]
{
	s schema = pContext.Schema
	s FunctionName=pContext.TargetFunc
	Set dataRef = pContext.DataRef
	ret:'schema.%IsDefined("required")
	s iter = schema.required.iterator()
	$$$CWriteLine(" ;validate the required schema propery is are available",FunctionName)
	$$$WriteLine(" s missing=""""",FunctionName)
	while iter.%GetNext(,.val) {
		S code = $$$FormatText(" s:'%1.%IsDefined(""%2"") missing=missing_""%3""",dataRef,val,val)
		$$$WriteLine(code,FunctionName)
	}
	;s failureCode = ..GetFailureCode(pContext,"datatype")
	if pContext.FailureMode="THROW" {
		set quitType="throw"
	}
	else{
		s quitType="q"
	}
	$$$WriteLine(" "_quitType_":missing'="""" $$Error^%apiOBJ(5001,""Required properties missing: ""_$e(missing,1,*-1))",FunctionName)
}

Method string(pContext)
{
	s schema = pContext.Schema
	s dataRef = pContext.DataRef
	S FunctionName=pContext.TargetFunc
	S FailureMode = pContext.FailureMode
	S SkipGenerate = pContext.SkipGenerate

	$$$CWriteLine(" ;string method validation for "_dataRef,FunctionName)

	i 'SkipGenerate {
		s failureCode = ..GetFailureCode(pContext,"datatype")
		i pContext.IsPrimitiveVar {
			#;Array Item Context (Local Variable)
			s generatedCode = $$$FormatText(" i $ISVALIDNUM(%1)%2", dataRef, failureCode)
		}
		Else{
			s generatedCode = $$$FormatText(" i %1.%GetTypeCodeOf(""%2"")'=6 "_failureCode, $p(dataRef,".",1,*-1),$S($p(dataRef,".",*)["""":$TR($p(dataRef,".",*),""""),1:$p(dataRef,".",*)))
		}
		$$$WriteLine(generatedCode, FunctionName)
	}
	d ..GenerateLenCode(pContext)
	d ..GeneratePatternCode(pContext)
	d ..GenerateEnumCode(pContext)
	d ..GenerateFormatCode(pContext)
	d ..GenerateConstCode(pContext)
	d ..GeneateContentMediaTypeCode(pContext)
}

/// TODO: additional checks for number
Method number(pContext)
{
	d ..integer(pContext)
}

Method integer(pContext)
{
	s schema = pContext.Schema
	s dataRef = pContext.DataRef
	S FunctionName=pContext.TargetFunc
	s FailureMode = pContext.FailureMode
	s SkipGenerate = pContext.SkipGenerate

	$$$CWriteLine(" ;integer method validation for "_dataRef,FunctionName)
	i 'SkipGenerate {
		s failureCode = ..GetFailureCode(pContext,"value")
		i pContext.IsPrimitiveVar {
			#;Array Item Context (Local Variable)
			s generatedCode = $$$FormatText(" i '$ISVALIDNUM(%1)%2", dataRef, failureCode)
		}
		else{
			s generatedCode = $$$FormatText(" i %1.%GetTypeCodeOf(""%2"")'=9 "_failureCode, $p(dataRef,".",1,*-1),$p(dataRef,".",*))
		}
		$$$WriteLine(generatedCode,FunctionName)
	}
	d ..GenerateLenCode(pContext)
	d ..GenerateEnumCode(pContext)
	d ..GenerateConstCode(pContext)
	d ..GenerateMultipleOfCode(pContext)
}

Method boolean(pContext)
{
	s schema = pContext.Schema
	s dataRef = pContext.DataRef
	s FunctionName=pContext.TargetFunc
	s FailureMode = pContext.FailureMode
	s SkipGenerate = pContext.SkipGenerate
	$$$CWriteLine(" ;boolean method validation for "_dataRef,FunctionName)
	i 'SkipGenerate {
		s failureCode = ..GetFailureCode(pContext,"value")
		i pContext.IsPrimitiveVar {
			#;Array Item Context (Local Variable)
			s generatedCode = $$$FormatText(" i '$ISVALIDNUM(%1)%2", dataRef, failureCode)
		}
		else{
			s generatedCode = $$$FormatText(" i %1.%GetTypeCodeOf(""%2"")'=3 "_failureCode, $p(dataRef,".",1,*-1),$p(dataRef,".",*))
		}
		$$$WriteLine(generatedCode,FunctionName)
		$$$WriteLine($$$FormatText(" i $c(0,1)[$c(%1) %2",dataRef,error),FunctionName)
	}
	d ..GenerateConstCode(pContext)
	d ..GenerateEnumCode(pContext)
	///TODO
	d ..GenerateIFThenElseCode()
}

Method null(pContext)
{
	s schema = pContext.Schema
	s dataRef = pContext.DataRef
	S FunctionName=pContext.TargetFunc
	S FailureMode = pContext.FailureMode
	S SkipGenerate = pContext.SkipGenerate
	$$$CWriteLine(" ;null method validation for "_dataRef,FunctionName)
	s failureCode =..GetFailureCode(pContext,"datatype")
	I 'SkipGenerate {
		i pContext.IsPrimitiveVar {
			#;Array Item Context (Local Variable)
			s generatedCode = $$$FormatText(" i '$ISVALIDNUM(%1)%2", dataRef, failureCode)
		}
		else{
			s generatedCode = $$$FormatText(" i %1.%GetTypeCodeOf(""%2"")'=2 "_failureCode, $p(dataRef,".",1,*-1),$S($p(dataRef,".",*)["""":$TR($p(dataRef,".",*),""""),1:$p(dataRef,".",*)))
		}
		$$$WriteLine(generatedCode,FunctionName)
	}
	d ..GenerateEnumCode(pContext)
	d ..GenerateConstCode(pContext)
}

Method array(pContext)
{
}

/// common method to tigger the error with whether "return" or "quit"
/// return is required Inside the loop
Method GetFailureCode(pContext As %DynamicAbstractObject, constraintType As %String) As %String
{
	s rtn=" q 0"
    Set pMode = pContext.FailureMode
    Set pDataRef = pContext.DataRef
    s propNameForMsg = $s(pDataRef["%Get(":+$P(pDataRef,"%Get(",2),pDataRef="%JSON":"",1:$tr($p(pDataRef,".",*),""""))
    if propNameForMsg="" s propNameForMsg = "validation"
    s primitiveType = pContext.Schema.type ; Get the current primitive type (e.g., "string", "integer")
    s genericMsg = ..ErrorMessages(primitiveType, constraintType)
    s errorMsg = $Replace(genericMsg, "%", propNameForMsg)
    if pMode = "THROW" {
        s rtn= " throw"
    }
    Elseif pMode = "ret" {
	    s rtn= $$$FormatText(" "_pMode_" $$Error^%apiOBJ(5001,""%1"")", errorMsg)
    }
    if pMode = "q" {
        s rtn=$$$FormatText(" "_pMode_" $$Error^%apiOBJ(5001,""%1"")", errorMsg)
    }
    q rtn
}

ClassMethod ErrorMessages(type = "", errorType) [ CodeMode = expression ]
{
$Select(
(type="string")&&(errorType="format") :"% must match with the format",
(type="string")&&(errorType="datatype") :"% must be a string type",
(type="string")&&(errorType="maxLength"):"% failed maximum length check",
(type="string")&&(errorType="minLength"):"% failed minimum length check",
(type="array")&&(errorType="minLength"):"% failed minimum size check",
(type="array")&&(errorType="maxLength"):"% failed maximum size check",
(type="object")&&(errorType="minLength"):"% failed minimum size check",
(type="object")&&(errorType="maxLength"):"% failed maximum size check",
(type="string")&&(errorType="maxmin")   :"% failed maximum and minimum length check",
(type="object")&&(errorType="maxmin")   :"% failed maximum and minimum size check",
(type="array")&&(errorType="maxmin")   :"% failed maximum and minimum size check",
(type="string")&&(errorType="pattern")  :"% failed pattern validation",
(type="integer")&&(errorType="datatype"):"% must be an integer type",
(type="integer")&&(errorType="minimum"):"% must be greater than or equal to minimum",
(type="integer")&&(errorType="multipleOf"):"% must be a multiple of the specified value",
(type="boolean")&&(errorType="multipleOf"):"% must be a multiple of the specified value",
(type="boolean")&&(errorType="const"):"% must match with const value",
(type="boolean")&&(errorType="datatype"):"% must match with boolean value",
(type="boolean")&&(errorType="datatype"):"% must match with null value",
(type="boolean")&&(errorType="value"):"% value must be true or false",
(type="null")&&(errorType="const"):"% must match with const value",
(type="string")&&(errorType="const"):"% must match with const value",
(type="integer")&&(errorType="const"):"% must match with const value",
(type="string")&&(errorType="enum"): "Invalid value of property %. Value must match one of the allowed enum items.",
(type="integer")&&(errorType="enum"): "Invalid value of property %. Value must match one of the allowed enum items.",
(type="boolean")&&(errorType="enum"): "Invalid value of property %. Value must match one of the allowed enum items.",
(type="null")&&(errorType="enum"): "Invalid value of property %. Value must match one of the allowed enum items.",
(type="integer")&&(errorType="multipleOf"):"Property % does not match the expected multipleOf",
(type="number")&&(errorType="multipleOf"):"Property % does not match the expected multipleOf",
 1:"% failed a general validation constraint"
    )
}

/// Proeprty max,min and additional length checks
/// type - is mainly used for multi types e.g "type":["string","integer"]
Method GenerateLenCode(pContext)
{
    s (min,amx,lenExpr)=""
	s PropertySchema = pContext.Schema
	s type = PropertySchema.type
	S dataRef = pContext.DataRef
	S FunctionName= pContext.TargetFunc
    i type= "string" {
        s:PropertySchema.%IsDefined("minLength") min = PropertySchema.minLength
        s:PropertySchema.%IsDefined("maxLength") max = PropertySchema.maxLength
        s lenExpr = "$l("_dataRef_")"
    }
    elseif type = "integer"!(PropertySchema.type="number") {
		s:PropertySchema.%IsDefined("exclusiveMinimum") emin = PropertySchema.exclusiveMinimum
		s:PropertySchema.%IsDefined("exclusiveMaximum") emax = PropertySchema.exclusiveMaximum
    	s min = $Select(emin'="": emin,1:PropertySchema.minimum)
		s max = $Select(emax'="":emax,1:PropertySchema.maximum)
        s lenExpr = dataRef
    }
    elseif type = "array" {
        i PropertySchema.%IsDefined("minItems") s min = PropertySchema.minItems
        i PropertySchema.%IsDefined("maxItems") s max = PropertySchema.maxItems
        s lenExpr=dataRef_".%Size()"

    }
    elseif type = "object" {
        s:PropertySchema.%IsDefined("minProperties") min=PropertySchema.minProperties
        s:PropertySchema.%IsDefined("maxProperties") max=PropertySchema.maxProperties
        s lenExpr=dataRef_".%Size()"
    }
    else {
        q ""
    }

    if min'=""&&(max'=""){
	    s error = ..GetFailureCode(pContext,"maxmin")
	    s code = $$$FormatText(" i '$IsValidNum(%1,,%2,%3) %4", lenExpr, min, max, error)
       $$$WriteLine(code,FunctionName)
    }
    elseif min'=""&&(max=""){
	    S error = ..GetFailureCode(pContext,"minLength")
	    s code = $$$FormatText(" i %1<%2 %3", lenExpr, +min, error)
        $$$WriteLine(code,FunctionName)
    }
    elseif min=""&&(max'=""){
	   S error = ..GetFailureCode(pContext,"maxLength")
	   s code = $$$FormatText(" i %1>%2 %3", lenExpr, +max, error)
       $$$WriteLine(code,FunctionName)
    }
}

Method GenerateEnumCode(pContext) [ Internal ]
{
	s schema = pContext.Schema
    q:'schema.%IsDefined("enum")
    S dataRef = pContext.DataRef
    //s typeCode=..CodeType(schema.type)
    S functionName = pContext.TargetFunc
    $$$CWriteLine(" ; enum check",FunctionName)
	s iter = schema.enum.%GetIterator(),enumList=""
	while iter.%GetNext(,.enum) {
		s enumList=enumList_""""_enum_""""_","
	}
	s:enumList'="" enumList="$lb("_$E(enumList,1,*-1)_")"

	$$$CWriteLine(" ; enum check for "_dataRef,functionName)
    s generatedCode = $$$FormatText(" i '$lf(%1,%2) %3",enumList, dataRef , ..GetFailureCode(pContext, "enum"))
    $$$WriteLine(generatedCode,functionName)

	/*i prop'="",(prop'["%Get") {


		$$$WriteLine(" i '$lf("_c_",%JSON."_prop_") q $$Error^%apiOBJ(5001,""Invalid value of property "_prop_". Value must match one of the allowed enum items."")",FunctionName)
	}
	else{
		$$$WriteLine(" i %JSON.%IsA(""%DynamicArray"") {s enumsval="_c_"  ",FunctionName)
		$$$WriteLine(" s iter=%JSON.%GetIterator() while iter.%GetNext(,.v){ i '$lf(enumsval,v) ret ""Invalid value. Value must match one of the allowed enum items."" }}",FunctionName)
	}*/
}

Method Getcontext(pContext, Output Schema, Output FunctionName, Output SkipGenerate)
{
	S Schema= pContext.Schema
	Set FunctionName = pContext.FunctionName
	s SkipGenerate=pContext.SkipGeneate
}

Method GeneratePatternCode(pContext As %DynamicObject)
{
    s schema = pContext.Schema
    q:'schema.%IsDefined("pattern")
    S pattern = schema.pattern
    S dataRef = pContext.DataRef
    S functionName = pContext.TargetFunc
    $$$CWriteLine(" ; pattern check for "_dataRef,functionName)
    s generatedCode = $$$FormatText(" i '$match(%1,""%2"") %3", dataRef, pattern, ..GetFailureCode(pContext, "pattern"))
    $$$WriteLine(generatedCode,functionName)
}

Method GenerateFormatCode(pContext)
{
	s schema = pContext.Schema
    q:'schema.%IsDefined("format")
    s format=schema.format
    S dataRef = pContext.DataRef
    S FunctionName = pContext.TargetFunc
	$$$CWriteLine(" ; "_format_" format check "_dataRef,FunctionName)
	s regex = ..RegexFormats(format)
	s error = ..GetFailureCode(pContext, "format")
	;q $$Error^%apiOBJ(5001,""Property "_prop_" does not match the expected "_format_" format"")",(regex'=""),FunctionName
	$$$WriteLine($$$FormatText(" i '$match(%1,""%2"") %3",dataRef,regex,error),FunctionName)
}

// TODO: implement multipleOf

Method GenerateMultipleOfCode(pContext)
{
	s schema = pContext.Schema
	q:'schema.%IsDefined("multipleOf")

	s dataRef = pContext.DataRef
	s FunctionName = pContext.TargetFunc
	$$$CWriteLine(" ; multipleOf check",FunctionName)
	s multipleOf=schema.multipleOf
	s error = ..GetFailureCode(pContext, "multipleOf")
	$$$WriteLine($$$FormatText(" i (%1/%2) %3",dataRef,multipleOf,error),FunctionName)
}

Method GenerateConstCode(pContext)
{
	s schema = pContext.Schema
    q:'schema.%IsDefined("const")
    s const=schema.const
    S dataRef = pContext.DataRef
    s type=schema.type
    S FunctionName = pContext.TargetFunc
	$$$CWriteLine(" ; const check",FunctionName)
	s error = ..GetFailureCode(pContext, "const")
	$$$WriteLine($$$FormatText(" i %1'=""%2"" %3", dataRef, const, error),FunctionName)
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
$case(datatype,"string":6,"integer":9,"number":9,"boolean":4,"object":18,"array":17,"null":2,:"")
}

Method WriteCodeToTarget(pCode, pFunctionName = "")
{
    if pFunctionName'="" {
        ; Write to the function array: %fjscode("FunctionName", index)
        s %fjscode(pFunctionName, $i(%fjscode(pFunctionName))) = pCode
    } else {
        s %fjscode("0fjs",$i(%fjscode)) = pCode
    }
    q
}

ClassMethod %INCLUDE(pCode As %String)
{
	#define CWriteLine(%code,%f)	d:'..KeepSource ..WriteCodeToTarget(%code,%f)
	#define WriteLine(%code,%f)		d ..WriteCodeToTarget(%code,%f)
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
/// Directly Embeded in GenerateCode. Will modify in future
Method GenerateOneOfCode(pContext As %DynamicObject) [ Deprecated ]
{
	q
	S FunctionName=pContext.TargetFunc
	$$$WriteLine(" ;----------------------",FunctionName)
	$$$WriteLine(" ;oneOf Check",FunctionName)
	d ..GenerateCombinatorValidation("oneOf", pContext)
}

/// TODO:
/// Directly Embeded in GenerateCode. Will modify in future
Method GenerateAnyOfCode(pContext As %DynamicObject)
{
	q
	S FunctionName=pContext.TargetFunc
	$$$WriteLine(" ;----------------------",FunctionName)
	$$$WriteLine(" ;anyOf Check",FunctionName)
	d ..GenerateCombinatorValidation("anyOf", pContext)
}

/// TODO:
/// Directly Embeded in GenerateCode. Will modify in future
/// allOf keyword can be placed in two main locations in a JSON Schema:
/// Inside a Property (as you suggested): This means the value of that specific property must satisfy the allOf requirements.
/// At the Root/Top Level: This means the entire object being validated must satisfy the allOf requirements.
Method GenerateAllOfCode(pContext As %DynamicObject)
{
	q
	S FunctionName=pContext.TargetFunc
	$$$WriteLine(" ;----------------------",FunctionName)
	$$$WriteLine(" ;allOf Check",FunctionName)
	d ..GenerateCombinatorValidation("allOf", pContext)
}

Method GenerateCombinatorValidation(alloneanyOf As %String, pContext As %DynamicAbstractObject)
{
    s schema = pContext.Schema
    s functionName = pContext.TargetFunc
    s dataRef = pContext.DataRef
    q:'schema.%IsDefined(alloneanyOf)
    s subSchemas = schema.%Get(alloneanyOf)
    q:'subSchemas.%IsA("%DynamicArray")
    s iter = subSchemas.%GetIterator()
    $$$WriteLine(" s comboPasses = 0", functionName)
    while iter.%GetNext(,.subSchema) {
        s type = subSchema.type
        s isComplex = (type = "object") || (type = "array")
        s newContext = ..CreateContext( subSchema, dataRef, "THROW", functionName)
        $$$WriteLine( " try {", functionName)
        if isComplex {
            d ..GenerateCode(newContext)
        }
        else {
            d:type'="" $method(,type, newContext)
        }
        $$$WriteLine("  s comboPasses = comboPasses + 1", functionName)
		$$$WriteLine(" } catch {}", functionName)
    }
    if alloneanyOf="oneOf" {
        // Must match exactly one: comboPasses must equal 1.
        $$$WriteLine($$$FormatText(" i comboPasses'=1 %1", ..GetFailureCode(pContext,"oneOf")), functionName)
    }
    elseif alloneanyOf="anyOf" {
        // Must match at least one: comboPasses must be greater than 0.
        $$$WriteLine($$$FormatText(" i comboPasses=0 %1", ..GetFailureCode(pContext,"anyOf")), functionName)
    }
    elseif alloneanyOf="allOf" {
        // Must match all: comboPasses must equal the number of sub-schemas.
        s numSubSchemas = subSchemas.%Size()
        $$$WriteLine($$$FormatText(" i comboPasses'=%1 %2", numSubSchemas, ..GetFailureCode(pContext,"allOf")), functionName)
    }
}

Method PatternCheckP(FunctionName)
{
	$$$WriteLine("ValidatePatternsExist(patterns,data) {",FunctionName)
	$$$WriteLine("  s ptr=0,match=0",FunctionName)
	$$$WriteLine("  while $listNext(pattens,ptr,pattern) {i $match(inp,pattern) s match=1}",FunctionName)
	$$$WriteLine("  i 'match q $$Error^%apiOBJ(5001,""does not match required patterns."")",FunctionName)
	$$$WriteLine("  q 1}",FunctionName)
}

/// TODO:
Method GeneateContentMediaTypeCode(pContext) [ Internal, Private ]
{
	q:'pContext.Schema.%IsDefined("contentMediaType")
}

/// TODO:
Method GenerateContentEncodingCode(pContext) [ Internal, Private ]
{
	q:''pContext.Schema.%IsDefined("contentMediaType")
}

Method configfunc(pContext) [ Internal, Private ]
{
	set FunctionName = pContext.TargetFunc
	s schema = pContext.Schema
	s DataRef = pContext.DataRef
	$$$WriteLine("%validate("_DataRef_")",FunctionName)
	$$$WriteLine(" n ("_DataRef_")",FunctionName)
	$$$WriteLine(" s $et=""q $ze""",FunctionName)
	$$$WriteLine(" s:'$iso("_DataRef_") %JSON={}.%FromJSON(%JSON)",FunctionName)
	$$$WriteLine(" i '$iso(%JSON)||('%JSON.%IsA(""%DynamicAbstractObject"")) q $$Error^%apiOBJ(16002)",FunctionName)
}

Method basicinfo(pContext) [ Internal, Private ]
{
	set FunctionName = pContext.TargetFunc
	$$$WriteLine(" q 1 ; no direct routine execute",FunctionName)
	q:'..KeepSource
	s schema = pContext.Schema
	$$$WriteLine(" ;Generated by "_$classname()_" at "_$ZDT($NOW()),FunctionName)
	$$$WriteLine(" ;$schema: "_schema."$schema",FunctionName)
	$$$WriteLine(" ;$id: "_schema."$id",FunctionName)
	$$$WriteLine(" ;title: "_schema.title,FunctionName)
	$$$WriteLine(" ;description: "_schema.description,FunctionName)
	$$$WriteLine(" ;schema type: "_schema.type,FunctionName)
}

Method Savefjs(FunctionName = "0fjs") [ Internal, Private ]
{
	$$$WriteLine(" q 1",FunctionName)
	s rot="fjsschema."_..Name
	i ..KeepSource {
		//do:##class(%Routine).%Exists($lb(rot)) ##class(%Routine).%Delete($lb(rot))
		s routine = ##class(%Routine).%New(rot_".int")
		s routine.Generated=1
		i $iso(routine) {
			;write the code first
			f i=1:1:%fjscode("0fjs") d routine.WriteLine(%fjscode("0fjs",i))

			;write the supporing functions

			s func=""
			f {
				s func=$o(%fjscode(func))  q:func=""
				continue:func="0fjs"
				f i=1:1:%fjscode(func) d routine.WriteLine(%fjscode(func,i))}
			}
		s rtn=routine.%Save()
		d routine.Compile()
	}
	else {
		;s %fjscode(0)=%fjscode
		m %ffcode=%fjscode("0fjs")
		s rtn=$COMPILE(%fjscode,0,errs,,,,rot)
    	i rtn=0 {w "Schema """_..Name_""" compiled successfully",! s rtn=1}
    	else {w "Schema compilation failred return code: ",rtn,! zw errs s rtn=0}
	}
	ret rtn
}

Method %OnNew(pSchemaName As %String, pKeepSource As %Boolean = 0) As %Status
{
	s ..Name = pSchemaName
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
