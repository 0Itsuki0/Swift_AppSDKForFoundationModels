//
//  AddRemoteServerView.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import SwiftUI

struct AddRemoteServerView: View {
    @Environment(ChatManager.self) private var chatManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var endpoint: String = "http://localhost:3000/mcp"
    
    @State private var errorMessage: String? = nil
    
    @State private var loading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Remote MCP Server")
                    .font(.headline)

                if let errorMessage = self.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)

                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Ex: `https://mcp.deepwiki.com/mcp`")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
                TextField("", text: $endpoint)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    self.dismiss()
                }, label: {
                    Text("Cancel")
                        .padding(.horizontal, 2)
                })
                
                Button(action: {
                    let endpoint = self.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !endpoint.isEmpty else {
                        self.errorMessage = "Endpoint cannot be empty."
                        return
                    }
                    
                    Task {
                        self.loading = true
                        self.errorMessage = nil
                        do {
                            try await self.chatManager.addMCPServers(endpoints: [endpoint])
                            self.endpoint = ""
                            
                            self.dismiss()

                        } catch (let error) {
                            self.errorMessage = "\(error)"
                        }
                        
                        self.loading = false
                    }
                }, label: {
                    Text("Add")
                        .padding(.horizontal, 2)
                })
            }
            .buttonStyle(.glassProminent)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .sheet(isPresented: $loading, content: {
                ProgressView()
                    .controlSize(.extraLarge)
                    .padding(.all, 24)
                    .frame(width: 280, height: 180)
                    .interactiveDismissDisabled()

            })
            .onDisappear {
                self.endpoint = ""
                self.errorMessage = nil
            }

        }
        .padding()
    }
}

