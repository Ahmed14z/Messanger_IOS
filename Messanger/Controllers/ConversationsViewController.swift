//
//  ViewController.swift
//  Messanger
//
//  Created by Ahmed Eslam on 03/03/2023.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .red
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
        
        
     
    }
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil {
        
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav,animated: false)
            
        }
    }
}

