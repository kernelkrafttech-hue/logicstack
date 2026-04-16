import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../context/AuthContext';

// Auth screens
import LoginScreen from '../screens/LoginScreen';
import RegisterScreen from '../screens/RegisterScreen';

// Main screens
import DashboardScreen from '../screens/DashboardScreen';
import MenuScreen from '../screens/MenuScreen';
import CartScreen from '../screens/CartScreen';
import OrdersScreen from '../screens/OrdersScreen';
import OrderDetailScreen from '../screens/OrderDetailScreen';
import AdminScreen from '../screens/AdminScreen';
import ManageUsersScreen from '../screens/ManageUsersScreen';
import ManageMenuScreen from '../screens/ManageMenuScreen';
import ManagePrintersScreen from '../screens/ManagePrintersScreen';
import SettingsScreen from '../screens/SettingsScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();
const OrderStack = createNativeStackNavigator();
const AdminStack = createNativeStackNavigator();

const headerStyle = {
  headerStyle: { backgroundColor: '#1a1a2e' },
  headerTintColor: '#fff',
  headerTitleStyle: { fontWeight: 'bold' },
};

function OrdersStackScreen() {
  return (
    <OrderStack.Navigator screenOptions={headerStyle}>
      <OrderStack.Screen name="OrdersList" component={OrdersScreen} options={{ title: 'Orders' }} />
      <OrderStack.Screen name="OrderDetail" component={OrderDetailScreen} options={{ title: 'Order Details' }} />
    </OrderStack.Navigator>
  );
}

function AdminStackScreen() {
  return (
    <AdminStack.Navigator screenOptions={headerStyle}>
      <AdminStack.Screen name="AdminHome" component={AdminScreen} options={{ title: 'Admin' }} />
      <AdminStack.Screen name="ManageUsers" component={ManageUsersScreen} options={{ title: 'Manage Staff' }} />
      <AdminStack.Screen name="ManageMenu" component={ManageMenuScreen} options={{ title: 'Manage Menu' }} />
      <AdminStack.Screen name="ManagePrinters" component={ManagePrintersScreen} options={{ title: 'Printers' }} />
      <AdminStack.Screen name="Settings" component={SettingsScreen} options={{ title: 'Settings' }} />
    </AdminStack.Navigator>
  );
}

function MainTabs() {
  const { isAdmin } = useAuth();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName;
          switch (route.name) {
            case 'Dashboard':
              iconName = focused ? 'grid' : 'grid-outline';
              break;
            case 'NewOrder':
              iconName = focused ? 'add-circle' : 'add-circle-outline';
              break;
            case 'Orders':
              iconName = focused ? 'receipt' : 'receipt-outline';
              break;
            case 'Admin':
              iconName = focused ? 'settings' : 'settings-outline';
              break;
          }
          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#e94560',
        tabBarInactiveTintColor: '#888',
        tabBarStyle: { backgroundColor: '#16213e', borderTopColor: '#0f3460', paddingBottom: 5, height: 60 },
        tabBarLabelStyle: { fontSize: 12 },
        headerShown: false,
      })}
    >
      <Tab.Screen name="Dashboard" component={DashboardScreen} options={{ headerShown: true, ...headerStyle }} />
      <Tab.Screen name="NewOrder" component={MenuScreen} options={{ title: 'New Order', headerShown: true, ...headerStyle }} />
      <Tab.Screen name="Orders" component={OrdersStackScreen} />
      {isAdmin && <Tab.Screen name="Admin" component={AdminStackScreen} />}
    </Tab.Navigator>
  );
}

export default function AppNavigator() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return null; // Or a loading screen
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {isAuthenticated ? (
        <Stack.Screen name="Main" component={MainTabs} />
      ) : (
        <>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Register" component={RegisterScreen} />
        </>
      )}
      <Stack.Screen name="Cart" component={CartScreen} options={{ headerShown: true, title: 'Review Order', ...headerStyle, presentation: 'modal' }} />
    </Stack.Navigator>
  );
}
