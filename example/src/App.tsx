import * as React from 'react';
import { createMaterialBottomTabNavigator } from '@react-navigation/material-bottom-tabs';
import { NavigationContainer } from '@react-navigation/native';
import AsyncModuleView from './AsyncModuleView';
import CredentialsView from './CredentialsView';
import ShareView from './ShareView';

const Tab = createMaterialBottomTabNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Tab.Navigator>
        <Tab.Screen name="Test Async Module" component={AsyncModuleView} />
        <Tab.Screen name="Credentials" component={CredentialsView} />
        <Tab.Screen name="Share" component={ShareView} />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
