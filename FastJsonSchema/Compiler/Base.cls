Include %occIO

Class FastJsonSchema.Compiler.Base Extends %RegisteredObject
{

Property Name As %String;

Property ErrorMap As %DynamicObject [ Internal ];

Property CompilerFlags As FastJsonSchema.Compiler.Parameters;

ClassMethod Compile(pSchemaName = "", pSchema As %DynamicObject = "", CompileParamsObj As %Boolean = 0)
{
	d ..OnBeforeCompile()
	s st=..%New(pSchemaName, CompileParamsObj).CompileToInternal(pSchema)
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
		s sc=..Savefjs()
	}
	catch ex{
		s sc=ex.AsStatus()
	}
	q sc
}

Method GenerateValidator(pRootSchema)
{
 	s pContext = ..CreateContext(pRootSchema)
 	d ..basicinfo(pContext)
	d ..configfunc(pContext)
    d ..GenerateCode(pContext)
}

/// main entry point for schema to compiled code creation
Method GenerateCode(pContext As %DynamicAbstractObject = "") [ Private ]
{
	s schema = pContext.Schema
	s FunctionName = pContext.TargetFunc

    #;If $ref is present, process it and QUIT the function immediately to skip all sibling keywords.
    i schema.%IsDefined("$ref") d ..GenerateRefCode(pContext) q

	#; Handle root level combinators (allOf, oneOf, anyOf)
	#; These checks run first against the entire current object/dataRef.
	i schema.%IsDefined("allOf") {
		d ..GenerateCombinatorValidation("allOf", pContext)
	}
	i schema.%IsDefined("oneOf") {
		d ..GenerateCombinatorValidation("oneOf", pContext)
	}
	i schema.%IsDefined("anyOf") {
		d ..GenerateCombinatorValidation("anyOf", pContext)
	}

	#; Conditional Logic
    d ..GenerateIfThenElseCode(pContext)

	#; Structural Constraints
	d ..GenerateMaxAndMinPropertiesCode(pContext)
	d ..GenerateAddPropertiesCode(pContext)
	d ..GeneratePatternPropertiesCode(pContext)
	d ..GenerateDependenciesCode(pContext)

	$$$CWriteLine(" ; schema type is "_ schema.type,FunctionName)

	d ..CheckRequiredProps(pContext)

	s isArrayContext = 0
    s iter = "" ; Initialize iter to $null

	#;Determine Iteration Source (Array or Object)
	i schema.type = "array" || (schema.%IsDefined("items")) {
		q:'schema.%IsDefined("items") ; Quit if array is defined but items are not
		$$$CWriteLine(" ;validate array items schema",FunctionName)

		i 'schema.items.%IsA("%DynamicArray") { ; Single item schema in array (List Validation)
			d $method(,"singleArr",pContext)
			q
		}
		#; If items is an array of schemas (tuple validation)
		s isArrayContext = 1
		s iter = schema.items.%GetIterator()
	}
	elseif schema.type="object"|| schema.%IsDefined("properties") {
		#; Standard object property iteration (Handles object type or structural definition)
		q:'schema.%IsDefined("properties")
		s iter = schema.properties.%GetIterator()
	}
    #; Iterate Properties/items
    i $IsObject(iter) {
	    while iter.%GetNext(.prop, .PropertySchema) {

            #; Determine Data Reference Path (Handle array index vs. object key)
            i isArrayContext {
                s dataRef = pContext.DataRef_ ".%Get("_prop_")"
            }
            else{
                s dataRef = pContext.DataRef_ "."_$Select(prop["_":""""_prop_"""",1:prop)
            }

            #;Create context for the property's schema
            s contextObj = ..CreateContext(PropertySchema, dataRef, pContext.FailureMode, pContext.TargetFunc)
            $$$WriteLine(" ;Started generating code for property "_prop_" full json path is "_contextObj.DataRef,contextObj.TargetFunc)
            d ..GenerateCode(contextObj)
        }
        q
    }
	#;Multi-Type Check e.g ["string","integer"]
	elseif $IsObject(schema.type) { // Check if 'type' is a DynamicArray
    	s arriter = schema.type.iterator()
    	d ..GenerateMultiTypeCode(pContext, arriter) // Use a new helper method to generate the OR logic
    	q
	}

    #; PRimtive types
    #;This is only reached if the schema has no $ref, no combinators, and is not
    elseif schema.type'="" {
        s type = schema.type
        d $method(, type, pContext)
        q
    }
}

