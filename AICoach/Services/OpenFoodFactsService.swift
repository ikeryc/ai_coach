import Foundation

/// Cliente para la API pública de Open Food Facts.
/// Búsqueda por nombre y lookup por código de barras.
final class OpenFoodFactsService {

    static let shared = OpenFoodFactsService()

    private let baseURL = Constants.API.openFoodFactsURL
    private let session: URLSession
    private let decoder = JSONDecoder()

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    // MARK: - Búsqueda por texto

    func search(query: String, pageSize: Int = 20) async throws -> [FoodItemDTO] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1&page_size=\(pageSize)&fields=product_name,brands,nutriments,serving_size,code")
        else { throw OFFError.invalidURL }

        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(OFFSearchResponse.self, from: data)
        return response.products.compactMap { FoodItemDTO(from: $0) }
    }

    // MARK: - Lookup por código de barras

    func lookup(barcode: String) async throws -> FoodItemDTO? {
        guard let url = URL(string: "\(baseURL)/api/v0/product/\(barcode).json") else {
            throw OFFError.invalidURL
        }
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(OFFProductResponse.self, from: data)
        guard response.status == 1, let product = response.product else { return nil }
        return FoodItemDTO(from: product)
    }
}

// MARK: - DTO intermedio

struct FoodItemDTO: Identifiable {
    let id = UUID()
    let externalId: String?
    let name: String
    let brand: String?
    let barcode: String?
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let servingSizeG: Double?

    var displayName: String {
        if let brand, !brand.isEmpty { return "\(name) — \(brand)" }
        return name
    }

    var macroSummary: String {
        "P: \(String(format: "%.0f", proteinPer100g))g · C: \(String(format: "%.0f", carbsPer100g))g · G: \(String(format: "%.0f", fatPer100g))g"
    }

    init?(from product: OFFProduct) {
        let trimmedName = product.productName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return nil }
        guard let kcal = product.nutriments?.energyKcal100g, kcal > 0 else { return nil }

        self.externalId = product.code
        self.name = trimmedName
        self.brand = product.brands?
            .components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces)
        self.barcode = product.code
        self.caloriesPer100g = kcal
        self.proteinPer100g = product.nutriments?.proteins100g ?? 0
        self.carbsPer100g = product.nutriments?.carbohydrates100g ?? 0
        self.fatPer100g = product.nutriments?.fat100g ?? 0
        self.fiberPer100g = product.nutriments?.fiber100g ?? 0
        self.servingSizeG = Self.parseServingSize(product.servingSize)
    }

    private static func parseServingSize(_ raw: String?) -> Double? {
        guard let raw else { return nil }
        // Extrae el primer número seguido de "g": "30g", "30 g", "1 serving (30g)"
        let numbers = raw.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .filter { !$0.isEmpty }
        if let first = numbers.first, let value = Double(first), value > 0 {
            return value
        }
        return nil
    }

    /// Crea o reutiliza un FoodItem en SwiftData.
    func toFoodItem() -> FoodItem {
        FoodItem(
            externalId: externalId,
            source: .openFoodFacts,
            name: name,
            brand: brand,
            barcode: barcode,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: fiberPer100g,
            servingSizeG: servingSizeG
        )
    }
}

// MARK: - Decodable response types

private struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]
}

private struct OFFProductResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let code: String?
    let productName: String
    let brands: String?
    let servingSize: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case nutriments
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        code = try c.decodeIfPresent(String.self, forKey: .code)
        productName = (try? c.decode(String.self, forKey: .productName)) ?? ""
        brands = try c.decodeIfPresent(String.self, forKey: .brands)
        servingSize = try c.decodeIfPresent(String.self, forKey: .servingSize)
        nutriments = try c.decodeIfPresent(OFFNutriments.self, forKey: .nutriments)
    }
}

private struct OFFNutriments: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let fiber100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case fiber100g = "fiber_100g"
    }
}

// MARK: - Error

enum OFFError: LocalizedError {
    case invalidURL
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: "URL inválida"
        case .productNotFound: "Producto no encontrado en Open Food Facts"
        }
    }
}
