Class FastJsonSchema.Compiler Extends %RegisteredObject [ Final ]
{

Property Name As %String;

Property Schema As %DynamicAbstractObject;

Property ProcessesFields [ MultiDimensional ];

Property KeepSource As %Boolean [ InitialExpression = 0 ];

ClassMethod Compile(pSchemaName = "", pSchema As %DynamicObject = "", pKeepSource As %Boolean = 0) [ CodeMode = expression, Internal ]
{
..%New(pSchemaName, pSchema, pKeepSource).CompileInternal()
}

Method CompileInternal() As %Status [ Internal, Private ]
{
	d $SYSTEM.Process.Undefined(2)
	k %fjscode
	try{
		d ..basicinfo()
		d ..configfunc()
		d ..GenerateCode()
		s sc= ..Savefjs()
	}
	catch ex{
		s sc=ex.AsStatus()
	}
	q sc
}

Method sarr(propobj)
{
	s prop="input"
	s %fjscode($i(%fjscode))=" i '$iso(%JSON)||('%JSON.%IsA(""%DynamicArray"")) q ""given input is not array"" "
	s:propobj.%IsDefined("minLength") min = propobj.minLength
	s:propobj.%IsDefined("maxLength") max = propobj.maxLength
	s:propobj.%IsDefined("pattern") pat=propobj.pattern
	if min'=""||(max'="") s %fjscode($i(%fjscode))=" i $isvalidnum(%JSON.size(),,"_min_","_max_") q ""array size not meets the schema definition"""
	i propobj.%IsDefined("enum")  d ..enum(propobj.enum)
	i pat'="" {
		s:..KeepSource %fjscode($i(%fjscode))=" ; pattern check"
		s %fjscode($i(%fjscode))=" i '$match(%JSON,"""_pat_""") q ""pattern not match with "_prop_" data"""
	}
	d:propobj.%IsDefined("format") ..format(propobj.format,prop)
	s:propobj.%IsDefined("const") %fjscode($i(%fjscode))=" i %JSON."_prop_"'="""_propobj.const_""" q """_prop_"  value must be "_propobj.const_""""
	i propobj.%IsDefined("contentEncoding") d ..format(propobj.contentEncoding,prop)
	i propobj.%IsDefined("contentMediaType") d ..contentMediaType(propobj,prop)
}

Method GenerateCodeArr(pSchemaObj) [ Private ]
{
	s schema = $s(pSchemaObj'="": pSchemaObj, 1: ..Schema)
    if schema.items.%IsA("%DynamicArray"){ ; [ {} ,{} ]
    	s iter = schema.items.%GetIterator()
    }
    else {
	    s propobj = schema.items
	    d $method(,"sarr",propobj)
	    q
    }
    while iter.%GetNext(.cp, .propobj) {
    	//s:..KeepSource %fjscode($i(%fjscode))=" ;validate "_prop_" schema propery"
    	i $iso(propobj.type){
        	d ..arrayprop(propobj)
    	}
    	else {
        	s type=propobj.type
        	
        	i type="object" {
	        	//s:..KeepSource %fjscode($i(%fjscode))=" ;validate "_prop_" schema propery"
            	d $method(,"GenerateCode",propobj)
            	continue
        	}elseif type="array" {
	            d $method(,"GenerateCodeArr",propobj)
            }else{
        	s prop="%Get("_cp_")"
        	d:type'="" $method(,type,propobj,prop)
            }
    	}
    }
}

Method GenerateCode(pSchemaObj As %DynamicAbstractObject = "") [ Private ]
{
    s schema = $s(pSchemaObj'="": pSchemaObj, 1: ..Schema)
    d ..checkrequired(schema)
    i schema.type="array" d ..GenerateCodeArr(pSchemaObj) q
    s iter = schema.properties.%GetIterator()
    while iter.%GetNext(.prop, .propobj) {
        s:..KeepSource %fjscode($i(%fjscode))=" ;validate "_prop_" schema propery"
        s:..KeepSource&&(propobj.%IsDefined("description")) %fjscode($i(%fjscode))=" ;description given in schema: "_propobj.description_" "
        i $iso(propobj.type){
            d ..arrayprop(propobj,prop)
        }
        else {
            s type=propobj.type
            i type="object" {
                d $method(,"GenerateCode",propobj)
                //continue
            }
            elseif type="array" {
	            d $method(,"GenerateCodeArr",propobj)
            }else{
            	d:type'="" $method(,type,propobj,prop)
            }
        }
    }
}

Method arrayprop(propobj, prop) [ Private ]
{
	s iter = propobj.type.iterator()
	s c="",dt=""
	while iter.%GetNext(,.val) {s c=c_..CodeType(val),dt=dt_val_","}
	s %fjscode($i(%fjscode))=" i "_"'$find("_c_",%JSON.%GetTypeCodeOf("_prop_"))"_" q """_prop_" datatype is should be ["_$e(dt,1,*-1)_"] """
	s iter = propobj.type.iterator()
	while iter.%GetNext(,.val) {
		d:val'="" $method(,val,propobj,prop,1)
	}
}

