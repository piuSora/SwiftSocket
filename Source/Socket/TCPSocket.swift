//
//  TcpSocket.swift
//  SocketDemo
//
//  Created by 呼哈哈 on 2019/10/16.
//  Copyright © 2019 piu. All rights reserved.
//

import Foundation

class Socket {
    var socket_fd : Int32
    var server_addr:String
    var port: uint16
    fileprivate var server_s : sockaddr_in
    
    init?(address : String,port : uint16) {
        self.server_addr = address
        self.port = port
        self.server_s = sockaddr_in()
        self.socket_fd = socket(AF_INET, SOCK_STREAM, 0)
        
        guard self.socket_fd >= 0 else {
            return nil
        }
        self.server_s.sin_family = sa_family_t(AF_INET)
        self.server_s.sin_port = port.bigEndian
        let hp = gethostbyname(address)
        guard let hpf = hp else { return nil }
        bcopy(hpf.pointee.h_addr_list[0], &server_s.sin_addr, Int(hpf.pointee.h_length))
        var ad = address.cString(using: .ascii)!
        inet_pton(AF_INET, &ad, &self.server_s.sin_addr.s_addr)
    }
    
    open func close(){
        guard self.socket_fd >= 0 else {
            return
        }
        _ = Darwin.close(self.socket_fd)
    }
}

class TcpClient: Socket {
    func connect(timeout : Int = 10) -> Result {
        //设置fd非阻塞
        _setSocketBlock(on: false)
        withUnsafePointer(to: &self.server_s) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, {(ptr)->Void in
                //发起连接
                _ = Darwin.connect(self.socket_fd, ptr, socklen_t(MemoryLayout<sockaddr>.size))
            })
        }
        //select判断文件读写状态
        let ret = select(fd_size: nil, fd: self.socket_fd, status: .SelectStatusWritable, timeout: timeout)
        if ret < 0 {
            self.close()
            return .failure(.SocketConnectClosed)
        }else if ret == 0{
            self.close()
            return .failure(.SocketConnectTimeout)
        }else{
            //检查是否连接成功
            var error = 0
            var errlen = socklen_t(MemoryLayout.size(ofValue: error))
            getsockopt(self.socket_fd, SOL_SOCKET, SO_ERROR, &error, &errlen)
            if error != 0{
                self.close()
                return .failure(.SocketConnectFail)
            }
            var set : Int = 1
            setsockopt(self.socket_fd, SOL_SOCKET, SO_NOSIGPIPE, UnsafeRawPointer(&set), socklen_t(MemoryLayout<Int>.size))
            return .success
        }
    }
    
    func send(bytes : [uint8],timeout : Int? = 10) -> Result {
        var bytesWrite = 0
        var buf = bytes
        let bufPtr = UnsafeRawPointer(&buf)
        
        while bytes.count - bytesWrite > 0{
            let writeLen = Darwin.write(self.socket_fd, bufPtr.advanced(by: bytesWrite), bytes.count - bytesWrite)
            if writeLen < 0{
                if errno == 35{
                    let ret = select(fd_size: nil, fd: self.socket_fd, status: .SelectStatusWritable, timeout: timeout)
                    if ret == 0{
                        return .failure(.SocketSendTimeout)
                    }else if ret < 0{
                        return .failure(.SocketSendFail)
                    }
                    continue
                }
                return .failure(SocketError.SocketSendFail)
            }
            bytesWrite += writeLen
        }
        print("should write:\(bytes.count),total write:\(bytesWrite)")
        return .success
    }
    
    private func _setSocketBlock(on : Bool) {
        var flags = Darwin.fcntl(self.socket_fd, F_GETFL,0)
        if on {//block
            flags &= ~O_NONBLOCK;
            let _ = Darwin.fcntl(self.socket_fd, F_SETFL,flags)
        }else{//nonBlock
            let _ = Darwin.fcntl(self.socket_fd, F_SETFL,flags | O_NONBLOCK)
        }
    }
    
    //timeout <= 0 not use select, timeout == nil wait for select forever,timeout > 0 wait until timeout
    open func read(_ length : Int,timeout : Int? = -1) -> [uint8]? {
        let expLen = length
        var needRetry = false
        var buf = Array<uint8>.init(repeating: 0x0, count: expLen)
        var readlen : Int = 0
        var datalen : Int = 0
        let bufPtr = UnsafeMutableRawPointer(&buf)
        if timeout == nil || timeout! > 0{
            let ret = select(fd_size: nil, fd: self.socket_fd, status: .SelectStatusReadable, timeout: timeout)
            if ret <= 0{
                return nil//timeout(0) or failed(-1)
            }
        }
        repeat{
            needRetry = false
            readlen = Darwin.read(socket_fd, bufPtr.advanced(by: datalen), expLen - datalen)
            if readlen > 0 {
                datalen += readlen
            }
            if readlen == -1 {
                if errno == 35{//EAGAIN 如果超过缓冲区大小
                    let ret = select(fd_size: nil, fd: self.socket_fd, status: .SelectStatusReadable, timeout: timeout)
                    if ret <= 0{
                        return nil//timeout(0) or failed(-1)
                    }
                    needRetry = true
                }
            }
            print("has read \(datalen),this time read return \(readlen)")
        } while readlen > 0 || needRetry
        if datalen <= 0 {
            return nil//error(-1) or disconnect(0)
        }else{
            print("should read: \(length) total read: \(datalen)")
            let rs = buf[0...(datalen-1)];
            return Array(rs)
        }
    }
}

class TcpServer : Socket {
    func bind() -> Result {
        var on : Int = 1
        setsockopt(self.socket_fd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int>.size))
        let ret = withUnsafePointer(to: &self.server_s) { (ptr) -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1, { (ptrSockAddr) -> Int32 in
                let ret = Darwin.bind(self.socket_fd, UnsafePointer(ptrSockAddr), socklen_t(MemoryLayout<sockaddr>.size))
                return ret
            })
        }
        if ret < 0 {
            return .failure(SocketError.SocketBindFail)
        }else{
            return .success
        }
    }
    
    open func listen() -> Result {
        let ret = Darwin.listen(self.socket_fd, 128)
        if ret < 0 {
            return .failure(SocketError.SocketListenFail)
        }else{
            return .success
        }
    }
    
    open func accept(timeout :Int? = nil) -> TcpClient?{
        var client_addr : sockaddr_in = sockaddr_in()
        var len : socklen_t = UInt32(MemoryLayout.size(ofValue: client_addr))
        let FD_SETSIZE = Int32(1024)
        let selRet = select(fd_size: FD_SETSIZE, fd: self.socket_fd, status: .SelectStatusReadable, timeout: timeout)
        if selRet != 1 {
            return nil
        }
        
        let cfd = withUnsafeMutablePointer(to: &client_addr) { (ptr) -> Int32 in
            let ret = ptr.withMemoryRebound(to: sockaddr.self, capacity: 1, { (ptrSockAddr) -> Int32 in
                let ret = Darwin.accept(self.socket_fd, ptrSockAddr, &len)
                return ret
            })
            return ret
        }
        if cfd < 0 {
            return nil
        }
        let addrPtr = Darwin.inet_ntoa(client_addr.sin_addr)
        let addrStr = String.init(cString: addrPtr!)
        var set = 1
        setsockopt(cfd, SOL_SOCKET, SO_NOSIGPIPE, UnsafeRawPointer(&set), socklen_t(MemoryLayout<Int>.size))
        let client = TcpClient.init(address: addrStr, port: client_addr.sin_port)
        client?.socket_fd = cfd
        return client
    }
}
