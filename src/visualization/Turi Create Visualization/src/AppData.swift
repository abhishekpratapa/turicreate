//  Copyright © 2017 Apple Inc. All rights reserved.
//
//  Use of this source code is governed by a BSD-3-clause license that can
//  be found in the LICENSE.txt file or at https://opensource.org/licenses/BSD-3-Clause
import Foundation
import Cocoa

final class SharedData {
    static let shared = SharedData() //lazy init, and it only runs once
    
    // Application Objects
    var vegaContainer: VegaContainer? = nil;
    var save_image:NSMenuItem? = nil;
    var save_vega:NSMenuItem? = nil;
    var print_vega:NSMenuItem? = nil;
    var page_setup:NSMenuItem? = nil;
}
