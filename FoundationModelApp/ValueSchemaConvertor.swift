//
//  ValueSchemaConvertor.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/12.
//

import MCP
import FoundationModels
import SwiftUI


// MARK: JSON Schema Type string
private extension String {
    static var nullType: String {
        return "null"
    }
    static var booleanType: String {
        return "boolean"
    }
    
    // corresponds to a Double
    static var numberType: String {
        return "number"
    }
    
    static var intType: String {
        return "integer"
    }
    
    static var arrayType: String {
        return "array"
    }
    
    static var stringType: String {
        return "string"
    }

    static var objectType: String {
        return "object"
    }
    
    static var enumType: String {
        return "enum"
    }
    
    static var constantType: String {
        return "const"
    }
}


// MARK: ValueSchemaConvertor
// converting JSON Schema (Value) to Dynamic Generation Schema
class ValueSchemaConvertor {

    static func objectToDynamicSchema(_ object: [String: Value]) -> DynamicGenerationSchema {
        
        let title = getTitle(object: object) ?? UUID().uuidString
        let description = getDescription(object: object)
        
        let type = getPropertyTypeString(object: object)
        switch type {
        case .booleanType:
            let schema = DynamicGenerationSchema(type: Bool.self)
            return schema
            
        case .arrayType:
            let arrayItems = getArrayItems(object: object)
            let (min, max) = getArrayMinMax(object: object)
            let itemSchema = objectToDynamicSchema(arrayItems)
            
            return DynamicGenerationSchema (
                arrayOf: itemSchema,
                minimumElements: min,
                maximumElements: max
            )
            
        case .numberType:
            let schema = if let value = object[.enumType] {
                createEnumSchema(name: title, description: description, object: value).0
            } else if let value = object[.constantType], let schema = createConstSchema(object: value) {
                schema
            } else {
                DynamicGenerationSchema(type: Double.self)
            }
             
            return schema
            
        case .intType:
            let schema = if let value = object[.enumType] {
                createEnumSchema(name: title, description: description, object: value).0
            } else if let value = object[.constantType], let schema = createConstSchema(object: value) {
                schema
            } else {
                DynamicGenerationSchema(type: Int.self)
            }
             
            return schema
            
        case .stringType:
            print("string: \(object)")
            let schema = if let value = object[.enumType] {
                createEnumSchema(name: title, description: description, object: value).0
            } else if let value = object[.constantType], let schema = createConstSchema(object: value) {
                schema
            } else {
                DynamicGenerationSchema(type: String.self)
            }
            return schema
            
        default:
            break
        }
        
        // enum or const without type key
        if type != .objectType {
            if let value = object[.enumType] {
                let schema = createEnumSchema(name: title, description: description, object: value)
                return schema.0
            }
            
            if let value = object[.constantType], let result = createConstSchema(object: value) {
                return result
            }
        }
         
        
        let requiredFields = getRequiredFields(object: object)
        let properties = getProperties(object: object)
        
        var schemaProperties: [DynamicGenerationSchema.Property] = []
        
        for (key, value) in properties {
        
            let propertyName: String = key
            
            let propertyDescription = getDescription(object: value)
            
            let propertyTypeString = getPropertyTypeString(object: value)
            
            var required = requiredFields.contains(key)
            
            switch propertyTypeString {
            case .nullType:
                continue
                
            case .booleanType:
                let schema = DynamicGenerationSchema(type: Bool.self)
                schemaProperties.append(createDynamicSchemaProperty(name: propertyName, description: propertyDescription, schema: schema, required: required))
                
            case .objectType:
                let schema = objectToDynamicSchema(value)
                schemaProperties.append(createDynamicSchemaProperty(name: propertyName, description: propertyDescription, schema: schema, required: required))
                
            case .arrayType:
                let arrayItems = getArrayItems(object: value)
                let (min, max) = getArrayMinMax(object: value)
                
                let schema = objectToDynamicSchema(arrayItems)
                let arraySchema = DynamicGenerationSchema (
                    arrayOf: schema,
                    minimumElements: min,
                    maximumElements: max
                )
                let arrayProperty = createDynamicSchemaProperty(name: propertyName, description: propertyDescription, schema: arraySchema, required: required)
                
                schemaProperties.append(arrayProperty)
                
            case .numberType:
                var schema = DynamicGenerationSchema(type: Double.self)
                
                if let value = value[.enumType] {
                    let result = createEnumSchema(name: propertyName, description: propertyDescription, object: value)
                    schema = result.0
                    if let r = result.1 {
                        required = r
                    }
                } else if let value = value[.constantType], let result = createConstSchema(object: value) {
                    schema = result
                }

                schemaProperties.append(createDynamicSchemaProperty(name: propertyName, description: propertyDescription, schema: schema, required: required))
                
            case .intType:
                var schema = DynamicGenerationSchema(type: Int.self)
                
                if let value = value[.enumType] {
                    let result = createEnumSchema(name: propertyName, description: propertyDescription, object: value)
                    schema = result.0
                    if let r = result.1 {
                        required = r
                    }
                } else if let value = value[.constantType], let result = createConstSchema(object: value) {
                    schema = result
                }

                schemaProperties.append(createDynamicSchemaProperty(name: propertyName, description: propertyDescription, schema: schema, required: required))
                
                
            case .stringType:
                var schema = DynamicGenerationSchema(type: String.self)
                
                if let value = value[.enumType] {
                    let result = createEnumSchema(name: propertyName, description: propertyDescription, object: value)
                    schema = result.0
                    if let r = result.1 {
                        required = r
                    }
                } else if let value = value[.constantType], let result = createConstSchema(object: value) {
                    schema = result
                }

                schemaProperties.append(createDynamicSchemaProperty(name: propertyName, description: propertyDescription, schema: schema, required: required))
                
            default:

                // const or enum without type
                if let value = value[.enumType] {
                    
                    let result = createEnumSchema(name: title, description: description, object: value)
                    if let r = result.1 {
                        required = r
                    }
                    schemaProperties.append(createDynamicSchemaProperty(name: propertyName, description: propertyDescription, schema: result.0, required: required))
                }
                
                if let value = value[.constantType], let result = createConstSchema(object: value) {
                    schemaProperties.append(createDynamicSchemaProperty(name: propertyName, description: propertyDescription, schema: result, required: required))
                }
                
                continue
            }
        }
        
        let schema =  DynamicGenerationSchema(
            name: title,
            description: description,
            properties: schemaProperties,
        )
        
        return schema
        
    }


