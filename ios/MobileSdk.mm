#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNMobileSdkSpec.h"
@interface RCT_EXTERN_MODULE(MobileSdk, RCTEventEmitter<NativeMobileSdkSpec>)
#else
#import <React/RCTBridgeModule.h>
@interface RCT_EXTERN_MODULE(MobileSdk, RCTEventEmitter<RCTBridgeModule>)
#endif

RCT_EXTERN_METHOD(createSoftPrivateKeyFromPKCS8PEM
                  :        (NSString *)             algo
                  key:     (NSString *)             key
                  cert:    (NSString *)             cert
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
    return std::make_shared<facebook::react::NativeMobileSdkSpecJSI>(params);
}
#endif

@end
