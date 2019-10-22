//
//  ViewController.swift
//  SocketChatDemo
//
//  Created by 呼哈哈 on 2019/10/18.
//  Copyright © 2019 piu. All rights reserved.
//
import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var inputField: UITextView!
    @IBOutlet weak var showView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    lazy var client: ChatClient = {
        return ChatClient.init(address: "10.1.1.40", port: 8888, msgCallBack: {(msg : ChatClient.MessageInfo) in
            DispatchQueue.main.async {
                if msg.type == "text"{
                    self.showView.text = self.showView.text.appending(msg.data)
                }else{
                    self.imageView.image = self.image(withString: msg.data)!
                }
            }
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.httpRequest(i:0)
        _ = self.client
    }
    
    func image(withString str : String) -> UIImage? {
        let imgData = Data.init(base64Encoded: str)!
        let img = UIImage.init(data: imgData)
        return img
    }
    
    func httpRequest(i : Int) {
        print("第\(i)次请求开始")
        let host = "apple.com"
        let port:uint16 = 80
        let client = TcpClient.init(address: host, port: port)!
        let connecRet = client.connect()
        if connecRet.isFailure{
            perror(connecRet.error)
        }
        
        let ret = client.send(bytes: [uint8]("GET / HTTP/1.0\n\n".utf8))
        if ret.isSuccess {
            let bytes = client.read(1024 * 3,timeout: nil)
            if bytes == nil{
                perror("read error")
            }else{
                print("第\(i)次请求成功")
            }
        }else{
            perror(ret.error)
        }
    }
    
    @IBAction func sendAction(_ sender: Any) {
        let msg = self.inputField.text;
        if msg == nil {
            return
        }
        DispatchQueue.global().async {
            let ret = self.client.send(message: msg!)
            if ret.isFailure {
                print("send Failed")
            }else{
                print("send Success")
                DispatchQueue.main.async {
                    self.showView.text = self.showView.text.appending(msg!)
                }
            }
        }
    }
}



