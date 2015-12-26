//
//  ViewController.swift
//  Calculator
//
//  Created by Frederico Schnekenberg on 10/04/15.
//  Copyright (c) 2015 Frederico Schnekenberg. All rights reserved.
//

// Controller

import UIKit

class ViewController: UIViewController
{
    // property for the display label
    @IBOutlet weak var display: UILabel!
    // property for displaying history of operations and operands
    @IBOutlet weak var history: UILabel!
    // property do append decimal digit
    @IBOutlet weak var decimalButton: UIButton!
    
    // boolean to check if user is typing
    var userIsInTheMiddleOfTypingNumber = false
    
    // Decimal separator formatter
    let decimalSeparator = NSNumberFormatter().decimalSeparator
    
    // Instance variable
    var brain = CalculatorBrain()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        decimalButton.setTitle(decimalSeparator, forState: UIControlState.Normal)
        display.text = " "
    }
    
    // function to display the digit on the screen
    @IBAction func appendDigit(sender: UIButton) {
        
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleOfTypingNumber {
            if (digit == decimalSeparator) && (display.text!.rangeOfString(decimalSeparator!) != nil) { return }
            if (digit == "0") && ((display.text == "0") || (display.text == "-0")) { return }
            if (digit != decimalSeparator) && ((display.text == "0") || (display.text == "-0")) {
                if (display.text == "0") {
                    display.text = digit
                } else {
                    display.text = "-" + digit
                }
            } else {
                display.text = display.text! + digit
            }
        } else {
            if digit == decimalSeparator {
                display.text = "0" + decimalSeparator!
            } else {
                display.text = digit
            }
            userIsInTheMiddleOfTypingNumber = true
            history.text = brain.description != "?" ? brain.description : ""
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        
        if let operation = sender.currentTitle {
            if userIsInTheMiddleOfTypingNumber {
                if operation == "±" {
                    let displayText = display.text!
                    if (displayText.rangeOfString("-") != nil) {
                        display.text = String(displayText.characters.dropFirst())
                    } else {
                        display.text = "-" + displayText
                    }
                    return
                }
                enter()
            }
            if let result = brain.performOperation(operation) {
                displayValue = result
            } else {
                // error?
                displayValue = nil
            }
        }
    }
    
    @IBAction func storeVariable(sender: UIButton) {
        if let variable = (sender.currentTitle!).characters.last {
            if displayValue != nil {
                brain.variableValues["\(variable)"] = displayValue
                if let result = brain.evaluate() {
                    displayValue = result
                } else {
                    displayValue = nil
                }
            }
        }
        userIsInTheMiddleOfTypingNumber = false
    }
    
    @IBAction func pushVariable(sender: UIButton) {
        if userIsInTheMiddleOfTypingNumber {
            enter()
        }
        if let result = brain.pushOperand(sender.currentTitle!) {
            displayValue = result
        } else {
            displayValue = nil
        }
    }
    
    @IBAction func enter()
    {
        userIsInTheMiddleOfTypingNumber = false
        if displayValue != nil {
            if let result = brain.pushOperand(displayValue!) {
                displayValue = result
            } else {
                // error?
                displayValue = nil
            }
        }
    }
    
    @IBAction func clear(sender: UIButton) {
        brain = CalculatorBrain()
        displayValue = nil
        history.text = ""
    }
    
    // When user is in the middle of typing, it's a backspace button
    // When not, it acts as an Undo button
    @IBAction func backSpace(sender: UIButton) {
        if userIsInTheMiddleOfTypingNumber {
            let displayText = display.text!
            if displayText.characters.count > 1 {
                display.text = String(displayText.characters.dropLast())
                if (displayText.characters.count == 2) && (display.text?.rangeOfString("-") != nil) {
                    display.text = "-0"
                }
            } else {
                display.text = "0"
            }
        } else {
            if let result = brain.popOperand() {
                displayValue = result
            } else {
                displayValue = nil
            }
        }
    }
    
    var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)?.doubleValue
        }
        set {
            if (newValue != nil) {
                let numberFormatter = NSNumberFormatter()
                numberFormatter.numberStyle = .DecimalStyle
                numberFormatter.maximumFractionDigits = 10
                display.text = numberFormatter.stringFromNumber(newValue!)
            } else {
                if let result = brain.evaluateAndReportErrors() as? String {
                    display.text = result
                } else {
                    display.text = " "
                }
            }
            userIsInTheMiddleOfTypingNumber = false
            history.text = brain.description != "" ? brain.description + " =" : ""
        }
    }
    
}