//
//  GPSPredictView.swift
//  PennIMG2GPS
//
//  Created by Grace Chi on 5/4/26.
//

import SwiftUI
import PhotosUI
import MapKit

struct GPSPredictView: View {
    @State private var viewModel = GPSPredictionViewModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                imageSection

                buttonSection

                if let coordinate = viewModel.predictedCoordinate {
                    predictionSection(coordinate: coordinate)
                    mapSection(coordinate: coordinate)
                }

                if let errorMessage = viewModel.errorMessage {
                    errorSection(errorMessage)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.10),
                    Color.purple.opacity(0.08),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .task(id: selectedItem) {
            await viewModel.loadImage(from: selectedItem)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "location.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(.blue)

            Text("Penn Image 2 GPS")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Upload an image and predict its latitude and longitude.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Image")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                    .shadow(radius: 8)

                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No image selected")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("Choose a photo to start prediction.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                }
            }
            .frame(height: 280)
        }
        .padding()
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose Image", systemImage: "photo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                viewModel.predict()
            } label: {
                Label("Predict Location", systemImage: "mappin.and.ellipse")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.selectedImage == nil)
        }
    }

    private func predictionSection(coordinate: CLLocationCoordinate2D) -> some View {
        VStack(spacing: 12) {
            Text("Predicted Coordinates")
                .font(.headline)

            VStack(spacing: 8) {
                coordinateRow(
                    title: "Latitude",
                    value: coordinate.latitude
                )

                coordinateRow(
                    title: "Longitude",
                    value: coordinate.longitude
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private func coordinateRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value, format: .number.precision(.fractionLength(6)))
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func mapSection(coordinate: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Map Preview")
                .font(.headline)

            Map {
                Marker("Predicted Location", coordinate: coordinate)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding()
        .background(.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private func errorSection(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
