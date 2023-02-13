//
//  main.swift
//  DetectFaces
//
//  Created by Kastro on 12/2/23.
//

import Vision
import CoreImage
import CoreGraphics
import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 3 else {
    print("Usage: \(arguments[0]) INPUT_IMAGE OUTPUT_IMAGE")
    exit(1)
}

let imagePath = arguments[1]
let outputPath = arguments[2]

guard let image = CIImage(contentsOf: URL(fileURLWithPath: imagePath)) else {
    print("Failed to load image.")
    exit(1)
}

let request = VNDetectFaceRectanglesRequest { (request, error) in
    guard let observations = request.results as? [VNFaceObservation] else {
        print("Failed to detect faces.")
        exit(1)
    }

    let ciContext = CIContext()
    let cgImage = ciContext.createCGImage(image, from: image.extent)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

    let width = Int(image.extent.width)
    let height = Int(image.extent.height)
    
    print("width: \(width), \(height)")

    let bytesPerRow = width * 4
    let bufferLength = bytesPerRow * height

    let data = UnsafeMutableRawPointer.allocate(byteCount: bufferLength, alignment: 4)

    guard let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
        print("Failed to create context.")
        exit(1)
    }

    context.draw(cgImage!, in: image.extent)

    for face in observations {
        let scale = CGAffineTransform(scaleX: image.extent.width, y: image.extent.height)
        let rect = face.boundingBox.applying(scale)
        
        print("rect: \(rect)")
        
        context.setStrokeColor(CGColor.init(red: 1, green: 0, blue: 0, alpha: 1))
        context.setLineWidth(4)
        context.stroke(rect)
    }
    
    // Create a CGImage from the bitmap context
    let outImage = context.makeImage()!

    // Save the CGImage as a JPEG file
    let url = URL(fileURLWithPath: outputPath)
    let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeJPEG, 1, nil)!
    CGImageDestinationAddImage(destination, outImage, nil)
    CGImageDestinationFinalize(destination)
}

let handler = VNImageRequestHandler(ciImage: image, options: [:])

do {
    try handler.perform([request])
} catch {
    print("Failed to perform request: \(error)")
    exit(1)
}
