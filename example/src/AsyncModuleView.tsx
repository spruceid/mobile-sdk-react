import * as React from 'react';

import { Button, StyleSheet, View, Text } from 'react-native';
import { multiply } from 'react-native-sprucekit-wallet-sdk';

interface ComputationData {
  value: string | number,
  status: string,
}

function useComputation() {
  const [data, setData] = React.useState<ComputationData>({value: "None", status: "Not Run"});

  function doCompute() {
    setData({
      value: data.value,
      status: "Computing...",
    });

    multiply(3, 2).then((res) => {
      setData({
        value: res,
        status: "Finished",
      })  
    });
  }

  return [data.value, doCompute, data.status];
} 

const AsyncModuleView = () => {
  const [value, doCompute, computationStatus] = useComputation();

  return (
      <View style={styles.container}>
        <Text>{computationStatus}</Text>
        <Text>Test Result: {value}</Text>
        <Button onPress={doCompute} title='Compute'/>
      </View>
  );
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

export default AsyncModuleView;
