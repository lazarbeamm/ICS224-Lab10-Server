//
//  ServerApp.swift
//  Server
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI

@main
struct ServerApp: App {
    // An instantiation of the Board object, which stores the information pertaining to each of the 100 gameboard tiles
    @StateObject var board = Board()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(board)
        }
    }
}
