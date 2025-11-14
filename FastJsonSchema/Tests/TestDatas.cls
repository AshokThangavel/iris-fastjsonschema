Class FastJsonSchema.Tests.TestDatas Extends %RegisteredObject
{

ClassMethod SampleSchema1()
{

	Set pSchema = {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://example.com/FullFeatureUser.schema.json",
  "title": "Full Feature User Profile",
  "description": "A complex schema designed to test compilation of all major validation keywords.",
  "type": "object",

  "required": ["username", "userID"],
  "minProperties": 3,
  "maxProperties": 6,
  "additionalProperties": false,

  "properties": {
    "username": {
      "type": "string",
      "minLength": 3,
      "maxLength": 30,
      "pattern": "^[a-zA-Z0-9]+$",
      "description": "Unique identifier, must be 3-30 alphanumeric characters.",
      "enum": ["Alice", "Bob", "Charlie"]
    },

    "numberProp": {
      "type": "number",
      "minimum": 0.5,
      "maximum": 100.5,
      "exclusiveMinimum": 0,
      "exclusiveMaximum": 101,
      "multipleOf": 0.5,
      "description": "Test number field."
    },

    "email": {
      "type": "string",
      "format": "email"
    },

    "api_key": {
      "type": "string",
      "const": "STATIC_KEY_XYZ"
    },

    "userID": {
      "type": "integer",
      "minimum": 1000,
      "exclusiveMaximum": 999999,
      "multipleOf": 5
    },

    "roles": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["admin", "editor", "viewer"]
      },
      "minItems": 1,
      "maxItems": 5,
      "uniqueItems": true
    },

    "settings": {
      "type": "object",
      "properties": {
        "notifications": { "type": "boolean" },
        "theme": { "type": "string", "default": "light" }
      },
      "required": ["notifications"],
      "additionalProperties": false
    }
   }
	}
	Return pSchema
}

ClassMethod SampleSchemaData1()
{
	return {
  "username": "Alice",
  "userID": 1005,
  "numberProp": 50.5,
  "email": "alice@example.com",
  "api_key": "STATIC_KEY_XYZ",
  "roles": ["admin", "editor"],
  "settings": {
    "notifications": true,
    "theme": "dark"
  },
  "accountStatus": "Active",
  "accountFindings": "Active"
 }
}

ClassMethod SampleSchema2()
{

	return {
	"$schema": "http://json-schema.org/draft-07/schema#",
	"$id": "https://example.com/full-feature-schema.json",
	"title": "Full Feature JSON Data Schema",
	"description": "A JSON Schema demonstrating all data types and validation keywords.",
	"type": "object",
	"required": [
		"stringProp",
		"numberProp",
		"integerProp",
		"booleanProp",
		"arrayProp",
		"objectProp",
		"nullProp"
	],
	"properties": {
		"usernamezz": {
			"type": "string",
			"minLength": 3,
			"maxLength": 30,
			"pattern": "^[a-zA-Z0-9]+$",
			"description": "Unique identifier, must be 3-30 alphanumeric characters.",
			"format": "email"
		},
		"stringProp": {
			"type": "string",
			"minLength": 3,
			"maxLength": 10,
			"pattern": "^[A-Za-z]+$",
			"enum": [
				"Alice",
				"Bob",
				"Charlie",
				null,
				12
			],
			"format": "ipv6",
			"const":"United States of America",
			"contentEncoding":"base64"
		},
		"numberProp": {
			"type": "number",
			"minimum": 0.5,
			"maximum": 100.5,
			"exclusiveMinimum": 0,
			"exclusiveMaximum": 101,
			"multipleOf": 0.5
		},
		"integerProp": {
			"type": "integer",
			"minimum": 1,
			"maximum": 100,
			"exclusiveMinimum": 0,
			"exclusiveMaximum": 101,
			"multipleOf": 2,
			"enum":[12,11]
		},
		"booleanProp": {
			"type": "boolean",
			"const": true
		},
		"arrayProp": {
			"type": "array",
			"minItems": 2,
			"maxItems": 5,
			"uniqueItems": true,
			"items": {
				"type": "string",
				"minLength": 1
			}
		},
		"notes": {
      		"description": "Optional user notes.",
      		"type": ["string", "null","integer"]
							// Using "type": ["string", "null"] is equivalent to:
							/*
							"oneOf": [
								{ "type": "string" },
								{ "type": "null" }
							]
							*/
    	}
    ,"fileData": {
      "type": "string",
      "contentEncoding": "base64",
      "contentMediaType": "application/pdf"
    },
    "imageData": {
      "type": "string",
      "contentEncoding": "base64",
      "contentMediaType": "image/png"
    },
		"objectProp": {
			"type": "object",
			"required": [
				"nestedString",
				"nestedNumber"
			],
			"properties": {
				"nestedString": {
					"type": "string",
					"minLength": 2,
					"maxLength": 8
				},
				"nestedNumber": {
					"type": "number",
					"minimum": 10,
					"maximum": 50
				},
				"optionalBoolean": {
					"type": "boolean"
				}
			},
			"additionalProperties": false
		},
		"nullProp": {
			"type": "null"
		}
	},
	"additionalProperties": false
 }
}

