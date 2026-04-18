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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(dismissPicker))
        navigationItem.rightBarButtonItem?.tintColor = .label
    }
    
    @objc private func dismissPicker() {
        dismiss(animated: true)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Choose currency"
        
        // 1. FIX: Register the correct Custom Cell class
        tableView.register(CurrencyPickerCell.self, forCellReuseIdentifier: CurrencyPickerCell.reuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false // Use constraints instead of frames
        
        view.addSubview(tableView)
        
        // 2. FIX: Set constraints to pin the table to the view
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
    
    // Left side: Flag + Code
    private let infoStack: UIStackView = {
        let stack = UIStackView()
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    
    let flagLabel = UILabel() // Use your enum's .flag here
    let codeLabel = UILabel() // Use your enum's .rawValue here
    
    // Right side: The Radio Circle
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
        // Style labels
        codeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        flagLabel.font = .systemFont(ofSize: 24)
        
        contentView.addSubview(infoStack)
        contentView.addSubview(selectionImageView)
        
        infoStack.addArrangedSubview(flagLabel)
        infoStack.addArrangedSubview(codeLabel)
        
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        selectionImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            selectionImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            selectionImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionImageView.widthAnchor.constraint(equalToConstant: 24),
            selectionImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
