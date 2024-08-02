import CoreBluetooth
import CryptoKit
import Foundation
import SpruceIDMobileSdk

@objc(MobileSdk)
class MobileSdk: RCTEventEmitter {
  public static var emitter: RCTEventEmitter!
  var credentials = CredentialStore(credentials: []);
  var bleSessionManager: BLESessionManager?;

  override init() {
    super.init()
    MobileSdk.emitter = self
  }

  @objc
  override static func requiresMainQueueSetup() -> Bool {
    return false
  }

  @objc
  override func supportedEvents() -> [String]! {
    return [
      "onCredentialAdded",
      "onDebugLog",
      "onBleSessionError",
      "onBleSessionEngagingQrCode",
      "onBleSessionProgress",
      "onBleSessionSelectNamespace",
      "onBleSessionSuccess",
      "onBleSessionEstablished"
    ]
  }

  @objc
  func createSoftPrivateKeyFromPKCS8PEM(_ algo: String, key: String, cert: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    if algo != "p256" {
      reject("mobilesdk", "Unknown algorithm: \(algo)", nil);
      return;
    }
    if #available(iOS 14.0, *) {
      var privateKey: P256.Signing.PrivateKey;
      do {
        privateKey = try P256.Signing.PrivateKey(pemRepresentation: key)
      } catch {
        reject("mobilesdk", "Error trying to load private key: \(error)", nil);
        return;
      }
      let attributes = [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                       kSecAttrKeyClass: kSecAttrKeyClassPrivate] as [String: Any]
      let secKey = SecKeyCreateWithData(
        privateKey.x963Representation as CFData,
        attributes as CFDictionary,
        nil)!
      var uuid = UUID();
      let query = [    kSecClass: kSecClassKey,
        kSecAttrApplicationLabel: "mdoc_key",
              kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
   kSecUseDataProtectionKeychain: true,
                    kSecValueRef: secKey] as [String: Any]
      SecItemDelete(query as CFDictionary)
      let status = SecItemAdd(query as CFDictionary, nil)
      //            guard status == errSecSuccess else {
      //                print("Unable to store item: \(status)")
      //            }
      resolve("mdoc_key")
    } else {
      // TODO could not find a way to increase minimum iOS version with React Native
      reject("mobilesdk", "iOS version not supported", nil);
      return;
    }
  }

  @objc
  func createMdocFromCbor(_ cborBase64: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    guard let mdocData = Data(base64Encoded: cborBase64) else {
      reject("mobilesdk", "Invalid base64 data", nil);
      return;
    }
    let mdoc = MDoc(fromMDoc: mdocData, namespaces: [:], keyAlias: "mdoc_key")!
    self.credentials.credentials.append(mdoc)
    MobileSdk.emitter.sendEvent(withName: "onCredentialAdded", body: ["id": mdoc.id])
    resolve(mdoc.id)
  }

  @objc
  func createBleManager(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    resolve("dummy");
  }

  @objc
  func bleSessionStartPresentMdoc(_ bleUuid: String, mdoc: String, privateKey: String, deviceEngagement: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    var deviceEngagement_: DeviceEngagement;
    if deviceEngagement == "qrCode" {
      deviceEngagement_ = .QRCode
    } else {
      reject("mobilesdk", "Unknown device engagement", nil);
      return;
    }
    self.bleSessionManager = self.credentials.presentMdocBLE(deviceEngagement: deviceEngagement_, callback: self);
    if self.bleSessionManager == nil {
      reject("mobilesdk", "There was an issue starting the BLE presentment", nil);
      return;
    }
    resolve(nil)
  }

  @objc
  func bleSessionSubmitNamespaces(_ bleUuid: String, namespaces: [NSDictionary], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    if self.bleSessionManager == nil {
      reject("mobilesdk", "No BLE presentment in progress", nil);
      return;
    }
    self.bleSessionManager?.submitNamespaces(items: namespaces.reduce(into: [:]) { dictionary, item in
      guard let doctype = item["docType"] as? String else {
        reject("mobilesdk", "No `docType` member in submitted namespaces", nil);
        return;
      }
      guard let namespaces = item["namespaces"] as? [NSDictionary] else {
        reject("mobilesdk", "No `namespaces` member in submitted namespaces", nil);
        return;
      }
      dictionary[doctype] = namespaces.reduce(into: [:]) { dictionary, item in
        guard let namespace = item["namespace"] as? String else {
          reject("mobilesdk", "No `namespace` member in submitted namespaces", nil);
          return;
        }
        guard let keys = item["keys"] as? [String] else {
          reject("mobilesdk", "No `keys` member in submitted namespaces", nil);
          return;
        }
        dictionary[namespace] = keys
      }
    })
    resolve(nil)
  }

  @objc
  func bleSessionCancel(_ bleUuid: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    if self.bleSessionManager == nil {
      reject("mobilesdk", "No BLE presentment in progress", nil);
      return;
    }
    self.bleSessionManager?.cancel();
    resolve(nil);
  }

  @objc
  func allCredentials(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    resolve(self.credentials.credentials.map{ $0.id});
  }

}

extension MobileSdk: BLESessionStateDelegate {
    public func update(state: BLESessionState) {
    switch state {
    case .engagingQRCode(let data):
      let str = String(decoding: data, as: UTF8.self)
      MobileSdk.emitter.sendEvent(withName: "onBleSessionEngagingQrCode", body: ["qrCodeUri": str])
    case .error(let error):
      switch error {
      case .bluetooth(let central):
          switch central.state {
                  case .poweredOff:
                      MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "poweredOff"]])
                  case .unsupported:
                      MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "unsupported"]])
                  case .unauthorized:
                      switch CBManager.authorization {
                      case .denied:
                          MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "denied"]])
                      case .restricted:
                          MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "restricted"]])
                      case .allowedAlways:
                          break
                      case .notDetermined:
                          MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "notDetermined"]])
                      @unknown default:
                          MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "unknown"]])
                      }
                  case .unknown:
                      MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "unknown"]])
                  case .resetting:
                      MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "resetting"]])
          case .poweredOn:
             break
          @unknown default:
                      MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "bluetooth", "error": "unknown"]])
                  }
      case .peripheral(let error):
          MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "peripheral", "error": error]])
      case .generic(let error):
          MobileSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": ["kind": "generic", "error": error]])
      }
    case .uploadProgress(let value, let total):
      MobileSdk.emitter.sendEvent(withName: "onBleSessionProgress", body: ["current": value,
                                                                             "total": total])
    case .success:
      MobileSdk.emitter.sendEvent(withName: "onBleSessionSuccess", body: [])
    case .connected:
      MobileSdk.emitter.sendEvent(withName: "onBleSessionEstablished", body: [])
    case .selectNamespaces(let doctypes):
      let items = doctypes.reduce(into: [NSDictionary]()) { result, doctype in
        let namespaces = doctype.namespaces.reduce(into: [NSDictionary]()) {result, namespace in
          let items = namespace.value.reduce(into: [NSDictionary]()) {result, item in
              result.append(["key": item.key, "value": item.value]);
            }
          result.append(["namespace": namespace.key, "kvPairs": items]);
        }
        result.append(["docType": doctype.docType, "namespaces": namespaces]);
      }
      MobileSdk.emitter.sendEvent(withName: "onBleSessionSelectNamespace", body: ["itemsRequest": items])
    }
  }
}
