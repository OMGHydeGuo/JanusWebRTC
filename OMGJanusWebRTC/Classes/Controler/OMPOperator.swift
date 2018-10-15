//
//  RTCForOMP.swift
//  
//
//  Created by Hydeguo on 29/01/2018.
//  Copyright © 2018 Hydeguo. All rights reserved.
//

import Foundation
import WebRTC



class RTCForOMPLog:OMGRTCClientDelegate
{
    func rtcClient(_ id:String, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack) {
        
    }
    
     func rtcClient(_ id:String, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack) {
        print("[RTCForOMP didReceive RemoteVideo Track..]")
    }
    
     func rtcClient(_ id:String, didReceiveError error: Error) {
        print("[RTCForOMP Error]:\(error)")
    }
    
     func rtcClient(_ id:String, didChangeConnectionState connectionState: RTCIceConnectionState) {
        if(connectionState == .checking){
            print("[RTCForOMP didChangeConnectionState]:checking)")
        }
        if(connectionState == .closed){
            print("[RTCForOMP didChangeConnectionState]:closed)")
        }
        if(connectionState == .completed){
            print("[RTCForOMP didChangeConnectionState]:completed)")
        }
        if(connectionState == .connected){
            print("[RTCForOMP didChangeConnectionState]:connected)")
        }
        if(connectionState == .disconnected){
            print("[RTCForOMP didChangeConnectionState]:disconnected)")
        }
        if(connectionState == .failed){
            print("[RTCForOMP didChangeConnectionState]:failed)")
        }
    }
    


}
