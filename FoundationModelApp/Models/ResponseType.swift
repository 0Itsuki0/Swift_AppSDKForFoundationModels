//
//  ResponseType.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//


import SwiftUI
import FoundationModels


@Generable
struct ResponseType {
//    @Guide(description: "A list of urls for the generated binaries. Empty if no binaries generated.")
//    var urls: [String]
//    @Guide(description: "Raw tool outputs from any tool used in the turn.")
//    var toolOutput: [ToolOutputType]
    
    @Guide(description: "A list of urls for the images obtained from the tool calls.")
    var images: [String]
    
    @Guide(description: "A list of urls for the audios obtained from the tool calls.")
    var audios: [String]
    
    @Guide(description: "A list of resources URI from the tool calls.")
    var resources: [String]

    @Guide(description: "Concise Text response. ")
    var textResponse: String
}

