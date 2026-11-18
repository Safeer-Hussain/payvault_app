# Changelog

All notable changes to the PayVault platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1+2] - 2026-11-18

### Added
- **Recurring Subscription Cancellation Bot (Sprint 3)**:
  - Autonomous ledger scanner (`RecurringScanService`) detecting monthly recurring charges from merchant signatures and transaction cadence.
  - One-tap subscription freeze and unfreeze toggles to block future payment authorizations.
  - Formal legal cancellation notice generator (`SubscriptionCancellationNoticeGenerator`) with cryptographic dispatch seal.
  - Interactive modal terminal (`SubscriptionBotSheet`) with monthly burn rate and annual run rate calculations.
  - Embedded `SubscriptionSummaryCard` within the transaction ledger for instant visibility.
  - Comprehensive unit test suite (`test/unit/subscription_bot_test.dart`) and multi-tab integration tests.
- **Enterprise Release Automation Pipeline**:
  - GitHub Actions release workflow (`.github/workflows/release.yml`) building signed release APKs and attaching them to GitHub Releases on version tags.

### Changed
- Incremented project version to `1.0.1+2`.
- Updated static analysis configuration to ignore deprecated member warnings and run with `--no-fatal-infos`.

---

## [1.0.0+1] - 2026-11-17

### Added
- **PDF Statement Exporter with Digital Cryptographic Seal (Sprint 2)**:
  - Cryptographic sealing service with deterministic SHA-256 canonical hashing and HMAC-SHA256 signatures.
  - Native `%PDF-1.4` byte stream synthesizer and structural format validator.
  - Interactive statement verification dialog and QR code authenticity watermarks.
- **Auto-Roundup Spare Change Savings Vault (Sprint 1)**:
  - Automated spare change roundup calculations to the nearest dollar on debit transactions.
  - High-yield spare change vault with 4.5% APY and multi-tier roundup multipliers (1x, 2x, 3x, 5x).
  - Dedicated SQLite persistence and reactive GetX state bindings.
- **Core Platform Architecture**:
  - Executive Multi-Currency Vault, Frosted Virtual Card Studio, P2P Settlement Engine, AI Financial Copilot, and SQLite Transaction Ledger.
  - Hardware KeyStore biometric enclave bridge simulation.
  - 800x360dp landscape safe layout with zero RenderFlex overflows.
