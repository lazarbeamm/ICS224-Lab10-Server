//
//  NetworkSupport.swift
//  Server
//
//  Created by Michael on 2022-02-24.
//

import Foundation
import MultipeerConnectivity

let serviceType = "lab10"

struct Request: Codable {
    var details: String
}

class NetworkSupport: NSObject, ObservableObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    var peerID: MCPeerID
    var session: MCSession
    var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    var nearbyServiceBrowser: MCNearbyServiceBrowser?
    
    @Published var peers: [MCPeerID] = [MCPeerID]()
    @Published var connected = false
    @Published var incomingMessage = ""
    
    init(browse: Bool) {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        if !browse {
            nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        }
        else {
            nearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        }
        
        super.init()
        
        session.delegate = self
        nearbyServiceAdvertiser?.delegate = self
        nearbyServiceBrowser?.delegate = self
        
        if browse {
            nearbyServiceBrowser?.startBrowsingForPeers()
        }
    }
    
    // MARK: -
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer", error)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        do {
            let request = try JSONDecoder().decode(Request.self, from: context ?? Data())
            print("didReceiveInvitationFromPeer", peerID, request)
            invitationHandler(true, self.session)
        }
        catch let error {
            print("didReceiveInvitationFromPeer", error)
        }
    }
    
    // MARK: -
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers", error)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer", peerID, info ?? "")
        if !peers.contains(peerID) {
            peers.append(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer", peerID, terminator: " ")
        guard let index = peers.firstIndex(of: peerID) else {
            print("NOT FOUND")
            return
        }
        peers.remove(at: index)
        print("removed")
    }
    
    // MARK: -
    
    func contactPeer(peerID: MCPeerID, request: Request) throws {
        print("contactPeer", peerID, request)
        let request = try JSONEncoder().encode(request)
        nearbyServiceBrowser?.invitePeer(peerID, to: session, withContext: request, timeout: TimeInterval(120))
    }
    
    // MARK: -
    
    func session(_ session: MCSession, didReceive: Data, fromPeer: MCPeerID) {
        do {
            let request = try JSONDecoder().decode(String.self, from: didReceive)
            print("didReceive", request, fromPeer)
            DispatchQueue.main.async {
                self.incomingMessage = request
            }
        }
        catch let error {
            print("didReceive", error)
        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {
        print("didStartReceivingResourceWithName", didStartReceivingResourceWithName, fromPeer, with)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {
        print("didFinishReceivingResourceWithName", didFinishReceivingResourceWithName, fromPeer, at ?? "", withError ?? "")
    }
    
    func session(_ session: MCSession, didReceive: InputStream, withName: String, fromPeer: MCPeerID) {
        print("didReceive:withName", didReceive, withName, fromPeer)
    }
    
    func session(_ session: MCSession, peer: MCPeerID, didChange: MCSessionState) {
        switch didChange {
        case .notConnected:
            print("didChange notConnected", peer)
            DispatchQueue.main.async {
                self.connected = false
            }
        case .connecting:
            print("didChange connecting", peer)
            DispatchQueue.main.async {
                self.connected = false
            }
        case .connected:
            print("didChange connected", peer)
            DispatchQueue.main.async {
                self.connected = true
            }
        default:
            print("didChange", peer)
            DispatchQueue.main.async {
                self.connected = false
            }
        }
    }
    
    func session(_ session: MCSession, didReceiveCertificate: [Any]?, fromPeer: MCPeerID, certificateHandler: (Bool) -> Void) {
        print("didReceiveCertificate", didReceiveCertificate ?? "", fromPeer)
        certificateHandler(true)
    }
    
    // MARK: -
    
    func send(message: String) {
        print("send", message)
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: peers, with: .reliable)
        }
        catch let error {
            print(error)
        }
    }
    
    // MARK: -
    deinit {
        print("deinit")
        nearbyServiceBrowser?.stopBrowsingForPeers()
    }
}
