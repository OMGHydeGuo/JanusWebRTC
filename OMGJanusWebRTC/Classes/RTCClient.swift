

import UIKit
import Foundation
import WebRTC

class AVCaptureState {
    static var isVideoDisabled: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return status == .restricted || status == .denied
    }
    
    static var isAudioDisabled: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        return status == .restricted || status == .denied
    }
}




public protocol RTCClientDelegate: class {
    func rtcClient(_ id:String,client : RTCClient, startCallWithSdp sdp: RTCSessionDescription)
    func rtcClient(_ id:String,client : RTCClient, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack)
    func rtcClient(_ id:String,client : RTCClient, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack)
    func rtcClient(_ id:String,client : RTCClient, didReceiveError error: Error)
    func rtcClient(_ id:String,client : RTCClient, didChangeConnectionState connectionState: RTCIceConnectionState)
    func rtcClient(_ id:String,client : RTCClient, didGenerateIceCandidate iceCandidate: RTCIceCandidate)
}



public class RTCClient: NSObject {
    
    
    fileprivate static var mainStream:RTCMediaStream?           // static or will cost a lot performance each time
    fileprivate var iceServers: [String:[RTCIceServer]] = [String:[RTCIceServer]]()
    fileprivate var peerConnections: [String:RTCPeerConnection] = [String:RTCPeerConnection]()
    fileprivate var connectionFactory: RTCPeerConnectionFactory = RTCPeerConnectionFactory()
    fileprivate var remoteIceCandidates: [String:[RTCIceCandidate]] = [String:[RTCIceCandidate]]()
    fileprivate var isVideoCall = true

    public weak var delegate: RTCClientDelegate?
    public var defaultIceServer:[RTCIceServer]?

    fileprivate let callConstraint = RTCMediaConstraints(mandatoryConstraints: nil,
                                                         optionalConstraints: [
                "OfferToReceiveAudio": kRTCMediaConstraintsValueTrue,
                "OfferToReceiveVideo": kRTCMediaConstraintsValueTrue])
    fileprivate var mediaConstraint: RTCMediaConstraints {
        let constraints = [kRTCMediaConstraintsMinAspectRatio:"1.77777777"]// kRTCMediaConstraintsMaxWidth : "360", kRTCMediaConstraintsMaxHeight: "640",
        return RTCMediaConstraints(mandatoryConstraints: constraints, optionalConstraints: nil)
    }

    
    public override init() {
        super.init()
    }

    public convenience init( videoCall: Bool = true) {
        self.init()
        self.isVideoCall = videoCall
        self.configure()
    }
    public func setIceServer(_ id:String,iceServers: [RTCIceServer]){
        self.iceServers[id] = iceServers
    }

    private func getPeerConnection(_ id:String)->RTCPeerConnection?{
        return peerConnections[id]
    }
    private func getPeerId(_ peerConnection:RTCPeerConnection)->String?{
        for peerC in peerConnections {
            if peerConnection == peerC.value {
                return peerC.key
            }
        }
        return nil
    }
    
    deinit {
        for peerC in peerConnections {
            if let stream = peerC.value.localStreams.first {
                peerC.value.remove(stream)
            }
        }
        peerConnections=[:]
    }

    public func configure() {
        initialisePeerConnectionFactory()
    }

    public func startConnection(_ id:String, localStream:Bool) {
        guard let peerConnection = getPeerConnection(id) else {
            peerConnections[id] = createPeerConnection(id)
            startConnection(id, localStream: localStream)
            return
        }
        if(localStream)
        {
            let localStream = self.localStream(id)
            peerConnection.add(localStream)
            if let localVideoTrack = localStream.videoTracks.first {
                self.delegate?.rtcClient(id ,client: self, didReceiveLocalVideoTrack: localVideoTrack)
            }
        }
    }

    public func setAudioEnable(flag:Bool)
    {
        RTCClient.mainStream?.audioTracks[0].isEnabled = flag
    }
    
    public func disconnect(_ id:String) {
        guard let peerConnection = getPeerConnection(id) else {
            return
        }
        peerConnection.close()
        if let stream = peerConnection.localStreams.first {
            peerConnection.remove(stream)
        }
        peerConnections.removeValue(forKey: id)
        remoteIceCandidates.removeValue(forKey: id)
    }
    
    public func disconnectAll() {
        for (_,peerConnection) in peerConnections {
            peerConnection.close()
            if let stream = peerConnection.localStreams.first {
                peerConnection.remove(stream)
            }
        }
        peerConnections.removeAll()
        remoteIceCandidates.removeAll()
    }
    
    public func getConnectActiveNum()->Int {
        var index = 0
        for (_,peerConnection) in peerConnections {
            if peerConnection.iceConnectionState == .connected {
                index += 1
            }
        }
        return index
    }

    public func makeOffer(_ id:String) {
        guard let peerConnection = getPeerConnection(id)  else {
            return
        }

        peerConnection.offer(for: self.callConstraint, completionHandler: { [weak self]  (sdp, error) in
            guard let this = self else { return }
            if let error = error {
                this.delegate?.rtcClient(id,client: this, didReceiveError: error)
            } else {
                this.handleSdpGenerated(id,sdpDescription: sdp)
            }
        })
    }

    public func handleAnswerReceived(_ id:String ,withRemoteSDP remoteSdp: String?) {
        guard let remoteSdp = remoteSdp,
            let peerConnection = getPeerConnection(id)  else {
            return
        }

        // Add remote description
        let sessionDescription = RTCSessionDescription.init(type: .answer, sdp: remoteSdp)
        peerConnection.setRemoteDescription(sessionDescription, completionHandler: { [weak self] (error) in
            guard let this = self else { return }
            if let error = error {
                this.delegate?.rtcClient(id,client: this, didReceiveError: error)
            } else {
                this.handleRemoteDescriptionSet(id)
            }
        })
    }

