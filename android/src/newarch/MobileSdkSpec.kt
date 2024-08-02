package com.mobilesdk

import com.facebook.react.bridge.ReactApplicationContext

abstract class MobileSdkSpec internal constructor(context: ReactApplicationContext) :
  NativeMobileSdkSpec(context) {
}
