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

  // --- Object Keywords ---
  "required": ["username", "userID"],
  "minProperties": 3,
  "maxProperties": 6,
  "additionalProperties": false,

  "properties": {

    // --- String Keywords ---
    "username": {
      "type": "string",
      "minLength": 3,
      "maxLength": 30,
      "pattern": "^[a-zA-Z0-9]+$", // Regex: Alphanumeric only
      "description": "Unique identifier, must be 3-30 alphanumeric characters.",
      "enum": [
				"Alice",
				"Bob",
				"Charlie",
				null
			]
    },"numberProp": {
			"type": "number",
			"minimum": 0.5,
			"maximum": 100.5,
			"exclusiveMinimum": 0,
			"exclusiveMaximum": 101,
			"multipleOf": 0.5,
			"description": "test number"
		},
    "email": {
      "type": "string",
      "format": "email" // Semantic validation (should compile to a specific function call)
    },
    "api_key": {
        "type": "string",
        "const": "STATIC_KEY_XYZ" // Value must be this exact string
    },

    // --- Number/Integer Keywords ---
    "userID": {
      "type": "integer",
      "minimum": 1000,
      "exclusiveMaximum": 999999, // Must be strictly less than 999999
      "multipleOf": 5
    },

    // --- Array Keywords ---
    "roles": {
      "type": "array",
      "items": { "type": "string" }, // All items must be strings
      "minItems": 1,
      "maxItems": 5,
      "uniqueItems": true, // Array values must not have duplicates
      "enum": [
        "admin",
        "editor",
        "viewer"
      ]
    },

    // --- Nested Object ---
    "settings": {
      "type": "object",
      "properties": {
        "notifications": { "type": "boolean" },
        "theme": { "type": "string", "default": "light" }
      },
      "required": ["notifications"],
      "additionalProperties": false
    },

    // --- Schema Composition (Complex Logic) ---
    "accountStatus": {
        "oneOf": [ // Must match EXACTLY ONE of the subschemas
            { "type": "string", "const": "Active" },
            { "type": "string", "const": "Suspended" }
        ]
    }
  },

  // --- Conditional Keywords ---
  "dependentRequired": {
    "email": ["accountStatus"] // If 'email' is present, 'accountStatus' is required
  }
 }

	/*{
    "type": "object",
    "properties": {
        "name": {"type": "string", "minLength": 1},
        "age": {"type": "integer", "minimum": 18}
    },
    "required": ["name", "age"],
    "additionalProperties": false
	}*/
	Return pSchema
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
		},"notes": {
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
				"user2@example.com"
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

}
