//
//  URL+Extensions.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import Foundation

extension URL {
    nonisolated
    var absolutePath: String {
        return self.path(percentEncoded: false)
    }
    
    nonisolated
    var parentDirectory: URL {
        return self.appending(component: "..").standardized
    }
    
    static func resolvedPathURL(string: String) -> URL? {
        guard let url = URL(string: string) else {
            return nil
        }
        
        if url.isFileURL {
            return url
        }
        
        return URL(filePath: string)
    }
    
}
