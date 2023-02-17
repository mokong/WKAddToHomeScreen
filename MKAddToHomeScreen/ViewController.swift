//
//  ViewController.swift
//  MKAddToHomeScreen
//
//  Created by MorganWang on 2021/4/22.
//

import UIKit
import Swifter

class ViewController: UIViewController {
    lazy var server = HttpServer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        server.stop()
    }
    
    
    @IBAction func addMethod1(_ sender: Any) {
        // 方法一，不需要本地放H5数据，只需要打开指定URL即可
        // 可使用mocky来提供模拟接口
        let urlStr = "https://run.mocky.io/v3/237ebeb3-7f10-48b9-b345-eb2623669b46"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func addMethod2(_ sender: Any) {
        // 定义好的URL Scheme
        let schemeStr = "mkaddtohomescreen://page/view2"
        // 要替换的桌面快捷方式图标
        let shortcutImageData = UIImage(named: "homescreen")?.jpegData(compressionQuality: 0.5)
        // 要替换的桌面快捷方式标题
        let shortcutTitle = "方法二标题"

        guard  let schemeURL = URL(string: schemeStr),
               let shortcutImageStr = shortcutImageData?.base64EncodedString() else {
            return
        }

        // 替换H5中的内容
        let htmlStr = htmlFor(title: shortcutTitle, urlToRedirect: schemeURL.absoluteString, icon: shortcutImageStr)

        guard let base64 = htmlStr.data(using: .utf8)?.base64EncodedString() else {
            return
        }

        // 启动本地服务器，端口号是9081
        if let shortcutUrl = URL(string: "http://localhost:9081/s") {
            // 转为dataURI格式
            let server = HttpServer()
            server["/s"] = { request in
                return .movedPermanently("data:text/html;base64,\(base64)")
            }
            try? server.start(9081)
            UIApplication.shared.open(shortcutUrl, options: [:], completionHandler: nil)
        }
    }
    
    
    @IBAction func addMethod3(_ sender: Any) {
        let urlStr = "https://run.mocky.io/v3/9631f29a-6781-4713-a481-f29eab9bc78b"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func htmlFor(title: String, urlToRedirect: String, icon: String) -> String {
        let shortcutsPath = Bundle.main.path(forResource: "content2", ofType: "html")
        
        var shortcutsContent = try! String(contentsOfFile: shortcutsPath!) as String
        shortcutsContent = shortcutsContent.replacingOccurrences(of: "\\(title)", with: title)
        shortcutsContent = shortcutsContent.replacingOccurrences(of: "\\(urlToRedirect.absoluteString)", with: urlToRedirect)
        shortcutsContent = shortcutsContent.replacingOccurrences(of: "\\(feature_icon)", with: icon)

        print(shortcutsContent)
        return shortcutsContent
    }


}

