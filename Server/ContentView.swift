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
    // successful message increment
    @State var messageNonce = 0
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
                        board[randomRow, randomCol] = "Treasure"
                        print("\(randomRow),\(randomCol)")
                    }
                }
            }
            else {
                Text(networkSupport.incomingMessage)
                    .padding()
                
                if networkSupport.connected && networkSupport.peers.count == 2{

                    LazyVGrid(columns: gridLayout, spacing: 10){
                        
                        ForEach(board.tiles, id: \.self) { row in
                            ForEach(row) { cell in
                                    
                                if (cell.guessed == false){
                                    Button(action: { // not yet guessed
                                    }){
                                        Image(systemName: "circle")
                                    }
                                } else if (cell.guessed == true && cell.item == "Treasure"){
                                    Button(action: { // treasure
                                    }){
                                        Image(systemName: "trash")
                                    }
                                } else if (cell.guessed == true && cell.item == nil){
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
                    networkSupport.send(message: "\(String(describing: networkSupport.peers.first)) WINS!!!")
                }
                // If last player's score is higher
                else if lastScore > firstScore {
                    networkSupport.send(message: "\(String(describing: networkSupport.peers.last)) WINS!!")
                }
                else {
                    networkSupport.send(message: "HOW DID YOU BREAK THIS?!?!?!\nARE THERE EVEN NUMBER OF TREASURES!??!?!")
                }
                // Had an idea of a game restart
            }
            // When two players have connected...
            if(networkSupport.peers.count == 2){
                // first players turn
                if firstTurn && (networkSupport.incomingPeer == networkSupport.peers.first){
                    // Extract the row and column chosen by the client (a char representing the row/column, respectively)
                    let chosenRow = Array(newValue)[0]
                    let chosenColumn = Array(newValue)[2]
                    
                    // Convert those extracted values to Int instead of char
                    // If conversion fails the result will be nil
                    let chosenRowInt = chosenRow.wholeNumberValue
                    let chosenColumnInt = chosenColumn.wholeNumberValue
                    
                    // Telling client its their turn
                    networkSupport.send(message: "Your turn.", first: "f")
                    if board.tiles[chosenRowInt!][chosenColumnInt!].item != nil && board.tiles[chosenRowInt!][chosenColumnInt!].guessed == false{
                        networkSupport.send(message: "Found Treasure! \(messageNonce)")
                        // Update score
                        firstScore += 1
                        // Send score update out to all clients
                        networkSupport.send(message: "\(String(describing: networkSupport.peers.first))'s Score: \(lastScore)\n\(String(describing: networkSupport.peers.last))'s Score: \(firstScore)")
                        // Set the tile to found
                        board.tiles[chosenRowInt!][chosenColumnInt!].guessed = true
                        // Decrement the total treasure remaining (once treasureRemaining == 0, game ends)
                        treasureRemaining -= 1
                        // Change turns and increment message
                        firstTurn = false
                        lastTurn = true
                        messageNonce += 1
                    } else if board.tiles[chosenRowInt!][chosenColumnInt!].item == nil && board.tiles[chosenRowInt!][chosenColumnInt!].guessed == false{
                        networkSupport.send(message: "No Treasure \(messageNonce)")
                        // Change turns and increment message
                        firstTurn = false
                        lastTurn = true
                        messageNonce += 1
                    }
                } else if lastTurn && (networkSupport.incomingPeer == networkSupport.peers.last){
                    // Extract the row and column chosen by the client (a char representing the row/column, respectively)
                    let chosenRow = Array(newValue)[0]
                    let chosenColumn = Array(newValue)[2]
                    
                    // Convert those extracted values to Int instead of char
                    // If conversion fails the result will be nil
                    let chosenRowInt = chosenRow.wholeNumberValue
                    let chosenColumnInt = chosenColumn.wholeNumberValue
                    // Telling client its their turn
                    networkSupport.send(message: "Your turn.", last: "l")
                    if board.tiles[chosenRowInt!][chosenColumnInt!].item != nil && board.tiles[chosenRowInt!][chosenColumnInt!].guessed == false{
                        networkSupport.send(message: "Found Treasure! \(messageNonce)")
                        lastScore += 1
                        // Send score update out to all clients
                        networkSupport.send(message: "\(String(describing: networkSupport.peers.first))'s Score: \(lastScore)\n\(String(describing: networkSupport.peers.last))'s Score: \(firstScore)")
                        // Update the player that found the treasures score
                        // Decrement the total treasure remaining (once treasureRemaining == 0, game ends)
                        treasureRemaining -= 1
                        // Change turns and increment message
                        firstTurn = false
                        lastTurn = true
                        messageNonce += 1
                    } else if board.tiles[chosenRowInt!][chosenColumnInt!].item == nil && board.tiles[chosenRowInt!][chosenColumnInt!].guessed == false{
                        networkSupport.send(message: "No Treasure \(messageNonce)")
                        // Change turns and increment message
                        firstTurn = false
                        lastTurn = true
                        messageNonce += 1
                    }
                }
            }
        }
    }
}//end of ContentView

struct Tile: Identifiable, Hashable {
    static func == (lhs: Tile, rhs: Tile) -> Bool {
        return  lhs.id == rhs.id
    }
    
    let id = UUID()
    var item: String?
    var rowNumber: Int
    var colNumber: Int
    var guessed: Bool
    
    init(item: String?, rowNumber: Int, colNumber: Int){
        self.item = item
        self.rowNumber = rowNumber
        self.colNumber = colNumber
        self.guessed = false
    }
    
//    deinit{
//        print("Deinitializing Tile")
//    }
}

class Board: ObservableObject {
    let boardSize = 10
    // declare an array of tiles caled tiles
    @Published var tiles: [[Tile]]
    
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

