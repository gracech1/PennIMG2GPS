//
//  ContentView.swift
//  PennIMG2GPS
//
//  Created by Grace Chi on 4/25/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Group {
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 44, weight: .regular))
                                    .foregroundStyle(.secondary)
                                Text("No image selected")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.gray.opacity(0.08))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.separator, lineWidth: 1)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        PhotosPicker(
                            selection: $viewModel.selectedItem,
                            matching: .images
                        ) {
                            Text("Choose Image")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .onChange(of: viewModel.selectedItem) {
                            Task { await viewModel.loadImage() }
                        }

                        if let lat = viewModel.latitude, let lon = viewModel.longitude {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Location Metadata")
                                    .font(.title3).bold()

                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text("Latitude:")
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.6f", lat))
                                }

                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text("Longitude:")
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.6f", lon))
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.background.secondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.separator, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("CIS 5190 IMG GPS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.selectedImage != nil {
                        ShareLink(item: UIImagePNGRepresentationWrapper(image: viewModel.selectedImage!), preview: SharePreview("Image")) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
}

private struct UIImagePNGRepresentationWrapper: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { wrapper in
            guard let data = wrapper.image.pngData() else { throw NSError(domain: "PNGError", code: -1) }
            return data
        }
    }
}
