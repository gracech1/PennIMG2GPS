//
//  ViewModel.swift
//  PennIMG2GPS
//
//  Created by Grace Chi on 4/25/26.
//

import SwiftUI
import PhotosUI
import Observation

@Observable
@MainActor
class ViewModel {
    var selectedItem: PhotosPickerItem?
    var selectedImage: UIImage?
    var latitude: Double?
    var longitude: Double?

    func loadImage() async {
        guard let selectedItem else { return }

        if let data = try? await selectedItem.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
            runDummyModel()
        }
    }

    func runDummyModel() {
        // Pretend model output
        latitude = 39.9522
        longitude = -75.1932
    }
}
