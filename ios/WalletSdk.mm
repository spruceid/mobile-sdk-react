#import "WalletSdk.h"

#import "WalletSdkObjc.h"

NSString * MODULE_NAME = @"walletsdk";

@implementation WalletSdk {
    NSMutableDictionary *objectTable;
}

-(instancetype)init {
    if (self = [super init]) {
        self->objectTable = [NSMutableDictionary new];
    }

    return self;
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[
        @"onCredentialAdded",
        @"onRustHelloed",
        @"onDebugLog",
        @"onBleSessionError",
        @"onBleSessionEngagingQrCode",
        @"onBleSessionProgress",
        @"onBleSessionSelectNamespace",
        @"onBleSessionSuccess",
    ];
}

RCT_EXPORT_MODULE()

// Example method
// See // https://reactnative.dev/docs/native-modules-ios
RCT_EXPORT_METHOD(multiply:(double)a
                  b:(double)b
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSNumber *result = @(a * b);

    resolve(result);
}

RCT_EXPORT_METHOD(helloRust:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    NSString *result = [WalletSdkObjc helloRust];

    [self sendEventWithName:@"onRustHelloed" body:@{@"sessionId": [NSNumber numberWithInt:10]}];

    resolve(result);
}

RCT_EXPORT_METHOD(createSoftPrivateKeyFromPem:(NSString*)algo
                  pem:(NSString*)pem
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    if(![algo isEqualToString:@"p256"]) {
        reject(MODULE_NAME, [NSString stringWithFormat:@"unknown algo: %@", algo], nil);
        return;
    }
    @try {
        SoftPrivateKey *privateKey = [[SoftPrivateKey alloc] initWithP256Pem:pem];

        NSUUID* uuid = [privateKey getUuid];

        [self insert:privateKey forKey:uuid];

        resolve([uuid UUIDString]);
    }
    @catch (NSException *e) {
        reject(MODULE_NAME, [e reason], nil);
    }
}

RCT_EXPORT_METHOD(createMdocFromCbor:(NSString*)cborBase64
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    @try {
        MDoc *mdoc = [MDoc fromCborBase64:cborBase64];

        NSUUID* uuid = [mdoc getUuid];

        [self insert:mdoc forKey:uuid];

        [self sendEventWithName:@"onCredentialAdded" body:@{@"id": [uuid UUIDString]}];

        resolve([uuid UUIDString]);
    }
    @catch (NSException *e) {
        reject(MODULE_NAME, [e reason], nil);
    }
}

RCT_EXPORT_METHOD(createBleManager:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    @try {
        BLESessionManager *bleManager = [[BLESessionManager alloc] initWithDelegate:self];

        if(!bleManager) {
            reject(MODULE_NAME, @"Failed to create BLESessionManager", nil);
            return;
        }

        [self insert:bleManager forKey:[bleManager getUuid]];

        resolve([[bleManager getUuid] UUIDString]);
    }
    @catch (NSException *e) {
        reject(MODULE_NAME, [e reason], nil);
    }
}

RCT_EXPORT_METHOD(bleSessionStartPresentMdoc:(NSString*)bleUuid
                  mdoc:(NSString*)mdocUuid
                  privateKey:(NSString*)privateKeyUuid
                  deviceEngagement:(NSString*)deviceEngagementString
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    @try {
        MDoc *mdoc = [self mdocForUuidString:mdocUuid];
        if(!mdoc) {
            reject(MODULE_NAME, @"Failed to find MDoc", nil);
            return;
        }

        BLESessionManager* ble = [self bleSessionManagerForUuidString:bleUuid];
        if(!ble) {
            reject(MODULE_NAME, @"Failed to find BLESessionMaanager", nil);
            return;
        }

        SoftPrivateKey* privateKey = [self privateKeyForUuidString:privateKeyUuid];
        if(!privateKey) {
            reject(MODULE_NAME, [NSString stringWithFormat:@"Failed to find PrivateKey %@", privateKeyUuid], nil);
            return;
        }

        DeviceEngagement deviceEngagement = DeviceEngagementQrCode;
        if([deviceEngagementString isEqualToString:@"qrCode"]) {
            deviceEngagement = DeviceEngagementQrCode;
        } else {
            reject(MODULE_NAME, @"Unknown device engagement", nil);
            return;
        }

        [ble startWithMdoc:mdoc privateKey:privateKey andDeviceEngagement:deviceEngagement];

        resolve(nil);
    }
    @catch (NSException *e) {
        reject(MODULE_NAME, [e reason], nil);
    }
}

