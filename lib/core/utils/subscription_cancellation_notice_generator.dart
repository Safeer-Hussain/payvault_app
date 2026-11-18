import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/entities/subscription_entity.dart';

class SubscriptionCancellationNoticeGenerator {
  static String generateNotice({
    required SubscriptionEntity subscription,
    required String userName,
    required String userEmail,
    String? reason,
  }) {
    final effectiveDate = DateTime.now().toUtc();
    final effectiveDateStr =
        '${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}';
    final cancellationReason =
        reason ?? 'Consolidation of operational recurring expenditures';

    final canonicalPayload =
        '${subscription.id}|${subscription.merchantName}|${subscription.accountReference}|${subscription.amount}|$effectiveDateStr';
    final sealHash = sha256
        .convert(utf8.encode(canonicalPayload))
        .toString()
        .substring(0, 16)
        .toUpperCase();
    final dispatchStamp = 'PV-CANCEL-SEAL-$sealHash';

    return '''
================================================================================
FORMAL NOTICE OF SUBSCRIPTION CANCELLATION & RECURRING BILLING REVOCATION
Issued via PayVault Autonomous FinTech Protocol
================================================================================

DATE: $effectiveDateStr
TO: Accounts Payable & Billing Department
    ${subscription.merchantName}
    Email: ${subscription.vendorEmail}

FROM:
    Account Holder: $userName
    Authorized Email: $userEmail
    Customer Reference: ${subscription.accountReference}
    Payment Method: ${subscription.paymentMethod}

RE: REVOCATION OF PRE-AUTHORIZED RECURRING PAYMENT MANDATE

Dear Billing Representative,

Please accept this official communication as written formal notice that I am
cancelling my subscription with immediate effect.

SUBSCRIPTION DETAILS:
- Merchant: ${subscription.merchantName}
- Category: ${subscription.category}
- Billing Cycle: ${subscription.billingCycle.name.toUpperCase()}
- Current Charge: ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}
- Reason for Termination: $cancellationReason

PURSUANT TO CONSUMER BANKING AND RECURRING BILLING MANDATES:
1. Revocation of Consent: All authorizations permitting ${subscription.merchantName}
   to debit, charge, or execute recurring pre-authorized transactions against my
   registered payment instrument are hereby formally revoked.
2. Immediate Termination: No further charges may be posted to this account on or
   after $effectiveDateStr.
3. Confirmation Requirement: Please dispatch written confirmation of account closure
   and billing termination to $userEmail within 3 business days.

CRYPTOGRAPHIC DISPATCH STAMP:
$dispatchStamp
Timestamp: ${effectiveDate.toIso8601String()}

Sincerely,
$userName
PayVault Executive Account Services
================================================================================
''';
  }
}
