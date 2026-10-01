import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../catalog/data/models/product.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../data/models/group_deal.dart';
import '../providers/society_providers.dart';
import '../../data/repositories/society_repository.dart';

class GroupBuyTab extends ConsumerWidget {
  const GroupBuyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(groupDealsProvider);

    return Scaffold(
      body: dealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (deals) {
          if (deals.isEmpty) {
            return const Center(child: Text('No active Group Buys right now.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Gap.m),
            itemCount: deals.length,
            separatorBuilder: (_, _) => const SizedBox(height: Gap.m),
            itemBuilder: (context, i) => GroupDealCard(deal: deals[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feature to propose new group buys coming soon!'))
          );
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Propose Deal'),
      ),
    );
  }
}

class GroupDealCard extends ConsumerWidget {
  const GroupDealCard({super.key, required this.deal});
  final GroupDeal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(deal.productId));
    final currentUser = ref.watch(authUserProvider).valueOrNull;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: productAsync.when(
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(height: 100, child: Center(child: Text('Error: $e'))),
        data: (product) {
          if (product == null) return const SizedBox.shrink();
          final isJoined = currentUser != null && deal.participantIds.contains(currentUser.uid);

          return Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: AppNetworkImage(url: product.thumbnail),
                    ),
                    const SizedBox(width: Gap.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2),
                          Text('₹${product.price} (Regular)'),
                          Text(
                            'Need ${deal.requiredParticipants} buyers to get discount!',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.s),
                LinearProgressIndicator(value: deal.progress),
                const SizedBox(height: Gap.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${deal.participantIds.length} / ${deal.requiredParticipants} joined'),
                    FilledButton(
                      onPressed: isJoined || deal.isExpired ? null : () async {
                        if (currentUser == null) return;
                        await ref.read(societyRepositoryProvider).joinGroupDeal(deal.id, currentUser.uid);
                      },
                      child: Text(isJoined ? 'Joined' : (deal.isExpired ? 'Expired' : 'Join Buy')),
                    ),
                  ],
                )
              ],
            ),
          );
        }
      ),
    );
  }
}
