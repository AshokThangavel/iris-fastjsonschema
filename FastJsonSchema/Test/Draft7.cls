Class FastJsonSchema.Test.Draft7 Extends %RegisteredObject
{

ClassMethod RunSingleTest(pSchemaName = "Test8", pSchema As %DynamicObject = "", CompileParameters = "DEBUG")
{
	Set pSchema = ##class(FastJsonSchema.Test.Data.Draft7).SampleSchema8()
	Set sc = ##class(FastJsonSchema.Core).Compile(pSchema, pSchemaName, CompileParameters)
	if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
}

ClassMethod RullAllTest(pSchemaName = "", pSchema As %DynamicObject = "", CompileParameters = "DEBUG")
{
	F i=1:1:18 {
		s pSchemaName = "Test"_i
		s pSchema = $ClassMethod("FastJsonSchema.Test.Data.Draft7","SampleSchema"_i)
		continue:'$iso(pSchema)
		Set sc = ##class(FastJsonSchema.Core).Compile(pSchema, pSchemaName, CompileParameters)
		if $$$ISERR(sc) W $SYSTEM.OBJ.DisplayError(sc)
	}
}

ClassMethod ValidateTestCase(pSchemaName, JSON)
{
    ret ##class(FastJsonSchema.Core).Validate(pSchemaName, JSON)
}

}