    private static func createDynamicSchemaProperty(name: String, description: String?, schema: DynamicGenerationSchema, required: Bool)  -> DynamicGenerationSchema.Property {
        return DynamicGenerationSchema.Property(
            name: name,
            description: description,
            schema: schema,
            optionality: required ? .required : .possiblyNull
        )
    }
    
    
    // "color": { "enum": ["red", "amber", "green", null, 42] }
    private static func createEnumSchema(name: String, description: String?, object: Value) -> (DynamicGenerationSchema, Bool?) {
        guard let array = object.arrayValue else {
            let schema = DynamicGenerationSchema(name: name, description: description, anyOf: [] as [String])
            return (schema, nil)
        }
        
        let strings: [String] = array.filter({$0.stringValue != nil}).map(\.stringValue!)
        let stringSchema = DynamicGenerationSchema(name: name, description: description, anyOf: strings)
        
        if strings.count == array.count {
            return (stringSchema, nil)
        }
        
        let required = !array.contains(where: {$0.isNull})

        let nonStrings = array.filter({$0.stringValue == nil})

        var schemas: [DynamicGenerationSchema] = [stringSchema]
        
        for value in nonStrings {
            if let intValue = value.intValue {
                schemas.append(createConstantIntSchema(value: intValue))
            }
            if let doubleValue = value.doubleValue {
                schemas.append(createConstantDoubleSchema(value: doubleValue))
            }
            if let _ = value.boolValue {
                schemas.append(DynamicGenerationSchema(type: Bool.self))
            }
        }
        
        let schema = DynamicGenerationSchema(name: name, description: description, anyOf: schemas)
        return (schema, required)
    }
    
    
    // "country": { "const": "United States of America" }
    // not handling array, object, or bool here
    private static func createConstSchema(object: Value) -> DynamicGenerationSchema? {
        if let intValue = object.intValue {
            return createConstantIntSchema(value: intValue)
        }
        if let doubleValue = object.doubleValue {
            return createConstantDoubleSchema(value: doubleValue)
        }
        if let stringValue = object.stringValue {
            return createConstantStringSchema(value: stringValue)
        }
        if let _ = object.arrayValue {
            // array constant not supported by dynamic schema
            return nil
        }
        
        if let _ = object.objectValue {
            // object constant not supported by dynamic schema
            return nil
        }
        return nil
    }
    
