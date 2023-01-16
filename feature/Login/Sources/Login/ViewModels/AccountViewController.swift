import Foundation
import Model
import Common

@MainActor
class AccountViewController: ObservableObject {

    @Published var serverProfileInfo: DataState<ProfileInfo> = DataState.loading
}
