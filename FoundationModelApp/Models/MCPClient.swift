//
//  MCPClient.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import Foundation
import MCP

// a wrapper around MCP.Client
struct MCPClient {
    var client: Client
    var serverInfo: Server.Info
    var endpoint: String
    var tools: [MCP.Tool]
}
