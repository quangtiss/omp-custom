import Foundation
import Vision
import AppKit

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("usage: ocr <image-path>\n".data(using: .utf8)!)
    exit(2)
}
let path = CommandLine.arguments[1]
guard let img = NSImage(contentsOfFile: path),
      let tiff = img.tiffRepresentation,
      let bmp = NSBitmapImageRep(data: tiff),
      let cg = bmp.cgImage else {
    FileHandle.standardError.write("cannot read image: \(path)\n".data(using: .utf8)!)
    exit(2)
}

let req = VNRecognizeTextRequest { r, _ in
    guard let obs = r.results as? [VNRecognizedTextObservation] else { return }
    for o in obs {
        guard let top = o.topCandidates(1).first else { continue }
        let b = o.boundingBox
        let x = Int(b.minX * CGFloat(cg.width))
        let y = Int((1 - b.maxY) * CGFloat(cg.height))
        let w = Int(b.width * CGFloat(cg.width))
        let h = Int(b.height * CGFloat(cg.height))
        print("\(x)\t\(y)\t\(w)\t\(h)\t\(top.string)")
    }
}
req.recognitionLevel = .accurate
req.usesLanguageCorrection = false
req.recognitionLanguages = ["vi-VN", "en-US"]
try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
