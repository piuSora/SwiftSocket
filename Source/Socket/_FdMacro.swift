//
//  _FdMacro.swift
//  SocketDemo
//
//  Created by 呼哈哈 on 2019/10/16.
//  Copyright © 2019 piu. All rights reserved.
//

import Foundation

typealias uint16 = UInt16
typealias uint8 = UInt8
typealias uint32 = UInt32

enum SelectStatusCheck {
    case SelectStatusReadable
    case SelectStatusWritable
    case SelectStatusErrorable
}

/**
 Darwin.select swift ez ver.
 
 - Parameter fd_size: if nil ,use fd + 1
 
 - Parameter fd: file description
 
 - Parameter status: for select status check
 
 - Parameter timeout: for select time out ,select will be set non_block if this para <= 0,timeout = nil select will block until the status changed
 
 - Returns: return Darwin.select method's return value , -1 error, 0 timeout,>0 total number of bits set in readfds.
 */
func select(fd_size : Int32?,fd : Int32,status : SelectStatusCheck,timeout:Int?) -> Int32 {
    var fdread : fd_set?
    var fdwrite : fd_set?
    var fderror : fd_set?
    var timeout_v : timeval?
    var timeout_ptr : UnsafeMutablePointer<timeval>?
    var read_ptr : UnsafeMutablePointer<fd_set>?
    var write_ptr : UnsafeMutablePointer<fd_set>?
    var error_ptr : UnsafeMutablePointer<fd_set>?
    var tmp_size = fd + 1
    if timeout != nil {
        timeout_v = timeval()
        timeout_v?.tv_sec = timeout!
        timeout_v?.tv_usec = 0
        withUnsafeMutablePointer(to: &timeout_v!) { (ptr) -> Void in
            timeout_ptr = ptr
        }
    }
    if status == .SelectStatusReadable {
        fdread = fd_set()
        FD_ZERO(&fdread!)
        FD_SET(fd, set: &fdread!)
        withUnsafeMutablePointer(to: &fdread!) { (ptr) -> Void in
            read_ptr = ptr
        }
    }
    if status == .SelectStatusWritable {
        fdwrite = fd_set()
        FD_ZERO(&fdwrite!)
        FD_SET(fd, set: &fdwrite!)
        withUnsafeMutablePointer(to: &fdwrite!) { (ptr) -> Void in
            write_ptr = ptr
        }
    }
    if status == .SelectStatusErrorable {
        fderror = fd_set()
        FD_ZERO(&fderror!)
        FD_SET(fd, set: &fderror!)
        withUnsafeMutablePointer(to: &fderror!) { (ptr) -> Void in
            error_ptr = ptr
        }
    }
    if fd_size != nil{
        tmp_size = fd_size!
    }
    return Darwin.select(tmp_size, read_ptr, write_ptr, error_ptr, timeout_ptr)
}

/**
 Replacement for FD_ZERO macro.
 
 - Parameter set: A pointer to a fd_set structure.
 
 - Returns: The set that is opinted at is filled with all zero's.
 */
public func FD_ZERO(_ set :inout fd_set){
    set.fds_bits = (0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0)
}

/**
 Replacement for FD_SET macro
 
 - Parameter fd: A file descriptor that offsets the bit to be set to 1 in the fd_set pointed at by 'set'.
 - Parameter set: A pointer to a fd_set structure.
 
 - Returns: The given set is updated in place, with the bit at offset 'fd' set to 1.
 
 - Note: If you receive an EXC_BAD_INSTRUCTION at the mask statement, then most likely the socket was already closed.
 */

