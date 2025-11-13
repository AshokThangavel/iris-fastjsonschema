Class FastJsonSchema.Tests.TestUtils Extends %RegisteredObject
{

/// include testcases in future
/// for now uses as a utils
/// test 5 and 7 for array fix : inrogress
/// need to validate schema 11
/// need to validate schema 8,6,7,11
ClassMethod RunSingleTest(pSchemaName = "Test5", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 1)
{
	Set pSchema = ##class(TestDatas).SampleSchema5()
	Set sc = ##class(FastJsonSchema.Compiler1).Compile(pSchemaName, pSchema, pKeepSource)
	if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
}

ClassMethod RullAllTest(pSchemaName = "", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 1)
{
	F i=1:1:13 {
		s pSchemaName = "Test"_i
		s pSchema = $ClassMethod("FastJsonSchema.Tests.TestDatas","SampleSchema"_i)
		Set sc = ##class(FastJsonSchema.Compiler1).Compile(pSchemaName, pSchema, pKeepSource)
		if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
	}
}

ClassMethod ValidateTestCase(pSchemaName, JSON)
{
    ret ##class(FastJsonSchema.Core).Validate(pSchemaName, JSON)
}

}
