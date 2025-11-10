Class FastJsonSchema.Tests.TestCases Extends %UnitTest.TestCase
{

Method TestSchema5()
{
	;generate schema
	Set st = ##class(TestUtils).RunSingleTest("Test5",##class(TestDatas).SampleSchema5())
	Do $$$AssertEquals(st,1, st)
	;validate the schema
	Do $$$AssertEquals(##class(TestUtils).ValidateTestCase("Test5", ##class(TestDatas).SampleSchemaData5(1)), 1, "schema matched with data")
    Do $$$AssertNotEquals(##class(TestUtils).ValidateTestCase("Test5", ##class(TestDatas).SampleSchemaData5(0)), 1, "schema not matched with data")
}

}
