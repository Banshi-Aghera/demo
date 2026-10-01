import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/society_membership.dart';
import '../providers/society_providers.dart';
import 'group_buy_tab.dart';

/// Locked until membership is approved. The three feature tabs get their
/// real screens in Phases 5, 6 and 7.
class MySocietyTab extends ConsumerWidget {
  const MySocietyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(myMembershipProvider);

    return membership.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.navMySociety)),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(myMembershipProvider),
        ),
      ),
      data: (m) {
        if (m == null || !m.isApproved) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.navMySociety)),
            body: _LockedState(membership: m),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(m.societyName),
              bottom: const TabBar(
                tabs: [
                  Tab(text: AppStrings.neighbourDrop),
                  Tab(text: AppStrings.lending),
                  Tab(text: AppStrings.groupBuy),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                EmptyState(
                  icon: Icons.local_shipping_rounded,
                  title: AppStrings.neighbourDrop,
                  message: AppStrings.featureComingBody,
                ),
                EmptyState(
                  icon: Icons.handshake_rounded,
                  title: AppStrings.lending,
                  message: AppStrings.featureComingBody,
                ),
                GroupBuyTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LockedState extends StatelessWidget {
  const _LockedState({required this.membership});

  final SocietyMembership? membership;

  @override
  Widget build(BuildContext context) {
    void openJoin() => context.push(Routes.joinSociety);

    switch (membership?.status) {
      case MembershipStatus.pending:
        return EmptyState(
          icon: Icons.hourglass_top_rounded,
          title: AppStrings.societyPendingTitle,
          message:
              '${membership!.societyName} · ${membership!.flatLabel}\n${AppStrings.societyPendingBody}',
        );
      case MembershipStatus.rejected:
        return EmptyState(
          icon: Icons.info_outline_rounded,
          title: AppStrings.societyRejectedTitle,
          message: AppStrings.societyRejectedBody,
          actionLabel: AppStrings.sendNewRequest,
          onAction: openJoin,
        );
      case MembershipStatus.approved:
      case null:
        return EmptyState(
          icon: Icons.lock_outline_rounded,
          title: AppStrings.societyLockedTitle,
          message: AppStrings.societyLockedBody,
          actionLabel: AppStrings.joinSocietyTitle,
          onAction: openJoin,
        );
    }
  }
}
