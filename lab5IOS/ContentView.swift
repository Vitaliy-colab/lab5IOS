//
//  ContentView.swift
//  lab5IOS
//
//  Created by mac on 19.10.2025.
//

import SwiftUI

struct DogBreed: Identifiable, Codable {
    let id: Int
    let name: String
    let temperament: String?
    let origin: String?
    let image: DogImage?

    struct DogImage: Codable {
        let url: String
    }
}

@MainActor
class DogViewModel: ObservableObject {
    @Published var breeds: [DogBreed] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchBreeds() async {
        isLoading = true
        errorMessage = nil

        let urlString = "https://api.thedogapi.com/v1/breeds"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue(
                "live_JjFAGgGEXb0iuz4JsxJly306CmOJVx3tR1gIUksdWr8UQT5KmC1mxGXA5ZZofDkR",
                forHTTPHeaderField: "x-api-key"
            )  // 👈 сюди встав свій ключ

            let (data, _) = try await URLSession.shared.data(for: request)
            let breeds = try JSONDecoder().decode([DogBreed].self, from: data)
            self.breeds = breeds
        } catch {
            errorMessage = "Failed to fetch data: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

struct ContentView: View {
    @StateObject private var viewModel = DogViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading breeds...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text("❌ \(error)")
                            .padding()
                        Button("Try again") {
                            Task { await viewModel.fetchBreeds() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.breeds) { breed in
                                NavigationLink(
                                    destination: BreedDetailView(breed: breed)
                                ) {
                                    HStack(spacing: 12) {
                                        AsyncImage(
                                            url: URL(
                                                string: breed.image?.url ?? ""
                                            )
                                        ) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Color.gray.opacity(0.3)
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 12)
                                        )

                                        VStack(alignment: .leading, spacing: 4)
                                        {
                                            Text(breed.name)
                                                .font(.headline)
                                            if let origin = breed.origin {
                                                Text(origin)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Dog Breeds")
            .task {
                await viewModel.fetchBreeds()
            }
        }
    }
}

struct BreedDetailView: View {
    let breed: DogBreed

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let url = breed.image?.url {
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }

                Text(breed.name)
                    .font(.largeTitle)
                    .bold()

                if let temperament = breed.temperament {
                    Text("🧠 Temperament:")
                        .font(.headline)
                    Text(temperament)
                }

                if let origin = breed.origin {
                    Text("🌍 Origin:")
                        .font(.headline)
                    Text(origin)
                }
            }
            .padding()
        }
        .navigationTitle(breed.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
