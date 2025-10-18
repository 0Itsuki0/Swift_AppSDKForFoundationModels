//
//  ScriptManager.swift
//  FoundationModelApp
//
//  Created by Itsuki on 2025/10/18.
//

import SwiftUI
import MCP
import WebKit

class WebPageScriptManager: NSObject {

    // Calls a tool on the tool's MCP. Returns the full response
    var callSelfMCPTool: ((String, Dictionary<String, Value>) async throws -> CallTool.Result)?
    //insert a message into the conversation as if the user asked it.
    var sendUserMessage: ((String) async throws -> Void)?

    // Messages we will be receiving from JavaScript code as well as responding to
    enum MessageWithReplyName: String {
        case callTool
        case sendFollowUpMessage
    }
        
    // message keys for postMessage called on MessageWithReplyName.callFunction
    // postMessage({
    //   "\(nameKey)": "some name",
    //   "\(argumentKey)": { key: "value" }
    // })
    private let toolNameKey = "name"
    private let toolArgumentKey = "args"

    func createUserContentController(
        toolInputJson: String,
        toolOutputJson: String,
        toolResponseMetadataJson: String
    ) -> WKUserContentController {
        let contentController = WKUserContentController()

        // script to be injected
        //
        // using the same `window.openai` API defined by openAi (https://developers.openai.com/apps-sdk/build/custom-ux) so that we can use the same MCP Server / App
        let script =
"""
window.openai = {
    "toolOutput": \(toolOutputJson),
    "toolInput": \(toolInputJson),
    "toolResponseMetadata": \(toolResponseMetadataJson),
    "callTool": async (name, value) => {
        return await window.webkit.messageHandlers.\(MessageWithReplyName.callTool.rawValue).postMessage({
            "\(toolNameKey)": name, 
            "\(toolArgumentKey)": value
        })
    },
    "sendFollowUpMessage": async (args) => {
        return await window.webkit.messageHandlers.\(MessageWithReplyName.sendFollowUpMessage.rawValue).postMessage(args)
    }

}
"""
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        
        // Installs a message handler that returns a reply to your JavaScript code.
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: MessageWithReplyName.callTool.rawValue)
        
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: MessageWithReplyName.sendFollowUpMessage.rawValue)

        return contentController
    }

}
 

// MARK: WKScriptMessageHandlerWithReply
// An interface for *responding* to messages from JavaScript code running in a webpage.
extension WebPageScriptManager: WKScriptMessageHandlerWithReply {
    
    // returning (Result, Error)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        print(#function, "WKScriptMessageHandlerWithReply")
        print(message.name)
        
        guard let name: MessageWithReplyName = .init(rawValue: message.name) else {
            return (nil, "Message received from unknown message handler with name: \(message.name)")
        }
        let body = message.body
        
        do  {
            switch name {
            case .callTool:
                let result = try await self.handleCallToolCalled(messageBody: body)
                return (result, nil)
            case .sendFollowUpMessage:
                try await self.handleSendFollowUpMessageCalled(messageBody: body)
                return (nil, nil)
            }
        } catch (let error) {
            return (nil, "Error: \(error.localizedDescription)")
        }

    }
    
    // body: { "name": string, args: Record }
    private func handleCallToolCalled(messageBody: Any) async throws -> Any? {
        print(messageBody)
        guard let body = messageBody as? Dictionary<String, Any> else {
            throw NSError(domain: "InvalidMessageBody", code: 400)
        }
        
        guard let name = body[toolNameKey] as? String, let arguments = body[toolArgumentKey] as? Dictionary<String, Any> else {
            throw NSError(domain: "InvalidParameters", code: 400)
        }
   
        print("Call Tool. Name: \(name). Arguments. \(arguments)")
        print(name, arguments)
        
        let encodedArgs = try JSONSerialization.data(withJSONObject: arguments)
        let argDict = try JSONDecoder().decode([String: Value].self, from: encodedArgs)

        guard let callTool = self.callSelfMCPTool else {
            throw NSError(domain: "CallToolUnavailable", code: 500)
        }

        let result: CallTool.Result = try await callTool(name, argDict)

        return try result.jsonDictionary
    }
    
    // body: { "prompt": string }
    private func handleSendFollowUpMessageCalled(messageBody: Any) async throws {
        guard let body = messageBody as? Dictionary<String, Any> else {
            throw NSError(domain: "InvalidMessageBody", code: 400)
        }
        
        guard let prompt = body["prompt"] as? String else {
            throw NSError(domain: "InvalidPrompt", code: 400)
        }
   
        print("prompt: \(prompt)")
        
        guard let sendUserMessage = self.sendUserMessage else {
            throw NSError(domain: "SendUserMessgaeUnavailable", code: 500)
        }

        try await sendUserMessage(prompt)
        
        return
    }
}
