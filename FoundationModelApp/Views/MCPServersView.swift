//
//  MCPServersView.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import SwiftUI
import MCP

struct MCPServersView: View {
    @Environment(ChatManager.self) private var chatManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAddView: Bool = false
        
    var body: some View {
        let serverInfo: [(String, [String])] = chatManager.mcpClients.map({($0.serverInfo.name, $0.tools.map(\.displayString))})
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("MCP Servers")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white)

                if serverInfo.isEmpty {
                    Text("No server added. ")
                        .foregroundStyle(.secondary)
                }

                ForEach(serverInfo, id: \.0) { info in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(info.0)
                            .font(.headline)

                        let tools: [String] = info.1
                        ForEach(tools, id: \.self) { tool in
                            Text(tool)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .foregroundStyle(.secondary)
            .padding()
        }
        .frame(width: 360, height: 320)
        .overlay(alignment: .topTrailing, content: {
            HStack(spacing: 8) {
                Button(action: {
                    self.showAddView = true
                }, label: {
                    Image(systemName: "plus")
                })
                                
                Button(action: {
                    self.dismiss()
                }, label: {
                    Image(systemName: "xmark")
                })

            }
            .padding()
            .buttonStyle(.glassProminent)


        })
        .sheet(isPresented: $showAddView, content: {
            AddRemoteServerView()
                .environment(self.chatManager)
        })

        
    }
}
