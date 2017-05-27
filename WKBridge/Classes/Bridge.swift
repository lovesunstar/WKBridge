//
//  Bridge.swift
//  JSBridge
//
//  Created by SunJiangting on 2017/5/27.
//  Copyright © 2017年 Samaritan. All rights reserved.
//

import UIKit
import WebKit

/// JS 和 Native 代码交互设计
open class Bridge: NSObject {
    
    static let name: String = "pacific"
    
    fileprivate enum MessageKey {
        static let action = "action"
        static let parameters = "parameters"
        static let callback = "callback"
        static let printable = "print"
    }
    
    public struct JSError {
        public let code: Int
        public let description: String
        
        public init(code: Int, description: String) {
            self.code = code
            self.description = description
        }
    }
    
    /// 执行完某个 action 的结果
    public enum Results {
        /// 执行成功
        case success([String: Any]?)
        /// 执行失败
        case failure(JSError)
    }
    
    /// Bridge 处理事件的回调, 处理事件之后，如果需要回调，则会通知 js
    /// - parameter results: 需要回调给 JS 的结果。均会转成 JS Objects
    public typealias Callback = (_ results: Results) -> Void
    
    /// 注册处理事件的回调，当满足条件时，会执行此闭包
    /// - Parameter parameters: js 传入的参数
    /// - Parameter callback: 执行完毕之后告诉外边执行的结果
    public typealias Handler = (_ parameters: [String: Any]?, _ callback: Callback) -> Void
    
    private(set) var handlers = [String: Handler]()
    
    private let configuration: WKWebViewConfiguration
    fileprivate weak var webView: WKWebView?
    
    public var printScriptMessageAutomatically = false
    
    deinit {
        configuration.removeObserver(self, forKeyPath: #keyPath(WKWebViewConfiguration.userContentController))
        configuration.userContentController.removeObserver(self, forKeyPath: Bridge.name)
    }
    
    fileprivate init(webView: WKWebView) {
        self.webView = webView
        self.configuration = webView.configuration
        super.init()
        configuration.addObserver(self, forKeyPath: #keyPath(WKWebViewConfiguration.userContentController), options: [.new, .old], context: nil)
        configuration.userContentController.add(self, name: Bridge.name)
    }
    
    /// 注册某个事件的处理
    /// - Parameter handler: 回调处理
    /// - parameter action: 需要处理的事件名称
    ///
    /// - SeeAlso: `Handler`
    public func register(_ handler: @escaping Handler, for action: String) {
        handlers[action] = handler
    }
    
    /// 取消注册某个事件的处理
    /// - Parameters action: 需要取消的事件名称
    public func unregister(for action: String) {
        handlers[action] = nil
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? WKWebViewConfiguration, let kp = keyPath, obj == configuration && kp == #keyPath(WKWebViewConfiguration.userContentController) {
            if let change = change {
                if let oldContentController = change[.oldKey] as? WKUserContentController {
                    oldContentController.removeObserver(self, forKeyPath: Bridge.name)
                }
                if let newContentController = change[.oldKey] as? WKUserContentController {
                    newContentController.add(self, name: Bridge.name)
                }
            }
        }
    }
}

extension Bridge: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let name = body[MessageKey.action] as? String, let handler = handlers[name] else {
            return
        }
        if (body[MessageKey.printable] as? NSNumber)?.boolValue ?? printScriptMessageAutomatically {
            print(body)
        }
        if let callbackID = (body[MessageKey.callback] as? NSNumber) {
            handler(body[MessageKey.parameters] as? [String: Any]) { (results) in
                // Do Nothing
                guard let webView = webView else { return }
                var eventDetail: [String: Any] = ["id": callbackID]
                switch results {
                case .failure(let error):
                    eventDetail["error"] = ["code": error.code, "description": error.description]
                case .success(let callbackParameters):
                    eventDetail["parameters"] = callbackParameters ?? [:]
                }
                let eventBody: [String: Any] = ["detail": eventDetail]
                let jsString: String
                if let _data = try? JSONSerialization.data(withJSONObject: eventBody, options: JSONSerialization.WritingOptions()), let eventString = String(data: _data, encoding: .utf8) {
                    jsString = "(function() { var event = new CustomEvent('PacificDidReceiveLocalCallback', \(eventString)); document.dispatchEvent(event)}());"
                } else {
                    // 这块代码是为了兼容 有一部分不能被序列化的字段
                    switch results {
                    case .success(_):
                        jsString = "(function() { var event = new CustomEvent('PacificDidReceiveLocalCallback', {'detail': {'parameters': {}}}); document.dispatchEvent(event)}());"
                    case .failure(let error):
                        jsString = "(function() { var event = new CustomEvent('PacificDidReceiveLocalCallback', {'detail': {'error': {'code': \(error.code), 'description': '\(error.description)'}}}); document.dispatchEvent(event)}());"
                    }
                }
                webView.evaluateJavaScript(jsString, completionHandler: nil)
            }
        } else {
            handler(body[MessageKey.parameters] as? [String: Any]) { (results) in
                // Do Nothing
            }
        }
    }
}

public extension WKWebView {
    
    private struct STPrivateStatic {
        fileprivate static var bridgeKey = "STPrivateStatic.bridgeKey"
    }
    
    public var bridge: Bridge {
        if let bridge = objc_getAssociatedObject(self, &STPrivateStatic.bridgeKey) as? Bridge {
            return bridge
        }
        let bridge = Bridge(webView: self)
        objc_setAssociatedObject(self, &STPrivateStatic.bridgeKey, bridge, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return bridge
    }
}
