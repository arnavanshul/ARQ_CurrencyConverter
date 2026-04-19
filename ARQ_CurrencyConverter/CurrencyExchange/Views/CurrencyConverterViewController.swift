//
//  ViewController.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/14/26.
//

import UIKit

protocol CurrencyConverterViewProtocol: AnyObject {
    func showLoading()
    func hideLoading()
    func showErrorMessage(message: String)
    func hideErrorMessage()
    var exchangeView: ExchangeCalculatorView { get }
}

class CurrencyConverterViewController: UIViewController {
    var presenter: ExchangePresenterProtocol? = nil
    
    let exchangeView: ExchangeCalculatorView = {
        let view = ExchangeCalculatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let loader: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.textAlignment = .center
        label.font = .systemFont(ofSize: UIConstants.valueFont.pointSize, weight: .medium)
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(exchangeView)
        view.addSubview(loader)
        view.addSubview(errorLabel)
        
        setupConstraints()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false // Allows buttons to still work
        view.addGestureRecognizer(tap)
        
        presenter?.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {}
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            exchangeView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: UIConstants.containerSpacing),
            exchangeView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            exchangeView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            exchangeView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            // Center the loader in the screen
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Center the error label
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.mainPadding),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(UIConstants.mainPadding)),
            errorLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension CurrencyConverterViewController : CurrencyConverterViewProtocol {
    func showLoading() {
        loader.startAnimating()
        exchangeView.isHidden = true
        errorLabel.isHidden = true
    }
    
    func hideLoading() {
        loader.stopAnimating()
        loader.isHidden = true
    }
    
    func showErrorMessage(message: String) {
        exchangeView.isHidden = true
        loader.stopAnimating()
        loader.isHidden = true
        errorLabel.isHidden = false
        errorLabel.text = message
    }
    
    func hideErrorMessage() {
        errorLabel.isHidden = true
    }
}

