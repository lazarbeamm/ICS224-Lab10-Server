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
    @State var board = Board()
    // The total number of treasures to be found. Once this value == 0, the game ends
    @State var treasureRemaining = 5
    // The maximum value a row or column will contain (our grid is 0-9, so (9,9) is the greatest value we can expect)
    private var maxRowOrCol = 9
    // Create layout for LazyGrid to adhere to (in this case, a 10 x 10 grid)
    private var gridLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            if !advertising {
                Button("Start") {
                    networkSupport.nearbyServiceAdvertiser?.startAdvertisingPeer()
                    advertising.toggle()
                    // Once Server has started, determine treasure locations
                    for _ in 0...4{
                        let randomRow = Int.random(in: 0...maxRowOrCol)
                        let randomCol = Int.random(in: 0...maxRowOrCol)
                        board[randomRow, randomCol] = "Treasure"
                    }
//                    print(board.tiles[0][0].item)
//                    print(board.tiles[0][1].item)
//                    print(board.tiles[0][2].item)
//                    print(board.tiles[0][3].item)
//                    print(board.tiles[0][4].item)
//                    print(board.tiles[0][5].item)
//                    print(board.tiles[0][6].item)
//                    print(board.tiles[0][7].item)
//                    print(board.tiles[0][8].item)
//                    print(board.tiles[0][9].item)
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
                
                // Display Gameboard
                LazyVGrid(columns: gridLayout, spacing: 10){
                    ForEach((0...9), id: \.self) { row in
                        ForEach((0...9), id: \.self) { col in
                            Button("?", action: {
                                // When Player Presses Button (A tile on the grid), transmit info to server
                                networkSupport.send(message: String("\(row),\(col)"))
                            })
                        }
                    }
                }//end of LazyVGrid
                
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
            
            // TO DO
                // IF newValue is an update of the client's grid (gameboard)
                    // Update the servers gameboard
                // IF newValue us a coordinate on the grid (execute the code below - No changes required)
            
            // Extract the row and column chosen by the client (a char representing the row/column, respectively)
            let chosenRow = Array(newValue)[0]
            let chosenColumn = Array(newValue)[2]
            
            // Convert those extracted values to Int instead of char
            // If conversion fails the result will be nil
            let chosenRowInt = chosenRow.wholeNumberValue
            let chosenColumnInt = chosenColumn.wholeNumberValue
            
            // Check the Board object to determine if the position chosen contains treasure or not
            // The chosen row & column and being forced to unwrap - may lead to problems later (if somehow some other data is sent)
            if (board.tiles[chosenRowInt!][chosenColumnInt!].item != nil){
                print("Found Treasure!")
                // TO DO
                    // Update the player that found the treasures score
                    // Decrement the total treasure remaining (once treasureRemaining == 0, game ends)
                    treasureRemaining -= 1
            } else {
                print("No treasure")
            }
        }
    }
}//end of ContentView

class Tile {
    var item: String?
    
    init(item: String?){
        self.item = item
    }
    
    deinit{
        print("Deinitializing Tile")
    }
}

class Board {
    let boardSize = 10
    // declare an array of tiles caled tiles
    var tiles: [[Tile]]
    
    init(){
        // create the tiles array
        tiles = [[Tile]]()
        
        for _ in 1...boardSize{
            var tileRow = [Tile]()
            for _ in 1...boardSize{
                tileRow.append(Tile(item: nil))
            }
            tiles.append(tileRow)
        }
    }
    
    deinit{
        print("Deinitializing Board")
    }
    
    subscript(row: Int, column: Int) -> String? {
        get {
            if(row < 0) || (boardSize <= row) || (column < 0) || (boardSize <= column){
                return nil
            } else {
                return tiles[row][column].item
            }
        }
        set {
            if(row < 0) || (boardSize <= row) || (column < 0) || (boardSize <= column){
                return
            } else {
                tiles[row][column].item = newValue
            }
        }
    }//end of subscript helper
    
}//end of Board class
