//
//  PlanOutOpContext.swift
//  PlanoutKit
//
//  Created by David Christiandy on 06/08/19.
//  Copyright © 2019 Traveloka. All rights reserved.
//

enum PlanOutExpression {
    case operation(op: PlanOutExecutable, args: [String: Any])
    case list([Any])
    case literal(Any)

    init(value: Any) {
        if let dictionaryValue = value as? [String: Any],
            let operation = PlanOutOperation.resolve(dictionaryValue) {
            self = .operation(op: operation, args: dictionaryValue)
        } else if let arrayValue = value as? [Any] {
            self = .list(arrayValue)
        } else {
            self = .literal(value)
        }
    }
}

/// PlanOutOpContext is responsible for storing assignment results and evaluating PlanOut operations.
public protocol PlanOutOpContext: ReadableAssignment {
    /// The experiment salt.
    var experimentSalt: String { get }

    /// Evaluates the given value, and returns the evaluated result(s) if any.
    ///
    /// - If the value is a potential PlanOut operator, then evaluate the operator and return the results.
    /// - If the value is an array, evaluate each element within the array, and return the array with evaluated results.
    /// - Other than the two types above, assume that the value is already a literal; therefore it will be directly returned.
    ///
    /// - Parameter value: The value to be evaluated.
    /// - Returns: Evaluated value, which can be null.
    /// - Throws: OperationError
    @discardableResult
    func evaluate(_ value: Any) throws -> Any?

    /// Registers a variable to the assignment.
    ///
    /// - Parameters:
    ///   - name: The variable name
    ///   - value: The variable value
    func set(_ name: String, value: Any) throws
}
