import 'package:cloud_functions/cloud_functions.dart';

import '../domain/plan.dart';

/// Wraps the Stripe-backed callable Cloud Functions:
///   - createStripeCheckoutSession({planId}) → { url }
///   - createStripeCustomerPortalSession() → { url }
///
/// The Stripe secret key lives entirely in Functions config; the client
/// only ever sees the redirect URL it should open in a browser.
class BillingService {
  BillingService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<String> startCheckout(Plan plan) async {
    if (!plan.selectable) {
      throw BillingException('That plan is not available for purchase.');
    }
    try {
      final HttpsCallableResult<Object?> result = await _functions
          .httpsCallable('createStripeCheckoutSession')
          .call<Object?>(<String, Object?>{'planId': plan.storageValue});
      final String? url = _readUrl(result.data);
      if (url == null || url.isEmpty) {
        throw BillingException('Stripe did not return a checkout URL.');
      }
      return url;
    } on FirebaseFunctionsException catch (e) {
      throw BillingException(_messageForCode(e));
    }
  }

  Future<String> startCustomerPortal() async {
    try {
      final HttpsCallableResult<Object?> result = await _functions
          .httpsCallable('createStripeCustomerPortalSession')
          .call<Object?>(<String, Object?>{});
      final String? url = _readUrl(result.data);
      if (url == null || url.isEmpty) {
        throw BillingException('Stripe did not return a portal URL.');
      }
      return url;
    } on FirebaseFunctionsException catch (e) {
      throw BillingException(_messageForCode(e));
    }
  }

  String? _readUrl(Object? raw) {
    if (raw is Map) {
      final Object? value = raw['url'];
      return value is String ? value : null;
    }
    return null;
  }

  String _messageForCode(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in again and try.';
      case 'failed-precondition':
        return e.message ?? 'You need an active subscription first.';
      case 'invalid-argument':
        return e.message ?? 'That request was rejected.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Stripe is taking too long. Please try again.';
      default:
        return e.message ?? 'Could not reach Stripe. Please try again.';
    }
  }
}

class BillingException implements Exception {
  BillingException(this.message);
  final String message;

  @override
  String toString() => message;
}
