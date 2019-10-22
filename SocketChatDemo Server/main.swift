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

CFRunLoopRun()
