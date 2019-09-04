//
//  ViewController.swift
//  SpamFilter
//
//  Created by liangaiwu on 2019/9/3.
//  Copyright © 2019 liangaiwu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var emailFileNameLabel: UILabel!
    @IBOutlet weak var emailTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadText()
    }
    
    
    /// 载入测试数据
    func loadText() {
        let randIndex = (arc4random() % 25) + 1
        let fileName = (arc4random() % 2) == 0 ? "ham\(randIndex)" : "spam\(randIndex)"
        
        guard let path = Bundle.main.path(forResource:fileName, ofType:"txt"), let text = try? String(contentsOfFile:path, encoding: String.Encoding.utf8) else {
            return
        }
        self.emailTextView.text = text
        emailFileNameLabel.text = "测试邮件名称：" + fileName
    }
    
    @IBAction func checkEmailAction(_ sender: Any) {
        let title = CheckEmail(email: emailTextView.text) ? "当前邮件是垃圾邮件" : "当前邮件不是垃圾邮件"
        let alertVC = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "我知道了", style: .default, handler: { [weak self] (action) in
            self?.loadText()
        }))
        self.present(alertVC, animated: true, completion: nil)
    }
    
}

