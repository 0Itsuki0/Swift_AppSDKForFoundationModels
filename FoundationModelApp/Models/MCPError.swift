//
//  MCPError.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import Foundation

enum MCPError: Error {
    case invalidURL(String)
    case invalidToolSchema
    case invalidImageData
    case invalidAudioData
}
