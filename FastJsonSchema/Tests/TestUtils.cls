Class FastJsonSchema.Tests.TestUtils Extends %RegisteredObject
{

/// include testcases in future
/// for now uses as a utils
ClassMethod RunSingleTest(pSchemaName = "Test8", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 1)
{
	Set pSchema = ##class(TestDatas).SampleSchema8()
	Set sc = ##class(FastJsonSchema.Compiler).Compile(pSchemaName, pSchema, pKeepSource)
	if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
}

ClassMethod RullAllTest(pSchemaName = "", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 1)
{
	F i=1:1:8 {
		s pSchemaName = "Test"_i
		s pSchema = $ClassMethod("FastJsonSchema.Tests.TestDatas","SampleSchema"_i)
		Set sc = ##class(FastJsonSchema.Compiler).Compile(pSchemaName, pSchema, pKeepSource)
		if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
	}
}

ClassMethod ValidateTestCase(pSchemaName, JSON)
{
    ret ##class(FastJsonSchema.Core).Validate(pSchemaName, JSON)
}

}
