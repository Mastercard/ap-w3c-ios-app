//
//  ViewController+.swift
//  CFITestApp
//
//  Created by Ujjwal Chafle on 04/11/19.
//  Copyright © 2021 Mastercard. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(withTitle title:String, andMessage message:String, andActions actions:[UIAlertAction]? = nil) {
        let alertViewController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        if actions == nil {
            alertViewController.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: { (action) in
            }))
        } else {
            alertViewController.addAction(actions![0])
        }
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    func showNoNetworkAlert() {
        self.showAlert(withTitle: "No Network Available", andMessage: "Please check the network settings and try again")
    }
    
    func error() {
        self.showAlert(withTitle: "Error", andMessage: "Please try again")
    }
    
    func showActivityIndicator() {
        guard let window = UIApplication.shared.delegate?.window, window?.viewWithTag(99) == nil else {
            return
        }
        
        DispatchQueue.main.async {
            let activityIndicatorView = UIView.init(frame: UIApplication.shared.keyWindow!.frame)
            activityIndicatorView.tag = 99
            activityIndicatorView.backgroundColor = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
            let imageView = UIImageView.init(frame: CGRect.init(x: (UIApplication.shared.keyWindow!.frame.size.width)/2 - 100, y: (UIApplication.shared.keyWindow!.frame.size.height)/2 - 100, width: 200, height: 100))
            imageView.contentMode = .scaleAspectFit
            let activityView = UIActivityIndicatorView(style: .whiteLarge)
            activityView.center = self.view.center
            activityView.startAnimating()
            activityIndicatorView.addSubview(imageView)
            activityIndicatorView.addSubview(activityView)
            UIApplication.shared.keyWindow!.addSubview(activityIndicatorView)
            UIApplication.shared.keyWindow!.bringSubviewToFront(activityIndicatorView)
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            guard let activityIndicatorView = UIApplication.shared.keyWindow?.viewWithTag(99) else { return }
            activityIndicatorView.removeFromSuperview()
        }
    }
}
