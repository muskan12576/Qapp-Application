package com.example.qapp

import android.media.MediaPlayer
import android.media.MediaRecorder
import android.media.AudioAttributes
import android.widget.VideoView
import android.widget.MediaController
import android.os.Build
import android.os.Bundle
import android.Manifest
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.location.Location
import android.location.LocationManager
import android.location.LocationListener
import android.content.pm.PackageManager
import android.view.View
import android.widget.FrameLayout
import android.view.Gravity
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import java.io.File
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null
    private var audioResult: MethodChannel.Result? = null
    private var locationResult: MethodChannel.Result? = null
    private var contactsPermissionResult: MethodChannel.Result? = null
    private var recorder: MediaRecorder? = null
    private var audioPath: String? = null
    private var mediaPlayer: MediaPlayer? = null
    private var currentAudioPath: String? = null

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 41 || requestCode == 42) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            val slot = if (requestCode == 41) permissionResult else audioResult
            slot?.success(granted)
            if (requestCode == 41) {
                permissionResult = null
            } else {
                audioResult = null
            }
            return
        }
        if (requestCode == 43) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                fetchLocation(locationResult)
            } else {
                locationResult?.error("permission_denied", "Location permission denied", null)
            }
            locationResult = null
            return
        }
        if (requestCode == 44) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            contactsPermissionResult?.success(granted)
            contactsPermissionResult = null
            return
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine.platformViewsController.registry.registerViewFactory(
            "qapp/camera",
            QappCameraFactory(flutterEngine.dartExecutor.binaryMessenger),
        )
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "qapp/video_player",
            QappVideoFactory(flutterEngine.dartExecutor.binaryMessenger),
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qapp/camera_perm")
            .setMethodCallHandler { call, result ->
                if (call.method != "grant") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val granted = ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.CAMERA,
                ) == PackageManager.PERMISSION_GRANTED
                if (granted) {
                    result.success(true)
                } else {
                    permissionResult = result
                    requestPermissions(arrayOf(Manifest.permission.CAMERA), 41)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qapp/open_file")
            .setMethodCallHandler { call, result ->
                if (call.method == "dial") {
                    val raw = call.argument<String>("number") ?: ""
                    val number = raw.filter { it.isDigit() || it == '+' }
                    if (number.isEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number")))
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                    return@setMethodCallHandler
                }
                if (call.method == "share") {
                    val text = call.argument<String>("text") ?: ""
                    val title = call.argument<String>("title") ?: "Share via"
                    try {
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(Intent.createChooser(shareIntent, title).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                    return@setMethodCallHandler
                }
                if (call.method == "map" || call.method == "open_url") {
                    val rawUrl = call.argument<String>("url") ?: ""
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(rawUrl)).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                    return@setMethodCallHandler
                }
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrEmpty()) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                try {
                    val src = File(path)
                    if (!src.exists()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val safe = src.name.replace(Regex("[^A-Za-z0-9._-]"), "_").ifBlank { "file" }
                    val dest = File(cacheDir, safe)
                    if (src.absolutePath != dest.absolutePath) {
                        src.copyTo(dest, overwrite = true)
                    }
                    val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", dest)
                    val mime = MimeTypeMap.getSingleton()
                        .getMimeTypeFromExtension(dest.extension.lowercase())
                        ?: "application/octet-stream"
                    val view = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, mime)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    val chooser = Intent.createChooser(view, dest.name).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(chooser)
                    result.success(true)
                } catch (_: Exception) {
                    result.success(false)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qapp/location")
            .setMethodCallHandler { call, result ->
                if (call.method == "getLocation") {
                    val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    val coarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    if (fine || coarse) {
                        fetchLocation(result)
                    } else {
                        locationResult = result
                        requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), 43)
                    }
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qapp/contacts")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.READ_CONTACTS
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }
                    "requestPermission" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.READ_CONTACTS
                        ) == PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success(true)
                        } else {
                            contactsPermissionResult = result
                            requestPermissions(arrayOf(Manifest.permission.READ_CONTACTS), 44)
                        }
                    }
                    "getContacts" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.READ_CONTACTS
                        ) == PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            result.success(emptyList<Map<String, String>>())
                            return@setMethodCallHandler
                        }
                        Thread {
                            val list = mutableListOf<Map<String, String>>()
                            val seen = HashSet<String>()
                            try {
                                val cursor = contentResolver.query(
                                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                                    arrayOf(
                                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                                        ContactsContract.CommonDataKinds.Phone.NUMBER,
                                        ContactsContract.CommonDataKinds.Phone.PHOTO_URI,
                                    ),
                                    null,
                                    null,
                                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC"
                                )
                                cursor?.use {
                                    val nameIdx = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                                    val numIdx = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                                    val photoIdx = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.PHOTO_URI)
                                    while (it.moveToNext()) {
                                        val name = if (nameIdx >= 0) it.getString(nameIdx) ?: "" else ""
                                        val rawNum = if (numIdx >= 0) it.getString(numIdx) ?: "" else ""
                                        val photo = if (photoIdx >= 0) it.getString(photoIdx) ?: "" else ""
                                        val cleanNum = rawNum.replace("[^0-9+]".toRegex(), "")
                                        val key = if (cleanNum.isNotEmpty()) cleanNum else name
                                        if (key.isNotEmpty() && !seen.contains(key)) {
                                            seen.add(key)
                                            val map = HashMap<String, String>()
                                            map["name"] = name.ifBlank { rawNum.ifBlank { "Contact" } }
                                            map["phone"] = if (cleanNum.isNotEmpty()) cleanNum else rawNum
                                            map["photo"] = photo
                                            list.add(map)
                                        }
                                    }
                                }

                                if (list.isEmpty()) {
                                    val cCursor = contentResolver.query(
                                        ContactsContract.Contacts.CONTENT_URI,
                                        arrayOf(
                                            ContactsContract.Contacts.DISPLAY_NAME,
                                            ContactsContract.Contacts.PHOTO_URI,
                                        ),
                                        null,
                                        null,
                                        ContactsContract.Contacts.DISPLAY_NAME + " ASC"
                                    )
                                    cCursor?.use {
                                        val nameIdx = it.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME)
                                        val photoIdx = it.getColumnIndex(ContactsContract.Contacts.PHOTO_URI)
                                        while (it.moveToNext()) {
                                            val name = if (nameIdx >= 0) it.getString(nameIdx) ?: "" else ""
                                            val photo = if (photoIdx >= 0) it.getString(photoIdx) ?: "" else ""
                                            if (name.isNotEmpty() && !seen.contains(name)) {
                                                seen.add(name)
                                                val map = HashMap<String, String>()
                                                map["name"] = name
                                                map["phone"] = ""
                                                map["photo"] = photo
                                                list.add(map)
                                            }
                                        }
                                    }
                                }
                            } catch (_: Exception) {}
                            runOnUiThread {
                                result.success(list)
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }

        val audioChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qapp/audio")
        audioChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "grant" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO,
                    ) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        result.success(true)
                    } else {
                        audioResult = result
                        requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 42)
                    }
                }
                "start" -> {
                    try {
                        result.success(startVoice())
                    } catch (error: Exception) {
                        result.error("audio", error.message, null)
                    }
                }
                "stop" -> result.success(stopVoice(true))
                "cancel" -> result.success(stopVoice(false))
                "play" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.error("invalid_path", "Path is empty", null)
                        return@setMethodCallHandler
                    }
                    try {
                        if (mediaPlayer != null && currentAudioPath == path) {
                            if (mediaPlayer?.isPlaying == false) {
                                mediaPlayer?.start()
                            }
                            result.success(mapOf("status" to "playing", "path" to path))
                            return@setMethodCallHandler
                        }

                        try {
                            mediaPlayer?.stop()
                            mediaPlayer?.release()
                        } catch (_: Exception) {}
                        mediaPlayer = null

                        val player = MediaPlayer()
                        player.setAudioAttributes(
                            AudioAttributes.Builder()
                                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                .setUsage(AudioAttributes.USAGE_MEDIA)
                                .build()
                        )
                        if (path.startsWith("http://") || path.startsWith("https://")) {
                            player.setDataSource(path)
                        } else {
                            val f = File(path)
                            if (!f.exists()) {
                                result.error("not_found", "Audio file not found: $path", null)
                                return@setMethodCallHandler
                            }
                            player.setDataSource(f.absolutePath)
                        }
                        player.setOnPreparedListener { mp ->
                            mp.start()
                            audioChannel.invokeMethod("onAudioPrepared", mapOf("duration" to mp.duration, "path" to path))
                        }
                        player.setOnCompletionListener { mp ->
                            currentAudioPath = null
                            try { mp.release() } catch (_: Exception) {}
                            if (mediaPlayer == mp) mediaPlayer = null
                            audioChannel.invokeMethod("onAudioComplete", mapOf("path" to path))
                        }
                        player.setOnErrorListener { mp, what, extra ->
                            currentAudioPath = null
                            try { mp.release() } catch (_: Exception) {}
                            if (mediaPlayer == mp) mediaPlayer = null
                            audioChannel.invokeMethod("onAudioError", mapOf("path" to path, "what" to what))
                            true
                        }
                        player.prepareAsync()
                        mediaPlayer = player
                        currentAudioPath = path
                        result.success(mapOf("status" to "playing", "path" to path))
                    } catch (e: Exception) {
                        result.error("play_error", e.message, null)
                    }
                }
                "pause" -> {
                    try {
                        if (mediaPlayer?.isPlaying == true) {
                            mediaPlayer?.pause()
                            result.success(mapOf("status" to "paused", "path" to currentAudioPath))
                        } else {
                            result.success(mapOf("status" to "idle"))
                        }
                    } catch (e: Exception) {
                        result.error("pause_error", e.message, null)
                    }
                }
                "stop_play" -> {
                    try {
                        mediaPlayer?.stop()
                        mediaPlayer?.release()
                    } catch (_: Exception) {}
                    mediaPlayer = null
                    currentAudioPath = null
                    result.success(true)
                }
                "status" -> {
                    val isPlaying = try { mediaPlayer?.isPlaying == true } catch (_: Exception) { false }
                    val pos = try { mediaPlayer?.currentPosition ?: 0 } catch (_: Exception) { 0 }
                    val dur = try { mediaPlayer?.duration ?: 0 } catch (_: Exception) { 0 }
                    result.success(mapOf(
                        "isPlaying" to isPlaying,
                        "position" to pos,
                        "duration" to dur,
                        "path" to currentAudioPath
                    ))
                }
                "seek" -> {
                    val pos = call.argument<Int>("position") ?: 0
                    try {
                        mediaPlayer?.seekTo(pos)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("seek_error", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun fetchLocation(result: MethodChannel.Result?) {
        try {
            val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            if (lm == null) {
                result?.error("no_manager", "LocationManager not available", null)
                return
            }
            val hasGps = lm.isProviderEnabled(LocationManager.GPS_PROVIDER)
            val hasNet = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)

            var bestLoc: Location? = null
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                if (hasGps) {
                    val loc = lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                    if (loc != null) bestLoc = loc
                }
                if (hasNet && (bestLoc == null || (bestLoc.time < System.currentTimeMillis() - 60000))) {
                    val netLoc = lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                    if (netLoc != null && (bestLoc == null || netLoc.time > bestLoc.time)) {
                        bestLoc = netLoc
                    }
                }
            }

            if (bestLoc != null) {
                result?.success(mapOf("lat" to bestLoc.latitude, "lng" to bestLoc.longitude))
            } else {
                if (hasNet || hasGps) {
                    val provider = if (hasNet) LocationManager.NETWORK_PROVIDER else LocationManager.GPS_PROVIDER
                    lm.requestSingleUpdate(provider, object : LocationListener {
                        override fun onLocationChanged(loc: Location) {
                            result?.success(mapOf("lat" to loc.latitude, "lng" to loc.longitude))
                        }
                        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                        override fun onProviderEnabled(provider: String) {}
                        override fun onProviderDisabled(provider: String) {}
                    }, mainLooper)
                } else {
                    result?.error("disabled", "GPS / Location is turned off", null)
                }
            }
        } catch (e: Exception) {
            result?.error("location_error", e.message, null)
        }
    }

    private fun startVoice(): String {
        stopVoice(false)
        val file = File(cacheDir, "voice_${System.currentTimeMillis()}.m4a")
        val rec = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        rec.setAudioSource(MediaRecorder.AudioSource.MIC)
        rec.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        rec.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        rec.setOutputFile(file.absolutePath)
        rec.prepare()
        rec.start()
        recorder = rec
        audioPath = file.absolutePath
        return file.absolutePath
    }

    private fun stopVoice(keep: Boolean): String? {
        val path = audioPath
        try {
            recorder?.stop()
        } catch (_: Exception) {
        }
        try {
            recorder?.release()
        } catch (_: Exception) {
        }
        recorder = null
        audioPath = null
        if (!keep && path != null) {
            File(path).delete()
            return null
        }
        return path
    }
}

