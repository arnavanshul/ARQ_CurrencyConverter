//
//  main.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/20/26.
//

import UIKit

// Detect if XCTestCase is loaded in the process
let isRunningTests = NSClassFromString("XCTestCase") != nil

// Choose the delegate class name
let delegateClass = isRunningTests ?
    NSStringFromClass(UnitTestingAppDelegate.self) :
    NSStringFromClass(AppDelegate.self)

// Start the application
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    delegateClass
)