Method checkrequired(pSchemaObj) [ Private ]
{
	s schema = $s(pSchemaObj'="": pSchemaObj, 1: ..Schema)
	ret:'schema.%IsDefined("required")
	s iter = schema.required.iterator()
	s:..KeepSource %fjscode($i(%fjscode))=" ;validate the required schema propery is are available"
	s %fjscode($i(%fjscode))=" s missing="""""
	while iter.%GetNext(,.val) {
		s %fjscode($i(%fjscode))=" s:'%JSON.%IsDefined("""_val_""") missing=missing_"""_val_","""
	}
	s %fjscode($i(%fjscode))=" q:missing'="""" ""Missing required properties: [""_$e(missing,1,*-1)_""]"" "
	q
}

Method string(propobj As %DynamicObject, prop As %String = "", skipbasicchk = 0) [ Private ]
{
	s:propobj.%IsDefined("minLength") min = propobj.minLength
	s:propobj.%IsDefined("maxLength") max = propobj.maxLength
	s:propobj.%IsDefined("pattern") pat=propobj.pattern
	//s %fjscode($i(%fjscode))=" i '%JSON.%IsDefined("""_prop_""") q """_prop_" not available in the json"""
	//s %fjscode($i(%fjscode))=" i %JSON.%GetTypeOf("""_prop_""")'=""string"" q "" "_prop_"  must be a string type"""
	if 'skipbasicchk {
		s %fjscode($i(%fjscode))=" i %JSON.%GetTypeCodeOf("""_$S(prop["%Get(":+$P(prop,"%Get("),1:prop)_""")'=6 q """_prop_" must be a string type"""
		if min'=""!(max'="") s %fjscode($i(%fjscode))=" i '$IsValidnum($Length(%JSON."_prop_"),,"_min_","_max_") q "" "_prop_" length not match"""
	}
	i propobj.%IsDefined("enum")  d ..enum(propobj.enum,prop)
	i pat'="" {
		s:..KeepSource %fjscode($i(%fjscode))=" ; pattern check"
		i prop'=""{
			s %fjscode($i(%fjscode))=" i '$match(%JSON."_prop_","""_pat_""") q ""pattern not match with "_prop_" json data"""
		}
		else {
			s %fjscode($i(%fjscode))=" i '$match(%JSON,"""_pat_""") q ""pattern not match with "_prop_" json data"""
		}
	}
	d:propobj.%IsDefined("format") ..format(propobj.format,prop)
	s:propobj.%IsDefined("const") %fjscode($i(%fjscode))=" i %JSON."_prop_"'="""_propobj.const_""" q """_prop_"  value must be "_propobj.const_""""
	i propobj.%IsDefined("contentEncoding") {
		d ..format(propobj.contentEncoding,prop)
	}
	i propobj.%IsDefined("contentMediaType") d ..contentMediaType(propobj,prop)
}

Method number(propobj As %DynamicObject, prop As %String) [ Private ]
{
	d ..integer(propobj, prop)
}

Method integer(propobj As %DynamicObject, prop As %String, skipbasicchk = 0) [ Private ]
{
	s:propobj.%IsDefined("minimum") min = propobj.minimum
	s:propobj.%IsDefined("maximum") max = propobj.exclusiveMaximum
	s:propobj.%IsDefined("exclusiveMinimum") emin = propobj.exclusiveMinimum
	s:propobj.%IsDefined("exclusiveMaximum") emax = propobj.exclusiveMaximum
	s:propobj.%IsDefined("multipleOf") pat=propobj.multipleOf
	//s %fjscode($i(%fjscode))=" i '%JSON.%IsDefined("""_prop_""") q """_prop_" not available in the json"""
	//s %fjscode($i(%fjscode))=" i '$IsValidnum(%JSON."_prop_") q "" "_prop_"datatype not match with the json value"""
	s:'skipbasicchk %fjscode($i(%fjscode))=" i %JSON.%GetTypeCodeOf("""_prop_""")'=9 q """_prop_" datatype not match with the json value"""
	i (min'="")!(max'="")!(emin'="")!(emax'=""){
		s %fjscode($i(%fjscode))=" i '$IsValidnum($Length(%JSON."_prop_"),,"_$s(emin'="":emin,1:min)_","_$s(emax'="":emax,1:max)_") q """_prop_" length not match"""
	}
	d:propobj.%IsDefined("enum") ..enum(propobj.enum,prop)
	s:propobj.%IsDefined("const") %fjscode($i(%fjscode))=" i %JSON."_prop_"'="_propobj.const_" q """_prop_"  value must be "_$case(propobj.const,1:"true",:"false")_""""
}

Method boolean(propobj As %DynamicObject, prop As %String, skipbasicchk = 0) [ Private ]
{
	//s %fjscode($i(%fjscode))=" i %JSON.%GetTypeOf("""_prop_""")'=""boolean"" q """_prop_" datatype not match with the json value"""
	s %fjscode($i(%fjscode))=" i %JSON.%GetTypeCodeOf("""_prop_""")'=4 q """_prop_" datatype not match with the json value"""
	;validate the data
	//s %fjscode($i(%fjscode))=" s propval=%JSON.%Get("""_prop_""",,""json"") if propval'?1(1""true"",1""false"") q """_prop_" value is not boolean"""
	//s:'skipbasicchk %fjscode($i(%fjscode))=" s propval=%JSON."_prop_" if propval'=1&&(propval'=0) q "" "_prop_" must be a boolean type."""
	s:'skipbasicchk %fjscode($i(%fjscode))=" s bv=%JSON."_prop_" if $c(0,1)'[$c(bv) q "" "_prop_" is not boolean value"""
	s:propobj.%IsDefined("const") %fjscode($i(%fjscode))=" i %JSON."_prop_"'="_propobj.const_" q "" "_prop_" value must be "_$case(propobj.const,1:"true",:"false")_""""
	d:propobj.%IsDefined("enum") ..enum(propobj.enum,prop)

	; need to work with conditional check in boolean
	/*
	"if": {
    "properties": { "isPremium": { "const": true } }
  },
  "then": {
    "required": ["planID", "billingCycle"]
  },
  "else": {
    "required": ["planID"]
  }
	*/
}

