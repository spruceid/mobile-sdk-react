#ifdef __cplusplus
#import "react-native-sprucekit-wallet-sdk.h"
#endif

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNSprucekitWalletSdkSpec.h"

@interface SprucekitWalletSdk : NSObject <NativeSprucekitWalletSdkSpec>
#else
#import <React/RCTBridgeModule.h>

@interface SprucekitWalletSdk : NSObject <RCTBridgeModule>
#endif

@end
