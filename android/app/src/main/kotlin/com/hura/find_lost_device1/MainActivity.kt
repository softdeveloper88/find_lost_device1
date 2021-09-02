package com.hura.find_lost_device1

import android.Manifest
import android.annotation.SuppressLint
import android.app.*
import android.app.admin.DevicePolicyManager
import android.content.*
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.*
import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.*
import com.google.android.gms.tasks.OnFailureListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import java.io.File
import java.util.*
import kotlin.collections.ArrayList


class MainActivity : FlutterActivity() {
    val RESULT_ENABLE = 1
    var deviceManger: DevicePolicyManager? = null
    var activityManager: ActivityManager? = null
    var compName: ComponentName? = null
    var mLocationService: LocationService = LocationService()
    lateinit var mServiceIntent: Intent
    lateinit var mActivity: Activity
    var sensorScreen = false
    private val service: BatteryService? = null
    private val CHANNEL = "flutter.native/helper"
    lateinit var editor: SharedPreferences.Editor
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deviceManger = getSystemService(
            Context.DEVICE_POLICY_SERVICE
        ) as DevicePolicyManager
        activityManager = getSystemService(
            Context.ACTIVITY_SERVICE
        ) as ActivityManager
        compName = ComponentName(this, MyAdmin::class.java)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler {
                // Note: this method is invoked on the main thread.
                    call, result ->
                when (call.method) {
                    "uninstallApp" -> {
                        val greetings: String = uninstallApp()
                        result.success(greetings)
                    }
                    "lockScreen" -> {
                        val lockScreen: Boolean = lock()
                        result.success(lockScreen)
                    }
                    "disable" -> {
                        sensorScreen = true
//                        result.success(sensorScreen)

                    }
                    "batteryStart" -> {
                        if (service == null) {
                            Toast.makeText(this@MainActivity, "start", Toast.LENGTH_SHORT).show()
                            // start service
                            val i = Intent(this, BatteryService::class.java)
                                startService(i)
                        }
                    }
                    "batteryStop" -> {
                        if (service == null) {
                            Toast.makeText(this@MainActivity, "stop", Toast.LENGTH_SHORT).show()
                            val i = Intent(this, BatteryService::class.java)
                            stopService(i)
                        }
                    }
                    "eraseData" -> {
                        val active = call.argument<Boolean>("active")
                        editor.putBoolean("active", active!!)
                        editor.apply()

                        val isDeleted: Boolean = deleteAllData()
                    }
                    "sensorDetectionActive" -> {
                        val i = Intent(this, SensorService::class.java)

                            startService(i)
                        Toast.makeText(this@MainActivity, "Start sensor", Toast.LENGTH_SHORT).show()
                    }
                    "sensorDetectionDeactive" -> {
                        val i = Intent(this, SensorService::class.java)
                        Toast.makeText(this@MainActivity, "Stop sensor", Toast.LENGTH_SHORT).show()
                        stopService(i)
                    }

                }
            }


    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        try {
            when (requestCode) {
                RESULT_ENABLE -> {
                    if (resultCode == Activity.RESULT_OK) {
                        Log.i("DeviceAdminSample", "Admin enabled!")
                    } else {
                        Log.i("DeviceAdminSample", "Admin enable FAILED!")
                    }
                    return
                }
                1001 -> {
                    if (Build.VERSION.SDK_INT >= VERSION_CODES.M) {
                        if (ActivityCompat.checkSelfPermission(
                                context,
                                Manifest.permission.ACCESS_FINE_LOCATION
                            ) == PackageManager.PERMISSION_GRANTED ||
                            ActivityCompat.checkSelfPermission(
                                context,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ) == PackageManager.PERMISSION_GRANTED
                            || ActivityCompat.checkSelfPermission(
                                context,
                                Manifest.permission.ACCESS_BACKGROUND_LOCATION
                            ) == PackageManager.PERMISSION_GRANTED
                        ) {

                        }
                    }
                }
                2296 -> {
                    if (SDK_INT >= Build.VERSION_CODES.R) {
                        if (Environment.isExternalStorageManager()) {
                            // perform action when allow permission success
                        } else {
                            Toast.makeText(
                                this,
                                "Allow permission for storage access!",
                                Toast.LENGTH_SHORT
                            ).show()
                        }
                    }
                }
            }
            super.onActivityResult(requestCode, resultCode, data)
        } catch (e: java.lang.RuntimeException) {

        }
    }


    private fun uninstallApp(): String {
        val intent = Intent(Intent.ACTION_DELETE)
        intent.data = Uri.parse("package:" + this.packageName)
        startActivity(intent)
        return "Hello testing"

    }


    private fun lock(): Boolean {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(
            DevicePolicyManager.EXTRA_DEVICE_ADMIN,
            compName
        )
        intent.putExtra(
            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "Additional text explaining why this needs to be added."
        )

        startActivityForResult(intent, RESULT_ENABLE)
        val active = deviceManger!!.isAdminActive(compName!!)
        if (active) {
            deviceManger!!.lockNow()
        }
        val pm: PowerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        if (pm.isScreenOn) {
            val policy: DevicePolicyManager =
                getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            try {
                policy.lockNow()
            } catch (ex: SecurityException) {
                Toast.makeText(
                    this,
                    "Must be enable device administrator",
                    Toast.LENGTH_LONG
                ).show()
                val admin = ComponentName(context, MyAdmin::class.java)
                val intent: Intent = Intent(
                    DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN
                ).putExtra(
                    DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin
                )
                context.startActivity(intent)
            }
        }

        return true
    }

    @SuppressLint("CommitPrefEdits")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        FlutterMain.startInitialization(this)
        editor = getSharedPreferences("preferences", MODE_PRIVATE).edit()
        mLocationService = LocationService()
        mServiceIntent = Intent(context, mLocationService.javaClass)
        mLocationService = LocationService()
        mActivity = this@MainActivity
