import Foundation

@MainActor
class NameDatabase: ObservableObject {
    static let shared = NameDatabase()

    @Published private(set) var allNames: [BabyName] = []
    @Published private(set) var isLoaded = false

    private init() {
        loadNames()
    }

    // MARK: - Loading

    private func loadNames() {
        print("NameDatabase: Attempting to load names.json from bundle")
        print("NameDatabase: Bundle path: \(Bundle.main.bundlePath)")

        // Try to find the file
        if let url = Bundle.main.url(forResource: "names", withExtension: "json") {
            print("NameDatabase: Found names.json at: \(url.path)")

            do {
                let data = try Data(contentsOf: url)
                print("NameDatabase: Loaded \(data.count) bytes of data")

                let decoder = JSONDecoder()
                allNames = try decoder.decode([BabyName].self, from: data)
                isLoaded = true
                print("NameDatabase: Successfully decoded \(allNames.count) names")
            } catch {
                print("NameDatabase: Error decoding names: \(error)")
                print("NameDatabase: Error details: \(error.localizedDescription)")
            }
        } else {
            print("NameDatabase: ERROR - Could not find names.json in bundle")
            print("NameDatabase: Available resources:")
            if let resourcePath = Bundle.main.resourcePath {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    print("NameDatabase: Resources: \(contents.filter { $0.contains("json") })")
                } catch {
                    print("NameDatabase: Could not list resources: \(error)")
                }
            }
        }
    }

    // MARK: - Querying

    func filteredNames(with filters: NameFilters, excluding swipedIds: Set<String>) -> [BabyName] {
        allNames
            .filter { !swipedIds.contains($0.id) }
            .filter { filters.matches($0) }
    }

    func name(for id: String) -> BabyName? {
        allNames.first { $0.id == id }
    }

    func names(for ids: [String]) -> [BabyName] {
        ids.compactMap { id in allNames.first { $0.id == id } }
    }

    func randomNames(count: Int, with filters: NameFilters, excluding swipedIds: Set<String>) -> [BabyName] {
        let filtered = filteredNames(with: filters, excluding: swipedIds)
        return Array(filtered.shuffled().prefix(count))
    }

    // MARK: - Statistics

    var totalCount: Int { allNames.count }

    var maleCount: Int { allNames.filter { $0.gender == .male }.count }

    var femaleCount: Int { allNames.filter { $0.gender == .female }.count }

    var neutralCount: Int { allNames.filter { $0.gender == .neutral }.count }

    func count(for gender: Gender) -> Int {
        allNames.filter { $0.gender == gender }.count
    }

    func count(for origin: Origin) -> Int {
        allNames.filter { $0.origins.contains(origin) }.count
    }

    func count(for style: Style) -> Int {
        allNames.filter { $0.styles.contains(style) }.count
    }

    func count(for popularity: Popularity) -> Int {
        allNames.filter { $0.popularity == popularity }.count
    }

    // MARK: - Search

    func search(_ query: String) -> [BabyName] {
        guard !query.isEmpty else { return allNames }

        let lowercased = query.lowercased()
        return allNames.filter { name in
            name.name.lowercased().contains(lowercased) ||
            name.meaning?.lowercased().contains(lowercased) == true
        }
    }
}
