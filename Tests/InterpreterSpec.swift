//
//  InterpreterSpec.swift
//  PlanOutKitTests
//
//  Created by David Christiandy on 17/08/19.
//  Copyright © 2019 Traveloka. All rights reserved.
//

import Quick
import Nimble
@testable import PlanOutKit

final class InterpreterSpec: QuickSpec {
    override func spec() {
        describe("Interpreter") {
            it("has to be able to create interpreter and get params") {
                let jsonScript = "{\"op\":\"seq\",\"seq\":[{\"op\":\"set\",\"var\":\"group_size\",\"value\":{\"choices\":{\"op\":\"array\",\"values\":[1,10]},\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"uniformChoice\"}},{\"op\":\"set\",\"var\":\"specific_goal\",\"value\":{\"p\":0.8,\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"bernoulliTrial\"}},{\"op\":\"cond\",\"cond\":[{\"if\":{\"op\":\"get\",\"var\":\"specific_goal\"},\"then\":{\"op\":\"seq\",\"seq\":[{\"op\":\"set\",\"var\":\"ratings_per_user_goal\",\"value\":{\"choices\":{\"op\":\"array\",\"values\":[8,16,32,64]},\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"uniformChoice\"}},{\"op\":\"set\",\"var\":\"ratings_goal\",\"value\":{\"op\":\"product\",\"values\":[{\"op\":\"get\",\"var\":\"group_size\"},{\"op\":\"get\",\"var\":\"ratings_per_user_goal\"}]}}]}}]}]}"
                var serialization: [String: Any]
                if let script = jsonScript.data(using: .utf8),
                    let data = try? JSONSerialization.jsonObject(with: script) as? [String: Any] {
                    serialization = data
                } else {
                    serialization = [:]
                }
                let interpreter = Interpreter(serialization: serialization, salt: "foo", unit: Unit(keys: ["userid"], inputs: ["userid": "123454"]))
                // This script is should not throw error yet it is
                expect { try interpreter.getParams() }.notTo(throwError())
                expect { try interpreter.getParams() }.notTo(beNil())
                expect { try interpreter.get("specific_goal") as? Bool }.to(beTrue())
            }
            
            it("should be able to override when the value is valid.") {
                let jsonScript = "{\"op\":\"seq\",\"seq\":[{\"op\":\"set\",\"var\":\"group_size\",\"value\":{\"choices\":{\"op\":\"array\",\"values\":[1,10]},\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"uniformChoice\"}},{\"op\":\"set\",\"var\":\"specific_goal\",\"value\":{\"p\":0.8,\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"bernoulliTrial\"}},{\"op\":\"cond\",\"cond\":[{\"if\":{\"op\":\"get\",\"var\":\"specific_goal\"},\"then\":{\"op\":\"seq\",\"seq\":[{\"op\":\"set\",\"var\":\"ratings_per_user_goal\",\"value\":{\"choices\":{\"op\":\"array\",\"values\":[8,16,32,64]},\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"uniformChoice\"}},{\"op\":\"set\",\"var\":\"ratings_goal\",\"value\":{\"op\":\"product\",\"values\":[{\"op\":\"get\",\"var\":\"group_size\"},{\"op\":\"get\",\"var\":\"ratings_per_user_goal\"}]}}]}}]}]}"
                var serialization: [String: Any]
                if let script = jsonScript.data(using: .utf8),
                    let data = try? JSONSerialization.jsonObject(with: script) as? [String: Any] {
                    serialization = data
                } else {
                    serialization = [:]
                }
                
                let interpreter = Interpreter(serialization: serialization, salt: "foo", unit: Unit(keys: ["userid"], inputs: ["userid": "123454"], overrides: ["specific_goal": false]))
                // This script is should not throw error yet it is
                expect { try interpreter.getParams() }.notTo(throwError())
                expect { try interpreter.getParams() }.notTo(beNil())
                expect { try interpreter.get("specific_goal") as? Bool }.to(beFalse())
                
            }
            
            it("shouldn't be able to override when the value is invalid.") {
                let jsonScript = "{\"op\":\"seq\",\"seq\":[{\"op\":\"set\",\"var\":\"group_size\",\"value\":{\"choices\":{\"op\":\"array\",\"values\":[1,10]},\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"uniformChoice\"}},{\"op\":\"set\",\"var\":\"specific_goal\",\"value\":{\"p\":0.8,\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"bernoulliTrial\"}},{\"op\":\"cond\",\"cond\":[{\"if\":{\"op\":\"get\",\"var\":\"specific_goal\"},\"then\":{\"op\":\"seq\",\"seq\":[{\"op\":\"set\",\"var\":\"ratings_per_user_goal\",\"value\":{\"choices\":{\"op\":\"array\",\"values\":[8,16,32,64]},\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"uniformChoice\"}},{\"op\":\"set\",\"var\":\"ratings_goal\",\"value\":{\"op\":\"product\",\"values\":[{\"op\":\"get\",\"var\":\"group_size\"},{\"op\":\"get\",\"var\":\"ratings_per_user_goal\"}]}}]}}]}]}"
                var serialization: [String: Any]
                if let script = jsonScript.data(using: .utf8),
                    let data = try? JSONSerialization.jsonObject(with: script) as? [String: Any] {
                    serialization = data
                } else {
                    serialization = [:]
                }
                
                let interpreter = Interpreter(serialization: serialization, salt: "foo", unit: Unit(keys: ["userid"], inputs: ["userid": "123454"], overrides: ["userid": "123454"]))
                // This script is should not throw error yet it is
                expect { try interpreter.getParams() }.notTo(throwError())
                expect { try interpreter.getParams() }.notTo(beNil())
                expect { try interpreter.get("specific_goal") as? Bool }.to(beTrue())
                
            }
            
            it("has to be able to use default when the input is invalid.") {
                let jsonScript = "{\"op\":\"seq\",\"seq\":[{\"op\":\"set\",\"var\":\"group_size\",\"value\":{\"choices\":{\"op\":\"array\",\"values\":[1,10]},\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"uniformChoice\"}},{\"op\":\"set\",\"var\":\"specific_goal\",\"value\":{\"p\":0.8,\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"bernoulliTrial\"}},{\"op\":\"cond\",\"cond\":[{\"if\":{\"op\":\"get\",\"var\":\"specific_goal\"},\"then\":{\"op\":\"seq\",\"seq\":[{\"op\":\"set\",\"var\":\"ratings_per_user_goal\",\"value\":{\"choices\":{\"op\":\"array\",\"values\":[8,16,32,64]},\"unit\":{\"op\":\"get\",\"var\":\"userid\"},\"op\":\"uniformChoice\"}},{\"op\":\"set\",\"var\":\"ratings_goal\",\"value\":{\"op\":\"product\",\"values\":[{\"op\":\"get\",\"var\":\"group_size\"},{\"op\":\"get\",\"var\":\"ratings_per_user_goal\"}]}}]}}]}]}"
                var serialization: [String: Any]
                if let script = jsonScript.data(using: .utf8),
                    let data = try? JSONSerialization.jsonObject(with: script) as? [String: Any] {
                    serialization = data
                } else {
                    serialization = [:]
                }
                let interpreter = Interpreter(serialization: serialization, salt: "foo", unit: Unit(keys: ["userid"], inputs: ["cookieid": "123454"], overrides: ["userid": "123454"]))
                expect { try interpreter.getParams() }.notTo(throwError())
                expect { try interpreter.getParams() }.notTo(beNil())
            }
        }
    }
}
