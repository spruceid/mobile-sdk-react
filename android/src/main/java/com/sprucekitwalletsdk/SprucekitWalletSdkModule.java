package com.sprucekitwalletsdk;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactMethod;

public class SprucekitWalletSdkModule extends SprucekitWalletSdkSpec {
  public static final String NAME = "SprucekitWalletSdk";

  SprucekitWalletSdkModule(ReactApplicationContext context) {
    super(context);
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  static {
    System.loadLibrary("react-native-sprucekit-wallet-sdk");
  }

  public static native double nativeMultiply(double a, double b);

  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  public void multiply(double a, double b, Promise promise) {
    ComputationThread thread = new ComputationThread(a, b, promise);
    thread.run();
  }

  private class ComputationThread extends Thread {
    double a;
    double b;
    Promise promise;

    ComputationThread(double a, double b, Promise promise) {
      this.a = a;
      this.b = b;
      this.promise = promise;
    }

    @Override
    public void run() {
      try {
        Thread.sleep(2000);
      } catch(InterruptedException e) { }

      promise.resolve(nativeMultiply(a, b));
    }
  }
}
