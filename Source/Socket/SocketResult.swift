//
//  SocketResult.swift
//  SocketDemo
//
//  Created by 呼哈哈 on 2019/10/16.
//  Copyright © 2019 piu. All rights reserved.
//

import Foundation
public enum SocketError : String {
    case SocketInitFail = "SocketInitFail"
    case SocketBindFail = "SocketBindFail"
    case SocketConnectFail = "SocketConnectFail"
    case SocketConnectClosed = "SocketConnectClosed"
    case SocketConnectTimeout = "SocketConnectTimeout"
    case SocketSendFail = "SocketSendFail"
    case SocketSendTimeout = "SocketSendTimeout"
    case SocketListenFail = "SocketListenFail"
}

public enum Result {
    
    case success
    case failure(SocketError)
    
    public var isSuccess: Bool{
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    public var isFailure: Bool{
        return !isSuccess
    }
    
    public var error:String?{
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error.rawValue
        }
    }
}
