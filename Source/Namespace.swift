//
//  Namespace.swift
//  PlanoutKit
//
//  Created by David Christiandy on 29/07/19.
//  Copyright © 2019 Traveloka. All rights reserved.
//

/// Namespace represents an instance of traffic segmentation for experiments management.
///
/// Multiple namespaces segment traffic independently.
/// A unit (such as user GUID) can be part of a single experiment within a namespace, but in multiple experiments in different namespaces.
/// The experiment's parameters assignment will be eagerly evaluated and cached.
public class Namespace {
    /// The namespace identifier.
    let name: String

    /// The salt for this namespace.
    ///
    /// By default, the value will be the Namespace's name, unless otherwise supplied through the customSalt parameter when initializing the Namespace instance.
    let salt: String

    /// Model data that represents a unit, along with its inputs and overrides.
    private var unit: Unit

    /// The active experiment assigned for the particular unit.
    private var activeExperiment: Experiment? // TODO

    /// Map of running Experiment instances for the Namespace.
    private var experiments: [String: Experiment] = [:]

    /// List of ExperimentDefinitions registered for the Namespace.
    private var definitions: [String: ExperimentDefinition] = [:]

    /// Object that is responsible for the segment allocation and management.
    private var segmentAllocator: SegmentAllocator

    /// Responsible for processing exposure logs.
    ///
    /// Logger will be called whenever the unit is exposed to an experiment, and the params are assigned.
    private let logger: PlanOutLogger

    /// Flag for whether the Namespace has been assigned or not.
    private var isAssigned: Bool {
        return activeExperiment != nil
    }

    required public init(_ name: String,
                         unitKeys: [String],
                         inputs: [String: Any],
                         overrides: [String: Any] = [:],
                         totalSegments: Int,
                         customSalt: String? = nil,
                         logger: PlanOutLogger? = nil) {
        // TODO: throw errors instead of asserts.
        assert(unitKeys.count > 0, "Unit keys must have at least one element.")

        self.name = name
        self.salt = customSalt ?? name
        self.logger = logger ?? InMemoryLogger()

        unit = Unit(keys: unitKeys, inputs: inputs)
        segmentAllocator = DefaultSegmentAllocator(totalSegments: totalSegments)
    }
}

// MARK: Experiment Management

extension Namespace {
    /// Registers a new experiment definition for this namespace.
    ///
    /// - Parameters:
    ///   - identifier: The name of the experiment definition.
    ///   - serializedScript: The serialized PlanOut script for the experiment.
    public func defineExperiment(identifier: String, serializedScript: String) {
        // TODO: throw errors instead of asserts.
        assert(definitions[identifier] == nil, "Duplicate experiment definition found with id: \(identifier)")

        definitions[identifier] = ExperimentDefinition(identifier, serializedScript)
    }

    /// Allocates an experiment instance to a number of segments.
    ///
    /// The experiment requires an ExperimentDefinition registered within the Namespace, and a number representing how many segments will be allocated for the experiment. It is possible for multiple experiments to exist using the same ExperimentDefinition, but the name of the experiment must be unique.
    ///
    /// - Parameters:
    ///   - name: The name for the experiment instance.
    ///   - definition: The ExperimentDefinition used for the instance.
    ///   - segmentCount: The number of segments that should be allocated for this instance.
    public func addExperiment(name: String, definition: ExperimentDefinition, segmentCount: Int) throws {
        try segmentAllocator.allocate(name, segmentCount)

        let experimentName = "\(self.name)-\(name)"
        let experimentSalt = SaltProvider.generate(values: [self.salt, name])
        experiments[name] = Experiment(definition, name: experimentName, salt: experimentSalt)
    }

    /// Allocates an experiment instance to a list of defined segments.
    ///
    /// The experiment requires an ExperimentDefinition registered within the Namespace, and a list of integers representing segments that will be allocated for the experiment. It is possible for multiple experiments to exist using the same ExperimentDefinition, but the name of the experiment must be unique.
    ///
    /// This method is a variant version from `addExperiment(name:definition:segmentCount:)` where the experiment instance already has preallocated segments. By passing an array of integers as the pre-allocated segments, the Namespace no longer needs to assign the experiment and instead will directly block the requested segments from the available segment pool.
    ///
    /// - Parameters:
    ///   - name: The name for the experiment instance.
    ///   - definition: The ExperimentDefinition used for the instance.
    ///   - segments: An array of segments that is allocated for this instance.
    public func addExperiment(name: String, definition: ExperimentDefinition, segments: [Int]) throws {
        try segmentAllocator.allocate(name, segments: segments)

        let experimentName = "\(self.name)-\(name)" // Is this required?
        let experimentSalt = SaltProvider.generate(values: [self.salt, name])
        experiments[name] = Experiment(definition, name: experimentName, salt: experimentSalt)
    }

    /// Removes an experiment and deallocate the segments for that experiment instance.
    ///
    /// - Parameter name: The name of the experiment instance.
    public func removeExperiment(name: String) throws {
        try segmentAllocator.deallocate(name)
        experiments.removeValue(forKey: name)
    }
}

// MARK: ReadableAssignment

extension Namespace: ReadableAssignment {
    public func get(_ name: String) throws -> Any? {
        try assignIfNeeded()
        return try self.activeExperiment?.get(name)
    }

    public func get<T>(_ name: String, defaultValue: T) throws -> T {
        try assignIfNeeded()
        return try self.activeExperiment?.get(name, defaultValue: defaultValue) ?? defaultValue
    }

    public func getParams() throws -> [String : Any] {
        try assignIfNeeded()
        return try self.activeExperiment?.getParams() ?? [:]
    }
}

// MARK: Activation

extension Namespace {
    /// Assigns unit to an experiment.
    ///
    /// - Throws: SegmentAllocationError
    func assignIfNeeded() throws {
        if isAssigned { return }

        if let experimentId = segmentAllocator.identifier(forUnit: unit.identifier),
            let experiment = experiments[experimentId] {
            try experiment.assign(unit, logger: self.logger)
            activeExperiment = experiment
        }
    }
}