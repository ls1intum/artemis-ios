import Foundation
import RxSwift
import Model

public protocol ServerDataService {

    /**
     Get the details about the account of the logged in user from the server.
     Automatically retries on failure.
     */
    func getAccountData(serverUrl: String, authToken: String) -> Observable<DataState<Account>>
}
