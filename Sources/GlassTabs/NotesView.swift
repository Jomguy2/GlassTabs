import SwiftUI
import Foundation

/// Local-only note, stored as JSON in the app's documents directory.
/// No iCloud capability is attached to the app, so everything stays
/// on-device. (SwiftData's `@Model` macro plugin is Mac-only and cannot
/// run on a Linux build host, so plain Codable persistence is used.)
struct NoteItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var bodyText: String
    var createdAt: Date = Date()
}

@MainActor
@Observable
final class NoteStore {
    private(set) var notes: [NoteItem] = []

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("notes.json")
    }

    init() {
        load()
    }

    /// Newest first.
    var ordered: [NoteItem] {
        notes.sorted { $0.createdAt > $1.createdAt }
    }

    func add(title: String, bodyText: String) {
        notes.append(NoteItem(title: title, bodyText: bodyText))
        save()
    }

    func update(_ note: NoteItem, title: String, bodyText: String) {
        guard let index = notes.firstIndex(of: note) else { return }
        notes[index].title = title
        notes[index].bodyText = bodyText
        save()
    }

    func delete(_ note: NoteItem) {
        notes.removeAll { $0 == note }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let decoded = try? JSONDecoder().decode([NoteItem].self, from: data)
        else { return }
        notes = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }
}

struct NotesView: View {
    @State private var store = NoteStore()
    @State private var showingEditor = false
    @State private var editingNote: NoteItem?

    var body: some View {
        NavigationStack {
            Group {
                if store.ordered.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("No notes yet")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.headline)
                        Text("Tap + to add your first note. Notes stay on this device.")
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.ordered) { note in
                            Button {
                                editingNote = note
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(note.title.isEmpty ? "(No title)" : note.title)
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                    if !note.bodyText.isEmpty {
                                        Text(note.bodyText)
                                            .font(.body)
                                            .foregroundStyle(.black.opacity(0.75))
                                            .lineLimit(3)
                                    }
                                    Text(note.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.black.opacity(0.5))
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.delete(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .glassBackdrop()
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(.white)
                }
            }
            .sheet(isPresented: $showingEditor) {
                NoteEditor(title: "", bodyText: "") { newTitle, newBody in
                    store.add(title: newTitle, bodyText: newBody)
                }
            }
            .sheet(item: $editingNote) { note in
                NoteEditor(title: note.title, bodyText: note.bodyText) { newTitle, newBody in
                    store.update(note, title: newTitle, bodyText: newBody)
                }
            }
        }
    }
}

struct NoteEditor: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String) -> Void

    @State private var title: String
    @State private var bodyText: String

    init(title: String, bodyText: String, onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
        _title = State(initialValue: title)
        _bodyText = State(initialValue: bodyText)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $bodyText, axis: .vertical)
                    .lineLimit(5...10)
            }
            .navigationTitle(title.isEmpty ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, bodyText)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty && bodyText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
