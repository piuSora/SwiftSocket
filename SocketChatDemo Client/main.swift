//
//  main.swift
//  SocketChatDemo Client
//
//  Created by 呼哈哈 on 2019/10/21.
//  Copyright © 2019 piu. All rights reserved.
//

import Foundation

func getRandom(from :UInt32 ,to :UInt32) -> UInt32 {
    return from + (arc4random()%(to - from + 1))
}

let client = ChatClient.init(address: "127.0.0.1", port: 8888) { (msg) in
    if msg.type == .MessageTypeText{
        print("client: \(msg)")
    }else{
    }
}

let client1 = ChatClient.init(address: "127.0.0.1", port: 8888) { (msg) in
    if msg.type == .MessageTypeText{
        print("client: \(msg)")
    }else{
        let data = Data.init(base64Encoded: msg.data)
        let fm = FileManager.default
        let res = fm.createFile(atPath: "/Users/huhaha/Desktop/backup/down.data", contents: data, attributes: nil)
        print("creat \(res)")
    }
}

//let path = Bundle.main.path(forResource: "test", ofType: "png")
let url = URL.init(fileURLWithPath: "/Users/huhaha/Desktop/test.data")
let data = try! Data.init(contentsOf: url)
let buf = [uint8](data)
let res = client.sendImage(imgData: buf)
if res.isSuccess {
    print ("File Send Success")
}else{
    perror(res.error)
}

func sendRandomMsg() {
    let client = ChatClient.init(address: "127.0.0.1", port: 8888) { (msg) in
        print("client: \(msg)")
    }
    
    DispatchQueue.global().async {
        while true{
            let len = getRandom(from: 1, to: 200)
            var randMsg = ""
            for _ in 0...len{
                let asc = getRandom(from: 33, to: 126)
                randMsg += String(UnicodeScalar.init(asc)!)
            }
            sleep(getRandom(from: 1, to: 10))
            let ret = client.send(message: randMsg)
            if ret.isFailure {
                print("Send Failed")
            }else{
                print("Send Success")
            }
        }
    }
}
//sendRandomMsg()

CFRunLoopRun()
