# ARQ_CurrencyConverter

Exchange rate calculator iOS app 

## 🚀 Features

* Built using UIKit
* Ability to input values in both input fields. The app automatically converts the other currency
* Fetches the exchange rates from the mentioned API
* Implemented a mock API that returns the currencies for which exchange rates might be available
* Ability to select different currencies
* Ability to swap currencies to get buy and quote prices

## Assumptions

* `USDc` is the base currency
* First time default UI loads with USDc as the base currency and the first currency in the list of exchange rates returned
* The currency picker only shows the list of currencies for which exchange rates are available
* Whenever a new currency is selected, the base currency always remains the same and is treated as the source currency. Based on the position of the other currency (top field or bottom field), the buy or quote price is calculated

## 📁 Project Structure

```text
ARQ_CurrencyConverter/
├── Modules/
│   └── Exchange/
│       ├── Presenter/  # Logic, Formatting, & State Management
│       ├── View/       # Custom InputFields & Rate Labels
│       ├── Interactor/ # API Data Fetching & Business Logic
│       ├── Router/     # Navigation & Picker Presentation
│       └── Entity/     # Ticker & Currency Models
└── UIConstants/        # Centralized Design System
