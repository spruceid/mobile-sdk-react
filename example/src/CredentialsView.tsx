import * as React from 'react';

import { Button, StyleSheet, View } from 'react-native';
import type { Credential } from '../../src/credential';

const testCredentials: Credential[] = [
	{ id: "test credential 1" },
	{ id: "test credential 2" },
];

const CredentialsView = () => {
	const [credentials, _] = React.useState(testCredentials);

	return (
		<View style={styles.container}>
			{credentials.map((item, i) => {
				return (<Button key={i} title={item.id}></Button>)
			})}
		</View>
	)
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});

export default CredentialsView;
