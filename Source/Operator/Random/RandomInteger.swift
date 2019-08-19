//
//  RandomInteger.swift
//  PlanoutKit
//
//  Created by David Christiandy on 14/08/19.
//  Copyright © 2019 Traveloka. All rights reserved.
//

extension PlanOutOperation {
    // Generate deterministically random integer based on given unit.
    final class RandomInteger: PlanOutOpRandom<Int> {

        override func randomExecute() throws -> Int? {
            guard let minValue = args[Keys.min.rawValue], case let Literal.number(minNumber) = Literal(minValue),
                let maxValue = args[Keys.max.rawValue], case let Literal.number(maxNumber) = Literal(maxValue) else {
                    throw OperationError.missingArgs(args: "\(Keys.min.rawValue),\(Keys.max.rawValue)", type: self)
            }

            let minInt = Int(minNumber)
            let maxInt = Int(maxNumber)

            return minInt + (try hash() % (maxInt - minInt + 1))
        }

        /// Convenience method that runs the operation with only the minimum required arguments.
        ///
        /// - Parameters:
        ///   - minValue: Minimum integer value
        ///   - maxValue: Maximum integer value
        ///   - unit: The primary unit used for hashing
        /// - Returns: Random integer based on hashed value
        static func quickEval(min minValue: Int, max maxValue: Int, unit: String) -> Int? {
            let args: [String: Any] = [
                Keys.min.rawValue: minValue,
                Keys.max.rawValue: maxValue,
                Keys.unit.rawValue: unit,
                Keys.salt.rawValue: "x" // uses arbitrary string as salt.
            ]

            return try? self.init().execute(args, Interpreter())
        }
    }
}