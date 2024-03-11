#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNWalletSdkSpec.h"
@interface RCT_EXTERN_MODULE(WalletSdk, RCTEventEmitter<NativeWalletSdkSpec>)
#else
#import <React/RCTBridgeModule.h>
@interface RCT_EXTERN_MODULE(WalletSdk, RCTEventEmitter<RCTBridgeModule>)
#endif

RCT_EXTERN_METHOD(createSoftPrivateKeyFromSEC1PEM
                  :        (NSString *)             algo
                  pem:     (NSString *)             pem
                  resolve: (RCTPromiseResolveBlock) resolve
                  reject:  (RCTPromiseRejectBlock)  reject)

RCT_EXTERN_METHOD(createSoftPrivateKeyFromPKCS8PEM
                  :        (NSString *)             algo
                  pem:     (NSString *)             pem
                  resolve: (RCTPromiseResolveBlock) resolve
                  reject:  (RCTPromiseRejectBlock)  reject)

RCT_EXTERN_METHOD(createMdocFromCbor
                  :        (NSString*)              cborBase64
                  resolve: (RCTPromiseResolveBlock) resolve
                  reject:  (RCTPromiseRejectBlock)  reject)

RCT_EXTERN_METHOD(createBleManager
                  :       (RCTPromiseResolveBlock) resolve
                  reject: (RCTPromiseRejectBlock)  reject)

RCT_EXTERN_METHOD(bleSessionStartPresentMdoc
                  :                 (NSString*)              bleUuid
                  mdoc:             (NSString*)              mdocUuid
                  privateKey:       (NSString*)              privateKeyUuid
                  deviceEngagement: (NSString*)              deviceEngagementString
                  resolve:          (RCTPromiseResolveBlock) resolve
                  reject:           (RCTPromiseRejectBlock)  reject)

RCT_EXTERN_METHOD(bleSessionSubmitNamespaces
                  :           (NSString*)              bleUuid
                  namespaces: (NSArray*)               permitted
                  resolve:    (RCTPromiseResolveBlock) resolve
                  reject:     (RCTPromiseRejectBlock)  reject)

RCT_EXTERN_METHOD(bleSessionCancel
                  :        (NSString*)              bleUuid
                  resolve: (RCTPromiseResolveBlock) resolve
                  reject:  (RCTPromiseRejectBlock)  reject)

RCT_EXTERN_METHOD(allCredentials
                  :       (RCTPromiseResolveBlock) resolve
                  reject: (RCTPromiseRejectBlock)  reject)

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeWalletSdkSpecJSI>(params);
}
#endif

@end
