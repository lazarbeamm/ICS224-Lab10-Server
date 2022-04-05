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
    private var maxRowOrCol = 9
    
    var body: some View {
        VStack {
            if !advertising {
                Button("Start") {
                    networkSupport.nearbyServiceAdvertiser?.startAdvertisingPeer()
                    advertising.toggle()
                    // Once Server has started, determine treasure locations
                    for _ in 0...4{
                        var randomRow = Int.random(in: 0...maxRowOrCol)
                        var randomCol = Int.random(in: 0...maxRowOrCol)
//                        print("Random Row: ", randomRow)
//                        print("Random Col: ", randomCol)
                        board[randomRow, randomCol] = "Treasure"
                    }
                    print(board.tiles[0][0].item)
                    print(board.tiles[0][1].item)
                    print(board.tiles[0][2].item)
                    print(board.tiles[0][3].item)
                    print(board.tiles[0][4].item)
                    print(board.tiles[0][5].item)
                    print(board.tiles[0][6].item)
                    print(board.tiles[0][7].item)
                    print(board.tiles[0][8].item)
                    print(board.tiles[0][9].item)
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
            
            // Extract the row and column chosen by the client (a char representing the row/column, respectively)
            var chosenRow = Array(newValue)[0]
            var chosenColumn = Array(newValue)[2]
            
            // Convert those extracted values to Int instead of char
            // If conversion fails the result will be nil
            var chosenRowInt = chosenRow.wholeNumberValue
            var chosenColumnInt = chosenColumn.wholeNumberValue
            
            // Check the Board object to determine if the position chosen contains treasure or not
            if (board.tiles[chosenRowInt!][chosenColumnInt!].item != nil){
                print("Found Treasure!")
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
