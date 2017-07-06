//
//  ViewController.swift
//  WKBridge
//
//  Created by lovesunstar@sina.com on 05/27/2017.
//  Copyright (c) 2017 lovesunstar@sina.com. All rights reserved.
//

import UIKit
import WebKit
import WKBridge

class ViewController: UIViewController {
    
    var isLogin = false
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        
        return webView
    }()
    
    deinit {
        webView.removeBridge()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        webView.frame = self.view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(webView)
        
        if let url = Bundle.main.url(forResource: "test", withExtension: "html") {
            webView.load(URLRequest(url: url))
        }
        webView.bridge.printScriptMessageAutomatically = true
        webView.bridge.register({ (parameters, completion) in
            let error = Bridge.JSError(code: -1001, description: "Some Failed Reason")
            completion(.failure(error))
        }, for: "test_error")
        
        webView.bridge.register({ (parameters, completion) in
            completion(.success(["status": 0]))
        }, for: "test_success")
        
        webView.bridge.register({ (parameters, completion) in
            print("print - ", parameters?["message"] ?? "")
        }, for: "print")
        
        webView.bridge.register({ [weak self] (parameters, _) in
            guard let strongSelf = self, let parameters = parameters else { return }
            strongSelf.alert(with: parameters["title"] as? String, message: parameters["message"] as? String)
        }, for: "alert")
        
        updateLoginStatus()
    }
    
    private func updateLoginStatus() {
        if isLogin {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(handleLogout(_:)))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(handleLogin(_:)))
        }
        isLogin = !isLogin
    }

    private func alert(with title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func handleLogin(_ sender: Any) {
        webView.bridge.post(action: "login", parameters: nil)
        updateLoginStatus()
    }
    
    @objc private func handleLogout(_ sender: Any) {
        webView.bridge.post(action: "logout", parameters: nil)
        updateLoginStatus()
    }
}

