Class FastJsonSchema.Compiler.Parameters Extends %RegisteredObject
{

/// Primary Control: Maps to "DEBUG", "BALANCED", "SPEED" or "CUSTOM".
/// SPEED - Amins to maximum performance benefits
Property OptimizationLevel As %String(MAXLEN = 10) [ InitialExpression = "SPEED" ];

///  Feature/Speed Toggle: If False, skips code generation for the 'format' keyword.
Property UseFormats As %Boolean [ InitialExpression = 1 ];

/// TODO: Feature/Speed Toggle: If False, skips code generation for ContentMediaType/ContentEncoding.
Property UseContentChecks As %Boolean [ InitialExpression = 0 ];

/// Behavior Toggle: If False, skips code to insert values from the 'default' keyword.
Property UseDefaults As %Boolean [ InitialExpression = 0 ];

/// Debugging vs. Speed: If False, generates minimal error messages without detailed path/context.
Property DetailedExceptions As %Boolean [ InitialExpression = 0 ];

/// Debugging Output: If False, suppresses all $$$CWriteLine comments in the generated routine.
Property GenerateComments As %Boolean [ InitialExpression = 0 ];

/// Deployment Control: Allows specifying the package name for the compiled routines (e.g., ^<PackageName>.<SchemaName>).
Property PackageName As %String [ InitialExpression = "fjsschema" ];

/// Keep the source int file if the flag is enabled
Property KeepSource As %Boolean [ InitialExpression = 0 ];

/// Method called after instantiation to ensure all boolean flags are correctly set
/// based on the user-defined OptimizationLevel.
ClassMethod Create(pFlag = "SPEED", Output CompilerParamsObj As FastJsonSchema.Compiler.Parameters) As %Status [ CodeMode = expression ]
{
..%New().Initialize(pFlag, .CompilerParamsObj)
}

Method IsHighOptimizeLevel() As %Boolean [ CodeMode = expression ]
{
..OptimizationLevel="SPEED"
}

Method IsVerboseMode() As %Boolean [ CodeMode = expression ]
{
..OptimizationLevel="DEBUG"
}

Method IsBalancedMode() As %Boolean [ CodeMode = expression ]
{
..OptimizationLevel="BALANCED"
}

Method IsCustomMode() As %Boolean [ CodeMode = expression ]
{
..OptimizationLevel="CUSTOM"
}

Method Initialize(pFlag, Output CompilerParamsObj As FastJsonSchema.Compiler.Parameters) As %Status [ Internal, Private ]
{
	If pFlag="" Set FLAG="SPEED"
    If '$IsObject(pFlag) {
        Set FLAG = $Select(pFlag'="":$ZConvert(pFlag, "U"), 1:"SPEED")
        Do $Method(, FLAG)
    }
    Else {
        Set ..OptimizationLevel = $ZConvert(pFlag.%Get("OptimizationLevel", "CUSTOM"), "U")
        #dim iterator As %DynamicObject = pFlag.%GetIterator()
         While iterator.%GetNext(.key, .value) {
	         If '##class(%Dictionary.CompiledProperty).%ExistsId($classname()_"||"_key) {
                Return $$$ERROR($$$GeneralError,"Invalid flag "_key)
             }
            Set $Property(, key) = value
        }
    }
    Set CompilerParamsObj = $this
    Return $$$OK
}

Method SPEED() As %Status
{
	Set ..OptimizationLevel = "SPEED"
	Set ..DetailedExceptions = 0
	Set ..UseFormats = 1
	Set ..UseContentChecks = 0
	Set ..UseDefaults = 0
	Set ..GenerateComments = 0
	Set ..KeepSource = 0
	Quit $$$OK
}

Method BALANCED() As %Status
{
	Set ..OptimizationLevel = "BALANCED"
	Set ..DetailedExceptions = 1
	Set ..UseFormats = 1
	Set ..UseContentChecks = 0
	Set ..UseDefaults = 1
	Set ..GenerateComments = 0
	Set ..KeepSource = 0
	Quit $$$OK
}

Method DEBUG() As %Status
{
	Set ..OptimizationLevel="DEBUG"
    Set (..DetailedExceptions,..UseFormats,..UseContentChecks,..UseDefaults,..GenerateComments,..KeepSource) = 1
    Quit $$$OK
}

}
