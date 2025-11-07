Class FastJsonSchema.Tests.TestCases Extends %RegisteredObject
{

/// include testcases in future
/// for now uses as a utils
ClassMethod DebugCompile(pSchemaName = "Test8", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 1)
{
	Set pSchema = ##class(TestDatas).SampleSchema8()
	Set obj = ##class(FastJsonSchema.Compiler).%New(pSchemaName, pSchema, pKeepSource)
}

}
