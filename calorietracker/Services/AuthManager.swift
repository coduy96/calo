import Foundation
import AuthenticationServices

@Observable
class AuthManager {
    private(set) var isSignedIn = false
    private(set) var userID: String?
    private(set) var userEmail: String?
    private(set) var userDisplayName: String?

    private let userIDKey = "appleUserID"
    private let userEmailKey = "appleUserEmail"
    private let userDisplayNameKey = "appleUserDisplayName"

    init() {
        loadStoredCredentials()
    }

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) throws {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidCredential
            }
            let id = credential.user
            userID = id
            UserDefaults.standard.set(id, forKey: userIDKey)

            // Apple only provides name/email on FIRST sign-in
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    userDisplayName = name
                    UserDefaults.standard.set(name, forKey: userDisplayNameKey)
                }
            }
            if let email = credential.email {
                userEmail = email
                UserDefaults.standard.set(email, forKey: userEmailKey)
            }

            isSignedIn = true

        case .failure(let error):
            throw error
        }
    }

    func checkCredentialState() async {
        guard let userID else {
            isSignedIn = false
            return
        }
        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
            isSignedIn = (state == .authorized)
            if state == .revoked || state == .notFound {
                clearStoredCredentials()
            }
        } catch {
            // Network error — keep current state
        }
    }

    func signOut() {
        // Preserve display name and email — Apple only provides them on first sign-in
        isSignedIn = false
        userID = nil
        UserDefaults.standard.removeObject(forKey: userIDKey)
    }

    func deleteAllCredentials() {
        clearStoredCredentials()
    }

    private func loadStoredCredentials() {
        let id = UserDefaults.standard.string(forKey: userIDKey)
        userID = id
        userEmail = UserDefaults.standard.string(forKey: userEmailKey)
        userDisplayName = UserDefaults.standard.string(forKey: userDisplayNameKey)
        isSignedIn = (id != nil)
    }

    private func clearStoredCredentials() {
        userID = nil
        userEmail = nil
        userDisplayName = nil
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userDisplayNameKey)
    }

    enum AuthError: LocalizedError {
        case invalidCredential

        var errorDescription: String? {
            switch self {
            case .invalidCredential: return "Invalid Apple sign-in credential."
            }
        }
    }
}
