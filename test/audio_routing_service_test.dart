import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/services/audio_routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioRoutingService Tests', () {
    test('applyAudioRouting updates currentTarget', () async {
      final service = AudioRoutingService();
      expect(service.currentTarget, isNotEmpty);

      final successAux = await service.applyAudioRouting('AUX Cable / 3.5mm DAC');
      expect(successAux, isTrue);
      expect(service.currentTarget, equals('AUX Cable / 3.5mm DAC'));

      final successBt = await service.applyAudioRouting('Car Bluetooth Stereo (A2DP)');
      expect(successBt, isTrue);
      expect(service.currentTarget, equals('Car Bluetooth Stereo (A2DP)'));

      final successHdmi = await service.applyAudioRouting('HDMI Display Speakers');
      expect(successHdmi, isTrue);
      expect(service.currentTarget, equals('HDMI Display Speakers'));
    });
  });
}
