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

export function multiply(a: number, b: number): Promise<number> {
  return WalletSdk.multiply(a, b);
}

export function helloRust(): Promise<string> {
  return WalletSdk.helloRust();
}

export function createMdocFromCbor(cborBase64: string): Promise<String> {
  return WalletSdk.createMdocFromCbor(cborBase64);
}

export function createSoftPrivateKeyFromPem(algo: string, pem: string): Promise<String> {
  return WalletSdk.createSoftPrivateKeyFromPem(algo, pem);
}

export function allCredentials(): Promise<string[]> {
  return WalletSdk.allCredentials();
}

const eventEmitter = new NativeEventEmitter(WalletSdk);

const onRustHelloed = (event: any) => {
  console.log(event);
}

eventEmitter.addListener('onRustHelloed', onRustHelloed);
eventEmitter.addListener('onCredentialAdded', (event: any) => {
  console.log(event);
});
eventEmitter.addListener('onDebugLog', (event: any) => {
  console.log(event);
});

interface BleStateCallback {
  update(state: any):void;
}

export const BleSessionManager = (function() {
  let internalUuid: string | undefined = undefined;

  let toPresent: any = undefined;
  let callbacks: BleStateCallback[] = [];

  WalletSdk.createBleManager().then((uuid: string) => {
    internalUuid = uuid;

    if(toPresent !== undefined) {
      console.log("actually start present", toPresent);
    }
  });

  const sendStateUpdate = (state: any) => {
    callbacks.map((callback) => {
      callback.update(state);
    })
  };

  eventEmitter.addListener('onBleSessionEngagingQrCode', (event: any) => {
    console.log("onBleSessionEngagingQrCode", event);
    sendStateUpdate({
      kind: "sessionEngagingQrCode",
      qrCodeUri: event.qrCodeUri,
    });
  });

  eventEmitter.addListener('onBleSessionError', (event: any) => {
    console.log('onBleSessionError', event);
    sendStateUpdate({
      kind: "error",
      error: event.error,
    });
  });

  eventEmitter.addListener('onBleSessionProgress', (event: any) => {
    console.log('onBleSessionProgress', event);
    sendStateUpdate({
      kind: "progress",
      progressMsg: event.progressMsg,
    });
  });

  eventEmitter.addListener('onBleSessionSelectNamespace', (event: any) => {
    console.log('onBleSessionSelectNamespace', event);
    sendStateUpdate({
      kind: "selectNamespace",
      itemsRequest: event.itemsRequest,
    });
  });

  eventEmitter.addListener('onBleSessionSuccess', (event: any) => {
    console.log('onBleSessionSuccess', event);
    sendStateUpdate({
      kind: "success",
      itemsRequest: event.itemsRequest,
    });
  });

  return {
    registerCallback: function(newCallback: BleStateCallback) {
      console.log("registerCallbacks");
      callbacks.push(newCallback);
    },
    unRegisterCallback: function(oldCallback: BleStateCallback) {
      console.log("unRegisterCallbacks");
      callbacks = callbacks.filter((value) => {
        if(value === oldCallback) {
          return true;
        }
        return false;
      });
    },
    startPresentMdoc: function(mdocUuid: string, privateKey: string, deviceEngagement: string) {
      if(internalUuid === undefined) {
        toPresent = {
          mdocUuid: mdocUuid,
          privateKey: privateKey,
        };
        return;
      }
      WalletSdk.bleSessionStartPresentMdoc(internalUuid, mdocUuid, privateKey, deviceEngagement);
    },
    submitNamespaces: function(permitted: PermittedItemDocType[]) {
      console.log("permitted", permitted);
      WalletSdk.bleSessionSubmitNamespaces(internalUuid, permitted);
    },
    cancel: function() {
      console.log("cancelling");
      WalletSdk.bleSessionCancel(internalUuid);
    }
  };
})();

export interface ItemsRequestKvPair {
  key: string,
  value: boolean,
}

export interface ItemsRequestNamespace {
  namespace: string,
  kvPairs: ItemsRequestKvPair[],
}

export interface ItemsRequestDocType {
  docType: string,
  namespaces: ItemsRequestNamespace[],
}

export interface PermittedItemNamespace {
  namespace: string,
  keys: string[],
}

export interface PermittedItemDocType {
  docType: string,
  namespaces: PermittedItemNamespace[],
}