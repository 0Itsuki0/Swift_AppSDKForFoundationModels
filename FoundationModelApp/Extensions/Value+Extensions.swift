//
//  Value.swift
//  FoundationModelApp
//
//  Created by Itsuki on 2025/10/18.
//

import MCP
import Foundation

extension Value {
    var jsonString: String {
        get throws {
            let encoder = JSONEncoder()
            let content = self
            let jsonData = try encoder.encode(content)

            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw NSError(domain: "StructuredContentJsonConversionFailed", code: 500)
            }
            
            return jsonString
        }

    }
}
