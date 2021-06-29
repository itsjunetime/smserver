import Foundation
#if os(macOS)
import AppKit
typealias KitImage = NSImage
#elseif os(iOS)
import UIKit
typealias KitImage = UIImage
#endif


// an easy way of wrapping UIImage & NSImage so that I can use it for both macOS and iOS
class SMImage {
	var wrappedImage: KitImage?

	init(image: KitImage?) {
		self.wrappedImage = image
	}

	init(_ file: String) {
		self.wrappedImage = KitImage(contentsOfFile: file)
	}

	init(named name: String) {
		self.wrappedImage = KitImage(named: name)
	}

	final func parseableData(png: Bool = false) -> Data? {
		#if os(macOS)
		return self.wrappedImage?.tiffRepresentation
		#elseif os(iOS)
		return png ? self.wrappedImage?.pngData() : self.wrappedImage?.jpegData(compressionQuality: 0.25)
		#endif
	}
}
