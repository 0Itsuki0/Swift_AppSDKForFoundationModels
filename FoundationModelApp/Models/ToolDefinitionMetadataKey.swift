//
//  ToolDefinitionMetadataKey.swift
//  FoundationModelApp
//
//  Created by Itsuki on 2025/10/18.
//

import Foundation

// keys for the _meta field on MCP.Tool
// using the ones defined by openAi (https://developers.openai.com/apps-sdk/build/mcp-server#advanced) so that we can use the same MCP Server / App
enum ToolDefinitionMetadataKey: String {
    case outputTemplate = "openai/outputTemplate"
    case widgetAccessible = "openai/widgetAccessible"
}
