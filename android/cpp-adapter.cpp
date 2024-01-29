#include <jni.h>
#include "react-native-sprucekit-wallet-sdk.h"

extern "C"
JNIEXPORT jdouble JNICALL
Java_com_sprucekitwalletsdk_SprucekitWalletSdkModule_nativeMultiply(JNIEnv *env, jclass type, jdouble a, jdouble b) {
    return sprucekitwalletsdk::multiply(a, b);
}
