package ir.daram.daram

import android.Manifest
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val inbox = Telephony.Sms.Inbox.CONTENT_URI
    private val reader = Executors.newSingleThreadExecutor()
    private var channel: MethodChannel? = null
    private var permissionResult: MethodChannel.Result? = null
    private var observing = false
    private val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            channel?.invokeMethod("inboxChanged", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ir.daram.daram/sms")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(hasSmsPermission())
                "requestPermission" -> when {
                    hasSmsPermission() -> result.success(true)
                    permissionResult != null -> result.error("busy", "Permission request in progress", null)
                    else -> {
                        permissionResult = result
                        requestPermissions(arrayOf(Manifest.permission.READ_SMS), SMS_PERMISSION)
                    }
                }
                "observe" -> {
                    if (call.arguments == true && hasSmsPermission()) {
                        if (!observing) {
                            contentResolver.registerContentObserver(
                                Telephony.Sms.CONTENT_URI, true, observer,
                            )
                            observing = true
                        }
                    } else {
                        stopObserving()
                    }
                    result.success(null)
                }
                "messages" -> read(result) {
                    messages(
                        call.argument<Number>("since")?.toLong() ?: 0L,
                        call.argument<Number>("beforeId")?.toLong(),
                    )
                }
                "senders" -> read(result) { senders() }
                "message" -> read(result) {
                    val id = requireNotNull(call.argument<Number>("id")).toLong()
                    val date = requireNotNull(call.argument<Number>("date")).toLong()
                    contentResolver.query(
                        inbox, arrayOf("body"), "_id = ? AND date = ?",
                        arrayOf(id.toString(), date.toString()), null,
                    )?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
                }
                "examples" -> read(result) {
                    val addresses = requireNotNull(call.argument<List<String>>("addresses"))
                    examples(addresses)
                }
                "openSettings" -> {
                    startActivity(android.content.Intent(
                        android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        android.net.Uri.fromParts("package", packageName, null),
                    ))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        stopObserving()
        channel?.setMethodCallHandler(null)
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        reader.shutdown()
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION) {
            permissionResult?.success(hasSmsPermission())
            permissionResult = null
        }
    }

    private fun hasSmsPermission() =
        checkSelfPermission(Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED

    private fun stopObserving() {
        if (observing) contentResolver.unregisterContentObserver(observer)
        observing = false
    }

    private fun read(result: MethodChannel.Result, query: () -> Any?) {
        reader.execute {
            try {
                val data = query()
                runOnUiThread { result.success(data) }
            } catch (_: SecurityException) {
                runOnUiThread { result.error("permission", "SMS permission unavailable", null) }
            } catch (_: Exception) {
                runOnUiThread { result.error("inbox", "Could not read the SMS inbox", null) }
            }
        }
    }

    private fun messages(since: Long, beforeId: Long?): List<Map<String, Any>> {
        val where = if (beforeId == null) "date >= ?" else "date >= ? AND _id < ?"
        val args = if (beforeId == null) arrayOf(since.toString())
            else arrayOf(since.toString(), beforeId.toString())
        val rows = mutableListOf<Map<String, Any>>()
        contentResolver.query(inbox, arrayOf("_id", "address", "body", "date"), where, args, "_id DESC")
            ?.use { cursor ->
                var examined = 0
                while (examined < PAGE_SIZE && cursor.moveToNext()) {
                    examined++
                    rows.add(mapOf(
                        "id" to cursor.getLong(0),
                        "sender" to cursor.getString(1).orEmpty(),
                        "body" to cursor.getString(2).orEmpty(),
                        "date" to cursor.getLong(3),
                    ))
                }
            } ?: error("SMS provider returned no cursor")
        return rows
    }

    private fun senders(): List<String> {
        val addresses = linkedSetOf<String>()
        contentResolver.query(inbox, arrayOf("address"), null, null, "_id DESC")?.use { cursor ->
            while (cursor.moveToNext()) cursor.getString(0)?.let(addresses::add)
        } ?: error("SMS provider returned no cursor")
        return addresses.toList()
    }

    private fun examples(addresses: List<String>): List<String> {
        if (addresses.isEmpty()) return emptyList()
        val placeholders = addresses.joinToString(",") { "?" }
        val messages = mutableListOf<String>()
        contentResolver.query(
            inbox, arrayOf("body"), "address IN ($placeholders)",
            addresses.toTypedArray(), "_id DESC",
        )?.use { cursor ->
            while (messages.size < 3 && cursor.moveToNext()) {
                messages.add(cursor.getString(0).orEmpty())
            }
        }
        return messages
    }

    private companion object {
        const val SMS_PERMISSION = 405
        const val PAGE_SIZE = 400
    }
}
