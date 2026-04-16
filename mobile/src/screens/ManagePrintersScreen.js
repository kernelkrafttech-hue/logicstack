import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, TextInput, Alert, Modal } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { printers as printersApi } from '../services/api';

const PRINTER_TYPES = [
  { key: 'network', label: 'Network (WiFi/LAN)', icon: 'wifi-outline' },
  { key: 'clover', label: 'Clover Printer', icon: 'print-outline' },
  { key: 'bluetooth', label: 'Bluetooth', icon: 'bluetooth-outline' },
  { key: 'usb', label: 'USB', icon: 'cable-outline' },
];

export default function ManagePrintersScreen() {
  const [printerList, setPrinterList] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ name: '', type: 'network', address: '', port: '9100', isDefault: true });

  useFocusEffect(
    useCallback(() => {
      loadPrinters();
    }, [])
  );

  async function loadPrinters() {
    try {
      const data = await printersApi.list();
      setPrinterList(data);
    } catch (err) {
      Alert.alert('Error', 'Failed to load printers');
    }
  }

  async function handleCreate() {
    if (!formData.name) {
      Alert.alert('Error', 'Name is required');
      return;
    }

    try {
      await printersApi.create({
        name: formData.name,
        type: formData.type,
        address: formData.address || undefined,
        port: parseInt(formData.port) || 9100,
        isDefault: formData.isDefault,
      });
      setShowModal(false);
      setFormData({ name: '', type: 'network', address: '', port: '9100', isDefault: true });
      loadPrinters();
      Alert.alert('Success', 'Printer added');
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  }

  async function handleTest(printer) {
    try {
      await printersApi.test(printer.id);
      Alert.alert('Success', 'Test page sent to printer');
    } catch (err) {
      Alert.alert('Test Failed', err.message);
    }
  }

  async function handleDelete(printer) {
    Alert.alert('Remove Printer', `Remove "${printer.name}"?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: async () => {
          try {
            await printersApi.delete(printer.id);
            loadPrinters();
          } catch (err) {
            Alert.alert('Error', err.message);
          }
        },
      },
    ]);
  }

  function renderPrinter({ item: printer }) {
    const typeInfo = PRINTER_TYPES.find((t) => t.key === printer.type) || PRINTER_TYPES[0];

    return (
      <View style={styles.printerCard}>
        <View style={styles.printerIcon}>
          <Ionicons name={typeInfo.icon} size={24} color="#4ecca3" />
        </View>
        <View style={styles.printerInfo}>
          <View style={styles.printerHeader}>
            <Text style={styles.printerName}>{printer.name}</Text>
            {printer.is_default ? (
              <View style={styles.defaultBadge}>
                <Text style={styles.defaultText}>DEFAULT</Text>
              </View>
            ) : null}
          </View>
          <Text style={styles.printerType}>{typeInfo.label}</Text>
          {printer.address && <Text style={styles.printerAddress}>{printer.address}:{printer.port}</Text>}
        </View>
        <View style={styles.printerActions}>
          <TouchableOpacity onPress={() => handleTest(printer)} style={styles.iconBtn}>
            <Ionicons name="flash-outline" size={22} color="#f0a500" />
          </TouchableOpacity>
          <TouchableOpacity onPress={() => handleDelete(printer)} style={styles.iconBtn}>
            <Ionicons name="trash-outline" size={22} color="#e94560" />
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={printerList}
        renderItem={renderPrinter}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={
          <View style={styles.headerInfo}>
            <Ionicons name="information-circle-outline" size={18} color="#3282b8" />
            <Text style={styles.headerInfoText}>
              Add your receipt printers here. The app supports network (WiFi/LAN), Clover built-in, Bluetooth, and USB printers.
            </Text>
          </View>
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="print-outline" size={48} color="#444" />
            <Text style={styles.emptyText}>No printers configured</Text>
            <Text style={styles.emptySubtext}>Add a printer to start printing receipts</Text>
          </View>
        }
      />

      <TouchableOpacity style={styles.fab} onPress={() => setShowModal(true)}>
        <Ionicons name="add" size={28} color="#fff" />
      </TouchableOpacity>

      <Modal visible={showModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Add Printer</Text>
              <TouchableOpacity onPress={() => setShowModal(false)}>
                <Ionicons name="close" size={24} color="#fff" />
              </TouchableOpacity>
            </View>

            <Text style={styles.label}>Printer Name</Text>
            <TextInput
              style={styles.input}
              value={formData.name}
              onChangeText={(val) => setFormData({ ...formData, name: val })}
              placeholder="e.g. Kitchen Printer"
              placeholderTextColor="#666"
            />

            <Text style={styles.label}>Type</Text>
            <View style={styles.typeGrid}>
              {PRINTER_TYPES.map((type) => (
                <TouchableOpacity
                  key={type.key}
                  style={[styles.typeBtn, formData.type === type.key && styles.typeBtnActive]}
                  onPress={() => setFormData({ ...formData, type: type.key })}
                >
                  <Ionicons name={type.icon} size={20} color={formData.type === type.key ? '#fff' : '#aaa'} />
                  <Text style={[styles.typeLabel, formData.type === type.key && styles.typeLabelActive]}>
                    {type.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            {formData.type === 'network' && (
              <>
                <Text style={styles.label}>IP Address</Text>
                <TextInput
                  style={styles.input}
                  value={formData.address}
                  onChangeText={(val) => setFormData({ ...formData, address: val })}
                  placeholder="192.168.1.100"
                  placeholderTextColor="#666"
                  keyboardType="numeric"
                />

                <Text style={styles.label}>Port</Text>
                <TextInput
                  style={styles.input}
                  value={formData.port}
                  onChangeText={(val) => setFormData({ ...formData, port: val })}
                  placeholder="9100"
                  placeholderTextColor="#666"
                  keyboardType="numeric"
                />
              </>
            )}

            <TouchableOpacity
              style={styles.defaultToggle}
              onPress={() => setFormData({ ...formData, isDefault: !formData.isDefault })}
            >
              <Ionicons
                name={formData.isDefault ? 'checkbox' : 'square-outline'}
                size={22}
                color={formData.isDefault ? '#4ecca3' : '#888'}
              />
              <Text style={styles.defaultToggleText}>Set as default printer</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.submitBtn} onPress={handleCreate}>
              <Text style={styles.submitBtnText}>Add Printer</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  listContent: { padding: 16, paddingBottom: 80 },
  headerInfo: {
    flexDirection: 'row',
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 12,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#0f3460',
    gap: 8,
  },
  headerInfoText: { flex: 1, color: '#aaa', fontSize: 13, lineHeight: 18 },
  printerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  printerIcon: {
    width: 44,
    height: 44,
    borderRadius: 10,
    backgroundColor: '#4ecca320',
    alignItems: 'center',
    justifyContent: 'center',
  },
  printerInfo: { flex: 1, marginLeft: 12 },
  printerHeader: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  printerName: { fontSize: 16, fontWeight: '600', color: '#fff' },
  defaultBadge: { backgroundColor: '#4ecca3', paddingHorizontal: 6, paddingVertical: 1, borderRadius: 4 },
  defaultText: { color: '#1a1a2e', fontSize: 9, fontWeight: 'bold' },
  printerType: { color: '#888', fontSize: 13, marginTop: 2 },
  printerAddress: { color: '#666', fontSize: 12, marginTop: 2 },
  printerActions: { flexDirection: 'row', gap: 8 },
  iconBtn: { padding: 4 },
  emptyContainer: { alignItems: 'center', marginTop: 60 },
  emptyText: { color: '#666', fontSize: 16, marginTop: 12 },
  emptySubtext: { color: '#555', fontSize: 13, marginTop: 4 },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    backgroundColor: '#e94560',
    width: 56,
    height: 56,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 4,
  },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.7)', justifyContent: 'flex-end' },
  modalContent: { backgroundColor: '#16213e', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: 20, paddingBottom: 40 },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  modalTitle: { fontSize: 20, fontWeight: 'bold', color: '#fff' },
  label: { color: '#ccc', fontSize: 13, marginBottom: 4, marginTop: 10 },
  input: {
    backgroundColor: '#1a1a2e',
    color: '#fff',
    borderRadius: 8,
    padding: 12,
    fontSize: 15,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  typeGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 4 },
  typeBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: '#1a1a2e',
    borderWidth: 1,
    borderColor: '#0f3460',
    gap: 6,
  },
  typeBtnActive: { backgroundColor: '#e94560', borderColor: '#e94560' },
  typeLabel: { color: '#aaa', fontSize: 12 },
  typeLabelActive: { color: '#fff' },
  defaultToggle: { flexDirection: 'row', alignItems: 'center', marginTop: 16, gap: 8 },
  defaultToggleText: { color: '#ccc', fontSize: 14 },
  submitBtn: {
    backgroundColor: '#4ecca3',
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
    marginTop: 20,
  },
  submitBtnText: { color: '#1a1a2e', fontSize: 16, fontWeight: 'bold' },
});
