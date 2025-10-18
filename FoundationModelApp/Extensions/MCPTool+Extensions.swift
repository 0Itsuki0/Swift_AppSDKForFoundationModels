//
//  MCPTool+Extensions.swift
//  FoundationModelWithMCP
//
//  Created by Itsuki on 2025/10/13.
//

import MCP
import FoundationModels


extension MCP.Tool {
    var dynamicSchema: DynamicGenerationSchema? {
        guard case .object(let object) = self.inputSchema else {
            return nil
        }
        return ValueSchemaConvertor.objectToDynamicSchema(object)
    }
    
    var displayString: String {
        if let description = self.description {
            return "\(self.name): \(description)"
        }
        return self.name
    }
    
    var widgetAccessible: Bool {
        guard let meta = self._meta?.objectValue else {
            return false
        }
        
        guard let accessible = meta[ToolDefinitionMetadataKey.widgetAccessible.rawValue]?.boolValue else {
            return false
        }
        
        return accessible
    }
    
    var embeddedResourceURI: String? {
        guard let meta = self._meta?.objectValue else {
            return nil
        }
        
        guard let appResourceURI = meta[ToolDefinitionMetadataKey.outputTemplate.rawValue]?.stringValue else {
            return nil
        }
        
        return appResourceURI
    }
}
