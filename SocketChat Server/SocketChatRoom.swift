//
//  Server.swift
//  SocketDemo
//
//  Created by 呼哈哈 on 2019/10/16.
//  Copyright © 2019 piu. All rights reserved.
//

import Foundation

class ChatClient: UserManager {
    var msgCallBack:((String)->())?
    
    init(address : String, port : uint16,msgCallBack : ((String)->())?) {
        let c = TcpClient.init(address: address, port: port)!
        self.msgCallBack = msgCallBack
        super.init(client: c)
        self.connect()
    }
    
    func connect() {
        var ret :Result
        ret = client.connect()
        if handleResult(res: ret, handle: nil){
            return
        }
        print("Connect To Server Success")
        messageRecvLoop { (isDisconnect, msg) in
            if isDisconnect{
                perror("Server Disconnect Or Error")
            }else{
                if self.msgCallBack != nil{
                    self.msgCallBack!(msg!)
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
    
    //这里的发送需要理解为向服务端保存的客户端socket列表的文件中写入数据，对应的客户端socket接收到可读数据再读取
    func send(message : String) -> Result {
        var len = [uint8](message.utf8).count
        let lenData = Data.init(bytes: &len, count: 4)
        var ret : Result
        ret = self.client.send(bytes: [uint8](lenData))
        ret = self.client.send(bytes: [uint8](message.utf8))
        return ret
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
        if let index = self.clientList.firstIndex(of: user){
            self.log(msg: "remove user\(user.client.server_addr)")
            self.clientList.remove(at: index)
        }
    }
    
    func publishMessage(except exceptUsr: UserManager,msg : String ) {
        for usr in self.clientList {
            if usr != exceptUsr{
                let ret = usr.send(message: msg)
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
                self.publishMessage(except: usr, msg: msg!)
                self.log(msg: msg!)
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
        print("\(formatter.string(from: Date()))-Server: \(msg)")
    }
}
