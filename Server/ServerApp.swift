//
//  ServerApp.swift
//  Server
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI

@main
struct ServerApp: App {
    @StateObject var board = Board()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(board)
        }
    }
}
