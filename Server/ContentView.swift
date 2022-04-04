//
//  ContentView.swift
//  Server
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI

struct ContentView: View {
    @State var advertising = false
    @StateObject var networkSupport = NetworkSupport(browse: false)
    
    var body: some View {
        VStack {
            if !advertising {
                Button("Start") {
                    networkSupport.nearbyServiceAdvertiser?.startAdvertisingPeer()
                    advertising.toggle()
                    // Add Treasure to board
                    board[0,0] = "Treasure"
                    board[0,1] = "Treasure"
                    board[0,2] = "Treasure"
                    board[0,3] = "Treasure"
                    board[0,4] = "Treasure"
                }
            }
            else {
                Text(networkSupport.incomingMessage)
                    .padding()
                
                if networkSupport.connected {
                    Button("Reply") {
                        networkSupport.send(message: "Thank you for: " + networkSupport.incomingMessage)
                    }
                    .padding()
                }
                
                Button("Stop") {
                    networkSupport.nearbyServiceAdvertiser?.stopAdvertisingPeer()
                    advertising.toggle()
                }
                .padding()
            }
        }
        .padding()
        .onChange(of: networkSupport.incomingMessage){ newValue in
            // Handle incoming message here
            // This could be request for board state, or a move request (col, row)
            // If the same incomingMessage is sent twice, this will not trigger a second time (only called on change)
        }
    }
}//end of ContentView
