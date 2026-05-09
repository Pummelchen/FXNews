# Operations and Troubleshooting

## Expected Dashboard

The chart shows a red title and up to five newest signal messages:

```text
BREAKOUT RADAR

2026-05-16 15:35:45 - EURUSD UP - 75%
2026-05-16 15:32:10 - GBPJPY DOWN - 69%
```

Timestamps use local computer time.

## No Signals

Check that the broker symbols exist, Market Watch can select them, M1/M5/M15 history is loaded, and spreads are below the configured filters. If needed, lower `MinDisplayConfidence` temporarily to inspect signal flow.

## Too Many Signals

Raise `MinDisplayConfidence`, increase cooldowns, or tighten spread limits. During rollover, keep `IgnoreRolloverTime` enabled.

## Sync Problems

Run:

```bash
scripts/sync_to_mt5.sh
```

If MetaTrader is installed somewhere else, run with:

```bash
MT5_EXPERTS_DIR="/path/to/MetaTrader 5/MQL5/Experts" scripts/sync_to_mt5.sh
```
