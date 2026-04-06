import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays short synthesised tones for correct / wrong quiz answers.
class QuizSoundService {
  QuizSoundService._();
  static final instance = QuizSoundService._();

  static const _prefKey = 'quiz_sound_enabled';

  AudioPlayer? _player;
  Uint8List? _correctWav;
  Uint8List? _wrongWav;
  bool _enabled = true;
  bool _settingLoaded = false;

  bool get isEnabled => _enabled;

  /// Call whenever the user toggles the switch.
  void setEnabled(bool value) {
    _enabled = value;
    _settingLoaded = true;
  }

  /// Play the appropriate feedback sound. No-op when disabled.
  Future<void> play({required bool correct}) async {
    if (!_settingLoaded) await _loadSetting();
    if (!_enabled) return;
    _player ??= AudioPlayer();
    final bytes = correct ? _correctBytes() : _wrongBytes();
    await _player!.play(BytesSource(bytes));
  }

  Uint8List _correctBytes() =>
      _correctWav ??= _richToneWav(const [
        (freq: 523.25, ms: 80, vol: 0.30),
        (freq: 659.25, ms: 80, vol: 0.32),
        (freq: 783.99, ms: 160, vol: 0.35),
      ]);

  Uint8List _wrongBytes() =>
      _wrongWav ??= _richToneWav(const [
        (freq: 311.13, ms: 120, vol: 0.25),
        (freq: 233.08, ms: 220, vol: 0.22),
      ]);

  Future<void> _loadSetting() async {
    try {
      _enabled = await SharedPreferencesAsync().getBool(_prefKey) ?? true;
    } catch (_) {
      _enabled = true;
    }
    _settingLoaded = true;
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }

  static Uint8List _richToneWav(
    List<({double freq, int ms, double vol})> tones, {
    int sampleRate = 44100,
  }) {
    int totalSamples = 0;
    for (final t in tones) {
      totalSamples += (sampleRate * t.ms / 1000).round();
    }

    final dataSize = totalSamples * 2;
    final buffer = ByteData(44 + dataSize);

    _ascii(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    _ascii(buffer, 8, 'WAVE');

    _ascii(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);

    _ascii(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    int offset = 0;
    for (final tone in tones) {
      final segSamples = (sampleRate * tone.ms / 1000).round();
      final attackSamples = (sampleRate * 0.008).round();
      final releaseSamples = (sampleRate * 0.025).round();
      for (int i = 0; i < segSamples; i++) {
        final t = i / sampleRate;
        final attack = (i / attackSamples).clamp(0.0, 1.0);
        final release = ((segSamples - i) / releaseSamples).clamp(0.0, 1.0);
        final envelope = attack * release;

        final fundamental = sin(2 * pi * tone.freq * t);
        final octave = sin(2 * pi * tone.freq * 2 * t) * 0.20;
        final fifth = sin(2 * pi * tone.freq * 3 * t) * 0.10;

        final sample = ((fundamental + octave + fifth) *
                tone.vol *
                envelope *
                32767)
            .round()
            .clamp(-32768, 32767);
        buffer.setInt16(44 + (offset + i) * 2, sample, Endian.little);
      }
      offset += segSamples;
    }

    return buffer.buffer.asUint8List();
  }

  static void _ascii(ByteData data, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
