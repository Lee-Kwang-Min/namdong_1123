//
//  MainViewController.swift
//  Namdong
//
//  Created by Chris Song on 2017. 8. 1..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit
import Toaster 
import Firebase

class MainViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    var targetUrl = "http://google.com"
    var introViewController: UIViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.scrollView.bounces = false
        webView.backgroundColor = UIColor.white
        
        _ = ApplicationData.shared.getServerUrl()   // 등록용
        // Do any additional setup after loading the view.
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        introViewController = storyboard.instantiateViewController(withIdentifier: "introView")
        self.view.addSubview((introViewController?.view)!)
        
        self.loadWebViewMain()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadNotiUrl), name: NSNotification.Name(rawValue: "UrlNoti"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadNotiUrl), name: NSNotification.Name(rawValue: "TokenChanged"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let url = ApplicationData.shared.reservedUrl {
            let encodedString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let request = URLRequest.init(url: URL(string: encodedString)!)

            webView.loadRequest(request)
            ApplicationData.shared.reservedUrl = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ModalFileViewer" {
            let navi = segue.destination
            let fileView = navi.childViewControllers.last as? FileViewController
            if sender is URLRequest {
                fileView?.request = sender as? URLRequest
            }else if sender is URL {
                fileView?.localPath = sender as? URL
            }
        }
    }
    
    /// Load webview main page
    func loadWebViewMain() {
        let fcmToken = Messaging.messaging().fcmToken
        if fcmToken != nil {
            UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
            UserDefaults.standard.synchronize()
        }
        let userId = ApplicationData.shared.getUserLoginID()
        let isAutoLogin = ApplicationData.shared.isUseAutoLogin()
        
        if isAutoLogin && userId.characters.count > 0 {
            // 자동 로그인
            let requestUrl = ApplicationData.shared.getAutoLoginUrl()
            var request = URLRequest.init(url: URL(string: requestUrl)!)
            
            var postData = ("eTokenId=" + fcmToken! + "&eDevice=I&inpusr=" + userId)
            // menuid나 paramdata가 있을 경우 로그인에 실어서 보냄
            if ApplicationData.shared.menuid != nil || ApplicationData.shared.paramdata != nil {
                if let menuid = ApplicationData.shared.menuid {
                    postData = postData.appendingFormat("&menuid=%@", menuid)
                }
                if let paramdata = ApplicationData.shared.paramdata {
                    postData = postData.appendingFormat("&paramdata=%@", paramdata)
                }
                // menuid가 없고 link_url이 있을 경우 link_url을 호출
            }else if let reservedUrl = ApplicationData.shared.reservedUrl {
                request = URLRequest.init(url: URL.init(string: reservedUrl)!)
                postData = "";
            }else{
                // 그 외는 일반 로그인
            }
            
            if postData.count > 0 {
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = postData.data(using: .utf8)
            }
            
            webView.loadRequest(request)
        }else{
            // 일반 로그인
            if (ApplicationData.shared.paramdata != nil || ApplicationData.shared.menuid != nil || ApplicationData.shared.reservedUrl != nil){
                // 푸시: 무조건 일반 로그인 화면
                let loginUrlString = ApplicationData.shared.getAbsoluteLoginUrl()
                let request = URLRequest.init(url: URL(string: loginUrlString)!)
                webView.loadRequest(request)
            }else{
                // 실행: 메인 또는 로그인화면
                targetUrl = ApplicationData.shared.getNormalLoginUrl()
                var request = URLRequest.init(url: URL(string: targetUrl)!)
                if fcmToken != nil {
                    let body = ("eTokenId=" + fcmToken! + "&eDevice=I")
                    request.httpMethod = "POST"
                    request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    request.httpBody = body.data(using: .utf8)
                }
                webView.loadRequest(request)
            }
        }
        ApplicationData.shared.clearPushData()
    }
    
    func loadNotiUrl(_ noti: Notification){
        let instance = ApplicationData.shared
        if instance.isUseAutoLogin() {
            // AUTO Login
            // menuid나 paramdata가 있을 경우 로그인에 실어서 보냄
            let requestUrl = ApplicationData.shared.getAutoLoginUrl()
            var request = URLRequest.init(url: URL(string: requestUrl)!)
            
            var postData = ""
            // menuid나 paramdata가 있을 경우 로그인에 실어서 보냄
            if ApplicationData.shared.menuid != nil || ApplicationData.shared.paramdata != nil {
                if let menuid = ApplicationData.shared.menuid {
                    postData = postData.appendingFormat("&menuid=%@", menuid)
                }
                if let paramdata = ApplicationData.shared.paramdata {
                    postData = postData.appendingFormat("&paramdata=%@", paramdata)
                }
                // menuid가 없고 link_url이 있을 경우 link_url을 호출
            }else if let reservedUrl = ApplicationData.shared.reservedUrl {
                request = URLRequest.init(url: URL.init(string: reservedUrl)!)
                postData = "";
            }
            
            if postData.count > 0 {
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = postData.data(using: .utf8)
            }
            
            webView.loadRequest(request)
        }else{
            // Not Auto Login
            if let requestUrl = ApplicationData.shared.reservedUrl
            {
                let request = URLRequest.init(url: URL(string: requestUrl)!)
                webView.loadRequest(request)
            }
        }
        ApplicationData.shared.clearPushData()
    }
    
    /// Function caller
    ///
    /// - Parameter url: Scheme url
    /// - Returns: Result of processing.
    func callFunc(_ url: String?) -> Bool{
        let funcPrefix = "jscall://"
        let intentPrefix = "intent://"
        if let urlString = url, urlString.hasPrefix(funcPrefix) {
            let subString = urlString.substring(from: funcPrefix.endIndex)
            var funcName = ""
            var funcBody = Dictionary<String, String>()
            if subString.contains("?") {
                let funcArray = subString.components(separatedBy: "?")
                funcName = funcArray[0]
                let bodies = funcArray[1].components(separatedBy: "&")
                
                for row in bodies {
                    let result  = row.components(separatedBy: "=")
                    let key     = result[0].trimmingCharacters(in: NSCharacterSet.whitespaces)
                    let value   = result[1].trimmingCharacters(in: NSCharacterSet.whitespaces)
                    funcBody.updateValue(value, forKey: key)
                }
            }else{
                funcName = subString;
            }
            
            switch funcName {
            case "showToast":
                showToast(message: funcBody["message"]!)
                
            case "showAlertDialog":
                showDialog(title: funcBody["title"]!, message: funcBody["message"]!)
                
            case "mainPageReload":
                self.loadWebViewMain()
                
            default:
                break
            }
            
            return false;
        }
        
        if let urlString = url, urlString.hasPrefix(intentPrefix) {
            let subString = urlString.substring(from: funcPrefix.endIndex)
            var urlString = ""
            var platformName = ""
            var installUrlString = ""
            switch subString {
            case "com.kakao.talk":
                platformName = NSLocalizedString("KakaoTalk", comment: "App name KakaoTalk")
                urlString = "kakaolink://"
                installUrlString = "https://itunes.apple.com/kr/app/%EC%B9%B4%EC%B9%B4%EC%98%A4%ED%86%A1-kakaotalk/id362057947?mt=8"
                break
            case "com.facebook.katana":
                platformName = NSLocalizedString("Facebook", comment: "App name Facebook")
                urlString = "fb://"
                installUrlString = "https://itunes.apple.com/kr/app/facebook/id284882215?mt=8"
                break
            case "com.tencent.mm":
                platformName = NSLocalizedString("WeChat", comment: "App name WeChat")
                urlString = "weixin://"
                installUrlString = "https://itunes.apple.com/kr/app/wechat/id414478124?mt=8"
                break
                
            default:
                break
            }
            
            self.openUrl(urlString) { (isOpenable) in
                if !isOpenable {
                    let alertController = UIAlertController.init(title: NSLocalizedString("Open failed", comment: ""), message: String.init(format: NSLocalizedString("Can't open %@. Install the app for use this function.", comment: ""), platformName), preferredStyle: .alert)
                    let actionCancel = UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil)
                    let actionInstall = UIAlertAction.init(title: NSLocalizedString("Appstore", comment: ""), style: .default, handler: { (aletAction) in
                        self.openUrl(installUrlString)
                    })
                    alertController.addAction(actionCancel)
                    alertController.addAction(actionInstall)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            
            return false;
        }
        
        
        return true;
    }
    
    /// Content Opener
    ///
    /// - Parameter request: webview url request
    /// - Returns: is content url
    func openUrlByFileViewer(request: URLRequest) -> Bool{
        let isGoogle = request.url?.absoluteString.contains("drive.google.com")
        let isBlCopy = request.url?.absoluteString.contains("prtCopyBl.do")
        let isBooked = request.url?.absoluteString.contains("prtBookingSheet.do")
        let isInvoic = request.url?.absoluteString.contains("prtInvoice.do")
        let isExFree = request.url?.absoluteString.contains("prtExFreetime.do")
        let isArrive = request.url?.absoluteString.contains("prtArrivalNotice.do")
        let isFrmemo = request.url?.absoluteString.contains("prtFreightMemo.do")
        
        let result = (isGoogle == true || isBlCopy == true || isBooked == true || isInvoic == true || isExFree == true || isArrive == true || isFrmemo == true)
        if result {
            // 새 창
            self.performSegue(withIdentifier: "ModalFileViewer", sender: request)
        }
        return !result
    }
    
    /// Content Downloader
    ///
    /// - Parameter request: webview url request
    /// - Returns: is download
    func downloadFrom(request: URLRequest) -> Bool{
        let result = request.url?.absoluteString.contains("downloadFile.json")
        if result! {
            let session = URLSession.shared
            Toast.init(text: "Downloading").show()
            let task = session.dataTask(with: request) {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    if (statusCode == 200){
                        let fileName = httpResponse.suggestedFilename
                        // get document path
                        do {
                            let fManager = FileManager.default
                            let docPath = try fManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                            let filePath = docPath.appendingPathComponent(fileName!)
                            if (fManager.fileExists(atPath: filePath.path)){
                                try fManager.removeItem(at: filePath)
                            }
                            try data?.write(to: filePath)
                            
                            // open
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "ModalFileViewer", sender: filePath)
                            }
                        }catch{
                            // file save error
                            Toast.init(text: "Unknown error occur. try again.").show()
                        }
                        
                        Toast.init(text: "Download complete").show()
                    }else{
                        Toast.init(text: "Unknown error occur. try again.").show()
                    }
                }
            }
            task.resume()
        }
        
        return !result!
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
    
    /// Show Toast
    ///
    /// - Parameter message: Message to be shown on toast
    func showToast(message: String){
        let toast = Toast(text: message)
        toast.show()
    }
    
    /// Show Dialog
    ///
    /// - Parameters:
    ///   - title: Title to be shown on alert box
    ///   - message: Message to be shown on alert box
    func showDialog(title: String, message: String){
        let controller = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK button"), style: .default, handler: nil);
        controller.addAction(actionOK)
        self.present(controller, animated: true, completion: nil);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UIWebView Delegate
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if introViewController != nil {
            introViewController?.view.removeFromSuperview()
            introViewController = nil
        }
        
        guard let request = webView.request else { return }
        
        let cachedUrlResponse = URLCache.shared.cachedResponse(for: request)
        let httpUrlResponse = cachedUrlResponse?.response as? HTTPURLResponse
        if let statusCode = httpUrlResponse?.statusCode {
            if statusCode == 404 {
                // Handling 404 response
                do{
                    let htmlPath = Bundle.main.path(forResource: "notFound", ofType: "html");
                    let htmlString = try String.init(contentsOfFile: htmlPath!, encoding: String.Encoding.utf8)
                    
                    webView.loadHTMLString(htmlString, baseURL: nil)
                }catch{
                    NSLog("HTML File load error")
                }
            }
        }
        
        ApplicationData.shared.saveCookieData()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var result = callFunc(request.url?.absoluteString)
        
        if result == true{
            result = self.openUrlByFileViewer(request: request)
        }
        if result == true{
            result = self.downloadFrom(request: request)
        }
        
        return result
    }
    
}
