//
//  main.swift
//  SocketDemo
//
//  Created by 呼哈哈 on 2019/10/9.
//  Copyright © 2019 piu. All rights reserved.
//

import Foundation

let server = ChatServer.init(address: "0.0.0.0", port: 8888)
server!.start()

func getRandom(from :UInt32 ,to :UInt32) -> UInt32 {
     return from + (arc4random()%(to - from + 1))
}

let client = ChatClient.init(address: "127.0.0.1", port: 8888) { (msg) in
    if msg.type == "text"{
        print("client: \(msg)")
    }else{
        print("client: recv a image type message")
    }
}

let path = "/Users/huhaha/Desktop/IMG_1943.JPEG"
let url = URL.init(fileURLWithPath: path)
let data = try! Data.init(contentsOf: url)
let buf = [uint8](data)
let res = client.sendImage(imgData: buf)
if res.isSuccess {
    print ("Image Send Success")
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
