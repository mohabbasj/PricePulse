import SwiftData
import SwiftUI

struct AddProductView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddProductViewModel()
    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Product URL")
                            .font(.headline)

                        HStack {
                            TextField("https://www.amazon.com/...", text: $viewModel.urlText)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .focused($isURLFieldFocused)
                                .onSubmit { Task { await viewModel.fetchPreview() } }

                            if !viewModel.urlText.isEmpty {
                                Button {
                                    viewModel.urlText = ""
                                    viewModel.previewProduct = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                PasteButton(payloadType: String.self) { strings in
                                    guard let pasted = strings.first else { return }
                                    viewModel.urlText = pasted
                                    Task { await viewModel.fetchPreview() }
                                }
                                .labelStyle(.titleOnly)
                                .buttonBorderShape(.capsule)
                                .controlSize(.small)
                            }
                        }
                        .padding(14)
                        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        isURLFieldFocused = false
                        Task { await viewModel.fetchPreview() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Fetch Product")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canFetchPreview || viewModel.isLoading)

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let preview = viewModel.previewProduct {
                        ProductPreviewView(product: preview)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding()
                .animation(.spring(duration: 0.35), value: viewModel.previewProduct)
                .animation(.spring(duration: 0.35), value: viewModel.errorMessage)
            }
            .background(Color.screenBackground)
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(context: modelContext)
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.previewProduct == nil)
                }
            }
            .onChange(of: viewModel.didSave) { _, didSave in
                if didSave { dismiss() }
            }
        }
    }
}

#Preview {
    AddProductView()
        .modelContainer(PersistenceController.preview)
}
