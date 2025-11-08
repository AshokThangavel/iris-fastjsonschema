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
ClassMethod Compile(pSchema As %DynamicObject, pSchemaName As %String = "", KeepSoruce As %Boolean = 0)
{
	Set:'$IsObject(pSchema) pSchema = {}.%FromJSON(pSchema)
	If '$IsObject(pSchema) {
		Return "Invalid JSON schema provided."
	}
	If $Get(pSchemaName)="" {
		Set pSchemaName = "fjsschema"_$TRanslate($H,",")
	}
	Return ##class(FastJsonSchema.Compiler).Compile(pSchemaName, pSchema, KeepSoruce)
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
ClassMethod Validate(pSchemaName As %String = "", pJson As %DynamicObject)
{
	If $Get(pSchemaName)="" {
		Return "Schema name is required for validation."
	}
	If pJson="" {
		Return "JSON data is required for validation."
	}
	If $IsObject(pJson) {
		Set pJson = pJson.%ToJSON()
	}
	Return $Xecute("quit $$%validate^fjsschema."_pSchemaName_"("_pJson_") ")
}

}