ClassMethod SampleSchema3()
{

 ret {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {

    "myString": {
      "type": "string",
      "minLength": 5,
      "maxLength": 20,
      "pattern": "^[A-Za-z0-9]+$",
      "format": "email",
      "enum": ["user1@example.com", "user2@example.com"],
      "const": "user1@example.com",
      "contentEncoding": "base64",
      "contentMediaType": "text/plain"
    },

    "myInteger": {
      "type": "integer",
      "minimum": 0,
      "exclusiveMinimum": -1,
      "maximum": 100,
      "exclusiveMaximum": 101,
      "multipleOf": 5,
      "enum": [0, 5, 10, 15],
      "const": 10
    },

    "myNumber": {
      "type": "number",
      "minimum": 0.0,
      "exclusiveMinimum": -0.1,
      "maximum": 100.0,
      "exclusiveMaximum": 101.0,
      "multipleOf": 0.5,
      "enum": [0, 0.5, 1.0, 1.5],
      "const": 1.0
    },

    "myBoolean": {
      "type": "boolean",
      "enum": [true],
      "const": true
    },

    "myNull": {
      "type": "null",
      "enum": [null],
      "const": null
    },
    "myobjct":{
	"type": "object",
	"properties": {
		"myObject": {
			"type": "object",
			"description": "An example object property",
			"properties": {
				"id": {
					"type": "integer",
					"description": "Unique identifier"
				},
				"name": {
					"type": "string",
					"minLength": 3,
					"maxLength": 50
				},
				"active": {
					"type": "boolean"
				}
			},
			"required": [
				"id",
				"name"
			]
		}
	},
	"required": [
		"myObject"
	]
	}

  },
  "required": ["myString", "myInteger", "myNumber", "myBoolean", "myNull"]
	}
}

ClassMethod SampleSchema4()
{
	ret {
	"$schema": "http://json-schema.org/draft-07/schema#",
	"type": "object",
	"properties": {
		"ashok": {
			"type": "object",
			"properties": {
				"myObject": {
					"type": "object",
					"description": "An example object property",
					"properties": {
						"id": {
							"type": "integer",
							"description": "Unique identifier"
						},
						"name": {
							"type": "string",
							"minLength": 3,
							"maxLength": 50
						},
						"active": {
							"type": "boolean"
						}
					},
					"required": [
						"id",
						"name"
					]
				}
			},
			"required": [
				"myObject"
			]
		}
	},
	"required": [
		"ashok"
	]
	}
}

ClassMethod SampleSchema5()
{

	ret {
	"$schema": "http://json-schema.org/draft-07/schema#",
	"title": "Example Array Schema",
	"type": "array",
	"description": "An array of user IDs or email addresses",
	"minItems": 1,
	"maxItems": 10,
	"uniqueItems": true,
	"items": {
		"type": "string",
		"maxLength": 50,
		"pattern": "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
		"enum": [
			"user1@example.com",
			"user2@example.com",
			"user3@example.com",
			"user4@example.com"
		]
	}
	}
}

