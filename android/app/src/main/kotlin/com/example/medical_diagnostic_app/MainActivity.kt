package com.example.medical_diagnostic_app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var successPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FEEDBACK_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRingerModeNormal" -> result.success(isRingerModeNormal())
                "playPrescriptionSuccess" -> playPrescriptionSuccess(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun isRingerModeNormal(): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return audioManager.ringerMode == AudioManager.RINGER_MODE_NORMAL
    }

    private fun playPrescriptionSuccess(result: MethodChannel.Result) {
        try {
            successPlayer?.release()
            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            assets.openFd(SUCCESS_SOUND_ASSET).use { descriptor ->
                player.setDataSource(
                    descriptor.fileDescriptor,
                    descriptor.startOffset,
                    descriptor.length,
                )
            }
            player.setVolume(SUCCESS_VOLUME, SUCCESS_VOLUME)
            player.setOnCompletionListener { completedPlayer ->
                completedPlayer.release()
                if (successPlayer === completedPlayer) successPlayer = null
            }
            player.setOnErrorListener { failedPlayer, _, _ ->
                failedPlayer.release()
                if (successPlayer === failedPlayer) successPlayer = null
                true
            }
            player.prepare()
            successPlayer = player
            player.start()
            result.success(null)
        } catch (error: Exception) {
            successPlayer?.release()
            successPlayer = null
            result.error(
                "SUCCESS_SOUND_UNAVAILABLE",
                "The prescription success sound could not be played.",
                error.message,
            )
        }
    }

    override fun onDestroy() {
        successPlayer?.release()
        successPlayer = null
        super.onDestroy()
    }

    companion object {
        private const val FEEDBACK_CHANNEL = "com.testified/device_feedback"
        private const val SUCCESS_SOUND_ASSET =
            "flutter_assets/assets/audio/prescription_sent.wav"
        private const val SUCCESS_VOLUME = 0.46f
    }
}
