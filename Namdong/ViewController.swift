//
//  ViewController.swift
//  Namdong
//
//  Created by Chris Song on 2017. 7. 31..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit

public typealias CompletionHandler = (_ isOpenable: Bool) -> Void

class ViewController: UIViewController {
    
    @IBOutlet weak var imageIntro: UIImageView!
    var fcmReceiver: NSObjectProtocol? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.fcmReceiver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "TokenChanged2"), object: nil, queue: nil) { (notification) in
            // push to new view
            self.performSegue(withIdentifier: "showWeb", sender: nil)
        }
        
        let introImage = ApplicationData.shared.getIntroImage()
        imageIntro.image = introImage
        
        if ApplicationData.shared.isFirstInit == false {
            ApplicationData.shared.isFirstInit = true;
            var time = DispatchTime.now() + 5
            var fcmToken = UserDefaults.standard.object(forKey: "fcmToken")
            
            // Generate randome FCM Code for china
            let contryCode = Locale.current.regionCode
            if contryCode == "CN" && fcmToken == nil {
                fcmToken = ApplicationData.shared.randomString(length: 48)
            }
            // TODO: 시뮬레이터에서 테스트 할경우 임시 토큰이 발행됩니다.
            //#if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            //    if fcmToken == nil {
            //        fcmToken = ApplicationData.shared.randomString(length: 48)
            //    }
            //#endif
            
            if fcmToken != nil {
                time = DispatchTime.now() + 1
                
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self.performSegue(withIdentifier: "showWeb", sender: nil)
                }
            }else{
                // wait 10sec while receiving fcm token
                time = DispatchTime.now() + 30
                DispatchQueue.main.asyncAfter(deadline: time) {
                    if (ApplicationData.shared.fcmToken.count < 1)
                    {
                        let alertController = UIAlertController.init(title: "", message: "Check the network status and try again.", preferredStyle: .alert)
                        let actionOK = UIAlertAction.init(title: "OK", style: .cancel, handler: { (alert) in
                            exit(0)
                        })
                        alertController.addAction(actionOK)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // remove observer
        NotificationCenter.default.removeObserver(fcmReceiver as Any)
        fcmReceiver = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! MainViewController
        if sender != nil {
            let array = sender as! Array<String>
            viewController.title = array[0]
            viewController.targetUrl = array[1]
        }
    }
    
    /// Url Openner
    ///
    /// - Parameters:
    ///   - urlString: url string
    ///   - completion: call back closure
    func openUrl(_ urlString: String, _ completion: CompletionHandler? = nil){
        guard let url = URL(string: urlString) else {
            return
        }
    
        let openable = UIApplication.shared.canOpenURL(url)
        if openable {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: { (finished) in
                    
                })
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url)
            }
        }
        
        if (completion != nil) {
            completion!(openable)
        }
    }
}

