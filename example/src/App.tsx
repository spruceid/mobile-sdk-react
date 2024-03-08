import * as React from 'react';

import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
  NavigationContainer,
  DefaultTheme,
  DarkTheme,
} from '@react-navigation/native';
import { createMaterialBottomTabNavigator } from 'react-native-paper/react-navigation';
import DebugTab from './DebugTab';
import CredentialsTab from './CredentialsTab';
import ShareTab from './ShareTab';
import { useColorScheme, type ColorSchemeName } from 'react-native';

declare global {
  var mdocUuid: string;
  var privateKeyUuid: string;
}

const Tab = createMaterialBottomTabNavigator();

const showDebugTab = false;

const AppTheme = (scheme: ColorSchemeName) => {
  const Theme = scheme === 'dark' ? DarkTheme : DefaultTheme;
  return {
    ...Theme,
  };
};

export default function App() {
  const scheme = useColorScheme();

  return (
    <SafeAreaProvider>
      <NavigationContainer theme={AppTheme(scheme)}>
        <Tab.Navigator>
          <Tab.Screen name="Credentials" component={CredentialsTab} />
          <Tab.Screen name="Share" component={ShareTab} />
          {showDebugTab && <Tab.Screen name="Debug" component={DebugTab} />}
        </Tab.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
}
