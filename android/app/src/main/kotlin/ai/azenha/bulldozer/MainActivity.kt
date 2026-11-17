package ai.azenha.bulldozer

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Usage stats: Play pre-launch report devices (Firebase Test Lab) set
        // "firebase.test.lab"; the app then counts nothing (UsageStats.androidTestLab).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "azenha/usage")
            .setMethodCallHandler { call, result ->
                if (call.method == "isTestLab") {
                    result.success(Settings.System.getString(contentResolver, "firebase.test.lab") == "true")
                } else {
                    result.notImplemented()
                }
            }
    }
}
