Class FastJsonSchema.Compiler.Parameters Extends %RegisteredObject
{

/// Primary Control: Maps to "DEBUG", "BALANCED", "SPEED" or "CUSTOM".
/// SPEED - Amins to maximum performance benefits
Property OptimizationLevel As %String(MAXLEN = 8) [ InitialExpression = "SPEED" ];

/// TODO: Feature/Speed Toggle: If False, skips code generation for the 'format' keyword.
Property UseFormats As %Boolean [ InitialExpression = 1 ];

/// TODO: Feature/Speed Toggle: If False, skips code generation for ContentMediaType/ContentEncoding.
Property UseContentChecks As %Boolean [ InitialExpression = 0 ];

/// TODO: Behavior Toggle: If False, skips code to insert values from the 'default' keyword.
Property UseDefaults As %Boolean [ InitialExpression = 0 ];

/// TODO: Debugging vs. Speed: If False, generates minimal error messages without detailed path/context.
Property DetailedExceptions As %Boolean [ InitialExpression = 0 ];

/// Debugging Output: If False, suppresses all $$$CWriteLine comments in the generated routine.
Property GenerateComments As %Boolean [ InitialExpression = 0 ];

/// Deployment Control: Allows specifying the package name for the compiled routines (e.g., ^<PackageName>.<SchemaName>).
Property PackageName As %String [ InitialExpression = "fjsschema" ];

/// Keep the source int file if the flag is enabled
Property KeepSource As %Boolean [ InitialExpression = 0 ];

/// Method called after instantiation to ensure all boolean flags are correctly set
/// based on the user-defined OptimizationLevel.
ClassMethod Create(pInput = "SPEED", Output obj As FastJsonSchema.Compiler.Parameters) As %Status
{
	Set obj= ..%New()
	Set st = obj.InitializeInternal(pInput)
	ret st
}

Method InitializeInternal(pInput) As %Status [ Internal, Private ]
{
	If pInput="" S FLAG="SPEED"
    If '$IsObject(pInput) {
        Set FLAG = $Select(pInput'="":$ZConvert(pInput, "U"), 1:"SPEED")
        Set ..OptimizationLevel = FLAG
        Do $Method(, FLAG)
    }
    Else {
        Set ..OptimizationLevel = $ZConvert(pInput.%Get("OptimizationLevel", "CUSTOM"), "U")
        #dim iterator As %DynamicObject = pInput.%GetIterator()
         While iterator.%GetNext(.key, .value) {
	         If '##class(%Dictionary.CompiledProperty).%ExistsId($classname()_"||"_key) {
                Return $$$ERROR($$$GeneralError,"Invalid flag "_key)
             }
            Set $Property(, key) = value
        }
    }
    Return $$$OK
}

Method SPEED()
{
	Set ..DetailedExceptions = 0
	Set ..UseFormats = 1
	Set ..UseContentChecks = 0
	Set ..UseDefaults = 0
	Set ..GenerateComments = 0
	Set ..KeepSource = 0
}

Method BALANCED()
{
	Set ..DetailedExceptions = 1
	Set ..UseFormats = 1
	Set ..UseContentChecks = 0
	Set ..UseDefaults = 1
	Set ..GenerateComments = 0
	Set ..KeepSource = 0
}

Method DEBUG()
{
    Set ..DetailedExceptions = 1
    Set ..UseFormats = 1
    Set ..UseContentChecks = 1
    Set ..UseDefaults = 1
    Set ..GenerateComments = 1
    Set ..KeepSource = 1
}

}
