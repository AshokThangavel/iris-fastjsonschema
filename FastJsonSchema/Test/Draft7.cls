Class FastJsonSchema.Test.Draft7 Extends %RegisteredObject
{

ClassMethod RunSingleTest(pSchemaName As %String = "", pSchema As %DynamicObject = "", CompileParameters = "DEBUG") As %Status
{
	///default values
	Set:pSchema="" pSchema="Test17"
	Set:'$IsObject(pSchema) pSchema = ##class(FastJsonSchema.Test.Data.Draft7).SampleSchema17()
	Set sc = ##class(FastJsonSchema.Core).Compile(pSchema, pSchemaName, CompileParameters)
	If $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
	Return sc
}

ClassMethod RullAllTest(pSchemaName = "", pSchema As %DynamicObject = "", CompileParameters = "DEBUG") As %Status
{
	F i=1:1:19 {
		s pSchemaName = "Test"_i
		s pSchema = $ClassMethod("FastJsonSchema.Test.Data.Draft7","SampleSchema"_i)
		continue:'$iso(pSchema)
		Set sc = ##class(FastJsonSchema.Core).Compile(pSchema, pSchemaName, CompileParameters)
		If $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
	}
}

ClassMethod ValidateTestCase(pSchemaName, JSON)
{
    Return ##class(FastJsonSchema.Core).Validate(pSchemaName, JSON)
}

}
