#ifndef RNWALLTESDK_WALLETSDK_H
#define RNWALLTESDK_WALLETSDK_H

#import <React/RCTEventEmitter.h>
#import "WalletSdkObjc.h"

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNWalletSdkSpec.h"

@interface WalletSdk : RCTEventEmitter <NativeWalletSdkSpec, BLESessionStateDelegate>
#else
#import <React/RCTBridgeModule.h>

@interface WalletSdk : RCTEventEmitter <RCTBridgeModule, BLESessionStateDelegate>
#endif

@end

#endif // RNWALLTESDK_WALLETSDK_H
