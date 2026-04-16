import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, RefreshControl } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { orders as ordersApi } from '../services/api';

const STATUS_FILTERS = [
  { key: null, label: 'All' },
  { key: 'pending', label: 'Pending' },
  { key: 'in_progress', label: 'In Progress' },
  { key: 'ready', label: 'Ready' },
  { key: 'in_review', label: 'In Review' },
  { key: 'completed', label: 'Done' },
];

const statusColors = {
  pending: '#f0a500',
  in_progress: '#3282b8',
  ready: '#4ecca3',
  completed: '#888',
  cancelled: '#e94560',
  in_review: '#bb86fc',
};

const statusIcons = {
  pending: 'time-outline',
  in_progress: 'flame-outline',
  ready: 'checkmark-circle-outline',
  completed: 'checkmark-done-outline',
  cancelled: 'close-circle-outline',
  in_review: 'eye-outline',
};

export default function OrdersScreen({ navigation }) {
  const [ordersList, setOrdersList] = useState([]);
  const [statusFilter, setStatusFilter] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  const loadOrders = useCallback(async () => {
    try {
      const params = {};
      if (statusFilter) params.status = statusFilter;
      const data = await ordersApi.list(params);
      setOrdersList(data);
    } catch (err) {
      console.warn('Load orders error:', err);
    }
  }, [statusFilter]);

  useFocusEffect(
    useCallback(() => {
      loadOrders();
      const interval = setInterval(loadOrders, 15000);
      return () => clearInterval(interval);
    }, [loadOrders])
  );

  async function onRefresh() {
    setRefreshing(true);
    await loadOrders();
    setRefreshing(false);
  }

  function renderOrder({ item: order }) {
    const typeLabels = { dine_in: 'Dine In', takeout: 'Takeout', delivery: 'Delivery' };

    return (
      <TouchableOpacity
        style={styles.orderCard}
        onPress={() => navigation.navigate('OrderDetail', { orderId: order.id })}
      >
        <View style={styles.orderTop}>
          <View style={styles.orderLeft}>
            <Text style={styles.orderNumber}>#{order.order_number}</Text>
            <Text style={styles.orderType}>{typeLabels[order.order_type] || order.order_type}</Text>
          </View>
          <View style={[styles.statusBadge, { backgroundColor: statusColors[order.status] }]}>
            <Ionicons name={statusIcons[order.status]} size={14} color="#fff" />
            <Text style={styles.statusText}>{order.status.replace('_', ' ').toUpperCase()}</Text>
          </View>
        </View>

        {order.customer_name && <Text style={styles.customerName}>{order.customer_name}</Text>}
        {order.table_number && <Text style={styles.tableNum}>Table {order.table_number}</Text>}

        <View style={styles.orderBottom}>
          <Text style={styles.orderItems}>{order.items?.length || 0} items</Text>
          <Text style={styles.orderTotal}>${(order.total / 100).toFixed(2)}</Text>
        </View>

        <Text style={styles.orderTime}>
          {new Date(order.created_at).toLocaleString([], {
            month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
          })}
          {order.created_by_name ? ` - ${order.created_by_name}` : ''}
        </Text>
      </TouchableOpacity>
    );
  }

  return (
    <View style={styles.container}>
      {/* Status filter tabs */}
      <FlatList
        horizontal
        data={STATUS_FILTERS}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[styles.filterTab, statusFilter === item.key && styles.filterTabActive]}
            onPress={() => setStatusFilter(item.key)}
          >
            <Text style={[styles.filterText, statusFilter === item.key && styles.filterTextActive]}>
              {item.label}
            </Text>
          </TouchableOpacity>
        )}
        keyExtractor={(item) => item.label}
        style={styles.filterList}
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.filterContent}
      />

      {/* Orders list */}
      <FlatList
        data={ordersList}
        renderItem={renderOrder}
        keyExtractor={(item) => item.id}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#e94560" />}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="receipt-outline" size={48} color="#444" />
            <Text style={styles.emptyText}>No orders found</Text>
          </View>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  filterList: { maxHeight: 50, borderBottomWidth: 1, borderBottomColor: '#0f3460' },
  filterContent: { paddingHorizontal: 12, gap: 8, alignItems: 'center' },
  filterTab: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 16,
    backgroundColor: '#16213e',
  },
  filterTabActive: { backgroundColor: '#e94560' },
  filterText: { color: '#aaa', fontSize: 13, fontWeight: '600' },
  filterTextActive: { color: '#fff' },
  listContent: { padding: 12, paddingBottom: 20 },
  orderCard: {
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  orderTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  orderLeft: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  orderNumber: { fontSize: 20, fontWeight: 'bold', color: '#fff' },
  orderType: { fontSize: 13, color: '#aaa', backgroundColor: '#0f3460', paddingHorizontal: 8, paddingVertical: 2, borderRadius: 4 },
  statusBadge: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12, gap: 4 },
  statusText: { color: '#fff', fontSize: 11, fontWeight: 'bold' },
  customerName: { color: '#ccc', fontSize: 14, marginTop: 6 },
  tableNum: { color: '#f0a500', fontSize: 13, marginTop: 2 },
  orderBottom: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 10 },
  orderItems: { color: '#888', fontSize: 14 },
  orderTotal: { color: '#4ecca3', fontSize: 16, fontWeight: 'bold' },
  orderTime: { color: '#666', fontSize: 12, marginTop: 6 },
  emptyContainer: { alignItems: 'center', marginTop: 80 },
  emptyText: { color: '#666', fontSize: 16, marginTop: 12 },
});
