//
//  GridTapScratchApp.swift
//  GridTapScratch
//
//  Created by Nicholas Richards on 2/27/22.
//

import SwiftUI

@main
struct GridTapScratchApp: App {
    @StateObject public var h = Haptic()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
