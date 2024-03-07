import * as React from 'react';

import { Text, View } from 'react-native';
import styles from './Styles';
import { allCredentials } from '@spruceid/react-native-wallet-sdk';

export default function CredentialsTab() {
  const [credentials, setCredentials] = React.useState<string[]>([
    'Not yet read',
  ]);

  React.useEffect(() => {
    allCredentials().then(setCredentials);
  }, []);

  return (
    <View style={styles.container}>
      {credentials.map((credUuid, i) => (
        <Text style={{ color: 'black' }} key={i}>
          {credUuid}
        </Text>
      ))}
    </View>
  );
}