Method null(propobj As %DynamicObject, prop As %String, skipbasicchk = 0) [ Private ]
{
	//s %fjscode($i(%fjscode))=" i %JSON.%GetTypeOf("""_prop_""")'=""null"" q """_prop_" datatype not match with the json value"""
	s:'skipbasicchk %fjscode($i(%fjscode))=" i %JSON.%GetTypeCodeOf("""_prop_""")'=2 q """_prop_" datatype not match with the json value"""
	d:propobj.%IsDefined("enum") ..enum(propobj.enum,prop)
	s:propobj.%IsDefined("const") %fjscode($i(%fjscode))=" i %JSON."_prop_"'="_$S(propobj.const="":"""""",1:"""""")_" q """_prop_" value must be "_$Select(propobj.const="":"null",1:propobj.const)_""""
}

Method array(propobj As %DynamicObject, prop As %String, skipbasicchk = 0) [ Private ]
{
}

Method enum(enum As %DynamicArray, prop As %String = "")
{
	s %fjscode($i(%fjscode))=" ; enum check"
	s iter = enum.%GetIterator()
	;s c="" while iter.%GetNext(,.v) {s c=c_v_","} s c=","_c
	;s %fjscode($i(%fjscode))=" i """_c_"""'[("",""_"_"%JSON."_prop_"_"","") q ""enum not match with "_prop_" json data"" "
	s c="$lb(" while iter.%GetNext(,.v) {s c=c_$case($isvalidnum(v),1:v,:""""_v_"""")_","} s c=$E(c,1,*-1)_")"
	if prop'="" {
		s %fjscode($i(%fjscode))=" i '$lf("_c_",%JSON."_prop_") q ""enum not match with "_prop_" json data"" "
	}
	else{
		s %fjscode($i(%fjscode))=" i %JSON.%IsA(""%DynamicArray"") s iter=%JSON.%GetIterator() while iter.%GetNext(,.v){ i '$lf("_c_",v) ret ""input not match with the schema enum values"" }"
	}
}

Method format(format As %String, prop As %String)
{
	s regex = $case(format, "email":"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$","uri":"^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$",
			"date":"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$","datetime":"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):[0-5]\d:[0-5]\d(Z|[+-]([01]\d|2[0-3]):?[0-5]\d)?$",
			"uuid":"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$",
			"ipv4":"^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$",
			"ipv6":"^(([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){1,7}:)|(([0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,5}(:[0-9A-Fa-f]{1,4}){1,2})|(([0-9A-Fa-f]{1,4}:){1,4}(:[0-9A-Fa-f]{1,4}){1,3})|(([0-9A-Fa-f]{1,4}:){1,3}(:[0-9A-Fa-f]{1,4}){1,4})|(([0-9A-Fa-f]{1,4}:){1,2}(:[0-9A-Fa-f]{1,4}){1,5})|([0-9A-Fa-f]{1,4}:((:[0-9A-Fa-f]{1,4}){1,6}))|(:((:[0-9A-Fa-f]{1,4}){1,7}|:))$",
			"hostname":"^(?=.{1,253}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.(?!-)[A-Za-z0-9-]{1,63}(?<!-))*\.?$",
			"base64":"(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$",
			:"")
	s:regex'="" %fjscode($i(%fjscode))=" i '$match(%JSON."_prop_","""_regex_""") q """_format_" format not matched"" "
}

