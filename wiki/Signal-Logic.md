# Signal Logic

FXNews combines two weighted engines and displays only fresh events above the configured confidence threshold.

## Technical Breakout Engine

The technical engine builds a range from completed candles on each configured scan timeframe, calculates a dynamic breakout buffer from spread, ATR, and minimum pips, then scores directional breaks using:

- Range compression quality.
- Clean distance beyond the range.
- Short-window momentum acceleration.
- Tick-volume expansion.
- Price holding outside the range.
- Currency-strength confirmation.
- Spread and liquidity quality.

## Impulse Breakout Engine

The impulse engine detects news-like behavior from broker data only:

- Abnormal price speed over short windows.
- Current scan-timeframe candle expansion versus ATR.
- Tick-volume surge.
- Currency basket confirmation.
- Continuation after the first push.
- Spread quality.

## Confidence

The displayed percentage is an internal quality score. It is not a win probability. Fakeout penalties reduce confidence when price snaps back into the range, candle structure is weak, volume is low, spread is elevated, M5 or M15 context rejects the move, or the event is getting old.