//        checkRunTimePermission()
        if (!Util.isLocationEnabledOrNot(this)) {
            dialogGpsEnable()
        }
        mLocationService = LocationService()
        mServiceIntent = Intent(this, mLocationService.javaClass)
        if (!Util.isMyServiceRunning(mLocationService.javaClass, mActivity)) {
            startService(mServiceIntent)
            Toast.makeText(
                mActivity,
                getString(R.string.service_start_successfully),
                Toast.LENGTH_SHORT
            ).show()
        } else {
            Toast.makeText(
                mActivity,
                getString(R.string.service_already_running),
                Toast.LENGTH_SHORT
            ).show()
        }


//        val intent = Intent()
//        val packageName = context.packageName
//        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
//        if (pm.isIgnoringBatteryOptimizations(packageName)) intent.action =
//            Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS else {
//            intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
//            intent.data = Uri.parse("package:$packageName")
//        }
//        context.startActivity(intent)


//        val front_translucent = Intent(this, NotificationService::class.java)
//        startService(front_translucent)
//        val intent = Intent(
//            this@MainActivity,
//            MyServices::class.java
//        )
//        intent.action = MyServices.ACTION_START_FOREGROUND_SERVICE
//        startService(intent)
        if (Build.VERSION.SDK_INT >= VERSION_CODES.O) {
            // Create channel to show notifications.
            val channelId = getString(R.string.default_notification_channel_id)
            val channelName = getString(R.string.default_notification_channel_name)
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    channelName, NotificationManager.IMPORTANCE_HIGH
                )
            )
        }

        intent.extras?.let {
            for (key in it.keySet()) {
                val value = intent.extras?.get(key)
                Log.d("TAG", "Key: $key Value: $value")
            }
        }

    }


    fun checkRunTimePermission() {
        if (Build.VERSION.SDK_INT >= VERSION_CODES.M) {
            if (ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED || ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED || ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
            ) {

            } else {
                requestPermissions(
                    arrayOf(
                        Manifest.permission.ACCESS_COARSE_LOCATION,
                        Manifest.permission.ACCESS_FINE_LOCATION
                    ),
                    10
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String?>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 10) {
            if (grantResults.size > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            } else {
                if (!ActivityCompat.shouldShowRequestPermissionRationale(
                        (context as Activity),
                        Manifest.permission.ACCESS_FINE_LOCATION
                    )
                ) {
                    // If User Checked 'Don't Show Again' checkbox for runtime permission, then navigate user to Settings
                    val dialog: AlertDialog.Builder = AlertDialog.Builder(context)
                    dialog.setTitle("Permission Required")
                    dialog.setCancelable(false)
                    dialog.setMessage("You have to Allow permission to access user location")
                    dialog.setPositiveButton(
                        "Settings"
                    ) { dialog, which ->
                        val i = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts(
                                "package",
                                context.packageName, null
                            )
                        )
                        //i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        startActivityForResult(i, 1001)
                    }
                    val alertDialog = dialog.create()
                    alertDialog.show()
                }
                //code for deny
            }
        }
    }

    override fun onPause() {
        super.onPause()
        if (sensorScreen) {
            val activityManager = applicationContext
                .getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, 0)
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        if (Build.VERSION.SDK_INT >= VERSION_CODES.O) {
            if (sensorScreen) {
                if (!hasFocus) {
                    val closeDialog = Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS)
                    sendBroadcast(closeDialog)
                    // Method that handles loss of window focus

                }
            }
        }
    }


    fun deleteAllData(): Boolean {
        val dataDir = File(Environment.getExternalStorageDirectory().absolutePath)
        if (dataDir.length() > 0) {
            ListDir(dataDir)
        }
        val file = File("/storage/emulated/0/App_Name")
        val deleted: Boolean = file.delete()
        //just to scan an update for storage to be notified

//just to scan an update for storage to be notified
        MediaScannerConnection.scanFile(
            context, arrayOf<String>(file.absolutePath),
            null
        ) { path, uri ->
            //just to scan an update for gallery to be notified of a new image.
        }

        return true
    }

    fun ListDir(f: File) {
        val files = f.listFiles()
        val fileList: ArrayList<String> = ArrayList()
        for (file in files) {
            fileList.add(file.path)
            Log.d("Listfile::", file.path)
        }

    }


    private fun dialogGpsEnable() {

        val requestLocation = LocationRequest.create()
        requestLocation.interval = 10000
        requestLocation.fastestInterval = 5000
        requestLocation.priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        val mBuilder = LocationSettingsRequest.Builder().addLocationRequest(requestLocation)
        val settingsClient = LocationServices.getSettingsClient(context)
        val task: com.google.android.gms.tasks.Task<LocationSettingsResponse>? =
            settingsClient.checkLocationSettings(mBuilder.build())
        task!!.addOnSuccessListener(
            activity
        ) {

        }
        task.addOnFailureListener(activity, OnFailureListener { e ->
            if (e is ResolvableApiException) {
                val resolvable: ResolvableApiException = e
                try {
                    resolvable.startResolutionForResult(activity, 51)
                } catch (e1: IntentSender.SendIntentException) {
                    e1.printStackTrace()
                }
            }
        })
    }
}

