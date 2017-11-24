//
//  FileViewController.swift
//  Namdong
//
//  Created by Chris Song on 2017. 9. 5..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit

class FileViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    var request: URLRequest? = nil
    var localPath: URL? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if self.request == nil {
            self.request = URLRequest.init(url: self.localPath!)
        }
        webView.loadRequest(self.request!)
        webView.scrollView.bounces = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeModalView(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
