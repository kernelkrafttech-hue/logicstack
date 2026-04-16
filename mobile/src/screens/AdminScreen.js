import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../context/AuthContext';

export default function AdminScreen({ navigation }) {
  const { merchant, logout } = useAuth();

  const menuItems = [
    { title: 'Manage Staff', subtitle: 'Add, edit, remove staff members', icon: 'people-outline', screen: 'ManageUsers', color: '#3282b8' },
    { title: 'Manage Menu', subtitle: 'Edit categories and menu items', icon: 'restaurant-outline', screen: 'ManageMenu', color: '#4ecca3' },
    { title: 'Printers', subtitle: 'Configure receipt printers', icon: 'print-outline', screen: 'ManagePrinters', color: '#f0a500' },
    { title: 'Settings', subtitle: 'Billing, Clover integration', icon: 'settings-outline', screen: 'Settings', color: '#bb86fc' },
  ];

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.merchantName}>{merchant?.name}</Text>
        <View style={styles.subscriptionBadge}>
          <Text style={styles.subscriptionText}>
            {merchant?.subscription_status === 'active' ? 'Active' : 'Trial'}
          </Text>
        </View>
      </View>

      <View style={styles.menuList}>
        {menuItems.map((item) => (
          <TouchableOpacity
            key={item.screen}
            style={styles.menuItem}
            onPress={() => navigation.navigate(item.screen)}
          >
            <View style={[styles.iconContainer, { backgroundColor: item.color + '20' }]}>
              <Ionicons name={item.icon} size={24} color={item.color} />
            </View>
            <View style={styles.menuItemText}>
              <Text style={styles.menuItemTitle}>{item.title}</Text>
              <Text style={styles.menuItemSubtitle}>{item.subtitle}</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color="#555" />
          </TouchableOpacity>
        ))}
      </View>

      <TouchableOpacity style={styles.logoutBtn} onPress={logout}>
        <Ionicons name="log-out-outline" size={20} color="#e94560" />
        <Text style={styles.logoutText}>Sign Out</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#0f3460',
  },
  merchantName: { fontSize: 22, fontWeight: 'bold', color: '#fff' },
  subscriptionBadge: {
    backgroundColor: '#4ecca3',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  subscriptionText: { color: '#1a1a2e', fontSize: 12, fontWeight: 'bold' },
  menuList: { padding: 16 },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#16213e',
    borderRadius: 12,
    padding: 16,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  menuItemText: { flex: 1, marginLeft: 14 },
  menuItemTitle: { fontSize: 16, fontWeight: '600', color: '#fff' },
  menuItemSubtitle: { fontSize: 13, color: '#888', marginTop: 2 },
  logoutBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    margin: 16,
    padding: 14,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#e94560',
    gap: 8,
  },
  logoutText: { color: '#e94560', fontSize: 16, fontWeight: '600' },
});