ClassMethod SampleSchemaData5(case)
{
	/// true case
	if case {
		s arr=["user1@example.com","user2@example.com","user3@example.com","user4@example.com"]
	}
	else {
		/// failed
		s arr=["user1@example.com","user2@example.com","user3@example.com","user4@example.com","user4@example.com"]
	}
	return arr
}

ClassMethod SampleSchema6()
{

	ret {
	"$schema": "http://json-schema.org/draft-07/schema#",
	"type": "array",
	"description": "List of user emails",
	"minItems": 1,
	"maxItems": 10,
	"uniqueItems": true,
	"items": [
		{
			"type": "string",
			"minLength": 5,
			"maxLength": 50,
			"pattern": "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
			"enum": [
				"user1@example.com",
				"user2@example.com",
				"user3@example.com"
			]
		},
		{
			"type": "string",
			"minLength": 15,
			"maxLength": 50,
			"description": "test sample schema6",
			//"pattern": "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
			"enum": [
				"ak1@example.com",
				"ak2@example.com",
				"ak@example.com"
			]
		},{
			"type": "integer",
			"minimum": 0,
			"exclusiveMinimum": -1,
			"maximum": 100,
			"exclusiveMaximum": 101,
			"multipleOf": 5,
			"enum": [
				0,
				5,
				10,
				15
			],
			"const": 10
		}
	]
	}
}

ClassMethod SampleSchema7()
{

	ret {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "myString": {
      "type": "string",
      "minLength": 5,
      "maxLength": 20,
      "pattern": "^[A-Za-z0-9]+$",
      "format": "email",
      "enum": ["user1@example.com", "user2@example.com"],
      "const": "user1@example.com",
      "contentEncoding": "base64",
      "contentMediaType": "text/plain"
    },
    "myInteger": {
      "type": "integer",
      "minimum": 0,
      "exclusiveMinimum": -1,
      "maximum": 100,
      "exclusiveMaximum": 101,
      "multipleOf": 5,
      "enum": [0, 5, 10, 15],
      "const": 10
    },
    "myNumber": {
      "type": "number",
      "minimum": 0.0,
      "exclusiveMinimum": -0.10000000000000001,
      "maximum": 100.0,
      "exclusiveMaximum": 101.0,
      "multipleOf": 0.5,
      "enum": [0, 0.5, 1.0, 1.5],
      "const": 1.0
    },
    "myBoolean": {
      "type": "boolean",
      "enum": [true],
      "const": true
    },
    "myNull": {
      "type": "null",
      "enum": [null],
      "const": null
    },
    "myobjct": {
      "type": "object",
      "properties": {
        "myObject": {
          "type": "object",
          "description": "An example object property",
          "properties": {
            "id": {
              "type": "integer",
              "description": "Unique identifier"
            },
            "name": {
              "type": "string",
              "minLength": 3,
              "maxLength": 50
            },
            "active": {
              "type": "boolean"
            }
          },
          "required": ["id", "name"]
        }
      },
      "required": ["myObject"]
    },
    "myArray": {
      "type": "array",
      "description": "A list of unique strings.",
      "minItems": 1,
      "maxItems": 5,
      "uniqueItems": true,
      "items": {
        "type": "string",
        "minLength": 3
      }
    }
  },
  "required": [
    "myString",
    "myInteger",
    "myNumber",
    "myBoolean",
    "myNull",
    "myArray"
  ]
 }
}

