//  Copyright © 2018 Apple Inc. All rights reserved.
//
//  Use of this source code is governed by a BSD-3-clause license that can
//  be found in the LICENSE.txt file or at https://opensource.org/licenses/BSD-3-Clause

import WebKit

func log(_ message: String) {
    let withNewline = String(format: "%@\n", message)
    guard let data = withNewline.data(using: .utf8) else {
        assert(false)
        return
    }
    FileHandle.standardError.write(data)
    fflush(__stderrp)
}

func debug_log(_ message: String) {
    if let _ = ProcessInfo.processInfo.environment["TC_VISUALIZATION_CLIENT_ENABLE_DEBUG_LOGGING"] {
        log("DEBUG: " + message + "\n")
    }
}

class WebContainer: NSObject, WKScriptMessageHandler {
    
    public var view: WKWebView
    public var pipe: Pipe?
    private var loaded: Bool = false
    private var ready: Bool = false
    
    init(view: WKWebView) {
        
        self.view = view;
        self.pipe = nil
        
        super.init()
        
        self.pipe = Pipe(graph_data: self)
        
        let appBundle = Bundle.main
        let htmlPath = appBundle.url(forResource: "index", withExtension: "html")
        self.view.loadFileURL(htmlPath!, allowingReadAccessTo: appBundle.bundleURL)
        self.view.configuration.userContentController.add(self, name: "scriptHandler")
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let messageBody = message.body as? [String: Any] else {
            assert(false)
            return
        }
        guard let status = messageBody["status"] as? String else {
            assert(false)
            return
        }
        
        switch status {
            
        case "loaded":
            self.loaded = true
            self.pipe?.sendData(data: "{\"loaded\": true}")
            break
            
        case "ready":
            debug_log("got ready event")
            self.ready = true
            break
        
        case "log":
            guard let level = messageBody["level"] as? String else {
                assert(false)
                return
            }
            guard let logMessage = messageBody["message"] as? String else {
                assert(false)
                return
            }
            switch level {
            case "debug":
                #if DEBUG
                log(logMessage)
                #endif
                break
                
            case "log": fallthrough
            case "info": fallthrough
            case "warn":
                log(logMessage)
                break
                
            case "error":
                log(logMessage)
                assert(false, "Encountered an unhandled JavaScript error.")
                break
                
            default:
                log(logMessage)
                assert(false, "Unexpected log level specified.")
                break;
            }
            break
            
        case "print_message":
            guard let logMessage = messageBody["message"] as? String else {
                assert(false, "Expected a message provided in print_message")
                return
            }
            
            log(logMessage)
            break;
            
        case "getrows":
            guard let index_num = messageBody["index"] as? Int else {
                assert(false, "Expected index in getrows")
                return
            }
            
            self.pipe?.sendData(data: "{\"get\": "+String(index_num)+"}")
            break
            
        case "sendrows":
            guard let index_num = messageBody["index"] as? Int else {
                assert(false, "Expected 'index' in sendrows")
                return
            }
            
            guard let annotationDict = messageBody["annotations"] as? String else {
                assert(false, "Expected 'annotationDict' in sendrows")
                return
            }
            
            self.pipe?.sendData(data: "{\"set\": {\"index\":"+String(index_num)+", \"annotations\":"+annotationDict+"}}")
            
        default:
            assert(false)
            break
        }
    }
    
    public func loadImage(data: String){
        DispatchQueue.main.async {
            let updateJS = String(format: "window.displayImage(%@);", data)
            
            self.view.evaluateJavaScript(updateJS, completionHandler: {(value, err) in
                
                if err != nil {
                    // if we got here, we got a JS error
                    log(err.debugDescription)
                }
                
                debug_log("successfully sent data spec to JS")
            });
        }
    }
    
    public func termination(completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            self.view.evaluateJavaScript("window.terminationApplication();", completionHandler: {(value, err) in
                if err != nil {
                    // if we got here, we got a JS error
                    log(err.debugDescription)
                }
                
                debug_log("successfully sent annotations to Python")
                completion(nil)
            });
        }
    }
}
