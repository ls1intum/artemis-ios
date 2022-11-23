import Foundation
import SwiftDate

/**
 * Provides the implementations of the json encoder and decoder.
 */
public class JsonProvider {
    public let encoder = JSONEncoder()
    public let decoder = JSONDecoder()

    init() {
        decoder.dateDecodingStrategy = .custom { decoder in
            do {
                guard let dateInRegion = try decoder.singleValueContainer().decode(String.self).toDate() else {
                    return Date()
                }
                return dateInRegion.date
            } catch {
                print(error)
                return Date()
            }
        }
    }
}
