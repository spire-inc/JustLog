//
//  ConsoleDestination.swift
//  JustLog
//
//  Created by Alberto De Bortoli on 06/12/2016.
//  Copyright © 2017 Just Eat. All rights reserved.
//

import Foundation
import SwiftyBeaver

public class ConsoleDestination: BaseDestination {
    
    public override init() {
        super.init()
        
        levelColor.verbose = "�"
        levelColor.debug = "�"
        levelColor.info = "ℹ️"
        levelColor.warning = "⚠️"
        levelColor.error = "☠️"
        
        levelString.verbose = ""
        levelString.debug = ""
        levelString.info = ""
        levelString.warning = ""
        levelString.error = ""
    }

    override public func send(_ level: SwiftyBeaver.Level, msg: String, thread: String,
        file: String, function: String, line: Int, context: Any?) -> String? {

        var dict = msg.toDictionary()
        guard var innerMessage = dict?["message"] as? String else { return nil }

        if let userInfo = dict?["userInfo"] as? Dictionary<String, Any> {
            if let queueLabel = userInfo["queue_label"] as? String {
                innerMessage = "(\(queueLabel)) " + innerMessage
            }
        }

        let formattedString = super.send(level, msg: innerMessage, thread: thread, file: file, function: function, line: line, context: context)

        if let str = formattedString {
            print(str)
        }
        return formattedString
    }

}
