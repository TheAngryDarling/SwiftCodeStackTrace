//
//  CodeStackTrace.swift
//
//
//  Created by Tyler Anger on 2022-07-19.
//

import Foundation

/// Object used to keep track of stack trace items when calling functions
public struct CodeStackTrace: BidirectionalCollection {
    public struct ThreadDetails {
        /// Keys for Key/Value of the Thread Description key/values
        public enum ThreadDescripionKeys: String {
            case number
            case name
        }
        /// The Thread Object's Object Id
        public let threadObjectId: String?
        /// The Thread Number (From the thread description)
        public let threadNumber: Int?
        /// The Thread Name (From the thread description)
        public let descriptionName: String?
        ///  Thread Description Key/Value items
        public let descriptionKeyValues: [String: String]
        /// The Thread Name (From the name property)
        public let setName: String?
        /// The Thread Name (either .setName or .descriptionName)
        public var name: String? {
            return self.setName ?? self.descriptionName
        }
        /// The Thread Quality of Service
        public let qualityOfService: QualityOfService
        
        /// Indicator if the thread was the main thread
        ///
        /// Note: On OpenSwift < 4.1 this field is always false
        public let isMainThread: Bool
        
        public init(thread: Thread = Thread.current) {
            
            
            var descriptionKeyValues: [String: String] = [:]
            var description = "\(thread)"
            #if _runtime(_ObjC)
            // Open Swift does not provide any extra details within the thread description other than
            // thread object ID
            
            // parse out key/value 'key = value' from description inside { ... }
            if let startOfThreadDetails = description.range(of: "{"),
               let endOfThreadDetails = description.range(of: "}", options: .backwards) {
                description = String(description[startOfThreadDetails.upperBound..<endOfThreadDetails.lowerBound])
                let descriptionValues = description.split(separator: ",").map(String.init)
                for value in descriptionValues {
                    if let sep = value.range(of: "=") {
                        let key = String(value[..<sep.lowerBound]).trimmingCharacters(in: .whitespaces)
                        let val = String(value[sep.upperBound...]).trimmingCharacters(in: .whitespaces)
                        
                        if val != "null" && val != "nil" && val != "(null)" && val != "(nil)" {
                            descriptionKeyValues[key] = val
                        }
                    }
                }
            }
            #endif
            
            #if _runtime(_ObjC) || swift(>=4.1)
            let isMainTh: Bool = Thread.isMainThread
            #else
            let isMainTh: Bool = false
            #endif
            
            // we will set the thread description name to main if not set and thread is main thread
            if !descriptionKeyValues.keys.contains(ThreadDescripionKeys.name.rawValue) &&
                isMainTh {
                descriptionKeyValues[ThreadDescripionKeys.name.rawValue] = "main"
            }
            
            if !descriptionKeyValues.keys.contains(ThreadDescripionKeys.number.rawValue),
                let tn = Int("\(pthread_self())") {
                descriptionKeyValues[ThreadDescripionKeys.number.rawValue] = "\(tn)"
            }
            
            
            var objId: String? = nil
            // parse out object id from description inside <OBJECTTYPE: OBJECT ID> ...
            if description.hasPrefix("<"),
               let colonRange = description.range(of: ":"),
               let endOfObjectIdentRange = description.range(of: ">", range: colonRange.upperBound..<description.endIndex) {
                objId = String(description[colonRange.upperBound..<endOfObjectIdentRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            
            self.threadObjectId = objId
            
            var threadNumber: Int? = nil
            if let stn = descriptionKeyValues[ThreadDescripionKeys.number.rawValue],
               let tn = Int(stn) {
                threadNumber = tn
            }
            self.threadNumber = threadNumber
            self.descriptionName = descriptionKeyValues[ThreadDescripionKeys.name.rawValue]
            self.setName = thread.name
            self.descriptionKeyValues = descriptionKeyValues
            self.qualityOfService = thread._stackTraceQualityOfService
            self.isMainThread = isMainTh
            
        }
    }
    /// A stack trace item which contains the path to the file, the calling function and the line
    public struct StackItem: CustomStringConvertible {
        public let filePath: String
        public let function: String
        public let line: UInt
        public let threadDetails: ThreadDetails
        
        public var functionName: String {
            guard let r = self.function.range(of: "(") else {
                return self.function
            }
            return String(self.function[..<r.lowerBound])
        }
        
        public var description: String {
            return "\(self.filePath):\(self.line) - \(self.function)"
        }
        
        public init(filePath: StaticString,
                    function: StaticString,
                    line: UInt,
                    threadDetails: ThreadDetails = .init()) {
            self.filePath = "\(filePath)"
            self.function = "\(function)"
            self.line = line
            self.threadDetails = threadDetails
        }
    }
    /// Indicator if stacking should occur when called
    private var mutable: Bool
    /// The called stack
    private var stack: [StackItem]
    
    public var startIndex: Int { return self.stack.startIndex }
    public var endIndex: Int { return self.stack.endIndex }
    
    public subscript(position: Int) -> StackItem {
        return self.stack[position]
    }
    
    /// Copy the given stack trace and keep its locking flag
    /// - Parameters:
    ///   - locked: Override the locking flag of the stack trace to copy
    ///   - stackTrace: The stack trace to copy
    public init(locked: Bool, copying stackTrace: CodeStackTrace) {
        self.mutable = !locked
        self.stack = stackTrace.stack
    }
    
    /// Copy the given stack trace and keep its locking flag
    /// - Parameter stackTrace: The stack trace to copy
    public init(copying stackTrace: CodeStackTrace) {
        self.init(locked: !stackTrace.mutable, copying: stackTrace)
    }
    
    /// Stack a new stack item to the list if the stack trace is unlocked
    /// - Parameter item: The item to stack
    public mutating func stack(_ item: StackItem) {
        if self.mutable {
            self.stack.insert(item, at: 0)
        }
    }
    
    /// Create a copy of the of the current stack trace and stack the new stack item
    /// - Parameters:
    ///   - item: The item to stack
    ///   - locked: optional bool to set the lockable flag of the new stack trace before stacking the new item
    /// - Returns: Retruns the new stack trace
    public func stacking(_ item: StackItem, locked: Bool? = nil) -> CodeStackTrace {
        var rtn = CodeStackTrace(copying: self)
        if let l = locked { rtn.mutable = !l }
        rtn.stack(item)
        return rtn
    }
    
    
    public func index(after position: Int) -> Int {
        return self.stack.index(after: position)
    }
    
    public func index(before position: Int) -> Int {
        return self.stack.index(before: position)
    }
    
    #if swift(>=5.3)
    /// Create new Stack Trace
    /// - Parameters:
    ///   - locked: Indicator if the stack trace is locked an no other stack trace items can be appended
    ///   - filePath: The calling file
    ///   - function: The calling function
    ///   - line: The calling line
    ///   - threadDetails: The working thread details
    public init(locked: Bool = false,
                filePath: StaticString = #filePath,
                function: StaticString = #function,
                line: UInt = #line,
                threadDetails: ThreadDetails = .init()) {
        self.mutable = !locked
        self.stack = [.init(filePath: filePath,
                            function: function,
                            line: line,
                            threadDetails: threadDetails)]
    }
    
    /// Add new stack item to the stack trace
    /// - Parameters:
    ///   - filePath: The calling file
    ///   - function: The calling function
    ///   - line: The calling line
    ///   - threadDetails: The working thread details
    public mutating func stack(filePath: StaticString = #filePath,
                               function: StaticString = #function,
                               line: UInt = #line,
                               threadDetails: ThreadDetails = .init()) {
        self.stack(.init(filePath: filePath,
                         function: function,
                         line: line,
                         threadDetails: threadDetails))
    }
    
    /// Create a copy of the given stack trace and add a new stack item if the stack trace is not locked
    /// - Parameters:
    ///   - filePath: The calling file
    ///   - function: The calling function
    ///   - line: The calling line
    ///   - threadDetails: The working thread details
    ///   - locked: optional bool to set the lockable flag of the new stack trace before stacking the new item
    /// - Returns: Returns new stack trace
    public func stacking(filePath: StaticString = #filePath,
                         function: StaticString = #function,
                         line: UInt = #line,
                         threadDetails: ThreadDetails = .init(),
                         locked: Bool? = nil) -> CodeStackTrace {
        
        return self.stacking(.init(filePath: filePath,
                                   function: function,
                                   line: line,
                                   threadDetails: threadDetails),
                             locked: locked)
    }
    
    #else
    /// Create new Stack Trace
    /// - Parameters:
    ///   - locked: Indicator if the stack trace is locked an no other stack trace items can be appended
    ///   - filePath: The calling file
    ///   - function: The calling function
    ///   - line: The calling line
    ///   - threadDetails: The working thread details
    public init(locked: Bool = false,
                filePath: StaticString = #file,
                function: StaticString = #function,
                line: UInt = #line,
                threadDetails: ThreadDetails = .init()) {
        self.mutable = !locked
        self.stack = [.init(filePath: filePath,
                            function: function,
                            line: line,
                            threadDetails: threadDetails)]
    }
    
    /// Add new stack item to the stack trace
    /// - Parameters:
    ///   - filePath: The calling file
    ///   - function: The calling function
    ///   - line: The calling line
    ///   - threadDetails: The working thread details
    public mutating func stack(filePath: StaticString = #file,
                               function: StaticString = #function,
                               line: UInt = #line,
                               threadDetails: ThreadDetails = .init()) {
        self.stack(.init(filePath: filePath,
                         function: function,
                         line: line,
                         threadDetails: threadDetails))
    }
    
    /// Create a copy of the given stack trace and add a new stack item if the stack trace is not locked
    /// - Parameters:
    ///   - filePath: The calling file
    ///   - function: The calling function
    ///   - line: The calling line
    ///   - threadDetails: The working thread details
    ///   - locked: optional bool to set the lockable flag of the new stack trace before stacking the new item
    /// - Returns: Returns new stack trace
    public func stacking(filePath: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line,
                         threadDetails: ThreadDetails = .init(),
                         locked: Bool? = nil) -> CodeStackTrace {
        
        return self.stacking(.init(filePath: filePath,
                                   function: function,
                                   line: line,
                                   threadDetails: threadDetails),
                             locked: locked)
    }
    #endif
    
}
