//
//  Resource.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import SwiftUI
import FoundationModels
import MCP



struct MCPTool: FoundationModels.Tool {
    
    let name: String
    let description: String
    let parameters: GenerationSchema
    let onToolCall: @Sendable (Arguments) async throws -> ToolOutputType
    let includesSchemaInInstructions: Bool = true // default to true
    
    
    init(tool: MCP.Tool, onToolCall: @escaping @Sendable (Arguments) async throws -> ToolOutputType) throws {
        guard let dynamicSchema = tool.dynamicSchema else {
            throw MCPError.invalidToolSchema
        }
        
        let schema = try GenerationSchema(root: dynamicSchema, dependencies: [])
        
        self.name = tool.name
        self.description = tool.description ?? tool.name
        self.parameters = schema
        self.onToolCall = onToolCall
    }

    typealias Arguments = GeneratedContent
    
    func call(arguments: Arguments) async throws -> ToolOutputType {
        return try await self.onToolCall(arguments)
    }
}
