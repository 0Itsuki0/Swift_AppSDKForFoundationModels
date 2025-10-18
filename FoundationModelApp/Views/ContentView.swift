//
//  ContentView.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/09.
//

import SwiftUI



struct ContentView: View {
    @State private var chatManager: ChatManager = ChatManager()
    @State private var entry: String = "Tell me more about pikachu!"
    @State private var scrollPosition: ScrollPosition = .init()
    
    @State private var selectedURL: URL?
    @State private var entryHeight: CGFloat = 24

    @State private var showMCPServers: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            List {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apps For Foundation Models")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.white)

                        Text("Just like Apps For ChatGPT!")
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.bottom, 16)

                    Spacer()
                    
                    Button(action: {
                        showMCPServers = true
                    }, label: {
                        Text("MCP Servers")
                    })
                    .buttonStyle(.glassProminent)
                }
                
                if let error = chatManager.error {
                    Text(String("\(error)"))
                        .foregroundStyle(.red)
                        .listRowSeparator(.hidden)

                }
                
                ForEach(chatManager.messages) { message in
 
                    Group {
                        switch message {
                        case .response(_, let response):
                            VStack(alignment: .leading) {
                                Text(response.textResponse)
                                
                                if !response.images.isEmpty {
                                    Divider()
                                        .padding(.vertical, 8)
                                    Text("URL for the Generated Images")
                                        .font(.headline)
                                    
                                    ForEach(0..<response.images.count, id:\.self) { index in
                                        let urlString: String = response.images[index]
                                        if let url = URL.resolvedPathURL(string: urlString) {
                                            Button(action: {
                                                openFile(url)
                                            }, label: {
                                                Text(url.lastPathComponent.isEmpty ? urlString : url.lastPathComponent )
                                            })
                                        }
                                    }
                                }
                                
                                if !response.audios.isEmpty {
                                    Divider()
                                        .padding(.vertical, 8)
                                    Text("URL for the Generated Audios")
                                        .font(.headline)
                                    
                                    ForEach(0..<response.audios.count, id:\.self) { index in
                                        let urlString: String = response.audios[index]
                                        if let url = URL.resolvedPathURL(string: urlString) {
                                            Button(action: {
                                                openFile(url)
                                            }, label: {
                                                Text(url.lastPathComponent.isEmpty ? urlString : url.lastPathComponent )
                                            })
                                        }
                                    }
                                }
                                
                                if !response.resources.isEmpty {
                                    Divider()
                                        .padding(.vertical, 8)
                                    
                                    Text("Resources")
                                        .font(.headline)
                                    
                                    
                                    ForEach(0..<response.resources.count, id:\.self) { index in
                                        let urlString: String = response.resources[index]
                                        // not doing anything but displaying the URI here.
                                        // If needed, we can also call the `retrieveResource` function on the MCPManager to get the actual resource.
                                        Text(urlString)
                                            .multilineTextAlignment(.leading)
                                    }
                                }

                            }
                            .listRowBackground(Color.clear)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.all, 16)
                            .background(RoundedRectangle(cornerRadius: 24).fill(.yellow))
                            .padding(.leading, 64)

                        case .userPrompt(_, let prompt):
                            Text(prompt)
                                .listRowBackground(Color.clear)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.all, 16)
                                .background(RoundedRectangle(cornerRadius: 24).fill(.green))
                                .padding(.trailing, 64)

                        case .mcpApp(_, let params):
                            MCPAppWebview(params)
                                .environment(self.chatManager)
                                .listRowBackground(Color.clear)
                                .frame(height: 360)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 24).fill(.clear).stroke(.yellow.opacity(0.5), lineWidth: 2))
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                    }
                    .listRowInsets(.all, 0)
                    .padding(.vertical, 16)
                    .listRowSeparator(.hidden)

                }
                
                
                if let toolUseMessage = chatManager.toolUseMessage {
                    Text(toolUseMessage)
                        .font(.headline)
                        .foregroundStyle(.gray)
                }
                
            }
            .foregroundStyle(.black)
            .font(.headline)
            .scrollTargetLayout()
            .frame(maxWidth: .infinity)
            .scrollPosition($scrollPosition, anchor: .bottom)
            .defaultScrollAnchor(.bottom, for: .alignment)
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .onChange(of: self.chatManager.messages, initial: true, {
                if let last = chatManager.messages.last {
                    proxy.scrollTo(last.id)
                }
            })
        }
        .frame(minWidth: 480, minHeight: 400)
        .padding(.bottom, self.entryHeight)
        .overlay(alignment: .bottom, content: {
            HStack(spacing: 12) {
                TextEditor(text: $entry)
                    .onSubmit({
                        self.sendPrompt()
                    })
                    .textEditorStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundStyle(.background.opacity(0.8))
                    .padding(.all, 4)
                    .background(RoundedRectangle(cornerRadius: 4)
                        .stroke(.gray, style: .init(lineWidth: 1))
                        .fill(.white)
                    )
                    .frame(maxHeight: 120)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: {
                    self.sendPrompt()
                }, label: {
                    Image(systemName: "paperplane.fill")
                })
                .buttonStyle(.glass)
                .foregroundStyle(.blue)
                .disabled(self.chatManager.isResponding)
                
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(.yellow.opacity(0.2))
            .background(.white)
            .onGeometryChange(for: CGFloat.self, of: {
                $0.size.height
            }, action: { old, new in
                self.entryHeight = new
            })
            
        })
        .sheet(isPresented: $showMCPServers, content: {
            MCPServersView()
                .environment(self.chatManager)
        })
    }
    
    private func sendPrompt() {
        let entry = self.entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        guard !chatManager.isResponding else {
            return
        }
        
        self.entry = ""

        Task {
            do {
                try await self.chatManager.respond(to: entry)
            } catch(let error) {
                self.chatManager.error = error
            }
        }

    }
    
    private func openFile(_ url: URL) {
        let _ = NSWorkspace.shared.selectFile(
            url.absolutePath,
            inFileViewerRootedAtPath: url.parentDirectory.absolutePath
        )
    }

}
