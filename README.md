[![NPM Version](https://img.shields.io/npm/v/%40spruceid%2Freact-native-wallet-sdk)](https://www.npmjs.com/package/@spruceid/react-native-wallet-sdk)
[![ghpages](https://img.shields.io/badge/docs-passing-green)](https://spruceid.github.io/wallet-sdk-react/)

# SpruceID Wallet SDK for React Native

## Maturity Disclaimer

In its current version, Wallet SDK has not yet undergone a formal security audit
to desired levels of confidence for suitable use in production systems. This
implementation is currently suitable for exploratory work and experimentation
only. We welcome feedback on the usability, architecture, and security of this
implementation and are committed to a conducting a formal audit with a reputable
security firm before the v1.0 release.

## Installation

```sh
npm install @spruceid/react-native-wallet-sdk
```

### iOS

Add to the app's info.plist

```xml
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>Secure transmission of mobile DL/ID data</string>
```

### Android

Add to the `AndroidManifest.xml`

```xml
  <uses-permission android:name="android.permission.BLUETOOTH" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

In addition to the manifest, on newer Android versions your applications will
also need to trigger a dialogue prompt. [You can refer to this documentation for more information](https://reactnative.dev/docs/permissionsandroid)
```js
await PermissionsAndroid.requestMultiple([
  'android.permission.ACCESS_FINE_LOCATION',
  'android.permission.BLUETOOTH_CONNECT',
  'android.permission.BLUETOOTH_SCAN',
  'android.permission.BLUETOOTH_ADVERTISE',
]);
```

## Usage

```js
import { createMdocFromCbor } from '@spruceid/react-native-wallet-sdk';

// ...

const mdoc = await createMdocFromCbor(mdocCborBase64);
```

For more, see [the documentation](https://spruceid.github.io/wallet-sdk-react/).

## Contributing

See the [contributing guide](https://github.com/spruceid/wallet-sdk-react/blob/main/CONTRIBUTING.md)
to learn how to contribute to the repository and the development workflow.

## Architecture

Our Wallet SDKs use shared code, with most of the logic being written once in
Rust, and when not possible, native APIs (e.g. Bluetooth, OS Keychain) are
called in native SDKs.

```
  ┌────────────┐
  │React Native│
  └──────┬─────┘
         │
    ┌────┴────┐
┌───▼──┐   ┌──▼──┐
│Kotlin│   │Swift│
└───┬──┘   └──┬──┘
    └────┬────┘
         │
      ┌──▼─┐
      │Rust│
      └────┘
```
- [Kotlin SDK](https://github.com/spruceid/wallet-sdk-kt)
- [Swift SDK](https://github.com/spruceid/wallet-sdk-swift)
- [Rust layer](https://github.com/spruceid/wallet-sdk-rs)
