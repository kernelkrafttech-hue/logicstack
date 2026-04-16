import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../context/AuthContext';
import { orders as ordersApi } from '../services/api';

const statusColors = {
  pending: '#f0a500',
  in_progress: '#3282b8',
  ready: '#4ecca3',
  completed: '#888',
  cancelled: '#e94560',
  in_review: '#bb86fc',
};

const statusFlow = ['pending', 'in_progress', 'ready', 'completed'];

export default function OrderDetailScreen({ route, navigation }) {
  const { orderId } = route.params;
  const { isAdmin } = useAuth();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    loadOrder();
  }, [orderId]);

  async function loadOrder() {
    try {
      const data = await ordersApi.get(orderId);
      setOrder(data);
    } catch (err) {
      Alert.alert('Error', 'Failed to load order');
      navigation.goBack();
    } finally {
      setLoading(false);
    }
  }

  async function handleStatusChange(newStatus) {
    setUpdating(true);
    try {
      const updated = await ordersApi.updateStatus(orderId, newStatus);
      setOrder(updated);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setUpdating(false);
    }
  }

  async function handlePrint() {
    try {
      await ordersApi.print(orderId);
      Alert.alert('Success', 'Order sent to printer');
      loadOrder();
    } catch (err) {
      Alert.alert('Print Error', err.message);
    }
  }

  async function handleDelete() {
    Alert.alert('Delete Order', `Are you sure you want to delete order #${order.order_number}?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            await ordersApi.delete(orderId);
            navigation.goBack();
          } catch (err) {
            Alert.alert('Error', err.message);
          }
        },
      },
    ]);
  }

  async function handleSendToReview() {
    setUpdating(true);
    try {
      const updated = await ordersApi.updateStatus(orderId, 'in_review');
      setOrder(updated);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setUpdating(false);
    }
  }

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#e94560" />
      </View>
    );
  }

  if (!order) return null;

  const typeLabels = { dine_in: 'Dine In', takeout: 'Takeout', delivery: 'Delivery' };
  const currentStatusIndex = statusFlow.indexOf(order.status);
  const nextStatus = currentStatusIndex >= 0 && currentStatusIndex < statusFlow.length - 1
    ? statusFlow[currentStatusIndex + 1]
    : null;

  return (
    <ScrollView style={styles.container}>
      {/* Order Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.orderNumber}>Order #{order.order_number}</Text>
          <Text style={styles.orderType}>{typeLabels[order.order_type] || order.order_type}</Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: statusColors[order.status] }]}>
          <Text style={styles.statusText}>{order.status.replace('_', ' ').toUpperCase()}</Text>
        </View>
      </View>

      {/* Customer Info */}
      <View style={styles.infoCard}>
        {order.customer_name && (
          <View style={styles.infoRow}>
            <Ionicons name="person-outline" size={18} color="#aaa" />
            <Text style={styles.infoText}>{order.customer_name}</Text>
          </View>
        )}
        {order.table_number && (
          <View style={styles.infoRow}>
            <Ionicons name="grid-outline" size={18} color="#aaa" />
            <Text style={styles.infoText}>Table {order.table_number}</Text>
          </View>
        )}
        <View style={styles.infoRow}>
          <Ionicons name="time-outline" size={18} color="#aaa" />
          <Text style={styles.infoText}>{new Date(order.created_at).toLocaleString()}</Text>
        </View>
        <View style={styles.infoRow}>
          <Ionicons name="person-circle-outline" size={18} color="#aaa" />
          <Text style={styles.infoText}>Server: {order.created_by_name || 'Unknown'}</Text>
        </View>
        {order.printed ? (
          <View style={styles.infoRow}>
            <Ionicons name="print-outline" size={18} color="#4ecca3" />
            <Text style={[styles.infoText, { color: '#4ecca3' }]}>Printed</Text>
          </View>
        ) : null}
      </View>

      {/* Items */}
      <Text style={styles.sectionTitle}>Items</Text>
      <View style={styles.itemsCard}>
        {order.items?.map((item, index) => (
          <View key={item.id || index} style={[styles.itemRow, index > 0 && styles.itemDivider]}>
            <View style={styles.itemInfo}>
              <Text style={styles.itemName}>
                {item.quantity > 1 ? `${item.quantity}x ` : ''}{item.name}
              </Text>
              {item.notes && <Text style={styles.itemNotes}>{item.notes}</Text>}
            </View>
            <Text style={styles.itemPrice}>${((item.price * item.quantity) / 100).toFixed(2)}</Text>
          </View>
        ))}
      </View>

      {/* Totals */}
      <View style={styles.totalsCard}>
        <View style={styles.totalRow}>
          <Text style={styles.totalLabel}>Subtotal</Text>
          <Text style={styles.totalValue}>${(order.subtotal / 100).toFixed(2)}</Text>
        </View>
        <View style={styles.totalRow}>
          <Text style={styles.totalLabel}>Tax</Text>
          <Text style={styles.totalValue}>${(order.tax / 100).toFixed(2)}</Text>
        </View>
        <View style={[styles.totalRow, styles.grandTotal]}>
          <Text style={styles.grandTotalLabel}>Total</Text>
          <Text style={styles.grandTotalValue}>${(order.total / 100).toFixed(2)}</Text>
        </View>
      </View>

      {/* Notes */}
      {order.notes && (
        <View style={styles.notesCard}>
          <Text style={styles.notesTitle}>Notes</Text>
          <Text style={styles.notesText}>{order.notes}</Text>
        </View>
      )}

      {/* Review info */}
      {order.status === 'in_review' && order.review_notes && (
        <View style={[styles.notesCard, { borderLeftColor: '#bb86fc' }]}>
          <Text style={[styles.notesTitle, { color: '#bb86fc' }]}>Review Notes</Text>
          <Text style={styles.notesText}>{order.review_notes}</Text>
        </View>
      )}

      {/* Actions */}
      <View style={styles.actions}>
        {/* Print */}
        <TouchableOpacity style={styles.actionBtn} onPress={handlePrint}>
          <Ionicons name="print-outline" size={20} color="#fff" />
          <Text style={styles.actionBtnText}>Print</Text>
        </TouchableOpacity>

        {/* Send to Review (staff) */}
        {!isAdmin && order.status !== 'completed' && order.status !== 'cancelled' && order.status !== 'in_review' && (
          <TouchableOpacity
            style={[styles.actionBtn, { backgroundColor: '#bb86fc' }]}
            onPress={handleSendToReview}
            disabled={updating}
          >
            <Ionicons name="eye-outline" size={20} color="#fff" />
            <Text style={styles.actionBtnText}>Send to Review</Text>
          </TouchableOpacity>
        )}

        {/* Next Status */}
        {nextStatus && order.status !== 'cancelled' && (
          <TouchableOpacity
            style={[styles.actionBtn, { backgroundColor: statusColors[nextStatus] }]}
            onPress={() => handleStatusChange(nextStatus)}
            disabled={updating}
          >
            {updating ? (
              <ActivityIndicator color="#fff" size="small" />
            ) : (
              <>
                <Ionicons name="arrow-forward" size={20} color="#fff" />
                <Text style={styles.actionBtnText}>
                  Mark {nextStatus.replace('_', ' ')}
                </Text>
              </>
            )}
          </TouchableOpacity>
        )}

        {/* Admin actions */}
        {isAdmin && order.status !== 'cancelled' && (
          <TouchableOpacity
            style={[styles.actionBtn, { backgroundColor: '#e94560' }]}
            onPress={() => handleStatusChange('cancelled')}
            disabled={updating}
          >
            <Ionicons name="close-circle-outline" size={20} color="#fff" />
            <Text style={styles.actionBtnText}>Cancel</Text>
          </TouchableOpacity>
        )}

        {isAdmin && (
          <TouchableOpacity
            style={[styles.actionBtn, styles.deleteBtn]}
            onPress={handleDelete}
          >
            <Ionicons name="trash-outline" size={20} color="#e94560" />
            <Text style={[styles.actionBtnText, { color: '#e94560' }]}>Delete</Text>
          </TouchableOpacity>
        )}
      </View>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e', padding: 16 },
  loadingContainer: { flex: 1, backgroundColor: '#1a1a2e', justifyContent: 'center', alignItems: 'center' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  orderNumber: { fontSize: 28, fontWeight: 'bold', color: '#fff' },
  orderType: { fontSize: 14, color: '#aaa', marginTop: 4 },
  statusBadge: { paddingHorizontal: 14, paddingVertical: 6, borderRadius: 16 },
  statusText: { color: '#fff', fontSize: 13, fontWeight: 'bold' },
  infoCard: {
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    borderWidth: 1,
    borderColor: '#0f3460',
    marginBottom: 16,
  },
  infoRow: { flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 8 },
  infoText: { color: '#ccc', fontSize: 14 },
  sectionTitle: { fontSize: 16, fontWeight: 'bold', color: '#fff', marginBottom: 10 },
  itemsCard: {
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    borderWidth: 1,
    borderColor: '#0f3460',
    marginBottom: 16,
  },
  itemRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', paddingVertical: 8 },
  itemDivider: { borderTopWidth: 1, borderTopColor: '#0f3460' },
  itemInfo: { flex: 1, marginRight: 12 },
  itemName: { fontSize: 15, color: '#fff', fontWeight: '500' },
  itemNotes: { fontSize: 13, color: '#f0a500', marginTop: 2 },
  itemPrice: { fontSize: 15, color: '#4ecca3', fontWeight: '600' },
  totalsCard: {
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    borderWidth: 1,
    borderColor: '#0f3460',
    marginBottom: 16,
  },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 },
  totalLabel: { color: '#aaa', fontSize: 15 },
  totalValue: { color: '#fff', fontSize: 15 },
  grandTotal: { borderTopWidth: 1, borderTopColor: '#0f3460', paddingTop: 8, marginTop: 4 },
  grandTotalLabel: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  grandTotalValue: { color: '#4ecca3', fontSize: 18, fontWeight: 'bold' },
  notesCard: {
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    borderWidth: 1,
    borderColor: '#0f3460',
    borderLeftWidth: 4,
    borderLeftColor: '#f0a500',
    marginBottom: 16,
  },
  notesTitle: { color: '#f0a500', fontSize: 13, fontWeight: 'bold', marginBottom: 4 },
  notesText: { color: '#ccc', fontSize: 14 },
  actions: { gap: 10, marginTop: 8 },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#0f3460',
    borderRadius: 8,
    padding: 14,
    gap: 8,
  },
  actionBtnText: { color: '#fff', fontSize: 16, fontWeight: '600' },
  deleteBtn: { backgroundColor: 'transparent', borderWidth: 1, borderColor: '#e94560' },
});
