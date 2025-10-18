//
//  ChatManager.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import SwiftUI
import FoundationModels
import MCP

@Observable
class ChatManager {
        
    private(set) var messages: [MessageType] = []
    
    var isResponding: Bool {
        self.session?.isResponding ?? false
    }
        
    private(set) var toolUseMessage: String? = nil
    
    var mcpClients: [MCPClient] {
        return self.mcpManager.mcpClients
    }

    
    var error: (any Error)? = nil {
        didSet {
            if let error = error {
                print(error)
            }
        }
    }
    
    enum _Error: Error {
        case modelUnavailable(String)
        case initializationFailed
        
        var message: String {
            switch self {
            case .modelUnavailable(let string):
                return string
            case .initializationFailed:
                return "initialization failed"
            }
        }
    }
    
    enum MessageType: Identifiable, Equatable {
        case userPrompt(UUID, String)
        case mcpApp(UUID, MCPAppWebviewParameters)
        case response(UUID, ResponseType)
        
        var id: UUID {
            switch self {
            case .userPrompt(let id, _):
                return id
            case .mcpApp(let id, _):
                return id
            case .response(let id, _):
                return id
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.id == rhs.id
        }
        
        var userPrompt: String? {
            if case .userPrompt(_, let prompt) = self {
                return prompt
            }
            return nil
        }
        
        var response: ResponseType? {
            if case .response(_, let response) = self {
                return response
            }
            return nil
        }
        
        var mcpApp: MCPAppWebviewParameters? {
            if case .mcpApp(_, let params) = self {
                return params
            }
            return nil
        }
    }
    
   
    private var session: LanguageModelSession? = nil
    
    private let model = SystemLanguageModel.default
    
    private let mcpManager: MCPManager = MCPManager()
    
    init() {
        self.mcpManager.onToolUse = { self.toolUseMessage = $0 }
        self.mcpManager.onAppAvailable = { self.messages.append(.mcpApp(UUID(), $0)) }
        
        Task {
            do {
                try self.checkAvailability()
                self.session = .init(
                    model: self.model,
                    tools: [],
                    instructions: makePrompt(tools: [])
                )
            } catch (let error) {
                self.error = error
            }
        }
    }
    
    private func makePrompt(tools: [any FoundationModels.Tool]) -> String {
        var prompt = "You are a helpful assistant.\n" +
        "**IMPORTANT**: You always answer user's question **concisely**."
        
        if tools.isEmpty {
            return prompt
        }
        
        let toolDescription = tools.map({"- \($0.name): \($0.description)"}).joined(separator: "\n")
        prompt = "You have access to the following tools.\n" +
        toolDescription + "\n\n" +
        "Use the tools to answer user's question properly. \n"
        
        return prompt
    }

    func setMCPServers(endpoints: [String]) async throws {
        // disconnect any connected servers
        await withTaskGroup(of: Void.self) { group in
             for client in mcpManager.mcpClients {
                group.addTask {
                    await self.mcpManager.disconnect(client: client.client)
                }
            }
            await group.waitForAll()
            return
        }
        
        // connect to the new servers
        try await self.addMCPServers(endpoints: endpoints)

    }
    

    func addMCPServers(endpoints: [String]) async throws {
        let endpoints = endpoints.filter({ ed in !self.mcpClients.contains(where: {$0.endpoint == ed})})
        
        // connect to the new servers
        try await withThrowingTaskGroup(of: Void.self) { group in
            for endpoint in endpoints {
                group.addTask {
                    try await self.mcpManager.addServer(endpoint: endpoint)
                }
            }
            try await group.waitForAll()
            return
        }
        
        // Te-initialize session with the tools
        // Not using the transcripts to preserve the history because we want to reset the prompt.
        let tools = try mcpManager.tools
        print("Tools available: \(tools.map(\.name))")
        self.session = .init(
            model: self.model,
            tools: tools,
            instructions: makePrompt(tools: tools)
        )
    }
    
    func getAppResourceHTML(client: MCPClient, uri: String) async throws -> String {
        return try await self.mcpManager.getAppResource(client: client, uri: uri)
    }
    
    func callTool(client: MCPClient, toolName: String, arguments: [String: Value]? = nil) async throws -> CallTool.Result {
        return try await self.mcpManager.callTool(client: client, toolName: toolName, arguments: arguments)
    }


    func respond(to prompt: String) async throws {
        print(#function)
        print(prompt)
        guard let session else {
            throw _Error.initializationFailed
        }
        if session.isResponding {
            return
        }
        self.messages.append(.userPrompt(UUID(), prompt))
        let response = try await session.respond(to: prompt, generating: ResponseType.self)
        self.messages.append(.response(UUID(), response.content))
    }
    
    
    private func checkAvailability() throws {
        let availability = model.availability
        if case .unavailable(let reason) = availability {
            switch reason {
            case .appleIntelligenceNotEnabled:
                throw _Error.modelUnavailable("Apple Intelligence is not enabled.")
            case .deviceNotEligible:
                throw _Error.modelUnavailable("This device is not eligible.")
            case .modelNotReady:
                throw  _Error.modelUnavailable("Model is not ready.")
            @unknown default:
                throw _Error.modelUnavailable("Unknown reason.")
            }
        }
    }

}
