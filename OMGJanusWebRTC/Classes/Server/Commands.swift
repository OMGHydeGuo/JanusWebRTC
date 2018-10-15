//
//  Command.swift
//  JanusWebRTC
//
//  Created by Hydeguo on 2018/7/5.
//  Copyright © 2018 Hydeguo. All rights reserved.
//

import Foundation

public protocol CommandDelegate: class {
    func receive(strData:String)
    func getSendData()->String
}

public class BaseCommand:CommandDelegate
{
    var time:TimeInterval
    var transaction:String
    var delegate:RTCVideoServer
    var handle_id:Int
    var preData:Codable?
    public init(delegate:RTCVideoServer,handleId:Int,data:Codable? = nil) {
        self.transaction = UUID.init().uuidString
        self.delegate = delegate
        self.handle_id = handleId
        self.preData = data
        self.time = Date().timeIntervalSince1970
    }
    
    final public func getSendData() -> String {
        var sendData = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: getDataObject(),options: .prettyPrinted)
            sendData = String(data: jsonData, encoding: String.Encoding.utf8)!
        } catch let error {
            print("error converting to json: \(error)")
        }
        return sendData
    }
    
    func getDataObject()->[String : Any]{return [:]}
    
    public func receive(strData str: String) {}
}


class CreateCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            let data:CreateData = try JSONDecoder().decode(CreateData.self, from: strData.data(using: .utf8)!)
            delegate.setSessionId( data.data.id)
            delegate.sendCommand(command: AttachCommand(delegate: delegate, handleId: 0))
            
        }catch let error {
            print("error converting to json: \(error)")
        }
    }
    
    override func getDataObject() -> [String : Any] {
        return ["janus": "create", "transaction":transaction] as [String : Any]
    }
}


class AttachCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            let data:AttachData = try JSONDecoder().decode(AttachData.self, from: strData.data(using: .utf8)!)
            handle_id = data.data.id
            delegate.handle_id_for_cliendID[handle_id] = ""
            
            if(delegate.type == .Listparticipants){
                delegate.sendCommand(command: ListparticipantsCommand(delegate: delegate, handleId: handle_id))
            }else{
                if(preData == nil){
                    delegate.sendCommand(command: JoinForPublisherCommand(delegate: delegate, handleId: handle_id))
                }else{
                    delegate.sendCommand(command: JoinForSubscriberCommand(delegate: delegate, handleId: handle_id,data:preData))
                }
            }
        }catch let error {
            print("error converting to json: \(error)")
        }
    }
    
    override func getDataObject() -> [String : Any] {
        return ["janus": "attach", "transaction":transaction, "session_id":delegate.session_id,"plugin":"janus.plugin.videoroom","opaque_id":"videoroomtest-"
            ] as [String : Any]
    }
}

class JoinForPublisherCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            if strData.contains("event")
            {
                let data:JoinData = try JSONDecoder().decode(JoinData.self, from: strData.data(using: .utf8)!)
                let id = delegate.getMyClienID()
                
                if(delegate.initPublish){
                    delegate.client?.startConnection(id, localStream: true)
                    delegate.client?.makeOffer(id)
                }
                
                delegate.private_id = data.plugindata.data.private_id!
                var index = 0
                for publisher in data.plugindata.data.publishers
                {
                    if index == delegate.maxViewer {
                        return
                    }
                    delegate.info_for_cliendID[publisher.id] = publisher
                    delegate.sendCommand(command: AttachCommand(delegate: delegate, handleId: handle_id,data:AttachId(id: publisher.id)))
                    index += 1
                }
            }
        }catch let error {
            print("error converting to json: \(error)")
        }
    }
    
    override func getDataObject() -> [String : Any] {
        delegate.handle_id_for_cliendID[handle_id] = delegate.getMyClienID()
        return ["janus": "message", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"body":["display":delegate.displayName,"ptype":"publisher","request":"join","room":delegate.roomId]
            ] as [String : Any]
    }
}


class JoinForSubscriberCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            if strData.contains("event")
            {
                let data:JoinOfferData = try JSONDecoder().decode(JoinOfferData.self, from: strData.data(using: .utf8)!)
                let id = String(data.plugindata.data.id)
        
                delegate.client?.startConnection(id, localStream: false)
                delegate.client?.createAnswerForOfferReceived(id, withRemoteSDP: data.jsep.sdp)
            }
        }catch let error {
            print("error converting to json on JoinForSubscriberCommand: \(error)")
        }
    }
    
    override func getDataObject() -> [String : Any] {

        let pData:AttachId = preData as! AttachId
        delegate.handle_id_for_cliendID[handle_id] = String(pData.id)
        return ["janus": "message", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"body":["display":"subscriber", "feed":pData.id,"private_id":delegate.private_id,"ptype":"subscriber","request":"join","room":delegate.roomId]
            ] as [String : Any]
    }
}

class NewJoinActiveCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            if strData.contains("event")
            {
                let data:JoinData = try JSONDecoder().decode(JoinData.self, from: strData.data(using: .utf8)!)
                let id = data.plugindata.data.publishers[0].id
                delegate.info_for_cliendID[id] = data.plugindata.data.publishers[0]
                delegate.sendCommand(command: AttachCommand(delegate: delegate, handleId: 0, data: AttachId(id: id)))
            }
        }catch let error {
            print("error converting to json: \(error)")
        }
    }
    
}
class ReceiveUnpublishCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            if strData.contains("event")
            {
                let data:UnpublishData = try JSONDecoder().decode(UnpublishData.self, from: strData.data(using: .utf8)!)
                delegate.disconnectMeetingById(id: String(data.plugindata.data.unpublished))
            }
        }catch let error {
            print("error converting to json: \(error)")
        }
    }
    
}
public class UnpublishCommand:BaseCommand
{
    override public func receive(strData: String) {
        if strData.contains("event")
        {
            delegate.disconnectMeetingById(id: delegate.getClienIDFromHandId(id: handle_id))
        }
    }
    override func getDataObject() -> [String : Any] {
        return ["janus": "message", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"body":["request":"unpublish"]
            ] as [String : Any]
    }
}
//---------------------------------------------------------

class ListparticipantsCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            let data:JoinParticipantsData = try JSONDecoder().decode(JoinParticipantsData.self, from: strData.data(using: .utf8)!)
            delegate.sendCommand(command: JoinParticipantCommand(delegate: delegate, handleId: handle_id,data:data))
        }catch let error {
            print("error converting to json: \(error)")
        }
    }
    
    override func getDataObject() -> [String : Any] {
        return ["janus": "message", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"body":["request":"listparticipants","room":delegate.roomId]
            ] as [String : Any]
    }
}

class JoinParticipantCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            if strData.contains("event")
            {
                let data:JoinOfferData = try JSONDecoder().decode(JoinOfferData.self, from: strData.data(using: .utf8)!)
                let id = String(data.plugindata.data.id)
                var iceServers = [RTCIceServer]()
                //            iceServers.append(RTCIceServer(urlStrings: iceServerdata.urls, username: iceServerdata.username, credential: iceServerdata.credential))
                iceServers.append(RTCIceServer(urlStrings:["stun:stun.l.google.com:19302"] ))
                delegate.client?.setIceServer(id, iceServers: iceServers)
                delegate.client?.startConnection(id, localStream: false)
                delegate.client?.createAnswerForOfferReceived(String(data.plugindata.data.id), withRemoteSDP: data.jsep.sdp)
            }
        }catch let error {
            print("error converting to json: \(error)")
        }
    }
    
    override func getDataObject() -> [String : Any] {
        var pData:JoinParticipantsData = preData as! JoinParticipantsData
        let view_id = pData.plugindata.data.participants[0].id
        delegate.handle_id_for_cliendID[handle_id] = String(view_id)
        return ["janus": "message", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"body":["feed":view_id,"private_id":0,"ptype":"subscriber","request":"join","room":delegate.roomId]
            ] as [String : Any]
    }
}

import WebRTC
class SendOfferCommand:BaseCommand
{
    override func receive(strData: String) {
        do {
            if strData.contains("event")
            {
                let data:OfferReturnData = try JSONDecoder().decode(OfferReturnData.self, from: strData.data(using: .utf8)!)
                let id = delegate.getClienIDFromHandId(id: data.sender)
                delegate.client?.handleAnswerReceived(id,withRemoteSDP: data.jsep.sdp)
            }
        }catch let error {
            print("error converting to json: \(error)")
        }
    }
    
    override func getDataObject() -> [String : Any] {
        let pData:JsepData = preData as! JsepData
        return ["janus": "message", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"body":["request":"configure","audio":true,"video":true],"jsep":["type":pData.type,"sdp":pData.sdp]
            ] as [String : Any]
    }
}
class SendAnswerCommand:BaseCommand
{
    
    override func getDataObject() -> [String : Any] {
        let pData:JsepData = preData as! JsepData
        return ["janus": "message", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"body":["request":"start","room":delegate.roomId],"jsep":["type":"answer","sdp":pData.sdp]
            ] as [String : Any]
    }
}
class SendCandidateCommand:BaseCommand
{
    
    override func getDataObject() -> [String : Any] {
        let pData:CandidateData = preData as! CandidateData
        return ["janus": "trickle", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"candidate":["candidate":pData.candidate,"sdpMLineIndex":pData.lineIndex,"sdpMid":pData.sdpMid]
            ] as [String : Any]
    }
}
class SendCandidateEndCommand:BaseCommand
{
    
    override func getDataObject() -> [String : Any] {
        return ["janus": "trickle", "transaction":transaction, "session_id":delegate.session_id,"handle_id":handle_id,"candidate":["completed":true]
            ] as [String : Any]
    }
}
class KeepAliveCommand:BaseCommand
{

    override func getDataObject() -> [String : Any] {
        return ["janus": "keepalive", "transaction":transaction, "session_id":delegate.session_id] as [String : Any]
    }
}




