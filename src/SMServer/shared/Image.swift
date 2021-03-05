import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// an easy way of wrapping UIImage & NSImage so that I can use it for both macOS and iOS
class SMImage {
	#if os(macOS)
	var wrappedImage: NSImage?
	
	init(image: NSImage?) {
		self.wrappedImage = image
	}
	#elseif os(iOS)
	var wrappedImage: UIImage?
	
	init(image: UIImage?) {
		self.wrappedImage = image
	}
	#endif
	
	init(_ file: String) {
		#if os(macOS)
		let image = NSImage(contentsOfFile: file)
		#elseif os(iOS)
		let image = UIImage(contentsOfFile: file)
		#endif
		
		self.wrappedImage = image
	}
	
	init(named name: String) {
		#if os(macOS)
		let image = NSImage(named: name)
		#elseif os(iOS)
		let image = UIImage(named: name)
		#endif
		
		self.wrappedImage = image
	}
	
	final func parseableData() -> Data? {
		#if os(macOS)
		return self.wrappedImage?.tiffRepresentation
		#elseif os(iOS)
		return self.wrappedImage?.pngData()
		#endif
	}
}
