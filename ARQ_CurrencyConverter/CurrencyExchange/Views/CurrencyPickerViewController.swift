//
//  CurrencyPickerViewController.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/17/26.
//

import Foundation
import UIKit

class CurrencyPickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var currencies: [Ticker] = []
    var selectedCurrencyCode: String?
    var onCurrencySelected: ((Ticker) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"),
//                                                            style: .plain,
//                                                            target: self,
//                                                            action: #selector(dismissPicker))
//        navigationItem.rightBarButtonItem?.tintColor = .label
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @objc private func dismissPicker() {
        dismiss(animated: true)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        tableView.register(CurrencyPickerCell.self, forCellReuseIdentifier: CurrencyPickerCell.reuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false // Use constraints instead of frames
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }
    
    // MARK: - TableView Header Styling
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerContainer = UIView()
        headerContainer.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "Choose currency"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.backgroundColor = .clear
        label.textColor = .label
        
        let closeButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        closeButton.tintColor = .label
        closeButton.backgroundColor = .secondarySystemBackground
        closeButton.layer.cornerRadius = 15
        
        // Add the action
        closeButton.addTarget(self, action: #selector(dismissPicker), for: .touchUpInside)
        
        // 3. Arrange them in a Stack
        let stackView = UIStackView(arrangedSubviews: [label, closeButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        headerContainer.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            // Standard button sizing
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Pin stack to container with padding
            stackView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: UIConstants.mainPadding),
            stackView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -UIConstants.mainPadding),
            stackView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: UIConstants.mainPadding),
            stackView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -(UIConstants.mainPadding))
        ])
        
        return headerContainer
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 80
    }

    // MARK: - TableView data population
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CurrencyPickerCell.reuseIdentifier, for: indexPath) as? CurrencyPickerCell else {
            return UITableViewCell()
        }
        
        let ticker = currencies[indexPath.row]
        
        // Use your model's helper to get the Currency enum
        if let currency = ticker.currency {
            cell.flagLabel.text = currency.flag
            cell.codeLabel.text = currency.rawValue
            
            // Check if this is the currently selected currency
            let isSelected = (currency.rawValue == selectedCurrencyCode)
            
            if isSelected {
                cell.selectionImageView.image = UIImage(systemName: "checkmark.circle.fill")
                cell.selectionImageView.tintColor = .systemGreen
            } else {
                cell.selectionImageView.image = UIImage(systemName: "circle")
                cell.selectionImageView.tintColor = .systemGray4
            }
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onCurrencySelected?(currencies[indexPath.row])
        dismiss(animated: true)
    }
}

class CurrencyPickerCell: UITableViewCell {
    static let reuseIdentifier = "CurrencyCell"
    
    private let infoStack: UIStackView = {
        let stack = UIStackView()
        stack.spacing = UIConstants.inputVerticalSpacing
        stack.alignment = .center
        return stack
    }()
    
    let flagLabel = UILabel()
    let codeLabel = UILabel()
    
    let selectionImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    private func setupLayout() {
        codeLabel.font = UIConstants.currencyLabelFont
        flagLabel.font = UIConstants.titleFont
        
        contentView.addSubview(infoStack)
        contentView.addSubview(selectionImageView)
        
        infoStack.addArrangedSubview(flagLabel)
        infoStack.addArrangedSubview(codeLabel)
        
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        selectionImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.mainPadding),
            infoStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            selectionImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -(UIConstants.mainPadding)),
            selectionImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionImageView.widthAnchor.constraint(equalToConstant: UIConstants.containerSpacing),
            selectionImageView.heightAnchor.constraint(equalToConstant: UIConstants.containerSpacing)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
