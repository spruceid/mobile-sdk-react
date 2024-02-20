import * as React from 'react';

import { SafeAreaProvider } from 'react-native-safe-area-context';
import { NavigationContainer } from '@react-navigation/native';
import { createMaterialBottomTabNavigator } from 'react-native-paper/react-navigation';
import DebugTab from './DebugTab';
import CredentialsTab from './CredentialsTab';
import ShareTab from './ShareTab';

const Tab = createMaterialBottomTabNavigator();

const showDebugTab = false;

export default function App() {
  return (
    <SafeAreaProvider>
      <NavigationContainer>
        <Tab.Navigator>
          <Tab.Screen name="Credentials" component={CredentialsTab} />
          <Tab.Screen name="Share" component={ShareTab} />
          {showDebugTab && (<Tab.Screen name="Debug" component={DebugTab} />)}
        </Tab.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
}