public func FD_SET(_ fd: Int32, set: inout fd_set) {
    let intOffset = Int(fd / 32)
    let bitOffset = fd % 32
    let mask : Int32 = 1 << bitOffset
    switch intOffset {
    case 0: set.fds_bits.0 = set.fds_bits.0 | mask
    case 1: set.fds_bits.1 = set.fds_bits.1 | mask
    case 2: set.fds_bits.2 = set.fds_bits.2 | mask
    case 3: set.fds_bits.3 = set.fds_bits.3 | mask
    case 4: set.fds_bits.4 = set.fds_bits.4 | mask
    case 5: set.fds_bits.5 = set.fds_bits.5 | mask
    case 6: set.fds_bits.6 = set.fds_bits.6 | mask
    case 7: set.fds_bits.7 = set.fds_bits.7 | mask
    case 8: set.fds_bits.8 = set.fds_bits.8 | mask
    case 9: set.fds_bits.9 = set.fds_bits.9 | mask
    case 10: set.fds_bits.10 = set.fds_bits.10 | mask
    case 11: set.fds_bits.11 = set.fds_bits.11 | mask
    case 12: set.fds_bits.12 = set.fds_bits.12 | mask
    case 13: set.fds_bits.13 = set.fds_bits.13 | mask
    case 14: set.fds_bits.14 = set.fds_bits.14 | mask
    case 15: set.fds_bits.15 = set.fds_bits.15 | mask
    case 16: set.fds_bits.16 = set.fds_bits.16 | mask
    case 17: set.fds_bits.17 = set.fds_bits.17 | mask
    case 18: set.fds_bits.18 = set.fds_bits.18 | mask
    case 19: set.fds_bits.19 = set.fds_bits.19 | mask
    case 20: set.fds_bits.20 = set.fds_bits.20 | mask
    case 21: set.fds_bits.21 = set.fds_bits.21 | mask
    case 22: set.fds_bits.22 = set.fds_bits.22 | mask
    case 23: set.fds_bits.23 = set.fds_bits.23 | mask
    case 24: set.fds_bits.24 = set.fds_bits.24 | mask
    case 25: set.fds_bits.25 = set.fds_bits.25 | mask
    case 26: set.fds_bits.26 = set.fds_bits.26 | mask
    case 27: set.fds_bits.27 = set.fds_bits.27 | mask
    case 28: set.fds_bits.28 = set.fds_bits.28 | mask
    case 29: set.fds_bits.29 = set.fds_bits.29 | mask
    case 30: set.fds_bits.30 = set.fds_bits.30 | mask
    case 31: set.fds_bits.31 = set.fds_bits.31 | mask
    default: break
    }
}

/**
 Replacement for FD_CLR macro
 
 - Parameter fd: A file descriptor that offsets the bit to be cleared in the fd_set pointed at by 'set'.
 - Parameter set: A pointer to a fd_set structure.
 
 - Returns: The given set is updated in place, with the bit at offset 'fd' cleared to 0.
 */