ClassMethod SampleSchema8()
{

	ret {
	"$schema": "http://json-schema.org/draft-07/schema#",
	"type": "object",
	"properties": {
		"myString": {
			"type": ["string","integer"],
			"minLength": 5,
			"maxLength": 20,
			"pattern": "^[A-Za-z0-9]+$",
			"format": "email",
			"enum": [
				"user1@example.com",
				"user2@example.com",
				"user3@example.com",
				"user4@example.com",
				"user5@example.com",
				"user6@example.com",
				"user7@example.com",
				"user8@example.com",
				"user9@example.com",
				"user10@example.com",
				"user11@example.com",
				"user12@example.com"
			],
			"const": "user1@example.com",
			"contentEncoding": "base64",
			"contentMediaType": "text/plain"
		},
		"myInteger": {
			"type": "integer",
			"minimum": 0,
			"exclusiveMinimum": -1,
			"maximum": 100,
			"exclusiveMaximum": 101,
			"multipleOf": 5,
			"enum": [
				0,
				5,
				10,
				15
			],
			"const": 10
		},
		"myNumber": {
			"type": "number",
			"minimum": 0.0,
			"exclusiveMinimum": -0.1,
			"maximum": 100.0,
			"exclusiveMaximum": 101.0,
			"multipleOf": 0.5,
			"enum": [
				0,
				0.5,
				1.0,
				1.5
			],
			"const": 1.0
		},
		"myBoolean": {
			"type": "boolean",
			"enum": [
				true
			],
			"const": true
		},
		"myNull": {
			"type": "null",
			"enum": [
				null
			],
			"const": null
		},
		"myobjct": {
			"type": "object",
			"properties": {
				"myObject": {
					"type": "object",
					"description": "An example object property",
					"properties": {
						"id": {
							"type": "integer",
							"description": "Unique identifier"
						},
						"name": {
							"type": "string",
							"minLength": 3,
							"maxLength": 50
						},
						"active": {
							"type": "boolean"
						}
					},
					"required": [
						"id",
						"name"
					]
				}
			},
			"required": [
				"myObject"
			]
		},
		"myArray": {
			"type": "array",
			"description": "A list of unique strings.",
			"minItems": 1,
			"maxItems": 5,
			"uniqueItems": true,
			"items": {
				"type": "string",
				"minLength": 3
			}
		},
		"myArray1": {
			"type": "array",
			"description": "A complicated array defined as a three-element tuple.",
			"minItems": 3,
			"maxItems": 3,
			"items": [
				{
					"title": "Date String",
					"type": "string",
					"format": "date",
					"description": "The first item must be a valid date string."
				},
				{
					"title": "Configuration Object",
					"type": "object",
					"description": "The second item must be an object with two required properties.",
					"properties": {
						"key": {
							"type": "string"
						},
						"value": {
							"type": "integer"
						}
					},
					"required": [
						"key",
						"value"
					]
				},
				{
					"title": "List of IDs",
					"type": "array",
					"description": "The third item must be an array of unique integers.",
					"minItems": 1,
					"uniqueItems": true,
					"items": {
						"type": "integer",
						"minimum": 1
					}
				}
			],
			"additionalItems": false
		}
	},
	"required": [
		"myString",
		"myInteger",
		"myNumber",
		"myBoolean",
		"myNull",
		"myArray",
		"myArray1"
	]
	}
}

ClassMethod SampleSchema9()
{

	ret {
  "type": "object",
  "properties": {
    "id": {
      "oneOf": [
        { "type": "string" },
        { "type": "integer" }
      ]
    }
  },
  "required": ["id"]
	}
}

ClassMethod SampleSchemaData9(type)
{
	if type="string" {
		s rtn = { "id": "abc123" }
	}
	else {
		s rtn = { "id": 1212 }
	}
	return rtn
}

ClassMethod SampleSchema10()
{
	ret {
	"$schema": "http://json-schema.org/draft-07/schema#",
	"$id": "https://example.com/ComplexValidatorTest.schema.json",
	"title": "Full Feature User Profile and Data",
	"description": "A complex schema designed to test compilation of advanced validation keywords including combinations and deep recursion.",
	"type": "object",
	"required": [
		"userID",
		"accountStatus"
	],
	"minProperties": 3,
	"additionalProperties": false,
	"properties": {
		"userID": {
			"type": "integer",
			"minimum": 1000,
			"description": "Required integer ID."
		},
		"accountStatus": {
			"description": "Tests simple oneOf aggregation (string const/enum checks).",
			"oneOf": [
				{
					"type": "string",
					"const": "Active",
					"pattern": "^[A-Z][a-z]+$"
				},
				{
					"type": "string",
					"const": "Suspended",
					"minLength": 9
				},
				{
					"type": "string",
					"const": "Inprogress",
					"minLength": 9,
					"maxLength":40
				}
			]
		}
	}
 }
}

