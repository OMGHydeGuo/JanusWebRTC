//
//  WebRTCOperator.swift
//  
//
//  Created by Hydeguo on 03/02/2018.
//  Copyright © 2018 Hydeguo. All rights reserved.
//

import Foundation
import WebRTC

public class  WebRTCOperator: RTCClientDelegate {
    
    
    var delegate:OMGRTCClientDelegate
    var omgSocket:OMGRTCServerDelegate
    var delegateArr:[String:OMGRTCClientDelegate] = [String:OMGRTCClientDelegate]()
    var omgSocketArr:[String:OMGRTCServerDelegate] = [String:OMGRTCServerDelegate]()
    
    
    // TODO  moew socket , move logic from OMPoperater
    public init(delegate:OMGRTCClientDelegate,omgSocket:OMGRTCServerDelegate) {
        self.delegate = delegate
        self.omgSocket = omgSocket
    }
    
    func addUnitServer(_ id:String,omgSocket:OMGRTCServerDelegate)
    {
        self.omgSocketArr[id] = omgSocket
    }
    func addUnitDelegate(_ id:String,delegate:OMGRTCClientDelegate)
    {
        self.delegateArr[id] = delegate
    }
    
     func getServer(_ id:String) -> OMGRTCServerDelegate {
        if let _server = self.omgSocketArr[id] {
            return _server
        }
        return omgSocket
    }
    
    public func disconnectAll()
    {
        for server in omgSocketArr {
            server.value.disconnectMeeting()
        }
        omgSocket.disconnectMeeting()
    }
    
     func getDelegate(_ id:String) -> OMGRTCClientDelegate {
        if let _delegate = self.delegateArr[id] {
            return _delegate
        }
        return delegate
    }
    
    public func rtcClient(_ id:String ,client: RTCClient, didChangeConnectionState connectionState: RTCIceConnectionState) {
        getDelegate(id).rtcClient(id, didChangeConnectionState: connectionState)
    }
    
    
    public func rtcClient(_ id : String,client : RTCClient, didReceiveError error: Error) {
        // Error Received
        getDelegate(id).rtcClient(id, didReceiveError: error)
    }
    
    public func rtcClient(_ id:String ,client : RTCClient, didGenerateIceCandidate iceCandidate: RTCIceCandidate) {
        // iceCandidate generated, pass this to other user using any signal method your app uses

        let cData = CandidateData(sdpMid: iceCandidate.sdpMid!, lineIndex: Int(iceCandidate.sdpMLineIndex), candidate: iceCandidate.sdp)
        let myServer = getServer(id)
        let handle_id = myServer.getHandIdForJanusId(id: id)
        myServer.sendCommand(command: SendCandidateCommand(delegate: myServer as! RTCVideoServer, handleId: handle_id, data: cData))
    }
    
    public func rtcClient(_ id : String,client: RTCClient, startCallWithSdp sdp: RTCSessionDescription) {
        // SDP generated, pass this to other user using any signal method your app uses
        if sdp.type == .offer
        {
            let jData = JsepData(type: "offer", sdp: sdp.sdp)
            let myServer = getServer(id)
            let handle_id = myServer.getHandIdForJanusId(id: id)
            myServer.sendCommand(command: SendOfferCommand(delegate: myServer as! RTCVideoServer, handleId: handle_id, data: jData))
        }
        else
        {
            let jData = JsepData(type: "answer", sdp: sdp.sdp)
            let myServer = getServer(id)
            let handle_id = myServer.getHandIdForJanusId(id: id)
            myServer.sendCommand(command: SendAnswerCommand(delegate: myServer as! RTCVideoServer, handleId: handle_id, data: jData))
        }
        
    }
    
    public func rtcClient(_ id : String,client : RTCClient, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack) {
        // Use localVideoTrack generated for rendering stream to remoteVideoView
        getDelegate(id).rtcClient(id, didReceiveLocalVideoTrack: localVideoTrack)
        
    }
    public func rtcClient(_ id : String,client : RTCClient, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack) {
        // Use remoteVideoTrack generated for rendering stream to remoteVideoView
        getDelegate(id).rtcClient(id, didReceiveRemoteVideoTrack: remoteVideoTrack)
    }
    
    
    private func returnJsonStr(data : [String : Any])->String
    {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data,
                                                      options: .prettyPrinted)
            return (String(data: jsonData, encoding: String.Encoding.utf8))!
        } catch let error {
            print("error converting to json: \(error)")
            return ""
        }
    }
}

public protocol OMGRTCServerDelegate: class {
    func sendCommand(command:BaseCommand)
    func getHandIdForJanusId(id:String)->Int
    func getJanusIdFromHandId(id:Int)->String
    func disconnectMeeting()
}

public protocol OMGRTCClientDelegate: class {
    func rtcClient(_ id : String, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack)
    func rtcClient(_ id : String, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack)
    func rtcClient(_ id : String, didReceiveError error: Error)
    func rtcClient(_ id : String, didChangeConnectionState connectionState: RTCIceConnectionState)
    
}

