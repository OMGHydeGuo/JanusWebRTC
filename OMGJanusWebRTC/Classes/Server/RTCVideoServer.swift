//
//  RTCVideoBase.swift
//  WebRTCDemo
//
//  Created by Hydeguo on 24/01/2018.
//  Copyright © 2018 Hydeguo. All rights reserved.
//

import Foundation
import Starscream
import WebRTC


enum JanusType
{
    case Join
    case Listparticipants
}


public class RTCVideoServer: WebSocketDelegate ,OMGRTCServerDelegate{

    

    open var initPublish = true
    open var maxViewer = 2
    open var displayName:String=""
    var roomId:Int64=1234
    var session_id:Int = 0
    var private_id:Int = 0
    var handle_id_for_cliendID:[Int:String] = [:]
    var info_for_cliendID:[Int:Publisher] = [:]
    var client:RTCClient?
    var type:JanusType = .Join
    private var socket:WebSocket?
    private var clientId:String = ""
    private var tempRemotSdp:String?
    private var _aliveTimer:Timer?
    
     var id:String = "main"
    var commandList = [BaseCommand]()
    /**
     url : handshake socket server url
     */
    init(url:String,client:RTCClient){
        socket = WebSocket(url: URL(string:url)!, protocols: ["janus-protocol"])
        socket?.delegate = self
        self.client = client
    }
    
    func setSessionId(_ id :Int)
    {
        session_id = id
        _aliveTimer = Timer.scheduledTimer(timeInterval: 25, target: self, selector: #selector(senfAlive), userInfo: nil, repeats: true)
  
    }
    @objc func senfAlive()
    {
        self.sendCommand(command: KeepAliveCommand(delegate: self, handleId: 0))
    }
    
    public func getHandIdForClienID(id:String)->Int
    {
        for (handleId,clientId) in handle_id_for_cliendID {
            if clientId == id{
                return handleId
            }
        }
        return 0
    }
    public func getClienIDFromHandId(id:Int)->String
    {
        for (handleId,clientId) in handle_id_for_cliendID {
            if handleId == id{
                return clientId
            }
        }
        return ""
    }
    public func getDisplayForClientId(id:String)-> String?
    {
        for (clientId,publishData) in info_for_cliendID {
            if String(clientId) == id {
                return publishData.display
            }
        }
        return nil
    }
    public func getMyClienID()->String
    {
        return self.clientId
    }
    public func sendCommand(command:BaseCommand)
    {
        commandList.append(command);
        let sendText = command.getSendData();
        socket?.write(string:sendText)
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        
        print("[websocket connected]")
        handle_id_for_cliendID = [:]
        info_for_cliendID = [:]
        sendCommand(command: CreateCommand(delegate: self, handleId: 0))
    }

    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let e = error {
            print("[websocket  is disconnected: \(e.localizedDescription)]")
        } else {
            print("[websocket disconnected]")
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
     
        onDataReceived(str: text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
//        print("Received data: \(data.count)")
        let dataString = String(data: data, encoding: .utf8)!
        onDataReceived(str: dataString)
        
    }
    
    func onDataReceived(str:String)
    {
        #if DEBUG
           print("[Received text]:\n___start___\n \(str)\n___end___")
        #endif
        if(str.contains("transaction"))
        {
            for command in commandList {
                if str.contains(command.transaction)
                {
                    command.receive(strData: str)
                }
            }
        }
        else
        {
            if(str.contains("unpublished")){
                ReceiveUnpublishCommand(delegate: self, handleId: 0).receive(strData: str)
                
            }else if(str.contains("publishers")){
                
                if((client?.getConnectActiveNum())! - 1 < maxViewer){
                    NewJoinActiveCommand(delegate: self, handleId: 0).receive(strData: str)
                }
            }
        }
        
        cleanTimeOutCommad()
        
    }
    
    
    public func registerMeetRoom(_ roomId:Int64, clientId:String){
        
        self.roomId = roomId
        self.clientId = clientId
        socket?.connect()
        print("[registerMeetRoom]:\(roomId),clientId:\(clientId)")
        
    }
    
    public func disconnectMeetingById(id:String)
    {
        client?.disconnect(id)
    }
    public func disconnectMeeting()
    {
        client?.disconnectAll()
        socket?.disconnect()
        _aliveTimer?.invalidate()
    }
    
    deinit{
        _aliveTimer?.invalidate()
        socket?.disconnect()
        socket?.delegate = nil
        socket = nil
        client?.disconnect(id)
        client?.delegate = nil
        client = nil
    }
    
    private func doRegister()
    {
        let props = ["cmd": "register", "clientid":clientId,"roomid":roomId] as [String : Any]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: props,
                                                      options: .prettyPrinted)
            socket?.write(string:String(data: jsonData, encoding: String.Encoding.utf8)!)
            print("[doRegister]:\(roomId),clientId:\(clientId)")
        } catch let error {
            print("error converting to json: \(error)")
        }
    }
    
    
    func sendMsg(string :String)
    {
        socket?.write(string: string)
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
    
    private func cleanTimeOutCommad()
    {
        let now = Date().timeIntervalSince1970
        var active = [BaseCommand]()
        for command in commandList {
            if now - command.time < 30
            {
                active.append( command)
            }
        }
        commandList = active
    }

}



