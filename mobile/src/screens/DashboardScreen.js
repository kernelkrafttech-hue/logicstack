import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, RefreshControl, ScrollView } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../context/AuthContext';
import { orders } from '../services/api';

export default function DashboardScreen({ navigation }) {
  const { user, merchant, isAdmin } = useAuth();
  const [stats, setStats] = useState(null);
  const [recentOrders, setRecentOrders] = useState([]);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = useCallback(async () => {
    try {
      const [statsData, ordersData] = await Promise.all([
        orders.getStats(),
        orders.list({ limit: 5 }),
      ]);
      setStats(statsData);
      setRecentOrders(ordersData);
    } catch (err) {
      console.warn('Dashboard load error:', err);
    }
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadData();
      // Refresh every 30 seconds
      const interval = setInterval(loadData, 30000);
      return () => clearInterval(interval);
    }, [loadData])
  );

  async function onRefresh() {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  }

  const statusColors = {
    pending: '#f0a500',
    in_progress: '#3282b8',
    ready: '#4ecca3',
    completed: '#888',
    cancelled: '#e94560',
    in_review: '#bb86fc',
  };

  return (
    <ScrollView
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#e94560" />}
    >
      <View style={styles.welcome}>
        <Text style={styles.greeting}>Welcome, {user?.name}</Text>
        <Text style={styles.merchantName}>{merchant?.name}</Text>
      </View>

      {/* Quick Actions */}
      <View style={styles.quickActions}>
        <TouchableOpacity style={styles.actionCard} onPress={() => navigation.navigate('NewOrder')}>
          <Ionicons name="add-circle" size={32} color="#e94560" />
          <Text style={styles.actionLabel}>New Order</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionCard} onPress={() => navigation.navigate('Orders')}>
          <Ionicons name="receipt" size={32} color="#3282b8" />
          <Text style={styles.actionLabel}>All Orders</Text>
        </TouchableOpacity>
        {isAdmin && (
          <TouchableOpacity style={styles.actionCard} onPress={() => navigation.navigate('Admin')}>
            <Ionicons name="settings" size={32} color="#4ecca3" />
            <Text style={styles.actionLabel}>Admin</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Stats */}
      {stats && (
        <View style={styles.statsContainer}>
          <Text style={styles.sectionTitle}>Today's Overview</Text>
          <View style={styles.statsGrid}>
            <View style={[styles.statCard, { borderLeftColor: '#f0a500' }]}>
              <Text style={styles.statNumber}>{stats.pending}</Text>
              <Text style={styles.statLabel}>Pending</Text>
            </View>
            <View style={[styles.statCard, { borderLeftColor: '#3282b8' }]}>
              <Text style={styles.statNumber}>{stats.in_progress}</Text>
              <Text style={styles.statLabel}>In Progress</Text>
            </View>
            <View style={[styles.statCard, { borderLeftColor: '#4ecca3' }]}>
              <Text style={styles.statNumber}>{stats.ready}</Text>
              <Text style={styles.statLabel}>Ready</Text>
            </View>
            <View style={[styles.statCard, { borderLeftColor: '#e94560' }]}>
              <Text style={styles.statNumber}>{stats.completed}</Text>
              <Text style={styles.statLabel}>Completed</Text>
            </View>
          </View>
          <View style={styles.revenueCard}>
            <Text style={styles.revenueLabel}>Today's Revenue</Text>
            <Text style={styles.revenueAmount}>${(stats.revenue / 100).toFixed(2)}</Text>
            <Text style={styles.revenueSubtext}>{stats.total_orders} total orders</Text>
          </View>
        </View>
      )}

      {/* Recent Orders */}
      <View style={styles.recentContainer}>
        <Text style={styles.sectionTitle}>Recent Orders</Text>
        {recentOrders.length === 0 ? (
          <Text style={styles.emptyText}>No orders yet. Create your first order!</Text>
        ) : (
          recentOrders.map((order) => (
            <TouchableOpacity
              key={order.id}
              style={styles.orderCard}
              onPress={() => navigation.navigate('Orders', { screen: 'OrderDetail', params: { orderId: order.id } })}
            >
              <View style={styles.orderHeader}>
                <Text style={styles.orderNumber}>#{order.order_number}</Text>
                <View style={[styles.statusBadge, { backgroundColor: statusColors[order.status] || '#888' }]}>
                  <Text style={styles.statusText}>{order.status.replace('_', ' ').toUpperCase()}</Text>
                </View>
              </View>
              <View style={styles.orderDetails}>
                <Text style={styles.orderInfo}>
                  {order.items?.length || 0} items - ${(order.total / 100).toFixed(2)}
                </Text>
                <Text style={styles.orderTime}>
                  {new Date(order.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </Text>
              </View>
            </TouchableOpacity>
          ))
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  welcome: { padding: 20, paddingBottom: 10 },
  greeting: { fontSize: 24, fontWeight: 'bold', color: '#fff' },
  merchantName: { fontSize: 14, color: '#aaa', marginTop: 4 },
  quickActions: { flexDirection: 'row', padding: 16, gap: 12 },
  actionCard: {
    flex: 1,
    backgroundColor: '#16213e',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  actionLabel: { color: '#fff', fontSize: 13, marginTop: 8, fontWeight: '600' },
  statsContainer: { padding: 16 },
  sectionTitle: { fontSize: 18, fontWeight: 'bold', color: '#fff', marginBottom: 12 },
  statsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  statCard: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 16,
    borderLeftWidth: 4,
  },
  statNumber: { fontSize: 28, fontWeight: 'bold', color: '#fff' },
  statLabel: { fontSize: 13, color: '#aaa', marginTop: 4 },
  revenueCard: {
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 20,
    marginTop: 12,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  revenueLabel: { fontSize: 14, color: '#aaa' },
  revenueAmount: { fontSize: 36, fontWeight: 'bold', color: '#4ecca3', marginTop: 4 },
  revenueSubtext: { fontSize: 13, color: '#888', marginTop: 4 },
  recentContainer: { padding: 16 },
  emptyText: { color: '#888', fontSize: 14, textAlign: 'center', marginTop: 20 },
  orderCard: {
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  orderHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  orderNumber: { fontSize: 18, fontWeight: 'bold', color: '#fff' },
  statusBadge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12 },
  statusText: { color: '#fff', fontSize: 11, fontWeight: 'bold' },
  orderDetails: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 8 },
  orderInfo: { color: '#ccc', fontSize: 14 },
  orderTime: { color: '#888', fontSize: 13 },
});
