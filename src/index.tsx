import { NativeEventEmitter, NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-wallet-sdk' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// @ts-expect-error
const isTurboModuleEnabled = global.__turboModuleProxy != null;

const WalletSdkModule = isTurboModuleEnabled
  ? require('./NativeWalletSdk').default
  : NativeModules.WalletSdk;

const WalletSdk = WalletSdkModule
  ? WalletSdkModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

/**
 * Register an MDoc with the wallet-sdk
 * @param cborBase64 Base64 of the CBOR of the MDoc to register
 * @returns UUID object ID of the MDoc created
 */
export function createMdocFromCbor(cborBase64: string): Promise<String> {
  return WalletSdk.createMdocFromCbor(cborBase64);
}

/**
 * Register a private key with the wallet-sdk from a PKCS#8 PEM
 * @param algo Accepted values: "p256"
 * @param key PEM encoded private key
 * @param cert PEM encoded self-signed cert (required by Android's key store)
 * @returns UUID object ID of the private key created
 */
export function createSoftPrivateKeyFromPKCS8PEM(
  algo: string,
  key: string,
  cert: string
): Promise<String> {
  return WalletSdk.createSoftPrivateKeyFromPKCS8PEM(algo, key, cert);
}

/**
 * Retrieve a list of all credentials (such as MDocs) registered with the
 * wallet-sdk
 * @returns Array of UUID object IDs of credentials
 */
export function allCredentials(): Promise<string[]> {
  return WalletSdk.allCredentials();
}

const eventEmitter = new NativeEventEmitter(WalletSdk);

eventEmitter.addListener('onCredentialAdded', (event: any) => {
  console.log(event);
});
eventEmitter.addListener('onDebugLog', (event: any) => {
  console.log(event);
});

/**
 * Event emitted when reader has begun ISO/IEC DIS 18013-5 mDL Peripheral
 * Server Mode with "qrCode" device engagement and the app is required to
 * present a URL QR code with the given qrCodeUri to be scanned by the reader
 */
export interface QrCodeState {
  kind: 'qrCode';
  /**
   * URI to be displayed as QR code
   */
  qrCodeUri: string;
}

/**
 * Event emitted on any error during BLE presentment
 */
export interface ErrorState {
  kind: 'error';
  /**
   * Debug error message
   */
  error: string;
}

/**
 * Event emitted when the list of field types requested by the reader have
 * been received and need to be validated by the app.  This state is cleared
 * with a subsequent call to BleManager.submitNamespaces()
 */
export interface SelectNamespaceState {
  kind: 'selectNamespace';
  /**
   * The list of field types requested by the reader
   */
  itemsRequest: ItemsRequestDocType[];
}

/**
 * Event emitted when an upload is in progress, such as when the holder sends a
 * response to the reader.
 */
export interface UploadProgressState {
  kind: 'uploadProgress';
  /**
   * Number of chunks sent so far.
   */
  current: number;
  /**
   * Total number of chunks to be sent.
   */
  total: number;
}

/**
 * Event emitted when the device connected to another, such as when the holder
 * connects to the reader.
 */
export interface ConnectedState {
  kind: 'connected';
}

/**
 * Event emitted upon successful completion of BLE presentment
 */
export interface SuccessState {
  kind: 'success';
}

export type BleUpdateState =
  | QrCodeState
  | ErrorState
  | SelectNamespaceState
  | UploadProgressState
  | SuccessState
  | ConnectedState;

export interface BleStateCallback {
  update(state: BleUpdateState): void;
}

export const BleSessionManager = (function () {
  let internalUuid: string | undefined;

  interface DeferredPresentArgs {
    mdocUuid: string;
    privateKey: string;
    deviceEngagement: string;
  }

  let toPresent: DeferredPresentArgs | undefined;
  let callbacks: BleStateCallback[] = [];

  WalletSdk.createBleManager().then((uuid: string) => {
    internalUuid = uuid;

    if (toPresent !== undefined) {
      WalletSdk.startPresentMdoc(
        internalUuid,
        toPresent.mdocUuid,
        toPresent.privateKey,
        toPresent.deviceEngagement
      );
      toPresent = undefined;
    }
  });

  const sendStateUpdate = (state: BleUpdateState) => {
    callbacks.map((callback) => {
      callback.update(state);
    });
  };

  eventEmitter.addListener('onBleSessionEngagingQrCode', (event: any) => {
    console.log('onBleSessionEngagingQrCode', event);
    sendStateUpdate({
      kind: 'qrCode',
      qrCodeUri: event.qrCodeUri,
    });
  });

  eventEmitter.addListener('onBleSessionEstablished', (event: any) => {
    console.log('onBleSessionEstablished', event);
    sendStateUpdate({
      kind: 'connected',
    });
  });

  eventEmitter.addListener('onBleSessionError', (event: any) => {
    console.log('onBleSessionError', event);
    sendStateUpdate({
      kind: 'error',
      error: event.error,
    });
  });

  eventEmitter.addListener('onBleSessionProgress', (event: any) => {
    sendStateUpdate({
      kind: 'uploadProgress',
      current: event.uploadProgress.current,
      total: event.uploadProgress.total,
    });
  });

  eventEmitter.addListener('onBleSessionSelectNamespace', (event: any) => {
    console.log('onBleSessionSelectNamespace', event);
    sendStateUpdate({
      kind: 'selectNamespace',
      itemsRequest: event.itemsRequest,
    });
  });

  eventEmitter.addListener('onBleSessionSuccess', (event: any) => {
    console.log('onBleSessionSuccess', event);
    sendStateUpdate({
      kind: 'success',
    });
  });

  return {
    /**
     * Register a callback with the BLE session manager
     * @param newCallback
     */
    registerCallback: function (newCallback: BleStateCallback) {
      console.log('registerCallbacks');
      callbacks.push(newCallback);
    },
    /**
     * Deregister a callback with the BLE session manager.  Note: all copies of
     * this callback will be removed if it had been registerd multiple times
     * @param oldCallback
     */
    unRegisterCallback: function (oldCallback: BleStateCallback) {
      console.log('unRegisterCallbacks');
      callbacks = callbacks.filter((value) => {
        if (value === oldCallback) {
          return true;
        }
        return false;
      });
    },
    /**
     * Begin ISO/IEC DIS 18013-5 mDL Peripheral Server Mode
     * @param mdocUuid UUID object ID of the mdoc to present
     * @param privateKey UUID object ID of the private key matched with the mdoc
     * @param deviceEngagement Accepted values: "qrCode"
     */
    startPresentMdoc: function (
      mdocUuid: string,
      privateKey: string,
      deviceEngagement: string
    ) {
      if (internalUuid === undefined) {
        toPresent = {
          mdocUuid: mdocUuid,
          privateKey: privateKey,
          deviceEngagement: deviceEngagement,
        };
        return;
      }
      WalletSdk.bleSessionStartPresentMdoc(
        internalUuid,
        mdocUuid,
        privateKey,
        deviceEngagement
      );
    },
    /**
     * Submit which fields are permitted by the reader to send after receiving
     * a SelectNamespaceEvent
     * @param permitted Fields that the app permits to send to the reader
     */
    submitNamespaces: function (permitted: PermittedItemDocType[]) {
      console.log('permitted', permitted);
      WalletSdk.bleSessionSubmitNamespaces(internalUuid, permitted);
    },

    /**
     * Cancel in progress connections and shutdown BLE stack
     */
    cancel: function () {
      console.log('cancelling');
      WalletSdk.bleSessionCancel(internalUuid);
    },
  };
})();

export interface ItemsRequestKvPair {
  key: string;
  value: boolean;
}

export interface ItemsRequestNamespace {
  namespace: string;
  kvPairs: ItemsRequestKvPair[];
}

export interface ItemsRequestDocType {
  docType: string;
  namespaces: ItemsRequestNamespace[];
}

export interface PermittedItemNamespace {
  namespace: string;
  keys: string[];
}

export interface PermittedItemDocType {
  docType: string;
  namespaces: PermittedItemNamespace[];
}
