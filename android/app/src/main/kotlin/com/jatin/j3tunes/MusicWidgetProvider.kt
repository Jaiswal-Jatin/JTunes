package com.jatin.J3Tunes

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews
import androidx.media.session.MediaButtonReceiver
import android.support.v4.media.session.PlaybackStateCompat
import androidx.palette.graphics.Palette
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class MusicWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.music_widget_layout).apply {
                // Get data from Flutter
                val title = widgetData.getString("title", "No Song Playing")
                val artist = widgetData.getString("artist", "JTunes")
                val artworkPath = widgetData.getString("artwork_path", null)
                val isPlaying = widgetData.getBoolean("is_playing", false)
                val duration = widgetData.getLong("duration", 0L)
                val position = widgetData.getLong("position", 0L)

                // Update text views
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_artist, artist)

                // Update time and progress
                setTextViewText(R.id.widget_current_time, formatDuration(position))
                setTextViewText(R.id.widget_total_time, formatDuration(duration))
                if (duration > 0) {
                    setProgressBar(R.id.widget_progress, duration.toInt(), position.toInt(), false)
                } else {
                    setProgressBar(R.id.widget_progress, 1, 0, false)
                }

                // Update play/pause icon
                val playPauseIcon = if (isPlaying) R.drawable.audio_service_pause else R.drawable.audio_service_play_arrow
                setImageViewResource(R.id.widget_button_play_pause, playPauseIcon)

                // Update artwork and background color
                var dominantColor: Int
                try {
                    if (artworkPath != null && File(artworkPath).exists()) {
                        val bitmap = BitmapFactory.decodeFile(artworkPath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.widget_album_art, bitmap)
                            // Use Palette to get dominant color synchronously
                            val palette = Palette.from(bitmap).generate()
                            dominantColor = palette.darkVibrantSwatch?.rgb ?: palette.darkMutedSwatch?.rgb ?: Color.parseColor("#424242")
                        } else {
                            setImageViewResource(R.id.widget_album_art, R.drawable.ic_launcher_foreground)
                            dominantColor = Color.parseColor("#424242")
                        }
                    } else {
                        setImageViewResource(R.id.widget_album_art, R.drawable.ic_launcher_foreground)
                        dominantColor = Color.parseColor("#424242")
                    }
                } catch (e: Exception) {
                    setImageViewResource(R.id.widget_album_art, R.drawable.ic_launcher_foreground)
                    dominantColor = Color.parseColor("#424242")
                }
                setInt(R.id.widget_root, "setBackgroundColor", dominantColor)


                // Set PendingIntents for buttons
                // Use the MediaButtonReceiver from the audio_service package
                val mediaSessionComponent = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")

                // Play/Pause
                val playPauseIntent = MediaButtonReceiver.buildMediaButtonPendingIntent(context, mediaSessionComponent, PlaybackStateCompat.ACTION_PLAY_PAUSE)
                setOnClickPendingIntent(R.id.widget_button_play_pause, playPauseIntent)

                // Next
                val nextIntent = MediaButtonReceiver.buildMediaButtonPendingIntent(context, mediaSessionComponent, PlaybackStateCompat.ACTION_SKIP_TO_NEXT)
                setOnClickPendingIntent(R.id.widget_button_next, nextIntent)

                // Previous
                val prevIntent = MediaButtonReceiver.buildMediaButtonPendingIntent(context, mediaSessionComponent, PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS)
                setOnClickPendingIntent(R.id.widget_button_prev, prevIntent)

                // Open App on click
                val openAppIntent = Intent(context, com.ryanheise.audioservice.AudioServiceActivity::class.java)
                val pendingIntentFlags = if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE else PendingIntent.FLAG_UPDATE_CURRENT
                val openAppPendingIntent = PendingIntent.getActivity(context, 0, openAppIntent, pendingIntentFlags)
                setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun formatDuration(millis: Long): String {
        val totalSeconds = millis / 1000
        val seconds = totalSeconds % 60
        val minutes = (totalSeconds / 60) % 60
        val hours = totalSeconds / 3600

        return if (hours > 0) {
            String.format("%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d", minutes, seconds)
        }
    }
}
