package com.jatin.J3Tunes

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.os.Build
import android.widget.RemoteViews
import androidx.media.session.MediaButtonReceiver
import android.support.v4.media.session.PlaybackStateCompat
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class MusicWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.music_widget).apply {
                // Get data from Flutter
                val title = widgetData.getString("title", "No Song Playing")
                val artist = widgetData.getString("artist", "JTunes")
                val artworkPath = widgetData.getString("artwork_path", null)
                val isPlaying = widgetData.getBoolean("is_playing", false)

                // Update text views
                setTextViewText(R.id.song_title, title)
                setTextViewText(R.id.artist_name, artist)

                // Update play/pause icon
                val playPauseIcon = if (isPlaying) R.drawable.ic_pause_white_24dp else R.drawable.ic_play_arrow_white_24dp
                setImageViewResource(R.id.play_pause_button, playPauseIcon)

                // Update artwork
                try {
                    if (artworkPath != null && File(artworkPath).exists()) {
                        val bitmap = BitmapFactory.decodeFile(artworkPath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.album_art, bitmap)
                        } else {
                            setImageViewResource(R.id.album_art, R.drawable.default_album_art)
                        }
                    } else {
                        setImageViewResource(R.id.album_art, R.drawable.default_album_art)
                    }
                } catch (e: Exception) {
                    setImageViewResource(R.id.album_art, R.drawable.default_album_art)
                }

                // Set PendingIntents for buttons
                val mediaSessionComponent = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")

                // Play/Pause
                val playPauseIntent = MediaButtonReceiver.buildMediaButtonPendingIntent(context, mediaSessionComponent, PlaybackStateCompat.ACTION_PLAY_PAUSE)
                setOnClickPendingIntent(R.id.play_pause_button, playPauseIntent)

                // Next
                val nextIntent = MediaButtonReceiver.buildMediaButtonPendingIntent(context, mediaSessionComponent, PlaybackStateCompat.ACTION_SKIP_TO_NEXT)
                setOnClickPendingIntent(R.id.next_button, nextIntent)

                // Previous
                val prevIntent = MediaButtonReceiver.buildMediaButtonPendingIntent(context, mediaSessionComponent, PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS)
                setOnClickPendingIntent(R.id.prev_button, prevIntent)

                // Open App on click (optional, if the entire widget should open the app)
                val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntentFlags = if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE else PendingIntent.FLAG_UPDATE_CURRENT
                val openAppPendingIntent = PendingIntent.getActivity(context, 0, openAppIntent, pendingIntentFlags)
                setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