RCT_EXPORT_METHOD(bleSessionSubmitNamespaces:(NSString*)bleUuid
                  namespaces:(NSArray*)permitted
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    @try {
        BLESessionManager* ble = [self bleSessionManagerForUuidString:bleUuid];
        if(!ble) {
            reject(MODULE_NAME, @"Failed to find BLESessionMaanager", nil);
            return;
        }

        [ble submitNamespaces:permitted];

        resolve(nil);
    }
    @catch (NSException *e) {
        reject(MODULE_NAME, [e reason], nil);
    }
}

RCT_EXPORT_METHOD(bleSessionCancel:(NSString*)bleUuid
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    @try {
        BLESessionManager* ble = [self bleSessionManagerForUuidString:bleUuid];
        if(!ble) {
            reject(MODULE_NAME, @"Failed to find BLESessionMaanager", nil);
            return;
        }

        [ble cancel];

        resolve(nil);
    }
    @catch (NSException *e) {
        reject(MODULE_NAME, [e reason], nil);
    }
}

RCT_EXPORT_METHOD(allCredentials:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSMutableArray *ret = [NSMutableArray new];

    for (id key in self->objectTable) {
        NSObject* obj = [self->objectTable objectForKey:key];
        if ([obj isKindOfClass: [MDoc class]]) {
            MDoc *mdoc = (MDoc*)obj;
            [ret addObject:[[mdoc getUuid] UUIDString]];
        }
    }

    resolve(ret);
}

-(MDoc*)mdocForUuidString:(NSString*)uuidString {
    id obj = [self->objectTable objectForKey:[[NSUUID alloc] initWithUUIDString:uuidString]];
    if ([obj isKindOfClass: [MDoc class]]) {
        return obj;
    } else {
        return nil;
    }
}

-(BLESessionManager*)bleSessionManagerForUuidString:(NSString*)uuidString {
    id obj = [self->objectTable objectForKey:[[NSUUID alloc] initWithUUIDString:uuidString]];
    if ([obj isKindOfClass: [BLESessionManager class]]) {
        return obj;
    } else {
        return nil;
    }
}

-(SoftPrivateKey*)privateKeyForUuidString:(NSString*)uuidString {
    id obj = [self->objectTable objectForKey:[[NSUUID alloc] initWithUUIDString:uuidString]];
    if ([obj isKindOfClass: [SoftPrivateKey class]]) {
        return obj;
    } else {
        return nil;
    }
}

-(void)insert:(NSObject*)obj forKey:(NSUUID*)key {
    if ([self->objectTable objectForKey:key] != nil) {
        throw [NSException exceptionWithName:@"ObjectTableException"
                           reason:[NSString stringWithFormat:@"Insertion, but key already exists: %@", [key UUIDString]]
                           userInfo:nil];
    }

    [self->objectTable setObject:obj forKey:key];
}

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeWalletSdkSpecJSI>(params);
}
#endif

- (void)onError:(NSString*)err withSessionManger:(BLESessionManager*)sessionManager {
    [self sendEventWithName:@"onBleSessionError" body:@{
        @"bleUuid": [[sessionManager getUuid] UUIDString],
        @"error": err,
    }];
}

- (void)onEngagingQrCode:(NSString*)uri withSessionManager:(BLESessionManager*)sessionManager {
    [self sendEventWithName:@"onBleSessionEngagingQrCode" body:@{
        @"bleUuid": [[sessionManager getUuid] UUIDString],
        @"qrCodeUri": uri,
    }];
}

- (void)onDebugLog:(NSString*)logMsg withSessionManager:(BLESessionManager*)sessionManager {
    [self sendEventWithName:@"onDebugLog" body:logMsg];
}

- (void)onProgress:(NSString*)progress withSessionManager:(BLESessionManager*)sessionManager {
    [self sendEventWithName:@"onBleSessionProgress" body:@{
        @"bleUuid": [[sessionManager getUuid] UUIDString],
        @"progressMsg": progress,
    }];
}

- (void)onSelectNamespace:(NSArray*)itemsRequest withSessionManager:(BLESessionManager*)sessionManager {
    [self sendEventWithName:@"onBleSessionSelectNamespace" body:@{
        @"bleUuid": [[sessionManager getUuid] UUIDString],
        @"itemsRequest": itemsRequest,
    }];
}

- (void)onSuccessWithSessionManager:(BLESessionManager*)sessionManager {
        [self sendEventWithName:@"onBleSessionSuccess" body:@{
        @"bleUuid": [[sessionManager getUuid] UUIDString],
    }];
}

@end
