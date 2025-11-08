# iris-fastjsonschema
iris‑fastjsonschema is a lightweight, high-performance JSON Schema validation toolkit. It combines the simplicity and speed of fastjsonschema with additional support for “iris”-style schema definitions

The `fastjsonschema` library is designed to support **[JSON Schema Draft-07](https://json-schema.org/draft-07/schema)**.  For more information, see the official specification.

### Usage

Compile the schema
```objectscript
Set sc = ##class(FastJsonSchema.Core).Compile(schema, schemaName)
```
Validate the json object against the schema
```objectscript
Set payload =  ##class(FastJsonSchema.Core).Validate(schemaName, JSONObject)
```
The `Compile` and `Validate` methods require the following:

- **SchemaName** — a `string` property
- **schema / JSONObject** — a `%DynamicObject` or `%DynamicArray`

## Contrbution
👉 Check out our [Contributing Guidelines](./CONTRIBUTING.md) for more details.
