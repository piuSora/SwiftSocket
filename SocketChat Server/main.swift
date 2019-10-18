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
     return from +  (arc4random()%(to - from + 1))
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

sendRandomMsg()

CFRunLoopRun()
