//
//  GPSPredictionViewModel.swift
//  PennIMG2GPS
//
//  Created by Grace Chi on 5/4/26.
//


import SwiftUI
import PhotosUI
import CoreML
import UIKit
import Observation
import MapKit

@MainActor
@Observable
final class GPSPredictionViewModel {
    var selectedImage: UIImage?
    var predictionText: String?
    var errorMessage: String?
    var predictedCoordinate: CLLocationCoordinate2D?

    @ObservationIgnored
    private let model: EfficientNetGPS

    init() {
        do {
            let config = MLModelConfiguration()
            self.model = try EfficientNetGPS(configuration: config)
        } catch {
            fatalError("Failed to load EfficientNetGPS model: \(error)")
        }
    }

    func testFakeInputs() {
        do {
            print("process started")
            let zeros = try MLMultiArray(shape: [1, 3, 224, 224], dataType: .float32)
            let ones = try MLMultiArray(shape: [1, 3, 224, 224], dataType: .float32)
            let random = try MLMultiArray(shape: [1, 3, 224, 224], dataType: .float32)

            for i in 0..<zeros.count {
                zeros[i] = 0
                ones[i] = 1
                random[i] = NSNumber(value: Float.random(in: -2...2))
            }

            let zeroOutput = try model.prediction(input: EfficientNetGPSInput(input: zeros))
            let oneOutput = try model.prediction(input: EfficientNetGPSInput(input: ones))
            let randomOutput = try model.prediction(input: EfficientNetGPSInput(input: random))

            print("ZERO OUTPUT:", zeroOutput.coordinates)
            print("ONE OUTPUT:", oneOutput.coordinates)
            print("RANDOM OUTPUT:", randomOutput.coordinates)
        } catch {
            print("Fake input test failed:", error)
        }
    }
    
    func loadImage(from item: PhotosPickerItem?) async {
        errorMessage = nil
        predictionText = nil
        predictedCoordinate = nil

        guard let item else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load image."
                return
            }

            selectedImage = image
            print("Image loaded:", image.size)
        } catch {
            errorMessage = "Image loading failed: \(error.localizedDescription)"
        }
    }

    func predict() {
        errorMessage = nil
        predictionText = nil

        guard let image = selectedImage else {
            errorMessage = "Please select an image first."
            return
        }

        do {
            let inputArray = try imageToMLMultiArray(image)

            let input = EfficientNetGPSInput(input: inputArray)
            let output = try model.prediction(input: input)

            let coordinates = output.coordinates

            print("Output shape:", coordinates.shape)
            print("Output count:", coordinates.count)
            print("Output values:", coordinates)

            let latitude = coordinates[0].doubleValue
            let longitude = coordinates[1].doubleValue

            predictedCoordinate = CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            )

            predictionText = """
            Predicted Coordinates :):
            \(latitude), \(longitude)
            """
        } catch {
            errorMessage = "Prediction failed: \(error.localizedDescription)"
        }
    }

    private func imageToMLMultiArray(_ image: UIImage) throws -> MLMultiArray {
        let width = 224
        let height = 224

        guard let resizedImage = image.resized(to: CGSize(width: width, height: height)),
              let cgImage = resizedImage.cgImage else {
            throw NSError(domain: "ImageProcessing", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not resize image."
            ])
        }

        let array = try MLMultiArray(
            shape: [1, 3, 224, 224],
            dataType: .float32
        )

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Force predictable RGBX byte layout:
        // pixelData[index + 0] = R
        // pixelData[index + 1] = G
        // pixelData[index + 2] = B
        // pixelData[index + 3] = unused
        let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue |
                         CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw NSError(domain: "ImageProcessing", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Could not create CGContext."
            ])
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let mean: [Float] = [0.485, 0.456, 0.406]
        let std: [Float] = [0.229, 0.224, 0.225]

        var minValue = Float.greatestFiniteMagnitude
        var maxValue = -Float.greatestFiniteMagnitude
        var sumValue: Float = 0

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel

                let r = Float(pixelData[pixelIndex + 0]) / 255.0
                let g = Float(pixelData[pixelIndex + 1]) / 255.0
                let b = Float(pixelData[pixelIndex + 2]) / 255.0

                let normalizedR = (r - mean[0]) / std[0]
                let normalizedG = (g - mean[1]) / std[1]
                let normalizedB = (b - mean[2]) / std[2]

                array[[0, 0, y, x] as [NSNumber]] = NSNumber(value: normalizedR)
                array[[0, 1, y, x] as [NSNumber]] = NSNumber(value: normalizedG)
                array[[0, 2, y, x] as [NSNumber]] = NSNumber(value: normalizedB)

                minValue = min(minValue, normalizedR, normalizedG, normalizedB)
                maxValue = max(maxValue, normalizedR, normalizedG, normalizedB)
                sumValue += normalizedR + normalizedG + normalizedB
            }
        }

        let meanValue = sumValue / Float(width * height * 3)

        print("Input tensor min:", minValue)
        print("Input tensor max:", maxValue)
        print("Input tensor mean:", meanValue)

        print("Top-left normalized RGB:",
              array[[0, 0, 0, 0] as [NSNumber]],
              array[[0, 1, 0, 0] as [NSNumber]],
              array[[0, 2, 0, 0] as [NSNumber]]
        )

        return array
    }
}

private extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
