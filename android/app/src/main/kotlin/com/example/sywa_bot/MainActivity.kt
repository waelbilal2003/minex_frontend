package site.minexsy.minex_syrian_arab

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()

val actionCodeSettings = actionCodeSettings {
    // URL you want to redirect back to. The domain (www.example.com) for this
    // URL must be whitelisted in the Firebase Console.
    url = "https://www.example.com/finishSignUp?cartId=1234"
    // This must be true
    handleCodeInApp = true
    setIOSBundleId("com.example.ios")
    setAndroidPackageName(
        "com.example.android",
        true, // installIfNotAvailable
        "12", // minimumVersion
    )
}

Firebase.auth.sendSignInLinkToEmail(email, actionCodeSettings)
    .addOnCompleteListener { task ->
        if (task.isSuccessful) {
            Log.d(TAG, "Email sent.")
        }
    }

val auth = Firebase.auth
val intent = intent
val emailLink = intent.data.toString()

// Confirm the link is a sign-in with email link.
if (auth.isSignInWithEmailLink(emailLink)) {
    // Retrieve this from wherever you stored it
    val email = "someemail@domain.com"

    // The client SDK will parse the code from the link for you.
    auth.signInWithEmailLink(email, emailLink)
        .addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d(TAG, "Successfully signed in with email link!")
                val result = task.result
                // You can access the new user via result.getUser()
                // Additional user info profile *not* available via:
                // result.getAdditionalUserInfo().getProfile() == null
                // You can check if the user is new or existing:
                // result.getAdditionalUserInfo().isNewUser()
            } else {
                Log.e(TAG, "Error signing in with email link", task.exception)
            }
        }
}

// Construct the email link credential from the current URL.
val credential = EmailAuthProvider.getCredentialWithLink(email, emailLink)

// Link the credential to the current user.
Firebase.auth.currentUser!!.linkWithCredential(credential)
    .addOnCompleteListener { task ->
        if (task.isSuccessful) {
            Log.d(TAG, "Successfully linked emailLink credential!")
            val result = task.result
            // You can access the new user via result.getUser()
            // Additional user info profile *not* available via:
            // result.getAdditionalUserInfo().getProfile() == null
            // You can check if the user is new or existing:
            // result.getAdditionalUserInfo().isNewUser()
        } else {
            Log.e(TAG, "Error linking emailLink credential", task.exception)
        }
    }

// Construct the email link credential from the current URL.
val credential = EmailAuthProvider.getCredentialWithLink(email, emailLink)

// Re-authenticate the user with this credential.
Firebase.auth.currentUser!!.reauthenticateAndRetrieveData(credential)
    .addOnCompleteListener { task ->
        if (task.isSuccessful) {
            // User is now successfully reauthenticated
        } else {
            Log.e(TAG, "Error reauthenticating", task.exception)
        }
    }

Firebase.auth.signOut()