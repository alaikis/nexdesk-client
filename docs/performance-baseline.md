# Flutter Performance Baseline

## Measurement Environment
- Device: Desktop (Linux x64)
- Build: `flutter build linux --release`
- Profiler: `flutter devtools` + `perf` + `dart:developer`

## Cold Start Time
- Target: < 2s from binary launch to first frame
- Measured: TBD (requires device-side instrumentation)

## Memory Footprint
- Target: < 150 MB RSS after first frame at idle
- Measured: TBD

## WebRTC Frame Rate
- Target: 30 fps sustained during screen share
- Measured: TBD

## Next Steps
1. Add `Trace.beginAsync` markers around startup path
2. Record baseline on target device
3. Track regressions in CI