private class QappVideoFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val path = params?.get("path") as? String ?: ""
        return QappVideoView(context, messenger, viewId, path)
    }
}

private class QappVideoView(
    private val context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    private var path: String,
) : PlatformView {
    private val container = FrameLayout(context).apply {
        setBackgroundColor(android.graphics.Color.TRANSPARENT)
    }
    private val videoView = VideoView(context)
    private var webView: WebView? = null
    private val channel = MethodChannel(messenger, "qapp/video_$viewId")
    private var isWebMode = false

    init {
        videoView.setOnErrorListener { _, _, _ -> true }
        val controller = MediaController(context)
        controller.setAnchorView(container)
        videoView.setMediaController(controller)

        container.addView(
            videoView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
                Gravity.CENTER,
            ),
        )

        if (path.isNotEmpty()) {
            loadVideo(path)
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    if (isWebMode) {
                        webView?.evaluateJavascript(
                            "try { document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":\"\"}', '*'); var v = document.querySelector('video'); if (v) v.play(); } catch(e) {}",
                            null,
                        )
                        webView?.onResume()
                    } else {
                        videoView.start()
                    }
                    result.success(true)
                }
                "pause" -> {
                    if (isWebMode) {
                        webView?.evaluateJavascript(
                            "try { document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"pauseVideo\",\"args\":\"\"}', '*'); var v = document.querySelector('video'); if (v) v.pause(); } catch(e) {}",
                            null,
                        )
                        webView?.onPause()
                    } else {
                        videoView.pause()
                    }
                    result.success(true)
                }
                "stop" -> {
                    if (isWebMode) {
                        webView?.loadUrl("about:blank")
                    } else {
                        videoView.stopPlayback()
                    }
                    result.success(true)
                }
                "load" -> {
                    val nextPath = call.argument<String>("path") ?: ""
                    loadVideo(nextPath)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun extractYouTubeId(url: String): String? {
        if (url.isEmpty()) return null
        val patterns = listOf(
            Regex("(?:youtu\\.be\\/|youtube\\.com\\/(?:embed\\/|v\\/|watch\\?v=|watch\\?.+&v=|shorts\\/|live\\/))([\\w-]{11})"),
            Regex("[?&]v=([\\w-]{11})"),
            Regex("list=RD([\\w-]{11})")
        )
        for (p in patterns) {
            val match = p.find(url)
            if (match != null) {
                return match.groupValues[1]
            }
        }
        if (url.matches(Regex("^[\\w-]{11}$"))) {
            return url
        }
        return null
    }

    private fun isEmbedUrl(url: String): Boolean {
        if (url.isEmpty()) return false
        val lower = url.lowercase()
        return extractYouTubeId(url) != null ||
               lower.contains("youtube.com") ||
               lower.contains("youtu.be") ||
               lower.contains("vimeo.com") ||
               lower.contains("dailymotion.com") ||
               lower.contains("dai.ly") ||
               lower.contains("instagram.com") ||
               lower.contains("tiktok.com") ||
               lower.contains("facebook.com") ||
               lower.contains("/embed")
    }

    private fun loadVideo(src: String) {
        path = src
        try {
            val ytId = extractYouTubeId(src)
            val isEmbed = ytId != null || isEmbedUrl(src)

            if (isEmbed) {
                isWebMode = true
                videoView.visibility = View.GONE
                try { videoView.stopPlayback() } catch (_: Exception) {}

                if (webView == null) {
                    val wv = WebView(context).apply {
                        layoutParams = FrameLayout.LayoutParams(
                            FrameLayout.LayoutParams.MATCH_PARENT,
                            FrameLayout.LayoutParams.MATCH_PARENT,
                            Gravity.CENTER,
                        )
                        setBackgroundColor(android.graphics.Color.TRANSPARENT)
                        settings.javaScriptEnabled = true
                        settings.domStorageEnabled = true
                        settings.databaseEnabled = true
                        val defaultUA = settings.userAgentString ?: ""
                        settings.userAgentString = defaultUA.replace("; wv", "")
                        settings.mediaPlaybackRequiresUserGesture = false
                        settings.loadWithOverviewMode = true
                        settings.useWideViewPort = true
                        settings.allowFileAccess = true
                        settings.allowContentAccess = true
                        webViewClient = object : WebViewClient() {
                            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                                return false
                            }
                        }
                        webChromeClient = WebChromeClient()
                    }
                    webView = wv
                    container.addView(wv)
                }
                webView?.visibility = View.VISIBLE

                if (ytId != null) {
                    val html = """
                        <!DOCTYPE html>
                        <html>
                        <head>
                          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                          <style>
                            * { margin:0; padding:0; box-sizing:border-box; background:transparent; overflow:hidden; }
                            html, body { width:100%; height:100%; position:fixed; background:transparent; }
                            iframe {
                              width:100%;
                              height:100%;
                              border:0;
                              position:absolute;
                              top:0;
                              left:0;
                            }
                          </style>
                        </head>
                        <body>
                          <iframe
                            src="https://www.youtube-nocookie.com/embed/$ytId?autoplay=1&mute=0&controls=1&playsinline=1&loop=1&playlist=$ytId&rel=0&modestbranding=1&enablejsapi=1&origin=https://www.youtube-nocookie.com"
                            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                            allowfullscreen>
                          </iframe>
                        </body>
                        </html>
                    """.trimIndent()
                    webView?.loadDataWithBaseURL("https://www.youtube-nocookie.com", html, "text/html", "UTF-8", null)
                } else {
                    // For Instagram, Vimeo, TikTok, Facebook, or generic embed URLs
                    val embedUrl = when {
                        src.contains("vimeo.com") && !src.contains("player.vimeo.com") -> {
                            val vId = Regex("vimeo\\.com\\/(\\d+)").find(src)?.groupValues?.get(1)
                            if (vId != null) "https://player.vimeo.com/video/$vId?autoplay=1&loop=1" else src
                        }
                        src.contains("instagram.com") && !src.contains("/embed") -> {
                            val clean = src.split("?").first().trimEnd('/')
                            "$clean/embed/"
                        }
                        else -> src
                    }
                    val html = """
                        <!DOCTYPE html>
                        <html>
                        <head>
                          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                          <style>
                            * { margin:0; padding:0; box-sizing:border-box; background:#000; overflow:hidden; }
                            html, body { width:100%; height:100%; }
                            iframe { width:100%; height:100%; border:none; }
                          </style>
                        </head>
                        <body>
                          <iframe src="$embedUrl" allow="autoplay; encrypted-media" allowfullscreen></iframe>
                        </body>
                        </html>
                    """.trimIndent()
                    webView?.loadDataWithBaseURL(src, html, "text/html", "UTF-8", null)
                }
            } else {
                isWebMode = false
                webView?.visibility = View.GONE
                videoView.visibility = View.VISIBLE
                videoView.setOnErrorListener { _, _, _ -> true }

                if (src.startsWith("http://") || src.startsWith("https://")) {
                    videoView.setVideoURI(Uri.parse(src))
                } else {
                    val file = File(src)
                    if (file.exists()) {
                        // Use Uri.fromFile so Android MediaPlayer opens the local file descriptor directly without ContentResolver
                        videoView.setVideoURI(Uri.fromFile(file))
                    } else if (src.startsWith("/")) {
                        videoView.setVideoURI(Uri.parse("file://$src"))
                    }
                }
                videoView.setOnPreparedListener { mp ->
                    videoView.setBackgroundColor(android.graphics.Color.TRANSPARENT)
                    mp.isLooping = true
                    try { mp.start() } catch (_: Exception) {}
                    try { videoView.start() } catch (_: Exception) {}
                }
                videoView.setOnCompletionListener {
                    try {
                        videoView.seekTo(0)
                        videoView.start()
                    } catch (_: Exception) {}
                }
                try { videoView.start() } catch (_: Exception) {}
            }
        } catch (_: Exception) {}
    }

    override fun getView(): View = container

    override fun dispose() {
        channel.setMethodCallHandler(null)
        try {
            videoView.stopPlayback()
        } catch (_: Exception) {}
        try {
            webView?.loadUrl("about:blank")
            webView?.destroy()
        } catch (_: Exception) {}
    }
}

