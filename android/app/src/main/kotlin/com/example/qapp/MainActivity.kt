package com.example.qapp

import android.media.MediaRecorder
import android.os.Build
import android.Manifest
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import android.view.View
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
    private var recorder: MediaRecorder? = null
    private var audioPath: String? = null

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
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "qapp/camera",
            QappCameraFactory(flutterEngine.dartExecutor.binaryMessenger),
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
                    }
                    startActivity(Intent.createChooser(view, dest.name))
                    result.success(true)
                } catch (_: Exception) {
                    result.success(false)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qapp/audio")
            .setMethodCallHandler { call, result ->
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
                    else -> result.notImplemented()
                }
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