Method CodeType(datatype) [ CodeMode = expression ]
{
$case(datatype,"string":6,"integer":9,"number":9,"boolean":4,"null":2,:"")
}

Method const(propobj As %DynamicObject, prop As %String, skipbasicchk = 0)
{
	//s %fjscode($i(%fjscode))=" i %JSON."_prop_"'="_propobj.const_" q "" "_prop_"   value must be "_$case(propobj.const,1:"true",:"false")_""""
}

Method oneOf(propobj As %DynamicObject, prop As %String)
{
}

Method contentMediaType(propobj As %DynamicObject, prop As %String) [ Internal ]
{

	q 1
}

Method configfunc() [ Internal ]
{
	s %fjscode($i(%fjscode))="%validate(%JSON)"
	s %fjscode($i(%fjscode))=" n (%JSON)"
	s %fjscode($i(%fjscode))=" s $et=""q $ze"""
	s %fjscode($i(%fjscode))=" s:'$iso(%JSON) %JSON={}.%FromJSON(%JSON)"
}

Method basicinfo() [ Internal ]
{
	q:'..KeepSource
	s %fjscode($i(%fjscode))=" ;Generated by FastJsonSchema.Compiler"
	s %fjscode($i(%fjscode))=" ;Routine Name: schema."_..Name
	s %fjscode($i(%fjscode))=" ;$schema: "_..Schema."$schema"
	s %fjscode($i(%fjscode))=" ;$id: "_..Schema."$id"
	s %fjscode($i(%fjscode))=" ;title: "_..Schema.title
	s %fjscode($i(%fjscode))=" ;description: "_..Schema.description
}

