//
//  Thread+CodeStackTrace.swift
//  
//
//  Created by Tyler Anger on 2022-10-28.
//

import Foundation

public extension Thread {
    /// Default property used for CodeStackTrace threadQOS parameter
    /// When qualityOfService is unavailable due to version of swift
    /// this will return 'default'
    var _stackTraceQualityOfService: QualityOfService {
        #if !_runtime(_ObjC) && !swift(>=5.1)
        return .default
        #else
        return self.qualityOfService
        #endif
    }
}
