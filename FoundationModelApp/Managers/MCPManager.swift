//
//  MCPManager.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import SwiftUI
import MCP
import Logging
import FoundationModels



nonisolated
class MCPManager {

    var onToolUse: ((String?) -> Void)?
    var onAppAvailable: ((MCPAppWebviewParameters) -> Void)?

    private let logger = Logger(label: "itsuki.enjoy.FoundationModelWithMCP")
    
    private let version = "1.0.0"
    
    private(set) var mcpClients: [MCPClient] = []
    
    private let jsonDecoder = JSONDecoder()
    
    // openAI uses skybridge for iframe sandbox, so we are including it as a target mime type
    private let appResourceMimeTypes = ["text/html+skybridge", "text/html"]
    
    var tools: [MCPTool] {
        get throws {
            try self.mcpClients.flatMap({ client in
                return try client.tools.map({ tool in
                    try MCPTool(tool: tool, onToolCall: { arguments in
                        try await self.callTool(client: client, toolName: tool.name, arguments: arguments)
                    })
                })
            })
        }
    }
    
    
    init() {
        // Configure Logger
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return handler
        }
    }
    
    deinit {
        Task { [weak self] in
            guard let self else {
                return
            }
            for client in self.mcpClients {
                await client.client.disconnect()
            }
        }
    }
    
    func disconnect(client: Client) async {
        await client.disconnect()
        self.mcpClients.removeAll(where: {$0.client.name == client.name})
    }

    func addServer(endpoint: String) async throws {
        guard let url = URL(string: endpoint) else {
            throw MCPError.invalidURL(endpoint)
        }
        
        let client = Client(name: endpoint, version: self.version)
        
        // Create a transport and connect
        let transport = HTTPClientTransport(
            endpoint: url,
            configuration: .default,
            streaming: false,
            sseInitializationTimeout: 20,
            logger: self.logger
        )
        
        let result = try await client.connect(transport: transport)
        
        let tools = try await self.listTools(client: client)
        
        self.mcpClients.append(.init(client: client, serverInfo: result.serverInfo, endpoint: endpoint, tools: tools))
        
    }
    
    
    private func listTools(client: Client) async throws -> [MCP.Tool] {
        var (tools, cursor) = try await client.listTools()

        while cursor != nil {
            let next = try await client.listTools(cursor: cursor)
            tools.append(contentsOf: next.tools)
            cursor = next.nextCursor
        }

        return tools
    }
    
    
    private func callTool(client: MCPClient, toolName: String, arguments: GeneratedContent) async throws  -> ToolOutputType {
        print(#function)
        
        let json = arguments.jsonString
        let arguments: [String: Value]? = try? self.jsonDecoder.decode([String: Value].self, from: Data(json.utf8))
        let message = "[Using Tool] Name: \(toolName). Arguments: \(arguments, default: "(No args).")"
        print(message)
        
        self.onToolUse?(message)
        defer {
            self.onToolUse?(nil)
        }
        
        // Call a tool with arguments
        let result = try await self.callTool(
            client: client,
            toolName: toolName,
            arguments: arguments
        )

        var output = try ToolOutputType(contents: result.content)
        
        if result.isError == true {
            
            output.texts.insert("Error executing tool.", at: 0)
            
        } else {
            
            do {
                if let parameters = try await self.createAppViewParams(client: client, toolName: toolName, inputArguments: arguments, toolResult: result) {
                    self.onAppAvailable?(parameters)
                }
            } catch(let error) {
                print(error)
            }
        }
        

        return output
    }
    
    private func createAppViewParams(
        client: MCPClient,
        toolName: String,
        inputArguments: [String: Value]?,
        toolResult: CallTool.Result
    ) async throws -> MCPAppWebviewParameters? {
        
        guard let resourceURI = getAppResourceURI(client: client, toolName: toolName) else {
            return nil
        }
            
        let inputValue = inputArguments == nil ? Value.null : Value.object(inputArguments!)
        let parameter = await MCPAppWebviewParameters(
            mcpClient: client,
            resourceURI: resourceURI,
            toolInputJson: try inputValue.jsonString,
            toolOutputJson: try toolResult.structuredContentJson,
            toolResponseMetadataJson: try toolResult.metadataJson
        )
        return parameter
    }
    
    
    private func getAppResourceURI(client: MCPClient, toolName: String) -> String? {
        guard let tool = client.tools.first(where: {$0.name == toolName}) else {
            return nil
        }
        guard let meta = tool._meta?.objectValue else {
            return nil
        }
        
        guard let appResourceURI = meta[ToolDefinitionMetadataKey.outputTemplate.rawValue]?.stringValue else {
            return nil
        }
        print("App Resource Available for tool: \(toolName). ResourceURI: \(appResourceURI)")

        return appResourceURI

    }
    
        
    func callTool(client: MCPClient, toolName: String, arguments: [String: Value]? = nil) async throws -> CallTool.Result {
        print(#function)
        
        // Call a tool with arguments
        let result = try await client.client.callTool(
            name: toolName,
            arguments: arguments
        )

        return result
    }
    
    // Retrieve the HTML string for the App Resource
    func getAppResource(client: MCPClient, uri: String) async throws -> String {
        let contents = try await self.retrieveResource(client: client.client, uri: uri)
        guard let targetContent = contents.first(where: { content in
            guard let mimeType = content.mimeType, content.text != nil else {
                return false
            }
            guard self.appResourceMimeTypes.contains(mimeType) else {
                return false
            }
            
            return true
        }) else {
            throw NSError(domain: "ResourceNotExist", code: 400)
        }
        
        return targetContent.text!
    }

    
    func retrieveResource(client: Client, uri: String) async throws -> [MCP.Resource.Content] {
        let contents = try await client.readResource(uri: uri)
        return contents
    }
    
    func saveResources(contents: [MCP.Resource.Content]) throws -> [URL]{
        let tempDirectory = FileManager.default.temporaryDirectory
        var urls: [URL] = []
        for item in contents {
            guard let mimeType = item.mimeType, let preferredExtension = mimeType.preferredExtension else {
                continue
            }
            let url = tempDirectory.appending(path: "\(item.uri).\(preferredExtension)")

            if let base64 = item.blob {
                guard let data = Data(base64Encoded: base64) else {
                    continue
                }
                try data.write(to: url)
                urls.append(url)
            }
            if let text = item.text {
                try Data(text.utf8).write(to: url)
                urls.append(url)
            }
        }
        
        return urls

    }
}