ClassMethod SampleSchemaData10(type, passorfail)
{
	ret {"userID": 1500,"accountStatus": "Active"}
}

ClassMethod SampleSchema11()
{
	ret {
	"$schema": "http://json-schema.org/draft-07/schema#",
	"$id": "https://example.com/ComplexValidatorTest.schema.json",
	"title": "Full Feature User Profile and Data",
	"description": "A complex schema designed to test compilation of advanced validation keywords including combinations and deep recursion.",
	"type": "object",
	"required": [
		"userID",
		"accountStatus",
		"contactInfo"
	],
	"minProperties": 3,
	"additionalProperties": false,
	"properties": {
		"userID": {
			"type": "integer",
			"minimum": 1000,
			"description": "Required integer ID."
		},
		"accountStatus": {
			"description": "Tests simple oneOf aggregation (string const/enum checks).",
			"oneOf": [
				{
					"type": "string",
					"const": "Active",
					"pattern": "^[A-Z][a-z]+$"
				},
				{
					"type": "string",
					"const": "Suspended",
					"minLength": 9
				}
			]
		},
		"contactInfo": {
			"description": "Tests complex/mixed oneOf, requiring recursive generation for the object case.",
			"oneOf": [
				{
					"type": "string",
					"format": "email"
				},
				{
					"type": "object",
					"properties": {
						"phone": {
							"type": "string",
							"pattern": "^\\d{10}$"
						},
						"verified": {
							"type": "boolean"
						}
					},
					"required": [
						"phone"
					]
				}
			]
		},
		"permissions": {
			"description": "Tests allOf: must satisfy all contained schemas.",
			"allOf": [
				{
					"type": "array"
				},
				{
					"items": {
						"type": "string",
						"enum": [
							"read",
							"write",
							"admin"
						]
					}
				}
			]
		},
		"dataValue": {
			"description": "Tests multi-type property (array of types). Must be string OR integer.",
			"type": [
				"string",
				"integer"
			],
			"minimum": 0,
			"maxLength": 50
		},
		"settingsArray": {
			"description": "Tests an array whose items are objects and requires recursion on array items.",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"key": {
						"type": "string"
					},
					"value": {
						"type": "string"
					}
				},
				"required": [
					"key"
				]
			}
		}
	}
 }
}

ClassMethod SampleSchemaData11()
{
	return {
  "userID": 1500,
  "accountStatus": "Active",
  "contactInfo": {
    "phone": "1234567890",
    "verified": true
  },
  "permissions": ["read", "write"],
  "dataValue": "example string",
  "settingsArray": [
    {
      "key": "theme",
      "value": "dark"
    },
    {
      "key": "notifications",
      "value": "enabled"
    }
  ]
 }
}