private class QappCameraFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return QappCameraView(context, messenger, viewId)
    }
}

private class QappCameraView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
) : PlatformView {
    private val preview = PreviewView(context).apply {
        scaleType = PreviewView.ScaleType.FILL_CENTER
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
    }
    private val channel = MethodChannel(messenger, "qapp/camera_$viewId")
    private val life = CameraLife()
    private var provider: ProcessCameraProvider? = null
    private var capture: ImageCapture? = null
    private var lens = CameraSelector.LENS_FACING_FRONT

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "flip" -> {
                    flip()
                    result.success(null)
                }
                "snap" -> snap(result)
                else -> result.notImplemented()
            }
        }
        life.open()
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener(
            {
                provider = future.get()
                bind()
            },
            ContextCompat.getMainExecutor(context),
        )
    }

    fun flip() {
        lens = if (lens == CameraSelector.LENS_FACING_FRONT) {
            CameraSelector.LENS_FACING_BACK
        } else {
            CameraSelector.LENS_FACING_FRONT
        }
        bind()
    }

    private fun bind() {
        val cameraProvider = provider ?: return
        val useCase = Preview.Builder().build()
        useCase.surfaceProvider = preview.surfaceProvider
        val shot = ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .build()
        capture = shot
        val preferred = CameraSelector.Builder().requireLensFacing(lens).build()
        val selector = try {
            if (cameraProvider.hasCamera(preferred)) preferred else CameraSelector.DEFAULT_BACK_CAMERA
        } catch (_: Exception) {
            CameraSelector.DEFAULT_BACK_CAMERA
        }
        try {
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(life, selector, useCase, shot)
        } catch (_: Exception) {
        }
    }

    private fun snap(result: MethodChannel.Result) {
        val shot = capture
        if (shot == null) {
            result.error("camera", "not ready", null)
            return
        }
        val file = File(preview.context.cacheDir, "qapp_${System.currentTimeMillis()}.jpg")
        val options = ImageCapture.OutputFileOptions.Builder(file).build()
        shot.takePicture(
            options,
            ContextCompat.getMainExecutor(preview.context),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    val bytes = if (file.exists()) file.readBytes() else ByteArray(0)
                    file.delete()
                    result.success(bytes)
                }

                override fun onError(exception: ImageCaptureException) {
                    result.error("snap", exception.message, null)
                }
            },
        )
    }

    override fun getView(): View = preview

    override fun dispose() {
        channel.setMethodCallHandler(null)
        provider?.unbindAll()
        life.close()
    }
}

private class CameraLife : LifecycleOwner {
    private val registry = LifecycleRegistry(this)
    override val lifecycle: Lifecycle = registry

    fun open() {
        registry.currentState = Lifecycle.State.STARTED
    }

    fun close() {
        registry.currentState = Lifecycle.State.DESTROYED
    }
}
