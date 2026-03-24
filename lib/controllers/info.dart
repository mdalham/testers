abstract class PublishConstants {
  static const String fallbackVersion = '1.0.3';

  static const int accountCreatingCoins = 130;

  // ── What the publisher pays ────────────────────────────────────────────────
  // Publish cost is dynamic: selectedTesterCount × kCoinsPerTester (in provider)
  static const int editCoinCost  = 65;
  static const int boostCoinCost = 65;

  // ── What the tester EARNS on completion ───────────────────────────────────
  static const int normalTesterReward  = 10; // normal app reward
  static const int boostedTesterReward = 30; // boosted app reward

  // ── Ads ────────────────────────────────────────────────────────────────────
  static const int adsCoolDown = 10;
  static const int adsM1 = 2;
  static const int adsM2 = 10;
  static const int adsM3 = 26;

  // ── Groups ─────────────────────────────────────────────────────────────────
  static const int groupJoinCoinCost = 129;
  static const int maxGroupMembers   = 15;
  static const int miniGroupMembers  = 12;
  static const int groupStartHours   = 36;
  static const int groupTestingDays  = 14;
}