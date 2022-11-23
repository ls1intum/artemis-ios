import Foundation
import RxSwift
import Model
import Device
import Common

class ServerDataServiceImpl: ServerDataService {

    private let jsonProvider: JsonProvider
    private let networkStatusProvider: NetworkStatusProvider

    init(jsonProvider: JsonProvider, networkStatusProvider: NetworkStatusProvider) {
        self.jsonProvider = jsonProvider
        self.networkStatusProvider = networkStatusProvider
    }

    func getAccountData(serverUrl: String, authToken: String) -> Observable<DataState<Account>> {
        retryOnInternet(connectivity: networkStatusProvider.currentNetworkStatus) { [self] in
            await performNetworkCall {
                var components = URLComponents(string: serverUrl)!
                components.path += "api/account"

                var request = URLRequest(url: components.url!)
                request.contentTypeJson()
                request.bearerAuth(authToken: authToken)

                let (data, _) = try await URLSession.shared.data(for: request)
                return try jsonProvider.decoder.decode(Account.self, from: data)
            }
        }
    }
}
