//
//  MCPAppWebview.swift
//  FoundationModelApp
//
//  Created by Itsuki on 2025/10/17.
//

import SwiftUI
import WebKit
import MCP

struct MCPAppWebviewParameters {
    var mcpClient: MCPClient
    var resourceURI: String
    var toolInputJson: String
    var toolOutputJson: String
    var toolResponseMetadataJson: String
}


extension MCPAppWebview {
    init(_ params: MCPAppWebviewParameters) {
        self.parameters = params
    }
}

struct MCPAppWebview: View {
    @Environment(ChatManager.self) private var chatManager

    private let parameters: MCPAppWebviewParameters
    private let scriptManager: WebPageScriptManager = WebPageScriptManager()

    @State private var webpage: WebPage?
    @State private var error: String?
        
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            if let error = self.error {
                ContentUnavailableView("Oops!", systemImage: "exclamationmark.octagon", description: Text(error))
            } else {
                if let webpage = self.webpage {
                    WebView(webpage)
                        .webViewContentBackground(.hidden)
                        .overlay(content: {
                            if webpage.isLoading {
                                ProgressView()
                                    .controlSize(.large)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.yellow.opacity(0.1))
                            }
                        })
                        
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.yellow.opacity(0.1))
                }
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            do {
                try await self.initWebpage()
            } catch(let error) {
                print(error)
                self.error = error.localizedDescription
            }
        }
    }
    
    
    private func initWebpage() async throws {
        let html = try await self.chatManager.getAppResourceHTML(client: parameters.mcpClient, uri: parameters.resourceURI)
        
        var configuration = WebPage.Configuration()
        
        var navigationPreference = WebPage.NavigationPreferences()
        
        navigationPreference.allowsContentJavaScript = true
        navigationPreference.preferredHTTPSNavigationPolicy = .keepAsRequested
        navigationPreference.preferredContentMode = .mobile
        configuration.defaultNavigationPreferences = navigationPreference
        

        // userContentController: An object for managing interactions between JavaScript code and your web view, and for filtering content in your web view.
        configuration.userContentController = self.scriptManager.createUserContentController(toolInputJson: parameters.toolInputJson, toolOutputJson: parameters.toolOutputJson, toolResponseMetadataJson: parameters.toolResponseMetadataJson
        )
        self.scriptManager.callSelfMCPTool = { name, args in
            let client = self.parameters.mcpClient
            guard let tool = client.tools.first(where: {$0.name == name}) else {
                throw NSError(domain: "ToolDoesNotExist", code: 400)
            }
            guard tool.widgetAccessible else {
                throw NSError(domain: "ToolNotCallableFromWidget", code: 400)
            }
            return try await self.chatManager.callTool(client: self.parameters.mcpClient, toolName: name, arguments: args)
        }
        self.scriptManager.sendUserMessage = { prompt in
            return try await self.chatManager.respond(to: prompt)
        }

        let page = WebPage(configuration: configuration)
        self.webpage = page

        page.load(html: html)
    }
}


