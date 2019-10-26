//
//  Server.swift
//  SocketDemo
//
//  Created by 呼哈哈 on 2019/10/16.
//  Copyright © 2019 piu. All rights reserved.
//

import Foundation

class ChatClient: UserManager {
    
    enum MessageType : String,Codable {
        case MessageTypeText = "text"
        case MessageTypeImage = "image"
        case MessageTypeFile = "file"
    }
    
    struct MessageInfo : Decodable{
        var type : MessageType
        var data : String
    }
    
    var msgCallBack:((MessageInfo)->())?
    
    init(address : String, port : uint16,msgCallBack : ((MessageInfo)->())?) {
        let c = TcpClient.init(address: address, port: port)!
        self.msgCallBack = msgCallBack
        super.init(client: c)
        self.connect()
    }
    
    func connect() {
        var ret :Result
        ret = client.connect()
        MessageInfo.decodeJSON(with: <#T##String?#>)
        if handleResult(res: ret, handle: nil){
            return
        }
        print("Connect To Server Success")
        messageRecvLoop { (isDisconnect, msg) in
            if isDisconnect{
                perror("Server Disconnect Or Error")
            }else{
                if self.msgCallBack != nil{
                    let data = MessageInfo.decodeJSON(with: msg!)
                    self.msgCallBack!(data!)
                }
            }
        }
    }
    
    
    func handleResult(res : Result,handle : (()->())?) -> Bool {
        if res.isFailure {
            perror(res.error)
            if handle != nil{
                handle!()
            }
            return true
        }
        return false
    }
}


class UserManager: NSObject{
    var client : TcpClient
    var server : ChatServer?
    
    init(client:TcpClient) {
        self.client = client
        super.init()
    }
    
    func forward(raw : String) -> Result {
        let data = raw.data(using: .utf8)!
        return send(data: [uint8](data))
    }
    
    //这里的发送需要理解为向服务端保存的客户端socket列表的文件中写入数据，对应的客户端socket接收到可读数据再读取
    private func send(data : [uint8]) -> Result {
        var len = data.count
        let lenData = Data.init(bytes: &len, count: 4)
        var ret : Result
        ret = self.client.send(bytes: [uint8](lenData))
        ret = self.client.send(bytes: data)
        return ret
    }
    
    func send(message : String) -> Result {
        let data = message.data(using: .utf8)!
        return send(data: encodeData(type: .MessageTypeText, data: data))
    }
    
    func sendImage(imgData : [uint8]) -> Result {
        var data = imgData
        return send(data: encodeData(type: .MessageTypeImage, data: Data.init(bytes: &data, count: data.count)))
    }
    
    func sendFile(fileData : [uint8]) -> Result {
        var data = fileData
        return send(data: encodeData(type: .MessageTypeFile, data: Data.init(bytes: &data, count: data.count)))
    }
    
    func encodeData(type : ChatClient.MessageType, data : Data) -> [uint8] {
        var obj : Dictionary<String,String> = [:]
        obj["type"] = type.rawValue
        if type == .MessageTypeText {
            obj["data"] = String.init(data: data, encoding: .utf8)
        }else{
            obj["data"] = data.base64EncodedString()
        }
        let json = obj.toJSONString()!
        return [uint8](json.utf8)
    }
    
    func disconnect() {
        self.client.close()
    }
    
    func readMessage() -> String? {
        if let byte = self.client.read(4,timeout: nil){//first 4 bit(Int) are size for data
            if byte.count == 4{
                let data = Data.init(bytes: byte, count: byte.count)
                let len = data.withUnsafeBytes({ (ptr) -> uint32 in
                    ptr.load(as: uint32.self)
                })
                if let buff = self.client.read(Int(len),timeout: nil){
                    let msg = String.init(bytes: buff, encoding: .utf8)
                    return msg
                }
            }
        }
        return nil
    }
    
    open func messageRecvLoop(callback : @escaping(Bool,String?)->()) {
        DispatchQueue.global(qos: .background).async {
            while true {
                if let msg = self.readMessage(){//拿到消息
                    callback(false,msg)
                }else{
                    callback(true,nil)
                    break
                }
            }
        }
    }
}

class ChatServer: NSObject {
    var serverRuning:Bool = false
    var server : TcpServer
    var clientList : [UserManager] = []
    var arrayLock : NSLock = NSLock()
    
    init?(address: String, port : uint16) {
        guard let s = TcpServer.init(address: address, port: port) else { perror("TcpServer Init Failed"); return nil}
        self.server = s
        super.init()
    }
    
    func start() {
        self.serverRuning = true
        var ret : Result
        ret = server.bind()
        if handleResult(res: ret, handle: nil){
            return
        }
        ret = server.listen()
        if handleResult(res: ret, handle: nil){
            return
        }
        DispatchQueue.global(qos: .background).async {
            while self.serverRuning{
                if let client = self.server.accept(){
                    self.handleClient(c: client)
                }
            }
        }
        self.log(msg: "Server Started...")
    }
    
    func removeUser(user : UserManager) {
        arrayLock.lock()
        if let index = self.clientList.firstIndex(of: user){
            self.log(msg: "remove user\(user.client.server_addr)")
            self.clientList.remove(at: index)
            arrayLock.unlock()
        }
    }
    
    func publishMessage(except exceptUsr: UserManager,msg : String ) {
        for usr in self.clientList {
            if usr != exceptUsr{
                let ret = usr.forward(raw: msg)
                _ = handleResult(res: ret){
                    print("publish message failed")
                }
            }
        }
    }
    
    func handleClient(c:TcpClient) {
        self.log(msg: "new client from:"+c.server_addr)
        let usr = UserManager.init(client: c)
        usr.server = self
        self.clientList.append(usr)
        usr.messageRecvLoop { (isDisconnect, msg) in
            if isDisconnect{
                self.removeUser(user: usr)
            }else{
                print("call back count:",msg?.count)
                self.publishMessage(except: usr, msg: msg!)
            }
        }
    }
    
    func handleResult(res : Result,handle : (()->())?) -> Bool {
        if res.isFailure {
            perror(res.error)
            if handle != nil{
                handle!()
            }
            return true
        }
        return false
    }
    
    func stop() {
        self.serverRuning = false
        _ = self.server.close()
        for c in self.clientList {
            c.disconnect()
        }
        self.log(msg: "Server Stopped...")
    }
    
    func log(msg:String) {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "HH:mm:ss"
        let timeinfo = formatter.string(from: Date())
        print("\(timeinfo)-Server: \(msg)")
    }
}
