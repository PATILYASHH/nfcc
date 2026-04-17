package com.nfccontrol.nfcc_mobile

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * Invisible activity that handles NFC NDEF_DISCOVERED intents.
 * Processes the tag silently and finishes immediately - no UI shown.
 * Sends data to MainActivity's Flutter engine via a static callback.
 */
class NfcReceiverActivity : Activity() {

    private val TAG = "NFCC_Receiver"

    companion object {
        // Callback to send tag data to Flutter (set by MainActivity)
        var onTagReceived: ((uid: String, ndefText: String?) -> Unit)? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "NFC receiver started")
        handleIntent()
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent()
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    private fun handleIntent() {
        val intent = intent ?: return
        val action = intent.action ?: return

        if (action != NfcAdapter.ACTION_NDEF_DISCOVERED &&
            action != NfcAdapter.ACTION_TECH_DISCOVERED &&
            action != NfcAdapter.ACTION_TAG_DISCOVERED) return

        Log.d(TAG, "Processing NFC intent: $action")

        // Extract UID
        val tag: Tag? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
        }
        val uid = tag?.id?.joinToString(":") { "%02X".format(it) } ?: "UNKNOWN"

        // Extract NDEF text
        var ndefText: String? = null
        val rawMessages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES, NdefMessage::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
        }

        if (rawMessages != null && rawMessages.isNotEmpty()) {
            val msg = rawMessages[0] as NdefMessage
            for (record in msg.records) {
                if (record.tnf == android.nfc.NdefRecord.TNF_MIME_MEDIA) {
                    val mimeType = String(record.type, Charsets.UTF_8)
                    if (mimeType == "application/com.nfccontrol.nfcc") {
                        ndefText = String(record.payload, Charsets.UTF_8)
                        break
                    }
                }
                if (record.tnf == android.nfc.NdefRecord.TNF_WELL_KNOWN) {
                    val payload = record.payload
                    if (payload.isNotEmpty()) {
                        val langLen = (payload[0].toInt() and 0x3F)
                        if (payload.size > langLen + 1) {
                            ndefText = String(payload, langLen + 1, payload.size - langLen - 1, Charsets.UTF_8)
                        }
                    }
                }
            }
        }

        Log.d(TAG, "Tag: uid=$uid ndef=$ndefText")

        // Handle UPI payment tags: payload format "UPI:<package>:<uri>"
        if (ndefText != null && ndefText!!.startsWith("UPI:")) {
            val parts = ndefText!!.substring(4).split(":", limit = 2)
            if (parts.size == 2) {
                val packageName = parts[0]
                val upiUri = parts[1]
                Log.d(TAG, "UPI tag! package=$packageName uri=$upiUri")
                try {
                    val upiIntent = Intent(Intent.ACTION_VIEW, Uri.parse(upiUri))
                    upiIntent.setPackage(packageName)
                    upiIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(upiIntent)
                } catch (e: Exception) {
                    Log.w(TAG, "App $packageName not found, trying generic")
                    try {
                        val fallback = Intent(Intent.ACTION_VIEW, Uri.parse(upiUri))
                        fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(fallback)
                    } catch (e2: Exception) {
                        Log.e(TAG, "No UPI app: ${e2.message}")
                    }
                }
                vibrateOnce()
                return
            }
        }

        // Send to Flutter via static callback for automation execution
        val callback = onTagReceived
        if (callback != null) {
            callback(uid, ndefText)
            Log.d(TAG, "Sent to Flutter")
        } else {
            // App not running - save to SharedPreferences for later pickup
            Log.w(TAG, "No Flutter callback - saving to SharedPreferences")
            val prefs = getSharedPreferences("nfcc_pending_tag", MODE_PRIVATE)
            prefs.edit()
                .putString("uid", uid)
                .putString("ndefText", ndefText)
                .putLong("timestamp", System.currentTimeMillis())
                .apply()
            vibrateOnce()
        }
    }

    @Suppress("DEPRECATION")
    private fun vibrateOnce() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val mgr = getSystemService(VIBRATOR_MANAGER_SERVICE) as VibratorManager
                mgr.defaultVibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                val v = getSystemService(VIBRATOR_SERVICE) as Vibrator
                v.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
            }
        } catch (_: Exception) {}
    }
}
