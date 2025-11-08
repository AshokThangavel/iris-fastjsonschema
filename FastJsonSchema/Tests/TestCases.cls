Class FastJsonSchema.Tests.TestCases Extends %UnitTest.TestCase
{

/// include testcases in future
/// for now uses as a utils
ClassMethod DebugCompile(pSchemaName = "Test3", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 1)
{
	Set pSchema = ##class(TestDatas).SampleSchema3()
	Set sc = ##class(FastJsonSchema.Compiler).Compile(pSchemaName, pSchema, pKeepSource)
	if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
}

}
