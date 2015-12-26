//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Frederico Schnekenberg on 10/04/15.
//  Copyright (c) 2015 Frederico Schnekenberg. All rights reserved.
//

// Model

import Foundation
// * Almost never import UIKit into the Model Class, it should be UI independent *

class CalculatorBrain {
    // * It won't inherit from any class. Sometimes we can use NSObject *
    
    private enum Op: CustomStringConvertible {
        // * enum used to selected the type of operation *
        
        case Operand(Double)
        case NullaryOperation(String, () -> Double)
        case UnaryOperation(String, Double -> Double, (Double -> String?)?)
        case BinaryOperation(String, Int, (Double, Double) -> Double, ((Double, Double) -> String?)?)
        case Variable(String)
        
        var description: String {
            // * description was created to convert Optional to String
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .NullaryOperation(let symbol, _):
                    return symbol
                case .UnaryOperation(let symbol, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _, _):
                    return symbol
                case .Variable(let symbol):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            get {
                switch self {
                case .BinaryOperation(_, let precedence, _, _):
                    return precedence
                default:
                    return Int.max
                }
            }
        }
    }
    
    private var opStack = [Op]()
    // * opStack is an Array used to keep track of operands & operations *
    // * Above is the preferred syntax, but we can also use Array<Op>() *
    
    private var knownOps = [String: Op]()
    // * Instance var of type Dictionary for associating operations *
    // * var knownOps = Dictionary<String, Op>() *
    
    var variableValues = [String: Double]()
    // * Instance var of type Dictionay to encounter variables *
    
    private var error: String?
    // * priv property to hold error messages *
    
    init() {
        // * initializer for CalculatorBrain *
        
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        
        learnOp(Op.BinaryOperation("×", 2, *, nil))
        learnOp(Op.BinaryOperation("÷", 2, { $1 / $0 },
            { divisor, _ in return divisor == 0.0 ? "Division by Zero" : nil }))
        learnOp(Op.BinaryOperation("+", 1, +, nil))
        learnOp(Op.BinaryOperation("−", 1, { $1 - $0 }, nil))
        learnOp(Op.UnaryOperation("√", sqrt, { $0 < 0 ? "SQRT of Neg. Number" : nil }))
        learnOp(Op.UnaryOperation("sin", sin, nil))
        learnOp(Op.UnaryOperation("cos", cos, nil))
        learnOp(Op.UnaryOperation("±", { -$0 }, nil))
        learnOp(Op.NullaryOperation("π", { M_PI }))
    }
    
    typealias PropertyList = AnyObject
    var program: PropertyList { // guaranteed to be a PropertyList
        get {
            return opStack.map { $0.description }
            /* All this code can be subed by the one above
            var returnValue = Array<String>()
            for op in opStack {
            returnValue.append(op.description)
            }
            return returnValue */
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                let numberFormatter = NSNumberFormatter()
                // numberFormatter.locale = NSLocaleIdentifier(localeIdentifier: "en_US")
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = numberFormatter.numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    // * Implement a new read-only (get only, no set) var to CalculatorBrain to describe the contents of the brain as a String 
    
    var description: String {
        get {
            var (result, ops) = ("", opStack)
            repeat {
                var current: String?
                (current, ops, _) = description(ops)
                result = result == "" ? current! : "\(current!), \(result)"
            } while ops.count > 0
            return result
        }
    }
    
    private func description(ops: [Op]) -> (result: String?, remainingOps: [Op], precedence: Int?) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (String(format: "%g", operand) , remainingOps, op.precedence)
            case .NullaryOperation(let symbol, _):
                return (symbol, remainingOps, op.precedence);
            case .UnaryOperation(let symbol, _, _):
                let operandEvaluation = description(remainingOps)
                if var operand = operandEvaluation.result {
                    if op.precedence > operandEvaluation.precedence {
                        operand = "(\(operand))"
                    }
                    return ("\(symbol)\(operand)", operandEvaluation.remainingOps, op.precedence)
                }
            case .BinaryOperation(let symbol, _, _, _):
                let op1Evaluation = description(remainingOps)
                if var operand1 = op1Evaluation.result {
                    if op.precedence > op1Evaluation.precedence {
                        operand1 = "(\(operand1))"
                    }
                    let op2Evaluation = description(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return ("\(operand2) \(symbol) \(operand1)",
                            op2Evaluation.remainingOps, op.precedence)
                    }
                }
            case .Variable(let symbol):
                return (symbol, remainingOps, op.precedence)
            }
        }
        return ("?", ops, Int.max)
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        // * Recursively calling evaluate, passing the whole opStack and working with Tuples to get the result and the remainder *
        
        if !ops.isEmpty {
            
            var remainingOps = ops
            // * this var was created cause ops is immutable *
            // * Op is an enum (struct) and structs are passed by value *
            
            let op = remainingOps.removeLast()
            
            switch op {
                
            case .Operand(let operand):
                return (operand, remainingOps)
                
            case .NullaryOperation(_, let operation):
                return (operation(), remainingOps)
                
            case .UnaryOperation(_, let operation, let errorTest):
                // * _ is used to ignore something, we're ignoring the symbol *
                let operandEvaluation = evaluate(remainingOps)
                // * recursively calling evaluate to get the remainigOps *
                if let operand = operandEvaluation.result {
                    // * operand was an Optional, we turned into a double by using let *
                    if let errorMessage = errorTest?(operand) {
                        error = errorMessage
                        return (nil, operandEvaluation.remainingOps)
                    }
                    return (operation(operand), operandEvaluation.remainingOps)
                }
                
            case .BinaryOperation(_, _, let operation, let errorTest):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        if let errorMessage = errorTest?(operand1, operand2) {
                            error = errorMessage
                            return (nil, op2Evaluation.remainingOps)
                        }
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }

            case .Variable(let symbol):
                if let variable = variableValues[symbol] {
                    return (variableValues[symbol], remainingOps)
                }
                error = "Variable Not Set"
                return (nil, remainingOps)
            }
            if error == nil {
                error = "Not Enough Operands"
            }
        }
        return (nil, ops)
        // * if failed, returns nil and the operands *
    }
    
    // function to display operations and operands onto the history label
    func showStack() -> String? {
        return opStack.map{ "\($0)" }.joinWithSeparator(" ")
    }
    
    func evaluate() -> Double? {
        error = nil
        let (result, remainder) = evaluate(opStack)
        // * using Tuples *
        // let (result, _) = evaluate(opStack)
        // println("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    
    func evaluateAndReportErrors() -> AnyObject? {
        let (result, _) = evaluate(opStack)
        return result != nil ? result : error
    }
    
    func pushOperand(operand: Double) -> Double? {
        // * method used to push values into the stack *
        
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        return evaluate()
    }
    
    func popOperand() -> Double? {
        if !opStack.isEmpty {
            opStack.removeLast()
        }
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        // * method used to get the operand and perform the corresponding operation *
        
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
}