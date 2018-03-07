//  Copyright © 2018 Apple Inc. All rights reserved.
//
//  Use of this source code is governed by a BSD-3-clause license that can
//  be found in the LICENSE.txt file or at https://opensource.org/licenses/BSD-3-Clause

import WebKit

class ViewController: NSViewController, NSWindowDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    // load view
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create graph object
        SharedData.shared.webContainer = WebContainer(view: webView)
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
        self.view.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    func windowShouldClose(_ sender: Any) -> Bool {
        // Wait until status is updated on the client side before closing the application
        SharedData.shared.webContainer?.termination{ error in
            if error != nil {
                print("Oops! Something went wrong...")
            } else {
                NSApplication.shared().terminate(self);
            }
        }
        return true
    }

}



