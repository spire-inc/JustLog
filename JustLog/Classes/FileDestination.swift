//
//  FileDestination.swift
//  JustLog
//
//  Created by Alberto De Bortoli on 20/12/2016.
//  Copyright © 2017 Just Eat. All rights reserved.
//

import Foundation
import SwiftyBeaver

public class FileDestination: BaseDestination {

    public var logFileURL: URL?
    public var syncAfterEachWrite: Bool = false

    override public var defaultHashValue: Int {return 2}
    let fileManager = FileManager.default
    var fileHandle: FileHandle?
    
    public override init() {
        super.init()
        
        levelColor.verbose = "📣 "
        levelColor.debug = "📝 "
        levelColor.info = "ℹ️ "
        levelColor.warning = "⚠️ "
        levelColor.error = "☠️ "
        
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
            let _ = saveToFile(str: str)
        }
        return formattedString
    }

    deinit {
        // close file handle if set
        if let fileHandle = fileHandle {
            fileHandle.closeFile()
        }
    }

    /// appends a string as line to a file.
    /// returns boolean about success
    func saveToFile(str: String) -> Bool {
        guard let url = logFileURL else { return false }
        do {
            if fileManager.fileExists(atPath: url.path) == false {
                // create file if not existing
                let line = str + "\n"
                try line.write(to: url, atomically: true, encoding: .utf8)
                
                #if os(iOS) || os(watchOS)
                if #available(iOS 10.0, watchOS 3.0, *) {
                    var attributes = try fileManager.attributesOfItem(atPath: url.path)
                    attributes[FileAttributeKey.protectionKey] = FileProtectionType.none
                    try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
                }
                #endif
            } else {
                // append to end of file
                if fileHandle == nil {
                    // initial setting of file handle
                    fileHandle = try FileHandle(forWritingTo: url as URL)
                }
                if let fileHandle = fileHandle {
                    _ = fileHandle.seekToEndOfFile()
                    let line = str + "\n"
                    if let data = line.data(using: String.Encoding.utf8) {
                        fileHandle.write(data)
                        if syncAfterEachWrite {
                            fileHandle.synchronizeFile()
                        }
                    }
                }
            }
            return true
        } catch {
            print("SwiftyBeaver File Destination could not write to file \(url).")
            return false
        }
    }

    /// deletes log file.
    /// returns true if file was removed or does not exist, false otherwise
    public func deleteLogFile() -> Bool {
        guard let url = logFileURL, fileManager.fileExists(atPath: url.path) == true else { return true }
        do {
            try fileManager.removeItem(at: url)
            fileHandle = nil
            return true
        } catch {
            print("SwiftyBeaver File Destination could not remove file \(url).")
            return false
        }
    }
}
