//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport

let nibFile = NSNib.Name("MyView")
var topLevelObjects : NSArray?

Bundle.main.loadNibNamed(nibFile, owner:nil, topLevelObjects: &topLevelObjects)
let views = (topLevelObjects as! Array<Any>).filter { $0 is NSView }

print("boo1 ")

// Present the view in Playground
PlaygroundPage.current.liveView = views[0] as! NSView
let em = EventMonitor()
try em.start()
print("boo2 ")