Method Savefjs()
{
	i ..KeepSource{
		s rot="aaschema."_..Name_".int"
		if ##class(%Routine).%ExistsId(rot){
			s routine = ##class(%Routine).%OpenId(rot)
			s routine.RoutineVersion=routine.RoutineVersion+1
		}
		else {
			s routine = ##class(%Routine).%New(rot)
		}
		s routine.Generated=1
		if $iso(routine) f i=1:1:%fjscode d routine.WriteLine(%fjscode(i))
		s rtn=routine.%Save()
		d routine.Compile()
	}
	else {
		s %fjscode(0)=%fjscode
		s rtn=$COMPILE(%fjscode,0,errs,,,,"aaschema."_..Name)
    	i rtn=0 {w "schema successfully generated",!}
    	else {w "no OBJ code generated return code: ",rtn,! zw errs  q}
		;generate code
	}
	ret rtn
}

Method %OnNew(pSchemaName As %String, pSchema As %DynamicAbstractObject, pKeepSource As %Boolean) As %Status
{
	s ..Name = pSchemaName
	s ..Schema = pSchema
	s ..KeepSource = pKeepSource
	q 1
}

Method GenerateCode1() [ Deprecated ]
{
	d ..checkrequired()
	s iter = ..Schema.properties.%GetIterator()
	While iter.%GetNext(.prop, .propobj) {
		continue:$Data(..ProcessesFields(prop))
		s:..KeepSource %fjscode($i(%fjscode))=" ;validate "_prop_" schema propery"
		s:propobj.%IsDefined("description") %fjscode($i(%fjscode))=" ;description: "_propobj.description
		i $iso(propobj.type){
			d ..arrayprop(propobj,prop)
		}else{
			s type=propobj.type
			s:type="object" type="GenerateCode"
			d:type'="" $method(,type,propobj,prop)
		}
}
}

Method checkrequiredduplic(pSchemaObj) [ Deprecated ]
{
	s schema = $s(pSchemaObj'="": pSchemaObj, 1: ..Schema)
	ret:'schema.%IsDefined("required")
	s iter = schema.required.iterator()

	s:..KeepSource %fjscode($i(%fjscode))=" ;validate the required schema propery is are available"
	s %fjscode($i(%fjscode))=" s missing="""""
	while iter.%GetNext(,.val) {
		s %fjscode($i(%fjscode))=" s:'%JSON.%IsDefined("""_val_""") missing=missing_"""_val_","""
	}
	s %fjscode($i(%fjscode))=" q:missing'="""" ""Missing required properties: [""_$e(missing,1,*-1)_""]"" "
	 q
	;
	/*s iter = ..Schema.required.iterator() Set c="$LB(" while iter.%GetNext(,.val) {Set c=c_""""_val_""""_","} s c=$E(c,1,*-1)_")"
	s %fjscode($i(%fjscode))=" s ptr=0,missing="""" while $ListNext("_c_",ptr,val) {if '%JSON.%IsDefined(val) s missing=missing_val_"",""} "*/
	;
	s %fjscode($i(%fjscode))=" q:missing'="""" ""Missing required properties: [""_$e(missing,1,*-1)_""]"" "
	s iter = schema.required.iterator()
	while iter.%GetNext(,.val) {
		s propobj = schema.properties.%Get(val)
		s $List(props,$i(i))=val
		s:..KeepSource %fjscode($i(%fjscode))=" ;validate "_val_" schema propery"
		d:propobj.type'="" $method(,propobj.type,propobj,val)
		s ..ProcessesFields(val)=""
	}
}

}
