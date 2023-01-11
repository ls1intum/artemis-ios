//
//  File.swift
//  
//
//  Created by Sven Andabaka on 09.01.23.
//

import SwiftyBeaver

public let log: SwiftyBeaver.Type = {
    let log = SwiftyBeaver.self
    
    // add log destinations. at least one is needed!
    let console = ConsoleDestination()  // log to Xcode Console
    log.addDestination(console)

    return log
}()
