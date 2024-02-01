import * as React from 'react';

import { StyleSheet, Text, View } from 'react-native';

const ShareView = () => {
	return (
		<View style={styles.container}>
			<Text>Share</Text>
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

export default ShareView;
