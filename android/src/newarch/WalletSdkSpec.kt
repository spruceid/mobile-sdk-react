package com.walletsdk

import com.facebook.react.bridge.ReactApplicationContext

abstract class WalletSdkSpec internal constructor(context: ReactApplicationContext) :
  NativeWalletSdkSpec(context) {
}
