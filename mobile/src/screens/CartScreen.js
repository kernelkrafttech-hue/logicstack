import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, TextInput, Alert, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useOrder } from '../context/OrderContext';
import { orders as ordersApi } from '../services/api';

export default function CartScreen({ navigation }) {
  const {
    items, customerName, orderType, tableNumber, notes,
    subtotal, tax, total, itemCount,
    removeItem, updateQuantity, setOrderInfo, clearCart,
  } = useOrder();
  const [submitting, setSubmitting] = useState(false);

  const orderTypes = [
    { key: 'dine_in', label: 'Dine In', icon: 'restaurant' },
    { key: 'takeout', label: 'Takeout', icon: 'bag-handle' },
    { key: 'delivery', label: 'Delivery', icon: 'bicycle' },
  ];

  async function handleSubmit() {
    if (items.length === 0) {
      Alert.alert('Error', 'Add items to your order');
      return;
    }

    setSubmitting(true);
    try {
      const order = await ordersApi.create({
        customerName,
        orderType,
        tableNumber,
        notes,
        items: items.map((item) => ({
          menu_item_id: item.menu_item_id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          notes: item.notes,
        })),
      });

      clearCart();
      Alert.alert('Order Created', `Order #${order.order_number} has been placed!`, [
        { text: 'View Order', onPress: () => {
          navigation.goBack();
          navigation.navigate('Orders', { screen: 'OrderDetail', params: { orderId: order.id } });
        }},
        { text: 'OK', onPress: () => navigation.goBack() },
      ]);
    } catch (err) {
      Alert.alert('Error', err.message || 'Failed to create order');
    } finally {
      setSubmitting(false);
    }
  }

  function renderItem({ item, index }) {
    return (
      <View style={styles.cartItem}>
        <View style={styles.itemInfo}>
          <Text style={styles.itemName}>{item.name}</Text>
          <Text style={styles.itemPrice}>${(item.price / 100).toFixed(2)} each</Text>
          {item.notes ? <Text style={styles.itemNotes}>Note: {item.notes}</Text> : null}
        </View>
        <View style={styles.quantityControl}>
          <TouchableOpacity style={styles.qtyBtn} onPress={() => updateQuantity(index, item.quantity - 1)}>
            <Ionicons name="remove" size={18} color="#fff" />
          </TouchableOpacity>
          <Text style={styles.qtyText}>{item.quantity}</Text>
          <TouchableOpacity style={styles.qtyBtn} onPress={() => updateQuantity(index, item.quantity + 1)}>
            <Ionicons name="add" size={18} color="#fff" />
          </TouchableOpacity>
        </View>
        <Text style={styles.itemTotal}>${((item.price * item.quantity) / 100).toFixed(2)}</Text>
        <TouchableOpacity onPress={() => removeItem(index)} style={styles.removeBtn}>
          <Ionicons name="trash-outline" size={20} color="#e94560" />
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={items}
        renderItem={renderItem}
        keyExtractor={(_, i) => i.toString()}
        ListEmptyComponent={<Text style={styles.emptyText}>Your cart is empty</Text>}
        ListHeaderComponent={
          <View>
            {/* Order Type */}
            <Text style={styles.sectionTitle}>Order Type</Text>
            <View style={styles.orderTypes}>
              {orderTypes.map((type) => (
                <TouchableOpacity
                  key={type.key}
                  style={[styles.typeBtn, orderType === type.key && styles.typeBtnActive]}
                  onPress={() => setOrderInfo({ orderType: type.key })}
                >
                  <Ionicons name={type.icon} size={20} color={orderType === type.key ? '#fff' : '#aaa'} />
                  <Text style={[styles.typeLabel, orderType === type.key && styles.typeLabelActive]}>{type.label}</Text>
                </TouchableOpacity>
              ))}
            </View>

            {/* Customer Info */}
            <View style={styles.inputRow}>
              <View style={styles.inputGroup}>
                <Text style={styles.inputLabel}>Customer Name</Text>
                <TextInput
                  style={styles.input}
                  value={customerName}
                  onChangeText={(val) => setOrderInfo({ customerName: val })}
                  placeholder="Optional"
                  placeholderTextColor="#666"
                />
              </View>
              {orderType === 'dine_in' && (
                <View style={[styles.inputGroup, { flex: 0.5 }]}>
                  <Text style={styles.inputLabel}>Table #</Text>
                  <TextInput
                    style={styles.input}
                    value={tableNumber}
                    onChangeText={(val) => setOrderInfo({ tableNumber: val })}
                    placeholder="#"
                    placeholderTextColor="#666"
                  />
                </View>
              )}
            </View>

            <Text style={styles.inputLabel}>Notes</Text>
            <TextInput
              style={[styles.input, styles.notesInput]}
              value={notes}
              onChangeText={(val) => setOrderInfo({ notes: val })}
              placeholder="Special instructions..."
              placeholderTextColor="#666"
              multiline
            />

            <Text style={styles.sectionTitle}>Items ({itemCount})</Text>
          </View>
        }
        ListFooterComponent={
          items.length > 0 ? (
            <View style={styles.totals}>
              <View style={styles.totalRow}>
                <Text style={styles.totalLabel}>Subtotal</Text>
                <Text style={styles.totalValue}>${(subtotal / 100).toFixed(2)}</Text>
              </View>
              <View style={styles.totalRow}>
                <Text style={styles.totalLabel}>Tax (8%)</Text>
                <Text style={styles.totalValue}>${(tax / 100).toFixed(2)}</Text>
              </View>
              <View style={[styles.totalRow, styles.grandTotal]}>
                <Text style={styles.grandTotalLabel}>Total</Text>
                <Text style={styles.grandTotalValue}>${(total / 100).toFixed(2)}</Text>
              </View>
            </View>
          ) : null
        }
        contentContainerStyle={styles.listContent}
      />

      {/* Submit Button */}
      {items.length > 0 && (
        <TouchableOpacity style={styles.submitBtn} onPress={handleSubmit} disabled={submitting}>
          {submitting ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.submitText}>Place Order - ${(total / 100).toFixed(2)}</Text>
          )}
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  listContent: { padding: 16, paddingBottom: 100 },
  sectionTitle: { fontSize: 16, fontWeight: 'bold', color: '#fff', marginTop: 16, marginBottom: 10 },
  orderTypes: { flexDirection: 'row', gap: 10 },
  typeBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#16213e',
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#0f3460',
    gap: 6,
  },
  typeBtnActive: { backgroundColor: '#e94560', borderColor: '#e94560' },
  typeLabel: { color: '#aaa', fontSize: 13, fontWeight: '600' },
  typeLabelActive: { color: '#fff' },
  inputRow: { flexDirection: 'row', gap: 10, marginTop: 12 },
  inputGroup: { flex: 1 },
  inputLabel: { color: '#ccc', fontSize: 13, marginBottom: 4, marginTop: 8 },
  input: {
    backgroundColor: '#16213e',
    color: '#fff',
    borderRadius: 8,
    padding: 12,
    fontSize: 15,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  notesInput: { height: 60, textAlignVertical: 'top' },
  cartItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#16213e',
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  itemInfo: { flex: 1 },
  itemName: { fontSize: 15, fontWeight: '600', color: '#fff' },
  itemPrice: { fontSize: 13, color: '#888', marginTop: 2 },
  itemNotes: { fontSize: 12, color: '#f0a500', marginTop: 2 },
  quantityControl: { flexDirection: 'row', alignItems: 'center', marginHorizontal: 8 },
  qtyBtn: { backgroundColor: '#0f3460', borderRadius: 4, padding: 4 },
  qtyText: { color: '#fff', fontSize: 16, fontWeight: 'bold', marginHorizontal: 10 },
  itemTotal: { color: '#4ecca3', fontSize: 15, fontWeight: 'bold', width: 60, textAlign: 'right' },
  removeBtn: { marginLeft: 8 },
  emptyText: { color: '#888', fontSize: 16, textAlign: 'center', marginTop: 60 },
  totals: { marginTop: 16, borderTopWidth: 1, borderTopColor: '#0f3460', paddingTop: 12 },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 },
  totalLabel: { color: '#aaa', fontSize: 15 },
  totalValue: { color: '#fff', fontSize: 15 },
  grandTotal: { borderTopWidth: 1, borderTopColor: '#0f3460', paddingTop: 10, marginTop: 4 },
  grandTotalLabel: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  grandTotalValue: { color: '#4ecca3', fontSize: 18, fontWeight: 'bold' },
  submitBtn: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#4ecca3',
    padding: 18,
    paddingBottom: 32,
    alignItems: 'center',
  },
  submitText: { color: '#1a1a2e', fontSize: 18, fontWeight: 'bold' },
});
