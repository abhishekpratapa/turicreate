//  Copyright © 2018 Apple Inc. All rights reserved.
//
//  Use of this source code is governed by a BSD-3-clause license that can
//  be found in the LICENSE.txt file or at https://opensource.org/licenses/BSD-3-Clause
import Foundation


class Pipe {
    private var graph_data: WebContainer
    
    init(graph_data:WebContainer){
        self.graph_data = graph_data
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.readPipe();
        }
        
    }
    
    public func readPipe(){
        
        while (true) {
            guard let data = readLine() else {
                break
            }

            if data == "" {
                continue
            }
            
            debug_log("Processing input: ")
            debug_log(data)
            process_data(data: data)
        }
    }
    
    public func sendData(data:String){
        print(data)
        fflush(__stdoutp)
    }
    
    private func process_data(data: String) {
        self.graph_data.loadImage(data: data)
    }
}
