class FoodStats {
  const FoodStats({
    this.activeCount = 0,
    this.urgentCount = 0,
    this.expiringThisWeekCount = 0,
    this.eatenCount = 0,
    this.discardedCount = 0,
  });

  final int activeCount;
  final int urgentCount;
  final int expiringThisWeekCount;
  final int eatenCount;
  final int discardedCount;

  int get historyTotal => eatenCount + discardedCount;
}
