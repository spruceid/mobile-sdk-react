package com.walletsdk

import android.os.Bundle
import androidx.annotation.CallSuper
import androidx.lifecycle.ViewModelProvider
import com.facebook.react.ReactActivity
import com.spruceid.wallet.sdk.CredentialsViewModel


/**
 * Activity to start from React Native JavaScript, triggered via
 * [ActivityStarterModule.navigateToExample].
 */
class ExampleActivity : ReactActivity() {
  @CallSuper
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(androidx.appcompat.R.layout.abc_screen_simple)


  }
}
