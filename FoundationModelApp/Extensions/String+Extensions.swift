//
//  String+Extensions.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import UniformTypeIdentifiers
import Foundation

extension String {
    nonisolated
    var preferredExtension: String? {
        if let utType = UTType(mimeType: self) {
            return utType.preferredFilenameExtension
        }
        return nil
    }

}
