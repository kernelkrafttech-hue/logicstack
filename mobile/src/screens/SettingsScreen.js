import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Alert, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../context/AuthContext';
import { billing } from '../services/api';

export default function SettingsScreen() {
  const { merchant, logout } = useAuth();
  const [billingStatus, setBillingStatus] = useState(null);

  useEffect(() => {
    loadBilling();
  }, []);

  async function loadBilling() {
    try {
      const data = await billing.getStatus();
      setBillingStatus(data);
    } catch (err) {
      console.warn('Billing load error:', err);
    }
  }

  async function handleSubscribe() {
    try {
      const { checkoutUrl } = await billing.createCheckout();
      if (checkoutUrl) {
        Linking.openURL(checkoutUrl);
      }
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  }

  return (
    <ScrollView style={styles.container}>
      {/* Subscription */}
      <Text style={styles.sectionTitle}>Subscription</Text>
      <View style={styles.card}>
        <View style={styles.planRow}>
          <View>
            <Text style={styles.planName}>CloverPOS Orders</Text>
            <Text style={styles.planPrice}>$10/month</Text>
          </View>
          <View style={[
            styles.statusBadge,
            {
              backgroundColor:
                billingStatus?.status === 'active' ? '#4ecca3' :
                billingStatus?.status === 'trial' ? '#f0a500' : '#e94560',
            },
          ]}>
            <Text style={styles.statusText}>
              {billingStatus?.status?.toUpperCase() || 'LOADING'}
            </Text>
          </View>
        </View>

        {billingStatus?.status === 'trial' && (
          <View style={styles.trialInfo}>
            <Ionicons name="time-outline" size={18} color="#f0a500" />
            <Text style={styles.trialText}>
              {billingStatus.trialDaysLeft} days left in trial
            </Text>
          </View>
        )}

        {billingStatus?.status !== 'active' && (
          <TouchableOpacity style={styles.subscribeBtn} onPress={handleSubscribe}>
            <Ionicons name="card-outline" size={20} color="#1a1a2e" />
            <Text style={styles.subscribeBtnText}>Subscribe Now</Text>
          </TouchableOpacity>
        )}

        <View style={styles.featureList}>
          <Text style={styles.featureTitle}>What's included:</Text>
          {[
            'Unlimited orders',
            'Multiple staff accounts',
            'Receipt printing',
            'Clover POS integration',
            'Real-time order tracking',
            'Daily sales reports',
          ].map((feature) => (
            <View key={feature} style={styles.featureRow}>
              <Ionicons name="checkmark-circle" size={16} color="#4ecca3" />
              <Text style={styles.featureText}>{feature}</Text>
            </View>
          ))}
        </View>
      </View>

      {/* Clover Integration */}
      <Text style={styles.sectionTitle}>Clover Integration</Text>
      <View style={styles.card}>
        <View style={styles.integrationRow}>
          <View style={styles.integrationIcon}>
            <Ionicons name="cloud-outline" size={24} color="#4ecca3" />
          </View>
          <View style={styles.integrationInfo}>
            <Text style={styles.integrationName}>Clover POS</Text>
            <Text style={styles.integrationDesc}>
              {merchant?.clover_merchant_id ? 'Connected' : 'Not connected'}
            </Text>
          </View>
          <View style={[
            styles.connectionDot,
            { backgroundColor: merchant?.clover_merchant_id ? '#4ecca3' : '#888' },
          ]} />
        </View>
        <Text style={styles.helpText}>
          To connect your Clover account, go to the Clover App Market and install this app, or contact support for setup assistance.
        </Text>
      </View>

      {/* About */}
      <Text style={styles.sectionTitle}>About</Text>
      <View style={styles.card}>
        <View style={styles.aboutRow}>
          <Text style={styles.aboutLabel}>App Version</Text>
          <Text style={styles.aboutValue}>1.0.0</Text>
        </View>
        <View style={styles.aboutRow}>
          <Text style={styles.aboutLabel}>Merchant ID</Text>
          <Text style={styles.aboutValue}>{merchant?.id?.slice(0, 8)}...</Text>
        </View>
      </View>

      <TouchableOpacity style={styles.logoutBtn} onPress={logout}>
        <Ionicons name="log-out-outline" size={20} color="#e94560" />
        <Text style={styles.logoutText}>Sign Out</Text>
      </TouchableOpacity>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#1a1a2e', padding: 16 },
  sectionTitle: { fontSize: 16, fontWeight: 'bold', color: '#fff', marginTop: 20, marginBottom: 10 },
  card: {
    backgroundColor: '#16213e',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#0f3460',
  },
  planRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  planName: { fontSize: 18, fontWeight: 'bold', color: '#fff' },
  planPrice: { fontSize: 14, color: '#4ecca3', marginTop: 2 },
  statusBadge: { paddingHorizontal: 12, paddingVertical: 4, borderRadius: 12 },
  statusText: { color: '#fff', fontSize: 11, fontWeight: 'bold' },
  trialInfo: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 12, backgroundColor: '#f0a50020', padding: 10, borderRadius: 8 },
  trialText: { color: '#f0a500', fontSize: 14 },
  subscribeBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#4ecca3',
    borderRadius: 8,
    padding: 14,
    marginTop: 14,
    gap: 8,
  },
  subscribeBtnText: { color: '#1a1a2e', fontSize: 16, fontWeight: 'bold' },
  featureList: { marginTop: 16 },
  featureTitle: { color: '#aaa', fontSize: 13, marginBottom: 8 },
  featureRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 6 },
  featureText: { color: '#ccc', fontSize: 14 },
  integrationRow: { flexDirection: 'row', alignItems: 'center' },
  integrationIcon: {
    width: 44,
    height: 44,
    borderRadius: 10,
    backgroundColor: '#4ecca320',
    alignItems: 'center',
    justifyContent: 'center',
  },
  integrationInfo: { flex: 1, marginLeft: 12 },
  integrationName: { fontSize: 16, fontWeight: '600', color: '#fff' },
  integrationDesc: { fontSize: 13, color: '#888', marginTop: 2 },
  connectionDot: { width: 10, height: 10, borderRadius: 5 },
  helpText: { color: '#888', fontSize: 13, marginTop: 12, lineHeight: 18 },
  aboutRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#0f3460',
  },
  aboutLabel: { color: '#aaa', fontSize: 14 },
  aboutValue: { color: '#fff', fontSize: 14 },
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
