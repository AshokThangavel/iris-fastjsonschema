Class FastJsonSchema.Core Extends %RegisteredObject
{

/// The <METHOD>Compile</METHOD> method generates fastjsonschema code from a given JSON schema.
/// <br><br>
/// Parameters
/// <br><br>
/// <b><var>pSchema</var></b> — The JSON schema used as input for code generation.
/// <p>
/// <b><var>pSchemaName</var></b>  — The name assigned to the generated schema. This name can be used later for schema validation.
/// <p>
/// <b><var>KeepSource</var></b>  — (Optional) A debug flag. The default value is 0.
/// Set this to 1 to retain the raw generated code for debugging purposes.
/// <br><br>
/// <EXAMPLE>
/// Set sc = ##class(FastJsonSchema.Core).Compile(schema,schemaName,keepSoruce)
/// </EXAMPLE>
ClassMethod Compile(pSchema As %DynamicObject = "", pSchemaName As %String = "", KeepSoruce As %Boolean = 0) As %Status
{
	d $SYSTEM.Process.Undefined(2)

	Set:'$IsObject(pSchema) pSchema = {}.%FromJSON(pSchema)
	If '$IsObject(pSchema) {
		Return $$$ERROR($$$GeneralError, "Invalid JSON schema provided.")
	}
	If $Get(pSchemaName)="" {
		Set pSchemaName = "fjsschema"_$TRanslate($Horolog,",")
	}
	Set schemaCls=..IsSchemaImplemented(pSchema."$schema",.schemaCls)
	If $$$ISERR(schemaCls){
		Return schemaCls
	}
	Set st = $ClassMethod("FastJsonSchema."_schemaCls, pSchemaName, pSchema, KeepSoruce)
	Return st
}

/// <METHOD>Validate</METHOD> method is used to execute the generated fastjsonschema code against the provided JSON data
/// <br>
/// Parameters
/// <br><br>
/// <b><var>pSchemaName</var></b> The 'pSchemaName' argument specifies the name of the generated schema used for validation
/// <p>
/// <b><var>pJSON</var></b> The 'pJSON' argument represents the actual JSON data to be validated, passed as an object
/// <EXAMPLE>
/// Set sc = ##class(FastJsonSchema.Core).Validate(schemaName, pJSON)
/// </EXAMPLE>
ClassMethod Validate(pSchemaName As %String = "", pJson As %DynamicObject) As %Status
{
	If $Get(pSchemaName)="" {
		Return $$$ERROR($$$GeneralError, "Schema name is required for validation.")
	}
	If pJson="" {
		Return $$$ERROR($$$GeneralError, "JSON is required for validation.")
	}
	If $IsObject(pJson) {
		Set pJson = pJson.%ToJSON()
	}
	Return $Xecute("quit $$%validate^fjsschema."_pSchemaName_"("_pJson_") ")
}

ClassMethod IsSchemaImplemented(pSchema As %String = "", Output pSchemaClass As %String) As %Boolean
{
    #;Extract the draft version (e.g., "draft-07")
    Set draftVersion = $Piece(pSchema,"/",4)
    #dim schemaDict as %DynamicObject = ..SupportedJSONSchemaList()
    If schemaDict.%IsDefined(draftVersion) {
        Set pSchemaClass = schemaDict.%Get(draftVersion)
        Quit $$$OK
    }
    Quit $$$ERROR($$$GeneralError, "Unsupported JSON Schema draft: "_draftVersion)
}

/// include the draft names in the below list.
/// key: draft version
/// value: Specific implementation class for that draft
ClassMethod SupportedJSONSchemaList() As %DynamicObject [ CodeMode = expression ]
{
{
"draft-07": "Compiler.Draft7"
}
}

}
