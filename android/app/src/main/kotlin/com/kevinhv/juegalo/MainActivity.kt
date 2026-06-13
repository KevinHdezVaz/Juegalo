package com.kevinhv.juegalo

import android.os.Handler
import android.os.Looper
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * MainActivity con MethodChannel para Google Play Integrity API.
 *
 * El channel "juegalo.app/play_integrity" expone el método "getToken" que recibe
 * un nonce desde Flutter y devuelve un token de Play Integrity firmado por
 * Google Play Services. Ese token va al backend (Supabase Edge Function
 * `verify-play-integrity`) que lo decodifica con Google Play Integrity API
 * para verificar:
 *   - APK no modificado (PLAY_RECOGNIZED)
 *   - Device legítimo (MEETS_DEVICE_INTEGRITY)
 *   - App instalada vía Play Store (LICENSED)
 */
class MainActivity : FlutterActivity() {

    private val CHANNEL = "juegalo.app/play_integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getToken" -> {
                        val nonce = call.argument<String>("nonce")
                        if (nonce.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "nonce is required", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val integrityManager =
                                IntegrityManagerFactory.create(applicationContext)
                            val tokenRequest = IntegrityTokenRequest.builder()
                                .setNonce(nonce)
                                .build()

                            // Anti-cuelgue: emulador con Play Services puede
                            // bindear al servicio pero Google nunca devuelve
                            // un token. Sin timeout la app queda colgada.
                            val replied = AtomicBoolean(false)
                            val timeoutMs = 8000L

                            Handler(Looper.getMainLooper()).postDelayed({
                                if (replied.compareAndSet(false, true)) {
                                    result.error(
                                        "INTEGRITY_TIMEOUT",
                                        "timeout waiting for integrity token (${timeoutMs}ms)",
                                        null
                                    )
                                }
                            }, timeoutMs)

                            integrityManager.requestIntegrityToken(tokenRequest)
                                .addOnSuccessListener { response ->
                                    if (replied.compareAndSet(false, true)) {
                                        result.success(response.token())
                                    }
                                }
                                .addOnFailureListener { exception ->
                                    if (replied.compareAndSet(false, true)) {
                                        result.error(
                                            "INTEGRITY_FAILED",
                                            exception.message ?: "unknown error",
                                            exception.toString()
                                        )
                                    }
                                }
                        } catch (e: Exception) {
                            result.error(
                                "INTEGRITY_EXCEPTION",
                                e.message ?: "unknown",
                                e.toString()
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
