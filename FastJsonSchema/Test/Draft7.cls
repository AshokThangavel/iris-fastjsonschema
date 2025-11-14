Class FastJsonSchema.Test.Draft7 Extends %RegisteredObject
{

ClassMethod RunSingleTest(pSchemaName = "Test1", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 1)
{
	Set pSchema = ##class(FastJsonSchema.Test.Data.Draft7).SampleSchema1()
	Set sc = ##class(FastJsonSchema.Compiler.Draft7).Compile(pSchemaName, pSchema, pKeepSource)
	if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
}

ClassMethod RullAllTest(pSchemaName = "", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 1)
{
	F i=1:1:18 {
		s pSchemaName = "Test"_i
		s pSchema = $ClassMethod("FastJsonSchema.Test.Data.Draft7","SampleSchema"_i)
		Set sc = ##class(FastJsonSchema.Compiler.Draft7).Compile(pSchemaName, pSchema, pKeepSource)
		if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
	}
}

ClassMethod ValidateTestCase(pSchemaName, JSON)
{
    ret ##class(FastJsonSchema.Core).Validate(pSchemaName, JSON)
}

}
