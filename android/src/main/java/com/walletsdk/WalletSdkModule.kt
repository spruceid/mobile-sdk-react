package com.walletsdk

import android.util.Log
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.spruceid.wallet.sdk.BLESessionManager
import com.spruceid.wallet.sdk.BLESessionStateDelegate
import com.spruceid.wallet.sdk.BleCentralCallback
import com.spruceid.wallet.sdk.CredentialsViewModel
import com.spruceid.wallet.sdk.MDoc
import com.spruceid.wallet.sdk.getBluetoothManager
import java.security.KeyFactory
import java.security.KeyStore
import java.security.cert.Certificate
import java.security.cert.CertificateFactory
import java.security.spec.PKCS8EncodedKeySpec

class BleStateCallback(private val context: ReactApplicationContext): BLESessionStateDelegate() {
  override fun update(state: Map<String, Any>) {
    val eventName = state.keys.first()
    var emitEvent = ""
    var eventValue: Any = ""
    if(eventName == "engagingQRCode") {
      emitEvent = "onBleSessionEngagingQrCode"
      val event: WritableMap = WritableNativeMap()
      event.putString("qrCodeUri", state[eventName].toString())
      eventValue = event
    }
    Log.d("SdkModule", "$emitEvent: $eventValue")
    context.emitDeviceEvent(emitEvent, eventValue)
  }
}

class WalletSdkModule internal constructor(context: ReactApplicationContext) :
  WalletSdkSpec(context) {

    var bleSessionManager: BLESessionManager? = null


  val viewModel =  CredentialsViewModel()


//  val session by viewModel.session
//  val currentState by viewModel.currState.collect {state ->
//  }
//  val credentials by viewModel.credentials.collectAsState()
//  val requestData by viewModel.requestData.collectAsState()
//  val allowedNamespaces by viewModel.allowedNamespaces.collectAsState()

  override fun getName(): String {
    return NAME
  }

  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  override fun multiply(a: Double, b: Double, promise: Promise) {
    promise.resolve(a * b)
  }

  @ReactMethod
  fun createSoftPrivateKeyFromPem(_algo: String, pem: String, promise: Promise) {
    var keyBase64 = pem.split("-----BEGIN PRIVATE KEY-----\n").last()
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
        pem.byteInputStream()
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
  fun createMdocFromCbor(cborMdoc: String, promise: Promise) {
    val mdoc = MDoc(
      "CBor",
      android.util.Base64.decode(cborMdoc.toByteArray(), android.util.Base64.DEFAULT),
      "mdoc_key"
    )
    viewModel.storeCredental(mdoc)
    this.reactApplicationContext.emitDeviceEvent("onCredentialAdded", "Credential 'CBor' added.")
    promise.resolve("CBor")
  }

  @ReactMethod
  fun createBleManager(promise: Promise) {
    promise.resolve("WIP")
  }

  @ReactMethod
  fun bleSessionStartPresentMdoc(_bleUuid: String, mdoc: String, privateKey: String, deviceEngagement: String, promise: Promise) {
    val context = this.reactApplicationContext
    this.bleSessionManager = BLESessionManager(viewModel.credentials.value.first() as MDoc, getBluetoothManager(this.reactApplicationContext)!!, BleStateCallback(context))
    promise.resolve(null)
  }

  @ReactMethod
  fun bleSessionSubmitNamespaces(promise: Promise) {
    promise.resolve("WIP")
  }

  @ReactMethod
  fun bleSessionCancel(promise: Promise) {
    promise.resolve("WIP")
  }

  @ReactMethod
  fun allCredentials(promise: Promise) {
    val array: WritableArray = WritableNativeArray()
    array.pushString("test")
    promise.resolve(array)
  }

  companion object {
    const val NAME = "WalletSdk"
  }
}
