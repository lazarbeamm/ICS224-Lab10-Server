//
//  ContentView.swift
//  Server
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @EnvironmentObject var board: Board
    @State var firstTurn = true
    @State var lastTurn = false
    @State var advertising = false
    @StateObject var networkSupport = NetworkSupport(browse: false)
    @State var firstScore = 0
    @State var lastScore = 0
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
                        if board[randomRow, randomCol] != "Treasure" {
                            board[randomRow, randomCol] = "Treasure"
                        } else {
                            let randomRow = Int.random(in: 0...maxRowOrCol)
                            let randomCol = Int.random(in: 0...maxRowOrCol)
                            board[randomRow, randomCol] = "Treasure"
                        }
                        print("\(randomRow),\(randomCol)")
                    }
                }
            }
            else {
                Text(networkSupport.incomingMessage)
                    .padding()
                
                if networkSupport.peers.count == 2{

                    LazyVGrid(columns: gridLayout, spacing: 10){
                        
                        ForEach(0..<board.tiles.count, id: \.self) { x in
                            ForEach(0..<board.tiles.count) { y in
                                    
                                if (board.tiles[x][y].guessed == false){
                                    Button(action: { // not yet guessed
                                    }){
                                        Image(systemName: "circle")
                                    }
                                } else if (board.tiles[x][y].guessed == true && board.tiles[x][y].item == "Treasure"){
                                    Button(action: { // treasure
                                    }){
                                        Image(systemName: "trash")
                                    }
                                } else if (board.tiles[x][y].guessed == true && board.tiles[x][y].item == nil){
                                    Button(action: { // guessed, no treasure
                                    }){
                                        Image(systemName: "circle.fill")
                                    }
                                }
                            }
                        }
                        }
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
            // If no treasures remain...
            if treasureRemaining == 0 {
                // If first player's score is higher...
                if firstScore > lastScore {
                    networkSupport.send(message: "Player First WINS!!!")
                }
                // If last player's score is higher
                else if lastScore > firstScore {
                    networkSupport.send(message: "Player Last WINS!!")
                }
                else {
                    networkSupport.send(message: "HOW DID YOU BREAK THIS?!?!?!\nARE THERE EVEN NUMBER OF TREASURES!??!?!")
                }
                // Had an idea of a game restart
            }
            // When two players have connected...
            if(networkSupport.peers.count == 2){
                // Telling client its their turn
                networkSupport.send(message: "First Player's turn.", first: "f")
                if firstTurn && (networkSupport.incomingPeer == networkSupport.peers.first){
                    
                    // Extract the row and column chosen by the client (a char representing the row/column, respectively)
                    let chosenRow = Array(newValue)[0]
                    let chosenColumn = Array(newValue)[2]
                    
                    // Convert those extracted values to Int instead of char
                    // If conversion fails the result will be nil
                    let chosenRowInt = chosenRow.wholeNumberValue
                    let chosenColumnInt = chosenColumn.wholeNumberValue
                    if board.tiles[chosenRowInt!][chosenColumnInt!].item != nil && board.tiles[chosenRowInt!][chosenColumnInt!].guessed == false{
                        firstScore += 1
                        networkSupport.send(message: "Found Treasure at [\(chosenRowInt),\(chosenColumnInt)], [\(firstScore), \(lastScore)]")
                        // Update score
                        
                        // Send score update out to all clients
                        //networkSupport.send(message: "First Player's Score: \(firstScore)\nLast Player's Score: \(lastScore)")
                        // Decrement the total treasure remaining (once treasureRemaining == 0, game ends)
                        treasureRemaining -= 1
                        // Change turns and increment message
                        firstTurn = false
                        lastTurn = true
                        //networkSupport.send(message: "Scores: \(firstScore), \(lastScore)")
                    } else if board.tiles[chosenRowInt!][chosenColumnInt!].item == nil && board.tiles[chosenRowInt!][chosenColumnInt!].guessed == false{
                        networkSupport.send(message: "No Treasure at [\(chosenRowInt),\(chosenColumnInt)]")
                        // Change turns and increment message
                        firstTurn = false
                        lastTurn = true
                    }
                    // Set the tile to found
                    board.tiles[chosenRowInt!][chosenColumnInt!].guessed = true
                    // Telling client its their turn
                    //networkSupport.send(message: "Last Player's turn.", last: "l")
                } else if lastTurn && (networkSupport.incomingPeer == networkSupport.peers.last){
                    
                    // Extract the row and column chosen by the client (a char representing the row/column, respectively)
                    let chosenRow = Array(newValue)[0]
                    let chosenColumn = Array(newValue)[2]
                    
                    // Convert those extracted values to Int instead of char
                    // If conversion fails the result will be nil
                    let chosenRowInt = chosenRow.wholeNumberValue
                    let chosenColumnInt = chosenColumn.wholeNumberValue
                    if board.tiles[chosenRowInt!][chosenColumnInt!].item != nil && board.tiles[chosenRowInt!][chosenColumnInt!].guessed == false{
                        lastScore += 1
                        networkSupport.send(message: "Found Treasure at [\(chosenRowInt),\(chosenColumnInt)], [\(firstScore), \(lastScore)]")
                        
                        // Send score update out to all clients
                        //networkSupport.send(message: "First Player's Score: \(firstScore)\nLast Player's Score: \(lastScore)")
                        // Update the player that found the treasures score
                        // Decrement the total treasure remaining (once treasureRemaining == 0, game ends)
                        treasureRemaining -= 1
                        // Change turns and increment message
                        firstTurn = true
                        lastTurn = false
                        //networkSupport.send(message: "Scores: \(firstScore), \(lastScore)")
                    } else if board.tiles[chosenRowInt!][chosenColumnInt!].item == nil && board.tiles[chosenRowInt!][chosenColumnInt!].guessed == false{
                        networkSupport.send(message: "No Treasure at [\(chosenRowInt),\(chosenColumnInt)]")
                        // Change turns and increment message
                        firstTurn = true
                        lastTurn = false
                    }
                    // Set the tile to found
                    board.tiles[chosenRowInt!][chosenColumnInt!].guessed = true
                    
                }
            }
        }
    }
}//end of ContentView