public func FD_CLR(_ fd: Int32, set: inout fd_set) {
    let intOffset = Int(fd / 32)
    let bitOffset = fd % 32
    let mask : Int32 = ~(1 << bitOffset)
    switch intOffset {
    case 0: set.fds_bits.0 = set.fds_bits.0 & mask
    case 1: set.fds_bits.1 = set.fds_bits.1 & mask
    case 2: set.fds_bits.2 = set.fds_bits.2 & mask
    case 3: set.fds_bits.3 = set.fds_bits.3 & mask
    case 4: set.fds_bits.4 = set.fds_bits.4 & mask
    case 5: set.fds_bits.5 = set.fds_bits.5 & mask
    case 6: set.fds_bits.6 = set.fds_bits.6 & mask
    case 7: set.fds_bits.7 = set.fds_bits.7 & mask
    case 8: set.fds_bits.8 = set.fds_bits.8 & mask
    case 9: set.fds_bits.9 = set.fds_bits.9 & mask
    case 10: set.fds_bits.10 = set.fds_bits.10 & mask
    case 11: set.fds_bits.11 = set.fds_bits.11 & mask
    case 12: set.fds_bits.12 = set.fds_bits.12 & mask
    case 13: set.fds_bits.13 = set.fds_bits.13 & mask
    case 14: set.fds_bits.14 = set.fds_bits.14 & mask
    case 15: set.fds_bits.15 = set.fds_bits.15 & mask
    case 16: set.fds_bits.16 = set.fds_bits.16 & mask
    case 17: set.fds_bits.17 = set.fds_bits.17 & mask
    case 18: set.fds_bits.18 = set.fds_bits.18 & mask
    case 19: set.fds_bits.19 = set.fds_bits.19 & mask
    case 20: set.fds_bits.20 = set.fds_bits.20 & mask
    case 21: set.fds_bits.21 = set.fds_bits.21 & mask
    case 22: set.fds_bits.22 = set.fds_bits.22 & mask
    case 23: set.fds_bits.23 = set.fds_bits.23 & mask
    case 24: set.fds_bits.24 = set.fds_bits.24 & mask
    case 25: set.fds_bits.25 = set.fds_bits.25 & mask
    case 26: set.fds_bits.26 = set.fds_bits.26 & mask
    case 27: set.fds_bits.27 = set.fds_bits.27 & mask
    case 28: set.fds_bits.28 = set.fds_bits.28 & mask
    case 29: set.fds_bits.29 = set.fds_bits.29 & mask
    case 30: set.fds_bits.30 = set.fds_bits.30 & mask
    case 31: set.fds_bits.31 = set.fds_bits.31 & mask
    default: break
    }
}

/**
 Replacement for FD_ISSET macro
 
 - Parameter fd: A file descriptor that offsets the bit to be tested in the fd_set pointed at by 'set'.
 - Parameter set: A pointer to a fd_set structure.
 
 - Returns: 'true' if the bit at offset 'fd' is 1, 'false' otherwise.
 */

public func FD_ISSET(_ fd: Int32, set: inout fd_set) -> Bool {
    let intOffset = Int(fd / 32)
    let bitOffset = fd % 32
    let mask : Int32 = 1 << bitOffset
    switch intOffset {
    case 0: return set.fds_bits.0 & mask != 0
    case 1: return set.fds_bits.1 & mask != 0
    case 2: return set.fds_bits.2 & mask != 0
    case 3: return set.fds_bits.3 & mask != 0
    case 4: return set.fds_bits.4 & mask != 0
    case 5: return set.fds_bits.5 & mask != 0
    case 6: return set.fds_bits.6 & mask != 0
    case 7: return set.fds_bits.7 & mask != 0
    case 8: return set.fds_bits.8 & mask != 0
    case 9: return set.fds_bits.9 & mask != 0
    case 10: return set.fds_bits.10 & mask != 0
    case 11: return set.fds_bits.11 & mask != 0
    case 12: return set.fds_bits.12 & mask != 0
    case 13: return set.fds_bits.13 & mask != 0
    case 14: return set.fds_bits.14 & mask != 0
    case 15: return set.fds_bits.15 & mask != 0
    case 16: return set.fds_bits.16 & mask != 0
    case 17: return set.fds_bits.17 & mask != 0
    case 18: return set.fds_bits.18 & mask != 0
    case 19: return set.fds_bits.19 & mask != 0
    case 20: return set.fds_bits.20 & mask != 0
    case 21: return set.fds_bits.21 & mask != 0
    case 22: return set.fds_bits.22 & mask != 0
    case 23: return set.fds_bits.23 & mask != 0
    case 24: return set.fds_bits.24 & mask != 0
    case 25: return set.fds_bits.25 & mask != 0
    case 26: return set.fds_bits.26 & mask != 0
    case 27: return set.fds_bits.27 & mask != 0
    case 28: return set.fds_bits.28 & mask != 0
    case 29: return set.fds_bits.29 & mask != 0
    case 30: return set.fds_bits.30 & mask != 0
    case 31: return set.fds_bits.31 & mask != 0
    default: return false
    }
    
}
