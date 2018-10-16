//
//  Modules.swift
//  WebRTCDemo
//
//  Created by Hydeguo on 24/01/2018.
//  Copyright © 2018 Hydeguo. All rights reserved.
//

import Foundation
import WebRTC


struct send : Codable {
    var cmd:String
    var msg:String
}

struct Params : Codable {
    var result:String
    var params:Params_detail
    var msg:[String:String]
}

//struct SendSdp : Codable {
//    var type:String
//    var sdp:Sdp
//}

struct Sdp : Codable {
    var type:String
    var sdp:String
}


struct Candidate : Codable {
    var type:String
    var id:String
    var label:Int
    var candidate:String
    
}

struct Bye : Codable {
    var type:String
}


struct Params_detail : Codable {
    var error_messages:[String]
    var messages:[String]
    var room_id:String
    var client_id:String
    var turn_server_override:[ice_server]
    var pc_config:String
    var is_initiator:String
    
}

struct ice_server : Codable {
    var urls:[String]
    var username:String?
    var credential:String?
}
//-------------------------------------------------------

struct JanusData : Codable {

    var janus:String
    var transaction:String
    var session_id:Int
}

struct CreateData : Codable {
    struct SessionData: Codable{
        var id:Int
    }
    var janus:String
    var transaction:String
    var data:SessionData
}

struct AttachData : Codable {
    struct HandleData: Codable{
        var id:Int
    }
    var janus:String
    var transaction:String
    var data:HandleData
    var session_id:Int
}
struct AttachId : Codable {
    var id:Int
}
struct Publisher : Codable {
    var id:Int
    var display:String
    var audio_codec:String?
    var video_codec:String?
    var talking:Bool?
}
struct Participant : Codable {
    var id:Int
    var display:String
    var publisher:Bool
    var talking:Bool
}
struct JsepData: Codable{
    var type:String
    var sdp:String
}
struct CandidateData: Codable{
    var sdpMid:String
    var lineIndex:Int
    var candidate:String
}
struct JoinData : Codable {
   
    struct InData: Codable{
        var videoroom:String
        var description:String?
        var id:Double?
        var room:Int
        var private_id:Int?
        var publishers:[Publisher]
    }
    struct PluginData: Codable{
        var plugin:String
        var data:InData
    }
    var janus:String
    var transaction:String?
    var plugindata:PluginData
    var session_id:Int
    var sender :Int
}
struct JoinOfferData : Codable {
    
    struct InData: Codable{
        var videoroom:String
        var display:String
        var id:Int
        var room:Int
    }
    struct PluginData: Codable{
        var plugin:String
        var data:InData
    }
    var janus:String
    var transaction:String
    var plugindata:PluginData
    var jsep:JsepData
    var session_id:Int
    var sender :Int
}

struct JoinParticipantsData : Codable {
    
    struct InData: Codable{
        var videoroom:String
        var room:Int
        var participants:[Participant]
    }
    struct PluginData: Codable{
        var plugin:String
        var data:InData
    }
    var janus:String
    var transaction:String
    var plugindata:PluginData
    var session_id:Int
    var sender :Int
}

struct AnswerReturnData : Codable {
    
    struct InData: Codable{
        var videoroom:String
        var started:String
        var room:Int
    }
    struct PluginData: Codable{
        var plugin:String
        var data:InData
    }
    var janus:String
    var transaction:String
    var plugindata:PluginData
    var session_id:Int
    var sender :Int
}
struct OfferReturnData : Codable {
    
    struct InData: Codable{
        var videoroom:String
        var room:Int
        var configured:String
        var audio_codec:String
        var video_codec:String
    }
    struct PluginData: Codable{
        var plugin:String
        var data:InData
    }
    struct JsepData: Codable{
        var type:String
        var sdp:String
    }
    var jsep:JsepData
    var transaction:String
    var plugindata:PluginData
    var session_id:Int
    var sender :Int
}

struct UnpublishData:Codable{
    struct InData: Codable{
        var videoroom:String
        var room:Int
        var unpublished:Int
    }
    struct PluginData: Codable{
        var plugin:String
        var data:InData
    }
    var janus:String
    var plugindata:PluginData
    var session_id:Int
    var sender :Int
}
