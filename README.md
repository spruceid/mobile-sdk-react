# react-native-wallet-sdk

SpruceID Wallet SDK for React Native

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

## Usage

```js
import { createMdocFromCbor } from '@spruceid/react-native-wallet-sdk';

// ...

const mdoc = await createMdocFromCbor(mdocCborBase64);
```

For more, see [documentation](githubjsdoc).

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## Licenses

```
MIT OR Apache-2.0
```

---
