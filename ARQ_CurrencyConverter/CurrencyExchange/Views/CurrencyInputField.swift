//
//  CurrencyInputField.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/20/26.
//

import UIKit

class CurrencyInputField: UIView {
    var showChevron: Bool = true
    var flag: String
    var code: String
    var value: String
    var symbol: String
    
    let currencyLabel: UILabel = {
        let currencyLabel = UILabel()
        currencyLabel.text = "Flag Code"
        currencyLabel.font = UIConstants.currencyLabelFont
        return currencyLabel
    }()
    
    let chevron: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: UIConstants.inputVerticalSpacing, weight: .bold)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: config))
        chevron.tintColor = .secondaryLabel
        chevron.contentMode = .scaleAspectFit
        return chevron
    }()
    
    let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = UIConstants.valueFont
        
        return label
    }()
    
    let textField: UITextField = {
        let tf = UITextField()
        tf.textAlignment = .right
        tf.font = UIConstants.valueFont
        tf.keyboardType = .decimalPad
        return tf
    }()
    var onAmountChanged: ((String) -> Void)?
    var isChangingAmount: Bool { return textField.isEditing }
    
    private let selectionButton = UIButton(type: .system)
    var onCurrencyPressed: (() -> Void)?
    
    required init?(coder: NSCoder) { fatalError() }
    
    init(flag: String, code: String, value: String, symbol: String, showChevron: Bool = true) {
        self.flag = flag
        self.code = code
        self.value = value
        self.symbol = symbol
        self.showChevron = showChevron
        
        super.init(frame: .zero)
        
        setupUI()
    }
    
    func updateFor(flag: String, code: String, value: String, symbol: String, showChevron: Bool) {
        self.flag = flag
        self.code = code
        self.value = value
        self.symbol = symbol
        self.showChevron = showChevron
        
        currencyLabel.text = "\(flag) \(code)"
        chevron.isHidden = !showChevron
        symbolLabel.text = symbol
        textField.text = value
    }
    
    @objc private func textDidChange(_ textField: UITextField) {
        onAmountChanged?(textField.text ?? "")
    }
    
    @objc private func handleTap() {
        onCurrencyPressed?()
    }
}

//  MARK: `CurrencyInputField` Layout and rendering
extension CurrencyInputField {
    func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = UIConstants.cornerRadiusLarge
        
        let currencyStack = UIStackView(arrangedSubviews: [currencyLabel])
        currencyStack.spacing = UIConstants.headerSpacing
        currencyStack.alignment = .center
        currencyStack.distribution = .fill
        
        NSLayoutConstraint.activate([
            currencyStack.widthAnchor.constraint(equalToConstant: 88)
        ])
        
        textField.text = value
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.addTarget(self, action: #selector(textDidChange), for: .editingDidEnd)
        
        let valueStack = UIStackView(arrangedSubviews: [symbolLabel, textField])
        valueStack.spacing = UIConstants.symbolValueSpacing
        valueStack.alignment = .center
        valueStack.distribution = .fill
        
        let mainStack = UIStackView(arrangedSubviews: [currencyStack, valueStack])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.alignment = .center
        mainStack.distribution = .equalSpacing
        
        addSubview(mainStack)
        
        if showChevron {
            currencyStack.addArrangedSubview(chevron)
            setupTapOverlay(over: currencyStack)
        }
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.inputInnerPadding),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIConstants.inputInnerPadding),
            mainStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            self.heightAnchor.constraint(equalToConstant: UIConstants.inputFieldHeight)
        ])
    }
    
    func setupTapOverlay(over view: UIView) {
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionButton)
        selectionButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            selectionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectionButton.topAnchor.constraint(equalTo: topAnchor),
            selectionButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
