//
//  LoginViewController.swift
//  Messanger
//
//  Created by Ahmed Eslam on 03/03/2023.
//

import UIKit
import FirebaseAuth
import FacebookLogin
import FacebookCore
class LoginViewController: UIViewController {
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    private let PasswordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let loginButton : UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private  let facebookLoginButton:FBLoginButton  = {
        let button = FBLoginButton()
        button.permissions = ["email,public_profile"]
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        PasswordField.delegate = self
        
        facebookLoginButton.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(PasswordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 60,
                                 width: size, height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+20,
                                  width: scrollView.width-60    , height: 52)
        PasswordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60    , height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: PasswordField.bottom+10,
                                   width: scrollView.width-60    , height: 52)
        facebookLoginButton.frame = CGRect(x: 30,
                                           y: loginButton.bottom+10,
                                           width: scrollView.width-60    , height: 52)
        facebookLoginButton.center = scrollView.center
        facebookLoginButton
            .frame.origin.y = loginButton.bottom+20
        
        
    }
    
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        PasswordField.resignFirstResponder()
        guard let email = emailField.text, let password = PasswordField.text,!email.isEmpty,!password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        //FireBase Login
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password,completion:  { [weak self] authResult, error in
            guard let strongSelf = self else{
                return
            }
            guard let result = authResult,error == nil else {
                print("Failed to log in with email : \(email)")
                return
            }
            let user = result.user
            print("Logged In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true,completion: nil)
        })
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Oops", message: "Please enter all information to log in.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel,handler: nil))
        
        present(alert,animated: true)
        
        
        
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            PasswordField.becomeFirstResponder()
        }else if textField == PasswordField {
            loginButtonTapped()
        }
        return true
    }
}

extension LoginViewController : LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        
        let facebookRequest = FacebookCore.GraphRequest(graphPath: "me", parameters: ["fields":"email, name"], tokenString: token, version: nil, httpMethod: .get)
        
        
        facebookRequest.start(completionHandler: {_,result,error in
            guard let result = result as? [String: Any],
                  error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            guard let userName = result["name"] as? String,
                  let email = result["email"] as? String else {
                print("Failed to get email and name from fb result")
                return
            }
            let nameComponents = userName.components(separatedBy: " ")
            guard nameComponents.count == 2 else {
                return
            }
            
            let firstName = nameComponents[0]
            let lastName = nameComponents[1]
            
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email))
                }
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential , completion: {[weak self]authResult , error in
                guard let strongSelf = self else {
                    return
                }
                guard   authResult != nil,error == nil else{
                    if let error = error {
                        print("Facebook credential login failed , MFA may be needed - \(error)")
                        
                    }
                    return
                }
                print("Successfully logged user in")
                strongSelf.navigationController?.dismiss(animated: true,completion: nil)
                
            })
        })
        
        
    }
    
    
}
