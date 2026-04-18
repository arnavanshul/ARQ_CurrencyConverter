//
//  ExchangeCalculatorView.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/16/26.
//

import UIKit

class ExchangeCalculatorView: UIView {
    
    // MARK: - UI Components
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = UIConstants.containerSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    let rateLabel: UILabel = {
        let label = UILabel()
        label.text = "---" // Placeholder
        label.font = UIConstants.rateFont
        label.textColor = .systemGreen
        return label
    }()
    
    private lazy var headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = UIConstants.headerSpacing
        
        let titleLabel = UILabel()
        titleLabel.text = "Exchange calculator"
        titleLabel.font = UIConstants.titleFont
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(rateLabel)
        return stack
    }()
    
    private let converterContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    var topCurrencyField = CurrencyInputField(flag: "Fl1", code: "Code1", value: "9,999", symbol: "")
    var bottomCurrencyField = CurrencyInputField(flag: "Fl2", code: "Code2" , value: "184,065.59", symbol: "")
    
    private let swapButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "arrow.down", withConfiguration: config), for: .normal)
        
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = UIConstants.swapButtonRadius
        button.layer.borderWidth = UIConstants.swapButtonBorder
        button.layer.borderColor = UIColor.systemBackground.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var onSwapButtonPressed: (() -> Void)?
    @objc private func handleSwapTap() { onSwapButtonPressed?() }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayout() {
        backgroundColor = .systemBackground
        
        addSubview(containerStackView)
        containerStackView.addArrangedSubview(headerStackView)
        containerStackView.addArrangedSubview(converterContainer)
        
        converterContainer.addSubview(topCurrencyField)
        converterContainer.addSubview(bottomCurrencyField)
        converterContainer.addSubview(swapButton)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: UIConstants.mainPadding),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.mainPadding),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIConstants.mainPadding),
            
            topCurrencyField.topAnchor.constraint(equalTo: converterContainer.topAnchor),
            topCurrencyField.leadingAnchor.constraint(equalTo: converterContainer.leadingAnchor),
            topCurrencyField.trailingAnchor.constraint(equalTo: converterContainer.trailingAnchor),
            
            bottomCurrencyField.topAnchor.constraint(equalTo: topCurrencyField.bottomAnchor, constant: UIConstants.inputVerticalSpacing),
            bottomCurrencyField.leadingAnchor.constraint(equalTo: converterContainer.leadingAnchor),
            bottomCurrencyField.trailingAnchor.constraint(equalTo: converterContainer.trailingAnchor),
            bottomCurrencyField.bottomAnchor.constraint(equalTo: converterContainer.bottomAnchor),
            
            swapButton.centerXAnchor.constraint(equalTo: converterContainer.centerXAnchor),
            // Offset the button slightly so it sits perfectly on the gap
            swapButton.centerYAnchor.constraint(equalTo: topCurrencyField.bottomAnchor, constant: UIConstants.inputVerticalSpacing / 2),
            swapButton.widthAnchor.constraint(equalToConstant: UIConstants.swapButtonSize),
            swapButton.heightAnchor.constraint(equalToConstant: UIConstants.swapButtonSize)
        ])
        
        swapButton.addTarget(self, action: #selector(handleSwapTap), for: .touchUpInside)
    }
}

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
//        textField.text = "\(symbol) \(value)"
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
        
        let mainStack = UIStackView(arrangedSubviews: [currencyStack, textField])
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
