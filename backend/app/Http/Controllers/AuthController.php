<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\UserToken;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Http\Services\AuthService;
use App\Http\Requests\LoginRequest;
use Illuminate\Support\Facades\Auth;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\ChangePasswordRequest;
use App\Http\Services\ChangePasswordService;
use App\Http\Services\TokenService;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request as HttpRequest;
use Illuminate\Support\Facades\Http as HttpClient;
use Carbon\Carbon;

class AuthController extends Controller
{
    protected $authService,$passwordService;

    public function __construct(AuthService $authService,ChangePasswordService $passwordService , protected TokenService $service)
    {
        $this->authService = $authService;
         $this->passwordService = $passwordService;
    }

    public function register(RegisterRequest $request)
    {
        $result = $this->authService->register($request->validated());

        return response()->json([
            'success' => $result['success'],
            'message' => $result['message'],
            'data'    => $result['user'] ?? null,
        ], $result['status']);
    }

       public function login(LoginRequest $request)
    {
        $result = $this->authService->login($request->validated(),$request);

        return response()->json([
            'success' => $result['success'],
            'message' => $result['message'],
            'data' => $result['data'] ?? null,
        ], $result['status']);
    }

    public function verifyToken(Request $request)
    {
        // جلب التوكن من الهيدر Bearer
        $authHeader = $request->header('Authorization', '');
        $token = null;
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
        }

        $result = $this->authService->verifyToken($token);

        return response()->json([
            'success' => $result['success'],
            'message' => $result['message'],
        ], $result['status']);
    }
      public function forgotPassword(Request $request)
    {
              $request->validate([
            'email_or_phone' => 'required|string|max:100',
        ]);
        $result = $this->authService->forgotPassword($request->input('email_or_phone'));

        return response()->json($result);
    }

        public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
         $userId=$this->service->validateToken($request->bearerToken());
$user=User::where('id',$userId->id)->first();
        $result = $this->passwordService->change(
            $user,
            $request->current_password,
            $request->new_password
        );

        return response()->json($result);
    }
    public function resendVerificationEmail(Request $request)
    {
        // نفترض أنك قمت بحقن AuthService في الـ constructor
        // protected $authService;
        // public function __construct(AuthService $authService) { $this->authService = $authService; }
    
        $result = $this->authService->resendVerification($request);
        return response()->json($result, $result['status']);
    }

    /**
     * Verify Firebase ID token and mark user's email as verified in the local DB.
     * Expects Authorization: Bearer <Firebase ID token>
     */
    public function verifyFirebaseEmail(HttpRequest $request)
    {
        $idToken = $request->bearerToken();
        if (!$idToken) {
            return response()->json(['success' => false, 'message' => 'No ID token provided'], 401);
        }

        try {
            // If kreait/firebase-php is installed, prefer verifying via the Admin SDK
            if (class_exists('\\Kreait\\Firebase\\Factory')) {
                $serviceAccount = env('FIREBASE_CREDENTIALS') ?: env('GOOGLE_APPLICATION_CREDENTIALS');
                $factory = new \Kreait\Firebase\Factory();
                if ($serviceAccount) {
                    $factory = $factory->withServiceAccount($serviceAccount);
                }
                $firebaseAuth = $factory->createAuth();

                $verifiedToken = $firebaseAuth->verifyIdToken($idToken);
                $email = $verifiedToken->claims()->get('email');
            } else {
                // Fallback: use Google's tokeninfo endpoint to validate the ID token
                // NOTE: This is a pragmatic fallback for environments where installing
                // the Admin SDK is not possible. It's less strict than server-side
                // signature verification but acceptable as a temporary measure.
                $resp = HttpClient::asForm()->post('https://oauth2.googleapis.com/tokeninfo', [
                    'id_token' => $idToken,
                ]);

                if (!$resp->ok()) {
                    Log::warning('tokeninfo failed: ' . $resp->body());
                    return response()->json(['success' => false, 'message' => 'Invalid Firebase token'], 401);
                }

                $data = $resp->json();
                $email = $data['email'] ?? null;

                // Optional: validate issuer/project
                $expectedProject = env('FIREBASE_PROJECT_ID') ?: env('FIREBASE_PROJECT');
                if ($expectedProject && isset($data['aud']) && $data['aud'] !== $expectedProject && ($data['aud'] ?? '') !== env('FIREBASE_CLIENT_ID')) {
                    Log::warning('tokeninfo aud mismatch: ' . ($data['aud'] ?? ''));
                    return response()->json(['success' => false, 'message' => 'Token audience mismatch'], 401);
                }
            }

            if (!$email) {
                return response()->json(['success' => false, 'message' => 'No email claim in token'], 400);
            }

            $user = User::where('email', $email)->first();
            if (!$user) {
                return response()->json(['success' => false, 'message' => 'User not found'], 404);
            }

            // Mark email verified locally
            $user->email_verified_at = Carbon::now();
            $user->save();

            return response()->json(['success' => true, 'message' => 'Email verified successfully']);
        } catch (\Kreait\Firebase\Exception\AuthException $e) {
            Log::error('Firebase auth error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Invalid Firebase token'], 401);
        } catch (\Throwable $e) {
            Log::error('verifyFirebaseEmail error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Server error'], 500);
        }
    }

}
