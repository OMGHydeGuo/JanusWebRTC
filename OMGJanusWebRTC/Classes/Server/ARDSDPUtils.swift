
import WebRTC

class ARDSDPUtils {
    class func description(for description: RTCSessionDescription, preferredVideoCodec codec: String) -> RTCSessionDescription {
        let sdpString: String = description.sdp
        let lineSeparator = "\n"
        let mLineSeparator = " "
        
        // Copied from PeerConnectionClient.java.
        // TODO(tkchin): Move this to a shared C++ file.
        var lines = sdpString.components(separatedBy: lineSeparator)
        // Find the line starting with "m=video".
        var mLineIndex: Int = -1
        for i in 0..<lines.count {
            if lines[i].hasPrefix("m=video") {
                mLineIndex = i
                break
            }
        }
        if mLineIndex == -1 {
            print("No m=video line, so can't prefer \(codec)")
            return description
        }
        // An array with all payload types with name |codec|. The payload types are
        // integers in the range 96-127, but they are stored as strings here.
        var codecPayloadTypes = [String]()
        // a=rtpmap:<payload type> <encoding name>/<clock rate>
        // [/<encoding parameters>]
        let pattern = "^a=rtpmap:(\\d+) \(codec)(/\\d+)+[\r]?$"

        for line: String in lines {
            if line.range(of:pattern, options: .regularExpression) != nil {
                codecPayloadTypes.append(String(line.components(separatedBy: mLineSeparator)[0].components(separatedBy: ":")[1]))
            }
        }
        if codecPayloadTypes.count == 0 {
            print("No payload types with name \(codec)")
            return description
        }
        let origMLineParts = lines[mLineIndex].components(separatedBy: mLineSeparator)
        // The format of ML should be: m=<media> <port> <proto> <fmt> ...
        let kHeaderLength: Int = 3
        if origMLineParts.count <= kHeaderLength {
            print("Wrong SDP media description format: \(lines[mLineIndex])")
        
            return description
        }
        // Split the line into header and payloadTypes.
        let header = origMLineParts[0...kHeaderLength-1]
        var payloadTypes = origMLineParts[kHeaderLength...origMLineParts.count-1]
        // Reconstruct the line with |codecPayloadTypes| moved to the beginning of the
        // payload types.
        var newMLineParts = [String]() /* TODO: .reserveCapacity(origMLineParts.count) */
        newMLineParts.append(contentsOf: header)
        newMLineParts.append(contentsOf: codecPayloadTypes)
        payloadTypes = payloadTypes.filter({ !codecPayloadTypes.contains($0) })
        
        newMLineParts.append(contentsOf: payloadTypes )
        let newMLine: String = newMLineParts.joined(separator: mLineSeparator)
        lines[mLineIndex] = newMLine
        let mangledSdpString: String = lines.joined(separator: lineSeparator)
        
        
        return RTCSessionDescription(type: description.type, sdp: mangledSdpString)
    }
}
