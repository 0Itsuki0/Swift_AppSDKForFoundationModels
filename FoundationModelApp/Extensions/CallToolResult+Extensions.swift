//
//  File.swift
//  FoundationModelApp
//
//  Created by Itsuki on 2025/10/18.
//

import MCP
import Foundation

extension CallTool.Result {
    
    var jsonDictionary: [String: Any?]  {
        get throws {
            let encodedResult = try JSONEncoder().encode(self)
            guard var jsonDictionary = try JSONSerialization.jsonObject(with: encodedResult, options: []) as? [String: Any?] else {
                throw NSError(domain: "ToolResultDictConversionFailed", code: 500)
            }
            
            let serializedStructureContent = String(data: try JSONEncoder().encode(self.structuredContent ?? .null), encoding: .utf8)
            jsonDictionary["result"] = serializedStructureContent
            
            return jsonDictionary
        }
    }
    
    var structuredContentJson: String {
        get throws {
            let content = self.structuredContent ?? .null
            return try content.jsonString
        }
    }
    
    var metadataJson: String {
        get throws {
            let content = self._meta ?? .null
            return try content.jsonString
        }

    }
}
