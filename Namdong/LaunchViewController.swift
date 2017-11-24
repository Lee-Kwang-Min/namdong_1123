//
//  LaunchViewController.swift
//  Namdong
//
//  Created by Chris Song on 2017. 9. 4..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit

class LaunchViewControllerr: UIViewController {

    @IBOutlet weak var imageLogo: UIImageView!
    @IBOutlet weak var lbeSubTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let titleInfo = ApplicationData.shared.getLogoWithTitle()
        imageLogo.image  = titleInfo.0
        lbeSubTitle.text = titleInfo.1
    }
}
