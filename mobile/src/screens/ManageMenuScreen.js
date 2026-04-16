import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, TextInput, Alert, Modal, ScrollView } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { menu as menuApi } from '../services/api';

export default function ManageMenuScreen() {
  const [categories, setCategories] = useState([]);
  const [items, setItems] = useState([]);
  const [tab, setTab] = useState('items'); // 'items' or 'categories'
  const [showItemModal, setShowItemModal] = useState(false);
  const [showCatModal, setShowCatModal] = useState(false);
  const [itemForm, setItemForm] = useState({ name: '', description: '', price: '', categoryId: '' });
  const [catForm, setCatForm] = useState({ name: '' });

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [])
  );

  async function loadData() {
    try {
      const [cats, menuItems] = await Promise.all([
        menuApi.listCategories(),
        menuApi.listItems(),
      ]);
      setCategories(cats);
      setItems(menuItems);
    } catch (err) {
      Alert.alert('Error', 'Failed to load menu data');
    }
  }

  async function handleCreateItem() {
    if (!itemForm.name || !itemForm.price) {
      Alert.alert('Error', 'Name and price are required');
      return;
    }

    try {
      await menuApi.createItem({
        name: itemForm.name,
        description: itemForm.description,
        price: Math.round(parseFloat(itemForm.price) * 100),
        categoryId: itemForm.categoryId || undefined,
      });
      setShowItemModal(false);
      setItemForm({ name: '', description: '', price: '', categoryId: '' });
      loadData();
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  }

  async function handleCreateCategory() {
    if (!catForm.name) {
      Alert.alert('Error', 'Name is required');
      return;
    }

    try {
      await menuApi.createCategory({ name: catForm.name });
      setShowCatModal(false);
      setCatForm({ name: '' });
      loadData();
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  }

  async function handleDeleteItem(item) {
    Alert.alert('Delete Item', `Remove "${item.name}" from the menu?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            await menuApi.deleteItem(item.id);
            loadData();
          } catch (err) {
            Alert.alert('Error', err.message);
          }
        },
      },
    ]);
  }

  async function handleDeleteCategory(cat) {
    Alert.alert('Delete Category', `Remove "${cat.name}"? Items will be uncategorized.`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            await menuApi.deleteCategory(cat.id);
            loadData();
          } catch (err) {
            Alert.alert('Error', err.message);
          }
        },
      },
    ]);
  }

  function renderItem({ item }) {
    return (
      <View style={styles.itemCard}>
        <View style={styles.itemInfo}>
          <Text style={styles.itemName}>{item.name}</Text>
          {item.description && <Text style={styles.itemDesc}>{item.description}</Text>}
          <Text style={styles.itemCategory}>{item.category_name || 'Uncategorized'}</Text>
        </View>
        <Text style={styles.itemPrice}>${(item.price / 100).toFixed(2)}</Text>
        <TouchableOpacity onPress={() => handleDeleteItem(item)} style={styles.deleteBtn}>
          <Ionicons name="trash-outline" size={20} color="#e94560" />
        </TouchableOpacity>
      </View>
    );
  }

  function renderCategory({ item }) {
    return (
      <View style={styles.catCard}>
        <Text style={styles.catName}>{item.name}</Text>
        <TouchableOpacity onPress={() => handleDeleteCategory(item)}>
          <Ionicons name="trash-outline" size={20} color="#e94560" />
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Tabs */}
      <View style={styles.tabs}>
        <TouchableOpacity
          style={[styles.tab, tab === 'items' && styles.tabActive]}
          onPress={() => setTab('items')}
        >
          <Text style={[styles.tabText, tab === 'items' && styles.tabTextActive]}>
            Items ({items.length})
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, tab === 'categories' && styles.tabActive]}
          onPress={() => setTab('categories')}
        >
          <Text style={[styles.tabText, tab === 'categories' && styles.tabTextActive]}>
            Categories ({categories.length})
          </Text>
        </TouchableOpacity>
      </View>

      {tab === 'items' ? (
        <FlatList
          data={items}
          renderItem={renderItem}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          ListEmptyComponent={<Text style={styles.emptyText}>No menu items</Text>}
        />
      ) : (
        <FlatList
          data={categories}
          renderItem={renderCategory}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          ListEmptyComponent={<Text style={styles.emptyText}>No categories</Text>}
        />
      )}

      {/* FAB */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => tab === 'items' ? setShowItemModal(true) : setShowCatModal(true)}
      >
        <Ionicons name="add" size={28} color="#fff" />
      </TouchableOpacity>

      {/* Add Item Modal */}
      <Modal visible={showItemModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <ScrollView contentContainerStyle={styles.modalScroll}>
            <View style={styles.modalContent}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>Add Menu Item</Text>
                <TouchableOpacity onPress={() => setShowItemModal(false)}>
                  <Ionicons name="close" size={24} color="#fff" />
                </TouchableOpacity>
              </View>

              <Text style={styles.label}>Name</Text>
              <TextInput
                style={styles.input}
                value={itemForm.name}
                onChangeText={(val) => setItemForm({ ...itemForm, name: val })}
                placeholder="Item name"
                placeholderTextColor="#666"
              />

              <Text style={styles.label}>Description</Text>
              <TextInput
                style={styles.input}
                value={itemForm.description}
                onChangeText={(val) => setItemForm({ ...itemForm, description: val })}
                placeholder="Short description"
                placeholderTextColor="#666"
              />

              <Text style={styles.label}>Price ($)</Text>
              <TextInput
                style={styles.input}
                value={itemForm.price}
                onChangeText={(val) => setItemForm({ ...itemForm, price: val })}
                placeholder="12.99"
                placeholderTextColor="#666"
                keyboardType="decimal-pad"
              />

              <Text style={styles.label}>Category</Text>
              <View style={styles.catPicker}>
                <TouchableOpacity
                  style={[styles.catOption, !itemForm.categoryId && styles.catOptionActive]}
                  onPress={() => setItemForm({ ...itemForm, categoryId: '' })}
                >
                  <Text style={styles.catOptionText}>None</Text>
                </TouchableOpacity>
                {categories.map((cat) => (
                  <TouchableOpacity
                    key={cat.id}
                    style={[styles.catOption, itemForm.categoryId === cat.id && styles.catOptionActive]}
                    onPress={() => setItemForm({ ...itemForm, categoryId: cat.id })}
                  >
                    <Text style={styles.catOptionText}>{cat.name}</Text>
                  </TouchableOpacity>
                ))}
              </View>

              <TouchableOpacity style={styles.submitBtn} onPress={handleCreateItem}>
                <Text style={styles.submitBtnText}>Add Item</Text>
              </TouchableOpacity>
            </View>
          </ScrollView>
        </View>
      </Modal>

      {/* Add Category Modal */}
      <Modal visible={showCatModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Add Category</Text>
              <TouchableOpacity onPress={() => setShowCatModal(false)}>
                <Ionicons name="close" size={24} color="#fff" />
              </TouchableOpacity>
            </View>

            <Text style={styles.label}>Name</Text>
            <TextInput
              style={styles.input}
              value={catForm.name}
              onChangeText={(val) => setCatForm({ ...catForm, name: val })}
              placeholder="Category name"
              placeholderTextColor="#666"
            />

            <TouchableOpacity style={styles.submitBtn} onPress={handleCreateCategory}>
              <Text style={styles.submitBtnText}>Add Category</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  tabs: { flexDirection: 'row', borderBottomWidth: 1, borderBottomColor: '#0f3460' },
  tab: { flex: 1, padding: 14, alignItems: 'center' },
  tabActive: { borderBottomWidth: 2, borderBottomColor: '#e94560' },
  tabText: { color: '#888', fontSize: 15, fontWeight: '600' },
  tabTextActive: { color: '#fff' },
  listContent: { padding: 16, paddingBottom: 80 },
  itemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  itemInfo: { flex: 1 },
  itemName: { fontSize: 15, fontWeight: '600', color: '#fff' },
  itemDesc: { fontSize: 13, color: '#888', marginTop: 2 },
  itemCategory: { fontSize: 12, color: '#e94560', marginTop: 4 },
  itemPrice: { color: '#4ecca3', fontSize: 16, fontWeight: 'bold', marginRight: 12 },
  deleteBtn: { padding: 4 },
  catCard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 16,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  catName: { fontSize: 16, fontWeight: '600', color: '#fff' },
  emptyText: { color: '#888', textAlign: 'center', marginTop: 40 },
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
  modalScroll: { flexGrow: 1, justifyContent: 'flex-end' },
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
  catPicker: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 4 },
  catOption: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: '#1a1a2e',
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  catOptionActive: { backgroundColor: '#e94560', borderColor: '#e94560' },
  catOptionText: { color: '#fff', fontSize: 13 },
  submitBtn: {
    backgroundColor: '#4ecca3',
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
    marginTop: 20,
  },
  submitBtnText: { color: '#1a1a2e', fontSize: 16, fontWeight: 'bold' },
});
