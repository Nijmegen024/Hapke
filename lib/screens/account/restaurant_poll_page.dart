import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/restaurant_poll_controller.dart';

class RestaurantPollResult {
  final String? selectedOption;
  final Map<String, int> votes;

  const RestaurantPollResult({
    required this.selectedOption,
    required this.votes,
  });
}

class RestaurantPollPage extends StatelessWidget {
  final Map<String, int> initialVotes;
  final String? initialChoice;

  const RestaurantPollPage({
    super.key,
    required this.initialVotes,
    this.initialChoice,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RestaurantPollController(
      initialVotes: initialVotes,
      initialChoice: initialChoice,
    ));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stem op het volgende restaurant'),
          actions: [TextButton(onPressed: () => controller.close(), child: const Text('Gereed'))],
        ),
        body: Obx(() => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Kies welk restaurant jij als eerste in de app wilt zien. '
              'We voegen de winnaar als volgende toe.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...RestaurantPollController.options.map(
              (option) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: RadioListTile<String>(
                  title: Text(option),
                  subtitle: Text('${controller.votes[option] ?? 0} stemmen'),
                  value: option,
                  groupValue: controller.selected,
                  onChanged: (value) => controller.selected = value,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.submitVote(),
                    child: const Text('Stem'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.confirmed == null ? null : () => controller.clearVote(),
                    child: const Text('Verwijder stem'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Tussenstand',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...RestaurantPollController.options.map((option) {
              final count = controller.votes[option] ?? 0;
              final total = controller.totalVotes;
              final double progress = total == 0 ? 0 : count / total;
              final percentage = total == 0 ? 0 : (progress * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$option · $count stem${count == 1 ? '' : 'men'}'),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0).toDouble(),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$percentage%'),
                  ],
                ),
              );
            }),
            if (controller.totalVotes == 0)
              const Text(
                'Nog geen stemmen — jij kunt de eerste zijn!',
                style: TextStyle(color: Color(0xFF6F7F99)),
              ),
          ],
        )),
      ),
    );
  }
}