ClassMethod SampleSchema12()
{

	Set pSchema = {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://example.com/FullFeatureUser.schema.json",
  "title": "Full Feature User Profile",
  "description": "A complex schema designed to test compilation of all major validation keywords.",
  "type": "object",

  "required": ["username", "userID"],
  "minProperties": 3,
  "maxProperties": 6,
  "additionalProperties": false,

  "properties": {
    "username": {
      "type": "string",
      "minLength": 3,
      "maxLength": 30,
      "pattern": "^[a-zA-Z0-9]+$",
      "description": "Unique identifier, must be 3-30 alphanumeric characters.",
      "enum": ["Alice", "Bob", "Charlie"]
    },

    "numberProp": {
      "type": "number",
      "minimum": 0.5,
      "maximum": 100.5,
      "exclusiveMinimum": 0,
      "exclusiveMaximum": 101,
      "multipleOf": 0.5,
      "description": "Test number field."
    },

    "email": {
      "type": "string",
      "format": "email"
    },

    "api_key": {
      "type": "string",
      "const": "STATIC_KEY_XYZ"
    },

    "userID": {
      "type": "integer",
      "minimum": 1000,
      "exclusiveMaximum": 999999,
      "multipleOf": 5
    },

    "roles": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["admin", "editor", "viewer"]
      },
      "minItems": 1,
      "maxItems": 5,
      "uniqueItems": true
    },

    "settings": {
      "type": "object",
      "properties": {
        "notifications": { "type": "boolean" },
        "theme": { "type": "string", "default": "light" }
      },
      "required": ["notifications"],
      "additionalProperties": false
    },

    "accountStatus": {
      "oneOf": [
        {
          "type": "string",
          "const": "Active",
          "pattern": "^[A-Z][a-z]+$"
        },
        {
          "type": "string",
          "const": "Suspended",
          "pattern": "^[A-Z][a-z]+$"
        },
        {
          "type": "object",
          "properties": {
            "phone": {
              "type": "string",
              "pattern": "^\\d{10}$"
            },
            "verified": {
              "type": "boolean"
            }
          },
          "required": ["phone"]
        }
      ]
    },

    "accountFindings": {
      "description": "Current operational state of the user account.",
      "oneOf": [
        {
          "type": "string",
          "const": "Active",
          "description": "Account is active and in good standing.",
          "examples": ["Active"]
        },
        {
          "type": "string",
          "const": "Suspended",
          "description": "Account temporarily disabled due to an issue.",
          "examples": ["Suspended due to non-payment"],
          "pattern": "^[A-Z][a-z]+$"
        },
        {
          "type": "string",
          "const": "Closed",
          "description": "Account permanently closed.",
          "examples": ["Closed"],
          "pattern": "^[A-Za-z]+$"
        }
      ]
    }
  },

  "dependentRequired": {
    "email": ["accountStatus"]
  }
 }
	Return pSchema
}

// allOf sample

ClassMethod SampleSchema13()
{
	ret {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AllOf Profile Schema",
  "type": "object",
  "properties": {
    "id": {
      "type": "integer"
    },
    "email": {
      "type": "string",
      "format": "email"
    },
    "status": {
      "type": "string",
      "enum": ["active", "suspended"]
    }
  },
  "allOf": [
    {
      "description": "Requirement Set 1: Must have a valid ID and be an object.",
      "type": "object",
      "properties": {
        "id": {
			"type":"integer",
          "minimum": 1
        }
      },
      "required": ["id"]
    },
    {
      "description": "Requirement Set 2: Must have a status and a specific email pattern.",
      "type": "object",
      "properties": {
        "email": {
			"type":"string",
          "maxLength": 100
        },
        "status": {"type": "string"}
      },
      "required": ["email", "status"]
    }
  ]
 }
}

ClassMethod SampleSchemaData13(isvalid)
{
	if isvalid=1 {
		return {
  			"id": 105,             // Meets Set 1 (id >= 1)
  			"email": "test@app.com", // Meets Set 2 (required, maxLength 100)
  			"status": "active"       // Meets Set 2 (required)
		}
	}
	else {
			ret {
				"email": "test@app.com"
				// Missing "id" (required by Set 1)
				// Missing "status" (required by Set 2)
				}
	}
}

/// additionalProperties test
ClassMethod SampleSchema14()
{
	ret {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Profile with Strict Additional Data",
  "type": "object",

  "properties": {
    "name": {
      "type": "string",
      "description": "Explicitly allowed property"
    },
    "age": {
      "type": "integer",
      "description": "Explicitly allowed property"
    }
  },

  // This is the core control mechanism
  "additionalProperties": {
    "type": "integer",
    "minimum": 0,
    "description": "All extra properties MUST have an integer value >= 0."
  }
 }
}

ClassMethod SampleSchemaData14()
{
	return {"name": "Sue","age": 22,"score": 98,"level": 10}
}

/// patternProperties
ClassMethod SampleSchema15()
{
	 ret {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Configuration and Error Validation",
  "type": "object",

  "properties": {
    "id": { "type": "string" } // Exclude this from pattern checks
  },

  "patternProperties": {
    // 1. Pattern: Any key starting with 'cfg_' (Configuration)
    "^cfg_": {
      "description": "Configuration values must be boolean.",
      "type": "boolean"
    },

    // 2. Pattern: Any key ending with 'Priority'
    "Priority$": {
      "description": "Priority values must be an integer >= 1.",
      "type": "integer",
      "minimum": 1
    }
  },

  // No other keys are allowed, forcing all data properties to be tested against the patterns.
  "additionalProperties": false
 }
}

