package com.walletsdk

import android.util.Log
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableNativeArray
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.spruceid.wallet.sdk.BLESessionManager
import com.spruceid.wallet.sdk.BLESessionStateDelegate
import com.spruceid.wallet.sdk.CredentialsViewModel
import com.spruceid.wallet.sdk.MDoc
import com.spruceid.wallet.sdk.getBluetoothManager
import com.spruceid.wallet.sdk.rs.ItemsRequest
import java.security.KeyFactory
import java.security.KeyStore
import java.security.cert.Certificate
import java.security.cert.CertificateFactory
import java.security.spec.PKCS8EncodedKeySpec

class BleStateCallback(private val context: ReactApplicationContext) : BLESessionStateDelegate() {
  override fun update(state: Map<String, Any>) {
    Log.i("WalletSdk", state.toString())
    val eventName = state.keys.first()
    var emitEvent = ""
    val eventValue: WritableMap = WritableNativeMap()
    when (eventName) {
      "engagingQRCode" -> {
        emitEvent = "onBleSessionEngagingQrCode"
        eventValue.putString("qrCodeUri", state[eventName].toString())
      }

      "error" -> {
        emitEvent = "onBleSessionError"
        eventValue.putString("error", state[eventName].toString())
      }

      "connected" -> {
        emitEvent = "onBleSessionEstablished"
      }

      "disconnected" -> {
        emitEvent = "onBleSessionDisconnected"
      }

      "selectNamespaces" -> {
        emitEvent = "onBleSessionSelectNamespace"
        val items = WritableNativeArray()
        for (doc in state[eventName] as ArrayList<*>) {
          val docType = doc as ItemsRequest
          val namespaces = WritableNativeArray()
          for (namespace in docType.namespaces) {
            val kvPairs = WritableNativeArray()
            for (kv in namespace.value) {
              val item = WritableNativeMap()
              item.putString("key", kv.key)
              item.putBoolean("value", kv.value)
              kvPairs.pushMap(item)
            }
            val newNamespace = WritableNativeMap()
            newNamespace.putString("namespace", namespace.key)
            newNamespace.putArray("kvPairs", kvPairs)
            namespaces.pushMap(newNamespace)
          }
          val item = WritableNativeMap()
          item.putString("docType", docType.docType)
          item.putArray("namespaces", namespaces)
          items.pushMap(item)
        }
        eventValue.putArray("itemsRequest", items)
      }

      "uploadProgress" -> {
        emitEvent = "onBleSessionProgress"
        val map = WritableNativeMap()
        map.putInt("current", ((state[eventName] as Map<*, *>)["curr"] as Int))
        map.putInt("total", ((state[eventName] as Map<*, *>)["max"] as Int))
        eventValue.putMap("uploadProgress", map)
      }

      "success" -> {
        emitEvent = "onBleSessionSuccess"
      }
    }
    Log.i("WalletSdkModule.BleStateCallback.update", "event: { $emitEvent: $eventValue }")
    context.emitDeviceEvent(emitEvent, eventValue)
  }
}

class WalletSdkModule internal constructor(context: ReactApplicationContext) :
  WalletSdkSpec(context) {

  private var bleSessionManager: BLESessionManager? = null


  private val viewModel = CredentialsViewModel()

  override fun getName(): String {
    return NAME
  }

  @ReactMethod
  override fun createSoftPrivateKeyFromPKCS8PEM(_algo: String, key: String, cert: String, promise: Promise) {
    var keyBase64 = key.split("-----BEGIN PRIVATE KEY-----\n").last()
    keyBase64 = keyBase64.split("-----END PRIVATE KEY-----").first()

    val decodedKey = android.util.Base64.decode(
      keyBase64,
      android.util.Base64.DEFAULT,
    )

    val privateKey = KeyFactory.getInstance(
      "EC"
    ).generatePrivate(
      PKCS8EncodedKeySpec(
        decodedKey
      )
    )

    val cert: Array<Certificate> = arrayOf(
      CertificateFactory.getInstance(
        "X.509"
      ).generateCertificate(
        cert.byteInputStream()
      )
    )

    val ks: KeyStore = KeyStore.getInstance(
      "AndroidKeyStore"
    )

    ks.load(
      null
    )

    ks.setKeyEntry(
      "mdoc_key",
      privateKey,
      null,
      cert
    )

    promise.resolve("mdoc_key")
  }

  @ReactMethod
  override fun createMdocFromCbor(cborMdoc: String, promise: Promise) {
    val mdoc = MDoc(
      "CBor",
      android.util.Base64.decode(cborMdoc.toByteArray(), android.util.Base64.DEFAULT),
      "mdoc_key"
    )
    viewModel.storeCredental(mdoc)

    val eventValue: WritableMap = WritableNativeMap()
    eventValue.putString("id", mdoc.inner.id())
    this.reactApplicationContext.emitDeviceEvent("onCredentialAdded", eventValue)
    promise.resolve(mdoc.inner.id())
  }

  @ReactMethod
  override fun createBleManager(promise: Promise) {
    promise.resolve("dummy")
  }

  @ReactMethod
  override fun bleSessionStartPresentMdoc(
    _bleUuid: String,
    mdoc: String,
    privateKey: String,
    deviceEngagement: String,
    promise: Promise
  ) {
    val context = this.reactApplicationContext
    Log.i("WalletSdk", "ble session start present mdoc")
    this.bleSessionManager = BLESessionManager(
      viewModel.credentials.value.first() as MDoc,
      getBluetoothManager(this.reactApplicationContext)!!,
      BleStateCallback(context)
    )
    Log.i("WalletSdk", "ble manager created")
    promise.resolve(null)
  }

  @ReactMethod
  override fun bleSessionSubmitNamespaces(
    _bleUuid: String,
    namespaces: ReadableArray,
    promise: Promise
  ) {
    val doctypes = mutableMapOf<String, Map<String, List<String>>>()
    for (doctype in (namespaces as ReadableNativeArray).toArrayList() as ArrayList<Map<String, Any>>) {
      val innerNamespaces = mutableMapOf<String, List<String>>()
      for (namespace in doctype["namespaces"] as ArrayList<Map<String, Any>>) {
        val items = mutableListOf<String>()
        for (item in namespace["keys"] as ArrayList<String>) {
          items.add(item)
        }
        innerNamespaces[namespace["namespace"]!! as String] = items
      }
      doctypes[doctype["docType"]!! as String] = innerNamespaces
    }
    this.bleSessionManager?.submitNamespaces(doctypes)
    promise.resolve(null)
  }

  @ReactMethod
  override fun bleSessionCancel(_bleUuid: String, promise: Promise) {
    this.bleSessionManager?.cancel()
    promise.resolve(null)
  }

  @ReactMethod
  override fun allCredentials(promise: Promise) {
    val array: WritableArray = WritableNativeArray()
    array.pushString("test")
    promise.resolve(array)
  }

  companion object {
    const val NAME = "WalletSdk"
  }
}