    private static func createConstantIntSchema(value: Int) -> DynamicGenerationSchema {
        DynamicGenerationSchema(type: Int.self, guides: [.range(value...value)])
    }
    
    private static func createConstantDoubleSchema(value: Double) -> DynamicGenerationSchema {
        DynamicGenerationSchema(type: Double.self, guides: [.range(value...value)])
    }
    
    private static func createConstantStringSchema(value: String) -> DynamicGenerationSchema {
        DynamicGenerationSchema(type: String.self, guides: [.constant(value)])
    }
    
    private static func getRequiredFields(object: [String: Value]) -> [String] {
        guard let array = object["required"]?.arrayValue else {
            return []
        }


        var requiredKeys: [String] = []
        
        for entry in array {
            if let string = entry.stringValue {
                requiredKeys.append(string)
            }
        }
        
        return requiredKeys
    }

    // minItems and maxItems
    private static func getArrayMinMax(object: [String: Value]) -> (Int?, Int?) {

        var minInt: Int? = nil
        var maxInt: Int? = nil
        
        if let min = object["minItems"]?.intValue {
            minInt = min
        }
        
        if let max = object["maxItems"]?.intValue {
            maxInt = max
        }

        return  (minInt, maxInt)
    }


    private static func getArrayItems(object: [String: Value]) -> [String: Value] {
        guard let items = object["items"]?.objectValue else {
            return [:]
        }

        return items
    }


    private static func getProperties(object: [String: Value]) -> [String: [String: Value]] {
        guard let propertyObject = object["properties"]?.objectValue else {
            return [:]
        }

        var propertyDict: [String: [String: Value]] = [:]
        
        for (key, value) in propertyObject {
            if let dict = value.objectValue {
                propertyDict[key] = dict
            }
        }
        return propertyDict
    }



    private static func getDescription(object: [String: Value]) -> String? {
        guard let description = object["description"]?.stringValue else {
            return nil
        }

        return description
    }

    private static func getTitle(object: [String: Value]) -> String? {
        guard let title = object["title"]?.stringValue else {
            return nil
        }

        return title
    }


    private static func getPropertyTypeString(object: [String: Value]) -> String? {
        guard let type = object["type"]?.stringValue else {
            return nil
        }

        return type
        
    }
    
}




// For testing
//import Playgrounds

//private let testSchema = """
//{
//    "title": "LikePokemonSchema",
//    "description": "Schema for liking a pokemon",
//    "type": "object",
//    "properties": {
//        "name": {
//            "description": "A list of pokemons name to like.",
//            "type": "array",
//            "items": {
//              "type": "string"
//            },
//            "minItems": 1
//        },
//        "details": {
//            "type": "object",
//            "description": "Details of the like action.",
//            "properties": {
//            "message": {
//                "description": "message to send to the pokemon.",
//                "type": "string"
//            },
//            "count": {
//                "description": "number of likes to send.",
//                "type": "number"
//            },
//          },
//          "required": []
//        }, 
//        "color": {
//          "type": "string",
//          "enum": ["red", "green", "blue", "yellow", 12]
//        }
//    },
//    "required": [ "name" ]
//}
//""".trimmingCharacters(in: .whitespacesAndNewlines)



//#Playground {
//    do {
//        let jsonDecoder = JSONDecoder()
//        let value = try jsonDecoder.decode(Value.self, from: testSchema.data(using: .utf8)!)
//        print(value)
//        if case .object(let object) = value {
//            let dynamic = ValueSchemaConvertor.objectToDynamicSchema(object)
//    //        print(schema)
//            let schema = try GenerationSchema(root: dynamic, dependencies: [])
//            print(schema.debugDescription)
//        }
//
//    } catch(let error) {
//        print(error)
//    }
//}
