//
//  ToolOutputType.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import FoundationModels
import MCP
import SwiftUI

@Generable
struct ToolOutputType {
    @Guide(description: "Text Output.")
    var texts: [String]

    @Guide(description: "A list of urls for images.")
    var images: [String]
    
    @Guide(description: "A list of urls for audios.")
    var audios: [String]
    
    @Guide(description: "A list of resources.")
    var resources: [String]

    init(texts: [String], images: [String], audios: [String], resources: [String]) {
        self.texts = texts
        self.images = images
        self.audios = audios
        self.resources = resources
    }
    
    init(contents: [MCP.Tool.Content]) throws {
        var texts: [String] = []
        var images: [String] = []
        var audios: [String] = []
        var resources: [String] = []
        
        let tempDirectory = FileManager.default.temporaryDirectory

        for item in contents {
            switch item {
            case .text(let text):
                texts.append(text)
            case .image(let base64, let mimeType, _):

                guard let data = Data(base64Encoded: base64), let preferredExtension = mimeType.preferredExtension else {
                    throw MCPError.invalidImageData
                }
                
                let url = tempDirectory.appending(path: "\(UUID()).\(preferredExtension)")
                try data.write(to: url)
                images.append(url.absolutePath)
                
            case .audio(let base64, let mimeType):
                guard let data = Data(base64Encoded: base64), let preferredExtension = mimeType.preferredExtension else {
                    throw MCPError.invalidAudioData
                }
                let url = tempDirectory.appending(path: "\(UUID()).\(preferredExtension)")
                try data.write(to: url)
                audios.append(url.absolutePath)

            case .resource(let uri, _,  _):
                resources.append(uri)
            }
        }
                
        self.texts = texts
        self.images = images
        self.audios = audios
        self.resources = resources

    }
}
