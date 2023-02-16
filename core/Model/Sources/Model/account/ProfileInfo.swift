import Foundation

/**
 * From: https://github.com/ls1intum/Artemis/blob/6edbff8a7fac2748e130d9c26f260eb6ad5e81e7/src/main/webapp/app/shared/layouts/profiles/profile-info.model.ts
 */
public struct ProfileInfo: Decodable {
    var activeProfiles: [String] = []
    var inProduction: Bool = false
    var contact: String = ""
    var testServer: Bool?
    var registrationEnabled: Bool?
    var needsToAcceptTerms: Bool = false
    var allowedEmailPattern: String?
    var allowedEmailPatternReadable: String?
    var allowedLdapUsernamePattern: String?
    var allowedCourseRegistrationUsernamePattern: String?
    var accountName: String?
    var externalCredentialProvider: String = ""
    var externalPasswordResetLinkMap: [String: String] = [String: String]()
    /**
     * Set if the server allows a saml2 based login. If not set, it is also not supported.
     */
    var saml2: Saml2Config?
}
