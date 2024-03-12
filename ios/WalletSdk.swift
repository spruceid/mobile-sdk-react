import CoreBluetooth
import CryptoKit
import Foundation
import SpruceIDWalletSdk

@objc(WalletSdk)
class WalletSdk: RCTEventEmitter {
  public static var emitter: RCTEventEmitter!
  var credentials = CredentialStore(credentials: []);
  var bleSessionManager: BLESessionManager?;

  override init() {
    super.init()
    WalletSdk.emitter = self
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
      reject("walletsdk", "Unknown algorithm: \(algo)", nil);
      return;
    }
    if #available(iOS 14.0, *) {
      var privateKey: P256.Signing.PrivateKey;
      do {
        privateKey = try P256.Signing.PrivateKey(pemRepresentation: key)
      } catch {
        reject("walletsdk", "Error trying to load private key: \(error)", nil);
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
      reject("walletsdk", "iOS version not supported", nil);
      return;
    }
  }

  @objc
  func createMdocFromCbor(_ cborBase64: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    guard let mdocData = Data(base64Encoded: cborBase64) else {
      reject("walletsdk", "Invalid base64 data", nil);
      return;
    }
    let mdoc = MDoc(fromMDoc: mdocData, namespaces: [:], keyAlias: "mdoc_key")!
    self.credentials.credentials.append(mdoc)
    WalletSdk.emitter.sendEvent(withName: "onCredentialAdded", body: ["id": mdoc.id])
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
      reject("walletsdk", "Unknown device engagement", nil);
      return;
    }
    self.bleSessionManager = self.credentials.presentMdocBLE(deviceEngagement: deviceEngagement_, callback: self);
    if self.bleSessionManager == nil {
      reject("walletsdk", "There was an issue starting the BLE presentment", nil);
      return;
    }
    resolve(nil)
  }

  @objc
  func bleSessionSubmitNamespaces(_ bleUuid: String, namespaces: [NSDictionary], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    if self.bleSessionManager == nil {
      reject("walletsdk", "No BLE presentment in progress", nil);
      return;
    }
    self.bleSessionManager?.submitNamespaces(items: namespaces.reduce(into: [:]) { dictionary, item in
      guard let doctype = item["docType"] as? String else {
        reject("walletsdk", "No `docType` member in submitted namespaces", nil);
        return;
      }
      guard let namespaces = item["namespaces"] as? [NSDictionary] else {
        reject("walletsdk", "No `namespaces` member in submitted namespaces", nil);
        return;
      }
      dictionary[doctype] = namespaces.reduce(into: [:]) { dictionary, item in
        guard let namespace = item["namespace"] as? String else {
          reject("walletsdk", "No `namespace` member in submitted namespaces", nil);
          return;
        }
        guard let keys = item["keys"] as? [String] else {
          reject("walletsdk", "No `keys` member in submitted namespaces", nil);
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
      reject("walletsdk", "No BLE presentment in progress", nil);
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

extension WalletSdk: BLESessionStateDelegate {
    public func update(state: BLESessionState) {
    switch state {
    case .engagingQRCode(let data):
      let str = String(decoding: data, as: UTF8.self)
      WalletSdk.emitter.sendEvent(withName: "onBleSessionEngagingQrCode", body: ["qrCodeUri": str])
    case .error(let error):
      let message = switch error {
      case .bluetooth(let central):
          switch central.state {
                  case .poweredOff:
                      "Is Powered Off."
                  case .unsupported:
                      "Is Unsupported."
                  case .unauthorized:
                      switch CBManager.authorization {
                      case .denied:
                          "Authorization denied"
                      case .restricted:
                          "Authorization restricted"
                      case .allowedAlways:
                          "Authorized"
                      case .notDetermined:
                          "Authorization not determined"
                      @unknown default:
                          "Unknown authorization error"
                      }
                  case .unknown:
                      "Unknown"
                  case .resetting:
                      "Resetting"
          case .poweredOn:
             "Impossible"
          @unknown default:
                      "Error"
                  }
      case .peripheral(let error):
          error
      case .generic(let error):
          error
      }
      WalletSdk.emitter.sendEvent(withName: "onBleSessionError", body: ["error": message])
    case .uploadProgress(let value, let total):
      WalletSdk.emitter.sendEvent(withName: "onBleSessionProgress", body: ["current": value,
                                                                             "total": total])
    case .success:
      WalletSdk.emitter.sendEvent(withName: "onBleSessionSuccess", body: [])
    case .connected:
      WalletSdk.emitter.sendEvent(withName: "onBleSessionEstablished", body: [])
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
      WalletSdk.emitter.sendEvent(withName: "onBleSessionSelectNamespace", body: ["itemsRequest": items])
    }
  }
}
