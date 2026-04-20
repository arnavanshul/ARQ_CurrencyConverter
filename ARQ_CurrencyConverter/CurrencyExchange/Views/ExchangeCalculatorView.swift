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
        titleLabel.text = NSLocalizedString("exchange_calculator_title", value: "Exchange calculator", comment: "Title for exchange calculator view")
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