    public func createAnswerForOfferReceived(_ id:String ,withRemoteSDP remoteSdp: String?) {
        guard let remoteSdp = remoteSdp,
            let peerConnection = getPeerConnection(id)  else {
                return
        }

        // Add remote description
        let sessionDescription = RTCSessionDescription(type: .offer, sdp: remoteSdp)
        peerConnection.setRemoteDescription(sessionDescription, completionHandler: { [weak self] (error) in
            guard let this = self else { return }
            if let error = error {
                this.delegate?.rtcClient(id,client: this, didReceiveError: error)
            } else {
                this.handleRemoteDescriptionSet(id)
                // create answer
                peerConnection.answer(for: this.callConstraint, completionHandler:
                { (sdp, error) in
                        if let error = error {
                            this.delegate?.rtcClient(id,client: this, didReceiveError: error)
                        } else {
                            this.handleSdpGenerated(id,sdpDescription: sdp)
                        }
                })
            }
        })
    }

    public func addIceCandidate(_ id:String ,iceCandidate: RTCIceCandidate) {
        // Set ice candidate after setting remote description

        guard let peerConnection = getPeerConnection(id) else {
            return
        }
        
        if peerConnection.remoteDescription != nil {
            peerConnection.add(iceCandidate)
        } else {
            if remoteIceCandidates[id] == nil{
                remoteIceCandidates[id] = [RTCIceCandidate]()
            }
            remoteIceCandidates[id]!.append(iceCandidate)
        }
    }
}

public struct ErrorDomain {
    static let videoPermissionDenied = "Video permission denied"
    static let audioPermissionDenied = "Audio permission denied"
}

private extension RTCClient {
    func handleRemoteDescriptionSet(_ id:String) {
        guard let peerConnection = getPeerConnection(id),
            var remoteIceCandidate = remoteIceCandidates[id] else {
            return
        }
        for iceCandidate in remoteIceCandidate {
            peerConnection.add(iceCandidate)
        }
        remoteIceCandidate = []
    }

    // Generate local stream and keep it live and add to new peer connection
    func localStream(_ id:String) -> RTCMediaStream {
        if(RTCClient.mainStream == nil)
        {
            let factory = self.connectionFactory
            let localStream = factory.mediaStream(withStreamId: "RTCmS")
            
            if self.isVideoCall {
                if !AVCaptureState.isVideoDisabled {
                    let videoSource = factory.avFoundationVideoSource(with: self.mediaConstraint)
                    let videoTrack = factory.videoTrack(with: videoSource, trackId: "RTCvS0")
                    localStream.addVideoTrack(videoTrack)
                } else {
                    // show alert for video permission disabled
                    let error = NSError.init(domain: ErrorDomain.videoPermissionDenied, code: 0, userInfo: nil)
                    self.delegate?.rtcClient(id,client: self, didReceiveError: error)
                }
            }
            
            if !AVCaptureState.isAudioDisabled {
                let audioTrack = factory.audioTrack(withTrackId: "RTCaS0")
                localStream.addAudioTrack(audioTrack)
            } else {
                // show alert for audio permission disabled
                let error = NSError.init(domain: ErrorDomain.audioPermissionDenied, code: 0, userInfo: nil)
                self.delegate?.rtcClient(id,client: self, didReceiveError: error)
            }
            RTCClient.mainStream  = localStream
        }
        return RTCClient.mainStream!
    }

    func initialisePeerConnectionFactory () {
        RTCPeerConnectionFactory.initialize()
        self.connectionFactory = RTCPeerConnectionFactory()
    }

    func createPeerConnection (_ id:String)->RTCPeerConnection {
     
        let configuration = RTCConfiguration()
        configuration.iceServers = self.iceServers[id] ?? (defaultIceServer ?? [])
        return self.connectionFactory.peerConnection(with: configuration,
                                                                    constraints: self.callConstraint,
                                                                    delegate: self)
//        self.peerConnection?.setBweMinBitrateBps(0, currentBitrateBps: 0, maxBitrateBps: 500)
    }

    func handleSdpGenerated(_ id:String,sdpDescription: RTCSessionDescription?) {
        guard let peerConnection = getPeerConnection(id), let sdpDescription = sdpDescription  else {
            return
        }
        let sdpDescription264 = ARDSDPUtils.description(for: sdpDescription, preferredVideoCodec: "H264")
        // set local description
        peerConnection.setLocalDescription(sdpDescription264, completionHandler: {[weak self] (error) in
            // issue in setting local description
            guard let this = self, let error = error else { return }
            this.delegate?.rtcClient(id,client: this, didReceiveError: error)
        })
        //  Signal to server to pass this sdp with for the session call
        self.delegate?.rtcClient(id ,client: self, startCallWithSdp: sdpDescription264)
    }
}

extension RTCClient: RTCPeerConnectionDelegate {
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if stream.videoTracks.count > 0 ,let id = getPeerId(peerConnection){
            self.delegate?.rtcClient(id,client: self, didReceiveRemoteVideoTrack: stream.videoTracks[0])
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {

    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        if let id = getPeerId(peerConnection){
            self.delegate?.rtcClient(id,client: self, didChangeConnectionState: newState)
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if let id = getPeerId(peerConnection){
            self.delegate?.rtcClient(id ,client: self, didGenerateIceCandidate: candidate)
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
}