Method GenerateMultiTypeCode(pContext As %DynamicAbstractObject, pIterator As %DynamicAbstractObject) [ Private ]
{
    s DataRef = pContext.DataRef
    s FunctionName = pContext.TargetFunc
    s SuccessVar = "multitypesuccess"
    $$$WriteLine(" ; Multi-type validation check (OR logic)", FunctionName)
    $$$WriteLine(" s "_SuccessVar_" = 0", FunctionName)

    #; Loop through each allowed type in the schema.type array
    while pIterator.%GetNext(,.arrPropType) {

        #;Skip if we already succeeded on a previous type to save processing time
        $$$WriteLine(" i '"_SuccessVar_" {", FunctionName)
        $$$WriteLine(" try {", FunctionName)
        s tempSchema = ##Class(%DynamicAbstractObject).%FromJSON(pContext.Schema.%ToJSON())
        s tempSchema.type = arrPropType
        s contextObj = ..CreateContext( tempSchema, DataRef, "THROW", FunctionName)
        i (arrPropType="object") || (arrPropType="array") {
            d ..GenerateCode(contextObj)
        } else {
            d $method(, arrPropType, contextObj)
        }

        #;If the type check and its constraints pass (no error thrown), set the success flag
        $$$WriteLine(" s "_SuccessVar_" = 1", FunctionName)

        $$$WriteLine(" } catch {", FunctionName)
        #;If an error is thrown (constraint failed), clear it and continue to the next type
        $$$WriteLine("  s $ZERROR = """" ; Clear error status to continue to next type check", FunctionName)
        $$$WriteLine(" }", FunctionName)
        $$$WriteLine(" }", FunctionName) // End of 'i !SuccessVar' block
    }

    #;Final Check: If the loop finishes without success, throw the overall error.
    $$$WriteLine(" ; Final check: Did the data match any type?", FunctionName)
    s failureCode = ..GetFailureCode(pContext,"datatype")
    $$$WriteLine(" i '"_SuccessVar_" "_failureCode, FunctionName)
}

/// no longer using
Method GenerateCodeOld(pContext As %DynamicAbstractObject = "") [ Deprecated, Private ]
{
	s schema = pContext.Schema
	s FunctionName = pContext.TargetFunc

    i schema.%IsDefined("$ref") d ..GenerateRefCode(pContext) q

	#;Handle root level combinators (allOf, oneOf, anyOf)
	#; These checks run first against the entire current object/dataRef.
	i schema.%IsDefined("allOf") {
		d ..GenerateCombinatorValidation("allOf", pContext)
	}
	if schema.%IsDefined("oneOf") {
		d ..GenerateCombinatorValidation("oneOf", pContext)
	}
	i schema.%IsDefined("anyOf") {
		d ..GenerateCombinatorValidation("anyOf", pContext)
	}
	// Runs right after other combinators (if implemented)
    d ..GenerateIfThenElseCode(pContext)

	d ..GenerateMaxAndMinPropertiesCode(pContext)

	d ..GenerateAddPropertiesCode(pContext)

	d ..GeneratePatternPropertiesCode(pContext)

	d ..GenerateDependenciesCode(pContext)

	$$$CWriteLine(" ; schema type is "_ schema.type,FunctionName)

	d ..CheckRequiredProps(pContext)


	s isArrayContext = 0

	#;Determine Iteration Source (Array or Object)
	if schema.type = "array" || (schema.%IsDefined("items")) {
		q:'schema.%IsDefined("items") ; Quit if array is defined but items are not
		$$$CWriteLine(" ;validate array items schema",FunctionName)

		if 'schema.items.%IsA("%DynamicArray") { ; Single item schema in array
			d $method(,"singleArr",pContext)
			q
		}
		#; If items is an array of schemas (tuple validation)
		s isArrayContext = 1
		s iter = schema.items.%GetIterator()
	}
	elseif schema.type="object"|| schema.%IsDefined("properties") {
		#;Standard object property iteration
		q:'schema.%IsDefined("properties")
		s iter = schema.properties.%GetIterator()
	}
	#; PRIMITIVE TYPES for additionalProperties sub-schemas
    elseif schema.type'="" {
        s type = schema.type
        d $method(, type, pContext)
        q
    }
    #; if then else
    elseif schema.properties'="" {
        s iter = schema.properties.%GetIterator()
    }
	#;Iterate Properties/Items
	while iter.%GetNext(.prop, .PropertySchema) {
		i isArrayContext {
			s dataRef = pContext.DataRef_ ".%Get("_prop_")"
		}
		else{
        	s dataRef = pContext.DataRef_ "."_$Select(prop["_":""""_prop_"""",1:prop)
		}
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

Method GenerateMaxAndMinPropertiesCode(pContext As %DynamicAbstractObject) [ Private ]
{
    s schema = pContext.Schema
    s FunctionName = pContext.TargetFunc
    q:schema.type'="object"
    q:'(schema.%IsDefined("maxProperties") || schema.%IsDefined("minProperties"))
    s code=""

    $$$WriteLine(" s keyCount = "_ pContext.DataRef _ ".%Size()", FunctionName)

    i schema.%IsDefined("maxProperties") {
        s maxProps = schema.maxProperties
        s failureCode = ..GetFailureCode(pContext, "maxProperties")
        s code = $$$FormatText(" i keyCount>%1 %2", maxProps, failureCode)
    }
    i schema.%IsDefined("minProperties") {
        s minProps = schema.minProperties
        s failureCode = ..GetFailureCode(pContext, "minProperties")
        s code = $$$FormatText(" i keyCount<%1 %2", minProps, failureCode)
    }
    i code'="" $$$WriteLine(code, FunctionName)
}

Method GenerateAddPropertiesCode(pContext As %DynamicAbstractObject) [ Private ]
{
    s schema = pContext.Schema
    s FunctionName = pContext.TargetFunc
    s DataRef = pContext.DataRef

    #;Only proceed if the schema is an object and the keyword is defined
    q:schema.type'="object"
    q:'schema.%IsDefined("additionalProperties")

    s apSchema = schema.additionalProperties
    ;s knownProps = schema.properties
	$$$WriteLine(" s knownProps="_DataRef_".properties", FunctionName)
    $$$WriteLine(" ; Start checking additionalProperties", FunctionName)
    $$$WriteLine(" s iter = "_ DataRef _ ".%GetIterator()", FunctionName)

    #; Loop over every key in the input JSON object
    $$$WriteLine(" while iter.%GetNext(.key, .value) {", FunctionName)

    #;Skip if the property is explicitly defined in 'properties'
    $$$WriteLine("  if knownProps.%IsDefined(key) continue", FunctionName)

    #; additionalProperties: false (Strict exclusion)
    i '$iso(apSchema) {
	    s oldFailureMode = pContext.FailureMode
        s pContext.FailureMode="ret"
        s failureCode = ..GetFailureCode(pContext, "additionalProperties")
        s pContext.FailureMode=oldFailureMode
        #;If we reach here, 'key' is NOT in 'properties', and additionalProps is false. Fail validation.
        $$$WriteLine($$$FormatText("  %1", failureCode), FunctionName)
    }
    elseif apSchema.%IsA("%DynamicAbstractObject") {
        s subSchemaContext = ..CreateContext( apSchema, DataRef_".%Get(key)","THROW",FunctionName)
        $$$WriteLine("  try {", FunctionName)
        d ..GenerateCode(subSchemaContext)
        $$$WriteLine("  } catch {", FunctionName)
        s oldFailureMode = pContext.FailureMode
        s pContext.FailureMode="ret"
        s failureCode = ..GetFailureCode(pContext, "additionalPropertiesSchema")
        s pContext.FailureMode=oldFailureMode
        $$$WriteLine($$$FormatText("  %1", failureCode), FunctionName)
        $$$WriteLine("  }", FunctionName)
    }
    $$$WriteLine(" }", FunctionName)
    $$$WriteLine(" ; End checking additionalProperties", FunctionName)
}

Method GeneratePatternPropertiesCode(pContext As %DynamicAbstractObject) [ Private ]
{
    s schema = pContext.Schema
    s FunctionName = pContext.TargetFunc
    s DataRef = pContext.DataRef
    #;Only proceed if the schema is an object and the keyword is defined
    q:schema.type'="object"
    q:'schema.%IsDefined("patternProperties")

    s patternProps = schema.patternProperties
    s patternIter = patternProps.%GetIterator()
    $$$WriteLine(" ; Start checking patternProperties", FunctionName)
    while patternIter.%GetNext(.pattern, .subSchema) {

        s QuotedPattern = """"_pattern_""""
        $$$WriteLine(" ; Pattern: "_ pattern, FunctionName)
        $$$WriteLine(" s iter = "_ DataRef _ ".%GetIterator()", FunctionName)
        $$$WriteLine(" while iter.%GetNext(.key, .value) {", FunctionName)
        $$$WriteLine("  if $MATCH(key, "_ QuotedPattern _ ") {", FunctionName)
        ;
        s subSchemaContext = ..CreateContext(subSchema, DataRef_".%Get(key)", "THROW", FunctionName)
        $$$WriteLine("   try {", FunctionName)
        d ..GenerateCode(subSchemaContext)
        $$$WriteLine("   } catch {", FunctionName)
        s generatedCode = $$$FormatText("    ret $$Error^%apiOBJ(5001, ""Property '""_key_""' failed patternProperties validation."")")
        $$$WriteLine(generatedCode, FunctionName)
        $$$WriteLine("   }", FunctionName) ; End catch
        $$$WriteLine("  }", FunctionName) ; End if $Match
        $$$WriteLine(" }", FunctionName) ; End Inner While (Data Iterator)
    }
    $$$WriteLine(" ; End checking patternProperties", FunctionName)
}

Method GenerateDependenciesCode(pContext As %DynamicAbstractObject) [ Private ]
{
    s schema = pContext.Schema
    s FunctionName = pContext.TargetFunc
    s DataRef = pContext.DataRef

    #;Only proceed if the schema is an object and the keyword is defined
    q:schema.type'="object"
    q:'schema.%IsDefined("dependencies")
    s dependencies = schema.dependencies
    s depIter = dependencies.%GetIterator()
    $$$WriteLine(" ; Start checking dependencies", FunctionName)
    while depIter.%GetNext(.requiredProp, .dependency) {

        s QuotedProp = """"_requiredProp_""""
        $$$WriteLine(" if "_ DataRef _ ".%IsDefined("_ QuotedProp _ ") {", FunctionName)
        i $IsObject(dependency) && dependency.%IsA("%DynamicArray") {

            #; Property Dependency (e.g., "credit_card": ["billing_address", "security_code"])
            s targetPropIter = dependency.%GetIterator()

            #; Loop over the list of required properties (e.g., "billing_address", "security_code")
            while targetPropIter.%GetNext(.i, .targetProp) {
	            s QuotedTargetProp = """"_targetProp_""""
                s failureCode = ..GetFailureCode(pContext, "dependencies")
                s failureMsg = "Property "_ QuotedTargetProp _ " is required by "_ QuotedProp _ "."
           		#; Generate runtime check: If the target property is NOT defined, fail.
                $$$WriteLine("  if '"_ DataRef _ ".%IsDefined("_ QuotedTargetProp _ ") {", FunctionName)
                $$$WriteLine("   "_ failureCode, FunctionName)
                $$$WriteLine("  }", FunctionName)
            }
        }

        #; Schema Dependency : Value is an object (a schema the whole object must satisfy)
        elseif $IsObject(dependency) && dependency.%IsA("%DynamicObject") {
            s subSchemaContext = ..CreateContext(dependency,  DataRef,  "THROW",  FunctionName)
            $$$WriteLine("  ; Schema Dependency triggered by "_ requiredProp, FunctionName)
            $$$WriteLine("  try {", FunctionName)
            d ..GenerateCode(subSchemaContext)
            $$$WriteLine("  } catch {", FunctionName)
            #; On failure, quit the whole validation process immediately
            s generatedCode = $$$FormatText("   ret $$Error^%apiOBJ(5001, ""Schema dependency triggered by %1 failed validation."")", QuotedProp)
            $$$WriteLine(generatedCode, FunctionName)
            $$$WriteLine("  }", FunctionName) // End CATCH
        }
        $$$WriteLine(" }", FunctionName) // End runtime IF (DataRef.%IsDefined)
    }
    $$$WriteLine(" ; End checking dependencies", FunctionName)
}

/// Internal Reference
/// External Reference
Method GenerateRefCode(pContext As %DynamicAbstractObject) [ Private ]
{
    #; The caller (GenerateCode) has already confirmed $ref is present.
    s schema = pContext.Schema
    s DataRef = pContext.DataRef
    s FunctionName = pContext.TargetFunc
    s refString = schema."$ref"
    s targetSchema = ..ResolveReference(refString, schema)
    i '$IsObject(targetSchema) {
        s failureMsg = "Failed to resolve schema reference: "_ refString
        $$$WriteLine($$$FormatText(" q $$Error^%%apiOBJ(5002, %1)", """" _ failureMsg _ """"), FunctionName)
        q
    }
    $$$WriteLine(" ; Applying $ref: "_ refString, FunctionName)
    s refContext = ..CreateContext(
        targetSchema,
        DataRef,
        pContext.FailureMode,
        FunctionName
    )
    d ..GenerateCode(refContext)
    $$$WriteLine(" ; End $ref application", FunctionName)
}

/// INPROGRESS : Testing required
/// Only handle internal references (starting with '#') for now
Method ResolveReference(pRefString As %String, pRootSchema As %DynamicAbstractObject) As %DynamicAbstractObject
{
    i $e(pRefString, 1)'="#" {
        q ..ResolveExternalReference(pRefString, pRootSchema)
    }
    s jsonPointer = $e(pRefString, 2, *)
    s target = pRootSchema

    #;Split the path into segments (e.g., "definitions", "Address")
    s numSegments = $l(jsonPointer, "/")

    #; Traverse the schema using the path segments
    for i = 1:1:numSegments {
        s segment = $p(jsonPointer,"/",i)
        continue:segment=""
        #;JSON Pointer decoding: '~1' -> '/', '~0' -> '~'
        s segment = $replace(segment, "~1", "/")
        s segment = $replace(segment, "~0", "~")
        #; Access the property on the current target object
        i target.%IsDefined(segment) {
            s target = target.Get(segment)
        } else {
            #;Path segment not found, invalid reference
            q
        }
        #;If the path traversal leads to a non-object/non-array, stop
        q:'$IsObject(target)
    }
    #;Return the resolved schema object
    q $i(target)
}

/// TODO: implementation of external api calls and files
ClassMethod ResolveExternalReference(pRefString, pRootSchema) As %DynamicAbstractObject
{
    s httpRequest = ##class(%Net.HttpRequest).%New()
    s httpStatus = 0
    s schemaObject = ""
    s pUrl = pRefString
    try {
        s httpRequest.Timeout = 10
        s httpRequest.Server = $p(pUrl, "/", 3)
        s httpRequest.Port = 80
        s httpRequest.URL = $e(pUrl, $l($p(pUrl, "/", 1, 3)) + 1, *)
        s sc = httpRequest.Get()
        s httpResponse =  httpRequest.HttpResponse
        s httpStatus =httpResponse.StatusCode
        i (sc && (httpStatus = 200)) {
            s jsonStream = httpResponse.Data
            i httpRequest.HttpResponse.ContentType="application/json" {
            	s schemaObject = ##class(%DynamicObject).%FromJSON(jsonStream)
            }
        }
    }
    catch {
	    s status=""
    }
    q status
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
    #; handel uniqueItems
    $$$WriteLine("  if $d(seenItems(singleArrIterValue)) ret $$Error^%apiOBJ(5001,""Array items must be unique."")",FunctionName)
    $$$WriteLine("  s seenItems(singleArrIterValue)=""""",FunctionName)
    s newContext = ..CreateContext(itemSchema,loopVar,"ret",pContext.TargetFunc,1)

    s type = itemSchema.type
    i (type="object")||(type="array") {
        d $method(,"GenerateCode", newContext)
    } else {
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
	i pContext.FailureMode="THROW" {
		set quitType="throw"
	}
	else{
		s quitType=pContext.FailureMode
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
		s failureCode = ..GetFailureCode(pContext,$$$strDT)
		i pContext.IsPrimitiveVar {
			#;Array Item Context (Local Variable)
			s generatedCode = $$$FormatText(" i $ISVALIDNUM(%1) %2", dataRef, failureCode)
		}
		Else{
			if dataRef["%Get" {
				s generatedCode=$$$FormatText(" i %1.%GetTypeCodeOf(%2) "_failureCode,$p(dataRef,".%Get("),$p($p(dataRef,".%Get(",2),")"))
			}
			else{
				s generatedCode = $$$FormatText(" i %1.%GetTypeCodeOf(""%2"")'=6 "_failureCode, $p(dataRef,".",1,*-1),$S($p(dataRef,".",*)["""":$TR($p(dataRef,".",*),""""),1:$p(dataRef,".",*)))
			}
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
		s failureCode = ..GetFailureCode(pContext,$$$intDT)
		i pContext.IsPrimitiveVar {
			#;Array Item Context (Local Variable)
			s generatedCode = $$$FormatText(" i '$ISVALIDNUM(%1) %2", dataRef, failureCode)
		}
		else{
			i dataRef["%Get" {
				s generatedCode=$$$FormatText(" i %1.%GetTypeCodeOf(%2) "_failureCode,$p(dataRef,".%Get("),$p($p(dataRef,".%Get(",2),")"))
			}
			else{
				s generatedCode = $$$FormatText(" i %1.%GetTypeCodeOf(%2)'=9 "_failureCode, $p(dataRef,".",1,*-1),$p(dataRef,".",*))
			}
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
		s failureCode = ..GetFailureCode(pContext,$$$boolDT)
		i pContext.IsPrimitiveVar {
			#;Array Item Context (Local Variable)
			s generatedCode = $$$FormatText(" i '$ISVALIDNUM(%1)%2", dataRef, failureCode)
		}
		else{
			i dataRef["%Get" {
				s generatedCode=$$$FormatText(" i %1.%GetTypeCodeOf(%2) "_failureCode,$p(dataRef,".%Get("),$p($p(dataRef,".%Get(",2),")"))
			}
			else {
				s generatedCode = $$$FormatText(" i %1.%GetTypeCodeOf(""%2"")'=3 "_failureCode, $p(dataRef,".",1,*-1),$p(dataRef,".",*))
			}
		}
		$$$WriteLine(generatedCode,FunctionName)
		$$$WriteLine($$$FormatText(" i $c(0,1)[$c(%1) %2",dataRef,error),FunctionName)
	}
	d ..GenerateConstCode(pContext)
	d ..GenerateEnumCode(pContext)
	d ..GenerateIfThenElseCode(pContext)
}

Method null(pContext)
{
	s schema = pContext.Schema
	s dataRef = pContext.DataRef
	S FunctionName=pContext.TargetFunc
	S FailureMode = pContext.FailureMode
	S SkipGenerate = pContext.SkipGenerate
	$$$CWriteLine(" ;null method validation for "_dataRef,FunctionName)
	s failureCode =..GetFailureCode(pContext,$$$nullDT)
	i 'SkipGenerate {
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
    s rtn = " q 0"
    s pMode = pContext.FailureMode
    s pDataRef = pContext.DataRef
    s propNameForMsg = $TR($P(pDataRef, ".", *), """")

    #;Check for array index access (e.g., DataRef.%Get(2))
    i propNameForMsg["%Get(" {
        s propNameForMsg = "index " _ +$P(propNameForMsg, "%Get(", 2)
    }
    #; Handle root object reference
    i (propNameForMsg = "") || (propNameForMsg = "%JSON") {
        s propNameForMsg = "ROOT object"
    }
    s genericMsg = ..ErrorMap.%Get(constraintType)
    s errorMsg = $Replace(genericMsg, "%", propNameForMsg)
    i pMode = "THROW" {
        s rtn = "throw"
    }
    elseif (pMode = "ret") || (pMode = "q") {
        s rtn = $$$FormatText(pMode_" $$Error^%apiOBJ(5001,""%1"")", errorMsg)
    }
    q rtn
}

/// <METHOD>GetErrorMap</METHOD> is a unified error Mappings as a key-value pair
ClassMethod GetErrorMap() As %DynamicObject
{
    s map = ##class(%DynamicObject).%New()
    d map.%Set("","% failed a general validation constraint")
    d map.%Set("default","% failed a general validation constraint")

    #; datatypes
	d map.%Set("stringDT", "% must be a string data type")
    d map.%Set("booleanDT", "% must be a boolean data type")
    d map.%Set("nullDT", "% must be a null data type")
    d map.%Set("integerDT", "% must be an integer data type")  // Corrected key to DT
    d map.%Set("numberDT", "% must be a number type")
    d map.%Set("objectDT", "% must be an object type")
    d map.%Set("arrayDT", "% must be an array type")
    d map.%Set("datatype", "% failed required data type check")

    #; string/number constraints
    d map.%Set("minLength", "% failed minimum length check")
    d map.%Set("maxLength", "% failed maximum length check")
    d map.%Set("minmax", "% failed maximum and minimum length check")
    d map.%Set("maxmin", "% failed maximum and minimum length check")
    d map.%Set("exclusiveMinimum", "% must be strictly greater than exclusive minimum")
    d map.%Set("multipleOf","Property % does not match the expected multipleOf value")
    d map.%Set("const","% must match with const value")
    d map.%Set("pattern", "% failed pattern validation")
    d map.%Set("format", "% must match with the format")
    d map.%Set("enum", "Invalid value of property %. Value must match one of the allowed enum items.")

    #; number constraints
    d map.%Set("minimum", "% must be greater than or equal to minimum")
    d map.%Set("exclusiveMinimum", "% must be strictly greater than exclusive minimum")
    d map.%Set("maximum", "% must be less than or equal to maximum") // Added
    d map.%Set("exclusiveMaximum", "% must be strictly less than exclusive maximum") // Added

    #;object/array size constraints
    d map.%Set("minItems", "% failed minimum size check (items)")
    d map.%Set("maxItems", "% failed maximum size check (items)")
    d map.%Set("minProperties", "The actual count is less than the minimum required")
    d map.%Set("maxProperties", "The actual count of object is greater than the maximum allowed")
    d map.%Set("minContains","% must contain a minimum of X items matching the subschema")
    d map.%Set("maxContains","% must contain a maximum of X items matching the subschema")
    d map.%Set("contains","% must contain at least one item matching the subschema")
    d map.%Set("uniqueItems","% must not contain duplicate items")
    #;
    #; combinators
    d map.%Set("allOf", "Data failed to match all schemas specified in allOf")
    d map.%Set("oneOf", "Data must match exactly one schema specified in oneOf")
    d map.%Set("anyOf", "Data must match at least one schema specified in anyOf")
    #;
    #; additional properties

    d map.%Set("additionalProperties","additionalProperties error")
    d map.%Set("objAdditonalPropsSchema","Additional property failed sub-schema validation")
    d map.%Set("propertyNames","The object's property names must match the propertyNames schema")
    d map.%Set("dependencies","Dependency check failed: % requires the presence of other properties")
    d map.%Set("dependentRequired","The presence of property % requires other specified properties")
    d map.%Set("dependentSchemas","The presence of property % requires a dependent schema validation to pass")
    ;
    #; Misc/Value Errors
    d map.%Set("boolvalue","% value must be true or false")
    d map.%Set("required","The required property % is missing")
    d map.%Set("not","Data must not be valid against the 'not' schema")
    q map
}

/// Proeprty max,min and additional length checks
Method GenerateLenCode(pContext)
{
    s (min,amx,lenExpr)=""
	s PropertySchema = pContext.Schema
	s type = PropertySchema.type
	S dataRef = pContext.DataRef
	S FunctionName= pContext.TargetFunc
	$$$CWriteLine(" ; Size/Length validation check", FunctionName)
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

    i min'=""&&(max'=""){
	    s error = ..GetFailureCode(pContext,"maxmin")
	    s code = $$$FormatText(" i '$IsValidNum(%1,,%2,%3) %4", lenExpr, min, max, error)
    }
    elseif min'=""{
	    S error = ..GetFailureCode(pContext,"minLength")
	    s code = $$$FormatText(" i %1<%2 %3", lenExpr, +min, error)
    }
    elseif max'=""{
	   S error = ..GetFailureCode(pContext,"maxLength")
	   s code = $$$FormatText(" i %1>%2 %3", lenExpr, +max, error)
    }
    i code'="" $$$WriteLine(code,FunctionName)
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
}

Method GeneratePatternCode(pContext As %DynamicObject)
{
    s schema = pContext.Schema
    q:'schema.%IsDefined("pattern")
    s pattern = schema.pattern
    s dataRef = pContext.DataRef
    s functionName = pContext.TargetFunc
    $$$CWriteLine(" ; pattern check for "_dataRef,functionName)
    s generatedCode = $$$FormatText(" i '$match(%1,""%2"") %3", dataRef, pattern, ..GetFailureCode(pContext, "pattern"))
    $$$WriteLine(generatedCode,functionName)
}

Method GenerateFormatCode(pContext)
{
	s schema = pContext.Schema
    q:'schema.%IsDefined("format")
    s format=schema.format
    s dataRef = pContext.DataRef
    s FunctionName = pContext.TargetFunc
	$$$CWriteLine(" ; "_format_" format check "_dataRef,FunctionName)
	s regex = ..RegexFormats(format)
	s error = ..GetFailureCode(pContext, "format")
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
	$$$WriteLine($$$FormatText(" i (%1/%2)[""."" %3",dataRef,multipleOf,error),FunctionName)
}

Method GenerateConstCode(pContext)
{
	s schema = pContext.Schema
    q:'schema.%IsDefined("const")
    s const=schema.const
    s dataRef = pContext.DataRef
    s type=schema.type
    s FunctionName = pContext.TargetFunc
	$$$CWriteLine(" ; const check",FunctionName)
	s error = ..GetFailureCode(pContext, "const")
	$$$WriteLine($$$FormatText(" i %1'=""%2"" %3", dataRef, const, error),FunctionName)
}

Method GenerateIfThenElseCode(pContext As %DynamicAbstractObject) [ Private ]
{
    s schema = pContext.Schema
    s DataRef = pContext.DataRef
    s FunctionName = pContext.TargetFunc
    q:'schema.%IsDefined("if")
    s IfCheckVar = "IfCheckSuccess" ;We'll generate a temp variable named 'IfCheckSuccess'

    $$$WriteLine(" ; Start if/then/else validation", FunctionName)

    $$$WriteLine(" s "_ IfCheckVar _ " = 0", FunctionName) // Initialize flag to 0 (Failure)
    $$$WriteLine(" try {", FunctionName)

    // Create context for the 'if' sub-schema. We use a custom failure mode here
    // so the error is caught locally, not thrown out globally.
    s ifContext = ..CreateContext( schema."if", DataRef, "THROW", FunctionName)

    d ..GenerateCode(ifContext)

    #; If the recursive validation completes without error, set the flag to 1 (Success)
    $$$WriteLine("  s "_ IfCheckVar _ " = 1", FunctionName)
    $$$WriteLine(" } catch {", FunctionName)

    #;If the 'if' validation fails, $ZERROR is set, the flag remains 0. Clear $ZERROR to proceed.
    $$$WriteLine("  s $ZERROR = """" ; Clear error status so we can continue to the ELSE block", FunctionName)
    $$$WriteLine(" }", FunctionName)

    #;Generate The 'Then' And 'Else' Branches

    #; If the 'if' condition passed
    $$$WriteLine(" if "_ IfCheckVar _ " {", FunctionName)

    #; then Block: Recursively validate against the 'then' schema if it exists
    i schema.%IsDefined("then") {
        s thenContext = ..CreateContext(schema."then", DataRef, "THROW", FunctionName)
        $$$WriteLine("  ; Applying THEN schema", FunctionName)
        d ..GenerateCode(thenContext) // THROW mode here will fail the entire process if 'then' fails
    }

    #;Else If The 'If' Condition Failed
    $$$WriteLine(" } else {", FunctionName)

    #; Else Block: Recursively validate against the 'else' schema if it exists
    i schema.%IsDefined("else") {
        s elseContext = ..CreateContext(schema."else", DataRef, "THROW", FunctionName)
        $$$WriteLine("  ; Applying ELSE schema", FunctionName)
        d ..GenerateCode(elseContext) // THROW mode here will fail the entire process if 'else' fails
    }

    $$$WriteLine(" }", FunctionName) ; End runtime if/else
    $$$CWriteLine(" ; End if/then/else validation", FunctionName)
}

Method CodeType(datatype) [ CodeMode = expression, Internal ]
{
$case(datatype,"string":6,"integer":9,"number":9,"boolean":4,"object":18,"array":17,"null":2,:"")
}

Method WriteCodeToTarget(pCode, pFunctionName = "")
{
    i pFunctionName="" {
	    s %fjscode("0fjs",$i(%fjscode)) = pCode
    }
    else {
	    ; use this for creating support function/procedures
	    #; Write to the function array: %fjscode("FunctionName", index)
        s %fjscode(pFunctionName, $i(%fjscode(pFunctionName))) = pCode
    }
    q
}

ClassMethod %INCLUDE(pCode As %String)
{
	#define CWriteLine(%code,%f)	d:'..CompilerFlags.GenerateComments ..WriteCodeToTarget(%code,%f)
	#define WriteLine(%code,%f)		d ..WriteCodeToTarget(%code,%f)

	#define intDT					"integerDT"
	#define strDT					"stringDT"
	#define boolDT					"booleanDT"
	#define nullDT					"nullDT"
	#define objDT					"objectDT"
	#define arrDT					"arrayDT"
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
    i alloneanyOf="oneOf" {
        #;Must match exactly one: comboPasses must equal 1.
        $$$WriteLine($$$FormatText(" i comboPasses'=1 %1", ..GetFailureCode(pContext,"oneOf")), functionName)
    }
    elseif alloneanyOf="anyOf" {
        #;Must match at least one: comboPasses must be greater than 0.
        $$$WriteLine($$$FormatText(" i comboPasses=0 %1", ..GetFailureCode(pContext,"anyOf")), functionName)
    }
    elseif alloneanyOf="allOf" {
        #;Must match all: comboPasses must equal the number of sub-schemas.
        s numSubSchemas = subSchemas.%Size()
        $$$WriteLine($$$FormatText(" i comboPasses'=%1 %2", numSubSchemas, ..GetFailureCode(pContext,"allOf")), functionName)
    }
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
	s FunctionName = pContext.TargetFunc
	s schema = pContext.Schema
	s DataRef = pContext.DataRef
	$$$WriteLine("%validate("_DataRef_")",FunctionName)
	$$$WriteLine(" s $zt=""err""",FunctionName)
	$$$WriteLine(" d $zu(18,2)",FunctionName)
	$$$WriteLine(" s $ze="""",$ec="""" ",FunctionName)
	$$$WriteLine(" n ("_DataRef_")",FunctionName)
	$$$WriteLine(" s:'$iso("_DataRef_") %JSON={}.%FromJSON(%JSON)",FunctionName)
	$$$WriteLine(" i '$iso(%JSON)||('%JSON.%IsA(""%DynamicAbstractObject"")) q $$Error^%apiOBJ(16002)",FunctionName)
}

Method basicinfo(pContext) [ Internal, Private ]
{
	s FunctionName = pContext.TargetFunc
	$$$WriteLine(" q 1 ; no direct routine execute",FunctionName)
	q:'..CompilerFlags.GenerateComments
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
	$$$WriteLine("err ret $ze",FunctionName)
	i ..CompilerFlags.PackageName'="" {
		s package=..CompilerFlags.PackageName
	}
	else{
		s package="fjsschema"
	}
	s rot=package_"."_..Name
	i ..CompilerFlags.KeepSource {
		s routine = ##class(%Routine).%New(rot_".int")
		s routine.Generated=1
		i $iso(routine) {
			;write the code first
			f i=1:1:%fjscode("0fjs") d routine.WriteLine(%fjscode("0fjs",i))
			#;write the supporing functions
			s func=""
			f {
				s func=$o(%fjscode(func))  q:func=""
				continue:func="0fjs"
				f i=1:1:%fjscode(func) d routine.WriteLine(%fjscode(func,i))
			}
			}
		s rtn=routine.%Save()
		d routine.Compile()
	}
	else {
		s %ffcode(0)=%fjscode("0fjs")
		m %ffcode=%fjscode("0fjs")
		#;write the supporing functions
		s func=""
		f {
			s func=$o(%fjscode(func))  q:func=""
			continue:func="0fjs"
			s previousCnt=%ffcode(0)
			s %ffcode(0)=%ffcode(0)+%fjscode(func)
			f i=1:1:%fjscode(func) s %ffcode(previousCnt+i)=%fjscode(func,i)
		}
		s rtn=$COMPILE(%ffcode,0,errs,,,,rot)
    	i rtn=0 {w "Schema """_..Name_""" compiled successfully",! s rtn=1}
    	else {w "Schema compilation failred return code: ",rtn,! zw errs s rtn=0}
	}
	ret rtn
}

Method %OnNew(pSchemaName As %String = "", CompilerFlags As %Boolean = 0) As %Status
{
	s ..Name = pSchemaName
	s ..CompilerFlags = CompilerFlags
	s ..ErrorMap = ..GetErrorMap()
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