ClassMethod SampleSchema16()
{
	ret {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "User Profile Schema",
  "type": "object",

  "required": ["userId", "username"],

  "properties": {
    "userId": {
      "type": "integer",
      "description": "Unique integer ID for the user.",
      "minimum": 1000
    },
    "username": {
      "type": "string",
      "description": "Unique username (must be 3 to 20 characters).",
      "minLength": 3,
      "maxLength": 20
    },
    "email": {
      "type": "string",
      "format": "email",
      "description": "Optional email address."
    },
    "roles": {
      "type": "array",
      "description": "List of user roles.",
      "items": { "type": "string" },
      "minItems": 1,
      "uniqueItems": true
    }
  },

  "dependencies": {
    "email": ["usern-ame"] // If 'email' is present, 'username' must also be present (redundant due to 'required', but demonstrates the concept)
  },

  "additionalProperties": false
 }
}

ClassMethod SampleSchemaData16()
{
	ret {
  "userId": 1050,
  "username": "atlas_dev",
  "email": "atlas@example.com",
  "roles": ["admin", "editor"]
 }
}

ClassMethod SampleSchema17()
{
	ret {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Conditional Validation Test",
  "type": "object",
  "required": ["status_code"],

  "properties": {
    "status_code": {
      "type": "integer",
      "enum": [200, 400, 500],
      "description": "The condition trigger."
    },
    "data_format": { "type": "string", "enum": ["JSON", "XML"] },
    "error_message": { "type": "string", "minLength": 1 }
  },

  // This is the IF/THEN/ELSE structure to test
  "if": {
    // CONDITION: If status_code is 200 (Success)
    "properties": {
      "status_code": {
		"type": "integer",
		"const": 200 }
    }
  },
  "then": {
    // THEN: If 200, it must have a valid 'data_format' and must NOT have 'error_message'
    "required": ["data_format"],
    "properties": {
      "error_message": { "not": {} } // Must not be present
    }
  },
  "else": {
    // ELSE: If NOT 200 (i.e., 400 or 500), it must have an 'error_message'
    "required": ["error_message"],
    "properties": {
      "data_format": { "not": {} } // Must not be present
    }
  },

  "additionalProperties": false
 }
}

ClassMethod SampleSchema18()
{
	ret {
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Customer Order Schema with Internal $ref",
  "type": "object",
  "required": ["customer_id", "shipping_address"],
  "properties": {
    "customer_id": {
      "type": "integer",
      "description": "Unique customer identifier"
    },

    "billing_address": {
		"type":"string",
      "description": "Optional billing address.",
      "$ref": "#/definitions/Address" // <--- REFERENCE 1
    },

    "shipping_address": {
		"type":"string",
      "description": "Mandatory shipping address.",
      "$ref": "#/definitions/Address" // <--- REFERENCE 2
    }
  },
  "definitions": {
    "Address": { // The target schema for the $ref pointers
      "type": "object",
      "required": ["street", "city"], // Required properties in the resolved schema
      "properties": {
        "street": { "type": "string", "minLength": 5 },
        "city": { "type": "string" },
        "zip_code": { "type": "string", "pattern": "^[0-9]{5}$" }
      },
      "additionalProperties": false
    }
  }
 }
}

ClassMethod SampleSchemaData18(isvalid = 1)
{
	i isvalid {
		s json ={"customer_id": 101, "shipping_address": {"street": "500 Main Street", "city": "Anytown"}, "billing_address": {"street": "P.O. Box 10", "city": "Remote"}}
	}
	else {
		s json ={"customer_id": 102, "shipping_address": {"street": "99 Elm Street"}, "billing_address": {"street": "123 Oak St", "city": "Nowhere"}}

	}
	ret json
}

}
