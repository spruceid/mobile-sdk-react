import { NativeModules, Platform } from 'react-native';
import { Credential } from './credential';

const LINKING_ERROR =
  `The package 'react-native-sprucekit-wallet-sdk' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// @ts-expect-error
const isTurboModuleEnabled = global.__turboModuleProxy != null;

const SprucekitWalletSdkModule = isTurboModuleEnabled
  ? require('./NativeSprucekitWalletSdk').default
  : NativeModules.SprucekitWalletSdk;

const SprucekitWalletSdk = SprucekitWalletSdkModule
  ? SprucekitWalletSdkModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );


function multiply(a: number, b: number): Promise<number> {
  return SprucekitWalletSdk.multiply(a, b);
}

export {
  type Credential,
  multiply,
}