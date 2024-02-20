import * as React from 'react';

import { Text, View } from 'react-native';
import { multiply, helloRust } from 'react-native-wallet-sdk';
import styles from './Styles';

export default function DebugTab() {
	const [result, setResult] = React.useState<number | undefined>();
	const [helloRustResult, setHelloRustResult] = React.useState<string>("Not yet read");

	React.useEffect(() => {
		multiply(3, 7).then(setResult);
	}, []);

	React.useEffect(() => {
		helloRust().then(setHelloRustResult);
	}, []);

	return (
		<View style={styles.container}>
			<Text>Result: {result}</Text>
			<Text>Hello Rust: {helloRustResult}</Text>
		</View>
	);
}