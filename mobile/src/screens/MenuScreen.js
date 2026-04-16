import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, TextInput, Alert } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { menu as menuApi } from '../services/api';
import { useOrder } from '../context/OrderContext';

export default function MenuScreen({ navigation }) {
  const [categories, setCategories] = useState([]);
  const [items, setItems] = useState([]);
  const [filteredItems, setFilteredItems] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [search, setSearch] = useState('');
  const { addItem, itemCount, total } = useOrder();

  useFocusEffect(
    useCallback(() => {
      loadMenu();
    }, [])
  );

  async function loadMenu() {
    try {
      const [cats, menuItems] = await Promise.all([
        menuApi.listCategories(),
        menuApi.listItems(),
      ]);
      setCategories(cats);
      setItems(menuItems);
      setFilteredItems(menuItems);
    } catch (err) {
      Alert.alert('Error', 'Failed to load menu');
    }
  }

  useEffect(() => {
    let filtered = items;
    if (selectedCategory) {
      filtered = filtered.filter((item) => item.category_id === selectedCategory);
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      filtered = filtered.filter((item) => item.name.toLowerCase().includes(q));
    }
    setFilteredItems(filtered);
  }, [selectedCategory, search, items]);

  function handleAddItem(item) {
    addItem(item);
  }

  function renderCategoryTab({ item }) {
    const isSelected = selectedCategory === item.id;
    return (
      <TouchableOpacity
        style={[styles.categoryTab, isSelected && styles.categoryTabActive]}
        onPress={() => setSelectedCategory(isSelected ? null : item.id)}
      >
        <Text style={[styles.categoryText, isSelected && styles.categoryTextActive]}>{item.name}</Text>
      </TouchableOpacity>
    );
  }

  function renderMenuItem({ item }) {
    return (
      <TouchableOpacity style={styles.menuItem} onPress={() => handleAddItem(item)}>
        <View style={styles.menuItemInfo}>
          <Text style={styles.menuItemName}>{item.name}</Text>
          {item.description && <Text style={styles.menuItemDesc}>{item.description}</Text>}
          <Text style={styles.menuItemCategory}>{item.category_name}</Text>
        </View>
        <View style={styles.menuItemRight}>
          <Text style={styles.menuItemPrice}>${(item.price / 100).toFixed(2)}</Text>
          <Ionicons name="add-circle" size={28} color="#4ecca3" />
        </View>
      </TouchableOpacity>
    );
  }

  return (
    <View style={styles.container}>
      {/* Search */}
      <View style={styles.searchBar}>
        <Ionicons name="search" size={20} color="#888" />
        <TextInput
          style={styles.searchInput}
          value={search}
          onChangeText={setSearch}
          placeholder="Search menu..."
          placeholderTextColor="#666"
        />
        {search.length > 0 && (
          <TouchableOpacity onPress={() => setSearch('')}>
            <Ionicons name="close-circle" size={20} color="#888" />
          </TouchableOpacity>
        )}
      </View>

      {/* Category tabs */}
      <FlatList
        horizontal
        data={categories}
        renderItem={renderCategoryTab}
        keyExtractor={(item) => item.id}
        style={styles.categoryList}
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.categoryContent}
      />

      {/* Menu items */}
      <FlatList
        data={filteredItems}
        renderItem={renderMenuItem}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.menuList}
        ListEmptyComponent={<Text style={styles.emptyText}>No menu items found</Text>}
      />

      {/* Cart bar */}
      {itemCount > 0 && (
        <TouchableOpacity style={styles.cartBar} onPress={() => navigation.navigate('Cart')}>
          <View style={styles.cartBadge}>
            <Text style={styles.cartBadgeText}>{itemCount}</Text>
          </View>
          <Text style={styles.cartText}>View Order</Text>
          <Text style={styles.cartTotal}>${(total / 100).toFixed(2)}</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e' },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#16213e',
    margin: 12,
    borderRadius: 8,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  searchInput: { flex: 1, color: '#fff', padding: 12, fontSize: 16 },
  categoryList: { maxHeight: 50 },
  categoryContent: { paddingHorizontal: 12, gap: 8 },
  categoryTab: {
    backgroundColor: '#16213e',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  categoryTabActive: { backgroundColor: '#e94560', borderColor: '#e94560' },
  categoryText: { color: '#ccc', fontSize: 14 },
  categoryTextActive: { color: '#fff', fontWeight: 'bold' },
  menuList: { padding: 12, paddingBottom: 100 },
  menuItem: {
    flexDirection: 'row',
    backgroundColor: '#16213e',
    borderRadius: 10,
    padding: 14,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#0f3460',
    alignItems: 'center',
  },
  menuItemInfo: { flex: 1 },
  menuItemName: { fontSize: 16, fontWeight: '600', color: '#fff' },
  menuItemDesc: { fontSize: 13, color: '#888', marginTop: 2 },
  menuItemCategory: { fontSize: 12, color: '#e94560', marginTop: 4 },
  menuItemRight: { alignItems: 'center', marginLeft: 12 },
  menuItemPrice: { fontSize: 16, fontWeight: 'bold', color: '#4ecca3', marginBottom: 4 },
  emptyText: { color: '#888', fontSize: 14, textAlign: 'center', marginTop: 40 },
  cartBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#e94560',
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    paddingBottom: 30,
  },
  cartBadge: {
    backgroundColor: '#fff',
    borderRadius: 12,
    width: 24,
    height: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cartBadgeText: { color: '#e94560', fontWeight: 'bold', fontSize: 14 },
  cartText: { flex: 1, color: '#fff', fontSize: 16, fontWeight: 'bold', marginLeft: 12 },
  cartTotal: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
});
