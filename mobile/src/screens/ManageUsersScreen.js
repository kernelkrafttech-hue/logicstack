import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, TextInput, Alert, Modal } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { auth } from '../services/api';

export default function ManageUsersScreen() {
  const [users, setUsers] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ name: '', email: '', password: '', role: 'staff', pin: '' });

  useFocusEffect(
    useCallback(() => {
      loadUsers();
    }, [])
  );

  async function loadUsers() {
    try {
      const data = await auth.listUsers();
      setUsers(data);
    } catch (err) {
      Alert.alert('Error', 'Failed to load users');
    }
  }

  async function handleCreate() {
    if (!formData.name || !formData.email || !formData.password) {
      Alert.alert('Error', 'Name, email, and password are required');
      return;
    }

    try {
      await auth.createUser(formData);
      setShowModal(false);
      setFormData({ name: '', email: '', password: '', role: 'staff', pin: '' });
      loadUsers();
      Alert.alert('Success', 'Staff member added');
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  }

  async function handleToggleActive(user) {
    try {
      await auth.updateUser(user.id, { is_active: user.is_active ? 0 : 1 });
      loadUsers();
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  }

  async function handleDelete(user) {
    Alert.alert('Remove Staff', `Remove ${user.name} from your team?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: async () => {
          try {
            await auth.deleteUser(user.id);
            loadUsers();
          } catch (err) {
            Alert.alert('Error', err.message);
          }
        },
      },
    ]);
  }

  function renderUser({ item: user }) {
    return (
      <View style={styles.userCard}>
        <View style={styles.userInfo}>
          <View style={styles.userHeader}>
            <Text style={styles.userName}>{user.name}</Text>
            <View style={[styles.roleBadge, user.role === 'admin' ? styles.adminBadge : styles.staffBadge]}>
              <Text style={styles.roleText}>{user.role.toUpperCase()}</Text>
            </View>
          </View>
          <Text style={styles.userEmail}>{user.email}</Text>
          {user.pin && <Text style={styles.userPin}>PIN: {user.pin}</Text>}
          {!user.is_active && <Text style={styles.inactiveText}>Inactive</Text>}
        </View>
        <View style={styles.userActions}>
          <TouchableOpacity onPress={() => handleToggleActive(user)} style={styles.iconBtn}>
            <Ionicons
              name={user.is_active ? 'pause-circle-outline' : 'play-circle-outline'}
              size={24}
              color={user.is_active ? '#f0a500' : '#4ecca3'}
            />
          </TouchableOpacity>
          <TouchableOpacity onPress={() => handleDelete(user)} style={styles.iconBtn}>
            <Ionicons name="trash-outline" size={22} color="#e94560" />
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={users}
        renderItem={renderUser}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={<Text style={styles.emptyText}>No staff members yet</Text>}
      />

      {/* Add button */}
      <TouchableOpacity style={styles.addBtn} onPress={() => setShowModal(true)}>
        <Ionicons name="add" size={28} color="#fff" />
      </TouchableOpacity>

      {/* Add User Modal */}
      <Modal visible={showModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Add Staff Member</Text>
              <TouchableOpacity onPress={() => setShowModal(false)}>
                <Ionicons name="close" size={24} color="#fff" />
              </TouchableOpacity>
            </View>

            <Text style={styles.label}>Name</Text>
            <TextInput
              style={styles.input}
              value={formData.name}
              onChangeText={(val) => setFormData({ ...formData, name: val })}
              placeholder="Staff name"
              placeholderTextColor="#666"
            />

            <Text style={styles.label}>Email</Text>
            <TextInput
              style={styles.input}
              value={formData.email}
              onChangeText={(val) => setFormData({ ...formData, email: val })}
              placeholder="staff@restaurant.com"
              placeholderTextColor="#666"
              keyboardType="email-address"
              autoCapitalize="none"
            />

            <Text style={styles.label}>Password</Text>
            <TextInput
              style={styles.input}
              value={formData.password}
              onChangeText={(val) => setFormData({ ...formData, password: val })}
              placeholder="Min 6 characters"
              placeholderTextColor="#666"
              secureTextEntry
            />

            <Text style={styles.label}>Quick Login PIN (4 digits)</Text>
            <TextInput
              style={styles.input}
              value={formData.pin}
              onChangeText={(val) => setFormData({ ...formData, pin: val })}
              placeholder="e.g. 1234"
              placeholderTextColor="#666"
              keyboardType="numeric"
              maxLength={4}
            />

            <Text style={styles.label}>Role</Text>
            <View style={styles.roleSelector}>
              <TouchableOpacity
                style={[styles.roleBtn, formData.role === 'staff' && styles.roleBtnActive]}
                onPress={() => setFormData({ ...formData, role: 'staff' })}
              >
                <Text style={[styles.roleBtnText, formData.role === 'staff' && styles.roleBtnTextActive]}>Staff</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.roleBtn, formData.role === 'admin' && styles.roleBtnActive]}
                onPress={() => setFormData({ ...formData, role: 'admin' })}
              >
                <Text style={[styles.roleBtnText, formData.role === 'admin' && styles.roleBtnTextActive]}>Admin</Text>
              </TouchableOpacity>
            </View>

            <TouchableOpacity style={styles.submitBtn} onPress={handleCreate}>
              <Text style={styles.submitBtnText}>Add Staff Member</Text>
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
  userCard: {
    flexDirection: 'row',
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  userInfo: { flex: 1 },
  userHeader: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  userName: { fontSize: 16, fontWeight: '600', color: '#fff' },
  roleBadge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 8 },
  adminBadge: { backgroundColor: '#e94560' },
  staffBadge: { backgroundColor: '#3282b8' },
  roleText: { color: '#fff', fontSize: 10, fontWeight: 'bold' },
  userEmail: { color: '#888', fontSize: 13, marginTop: 4 },
  userPin: { color: '#f0a500', fontSize: 12, marginTop: 2 },
  inactiveText: { color: '#e94560', fontSize: 12, marginTop: 2 },
  userActions: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  iconBtn: { padding: 4 },
  emptyText: { color: '#888', textAlign: 'center', marginTop: 40 },
  addBtn: {
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
    shadowColor: '#e94560',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.4,
    shadowRadius: 4,
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
  roleSelector: { flexDirection: 'row', gap: 10, marginTop: 4 },
  roleBtn: {
    flex: 1,
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
    backgroundColor: '#1a1a2e',
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  roleBtnActive: { backgroundColor: '#e94560', borderColor: '#e94560' },
  roleBtnText: { color: '#aaa', fontWeight: '600' },
  roleBtnTextActive: { color: '#fff' },
  submitBtn: {
    backgroundColor: '#4ecca3',
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
    marginTop: 20,
  },
  submitBtnText: { color: '#1a1a2e', fontSize: 16, fontWeight: 'bold' },
});
