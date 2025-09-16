import 'package:flutter/material.dart';
import 'package:j3tunes/screens/equalizer_service.dart';

import 'package:just_audio/just_audio.dart';

void showEqualizerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const EqualizerSheet(),
  );
}

class EqualizerSheet extends StatefulWidget {
  const EqualizerSheet({super.key});

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  final EqualizerService _equalizerService = EqualizerService();

  @override
  Widget build(BuildContext context) {
    if (_equalizerService.equalizer == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Equalizer is not available on this platform.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<AndroidEqualizerParameters>(
      future: _equalizerService.equalizer!.parameters, // Add null check here
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final parameters = snapshot.data!;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Equalizer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _equalizerService.isEqualizerEnabled,
                    builder: (context, isEnabled, child) {
                      return Switch(
                        value: isEnabled,
                        onChanged: (value) {
                          _equalizerService.setEnabled(value);
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250, // Adjust height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: parameters.bands.length,
                  itemBuilder: (context, index) {
                    final band = parameters.bands[index];
                    return _buildBandSlider(band, parameters.minDecibels, parameters.maxDecibels);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBandSlider(AndroidEqualizerBand band, double minDb, double maxDb) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: band.gain,
                min: minDb,
                max: maxDb,
                onChanged: (value) {
                  setState(() {
                    band.setGain(value);
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(band.centerFrequency / 1000).toStringAsFixed(1)} kHz',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