/// Defines the structure for the Tile object, which is used by the Board class to instantiate a gameboard
struct Tile: Identifiable, Hashable {
    
//    static func == (lhs: Tile, rhs: Tile) -> Bool {
//        return  lhs.id == rhs.id
//    }
    
    /// A unique identifier for each tile
    let id = UUID()
    /// The contents of a given tile. May be nil (empty), "Guessed" or "Treasure"
    var item: String?
    /// A reference to the row position the tile occupies on the gameboard
    var rowNumber: Int
    /// A reference to the column position the tile occupies on the gameboard
    var colNumber: Int
    /// A boolean representing whether or not the tile has been guessed yet
    var guessed: Bool
    
    
    /// The default initializer for a tile object
    /// - Parameters:
    ///   - item: The string representation of what a given tile contains (nil, guessed, or treasure)
    ///   - rowNumber: An integer representing the row position the tile occupies
    ///   - colNumber: An integer representing the column position the tile occupies
    init(item: String?, rowNumber: Int, colNumber: Int){
        self.item = item
        self.rowNumber = rowNumber
        self.colNumber = colNumber
        self.guessed = false
    }
}

/// This class is used behind the scenes to represent the state of the game, in the form of an array of tile objects called tiles
/// The board class is instantated once during startup, and initially each tile in the array is empy (nil)
/// As players take turns guessing, the board is updated to reflect whether or not a tile has been guessed and is empty, or has been guessed and contained treasure
class Board: ObservableObject {
    /// The size of a board object (in this case, 10 x 10)
    let boardSize = 10
    /// An array of tile objects, used to store information about the gamestate
    @Published var tiles: [[Tile]]
    
    /// The default initializer for the Board object
    init(){
        // create the tiles array
        tiles = [[Tile]]()
        
        for i in 0..<boardSize{
            var tileRow = [Tile]()
            for j in 0..<boardSize{
                tileRow.append(Tile(item: nil, rowNumber: i, colNumber: j))
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

