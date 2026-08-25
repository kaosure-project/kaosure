import 'package:flutter/material.dart';

import 'auction_tile.dart';
import 'kaopay_tile.dart';
import 'marketplace_tile.dart';
import 'more_services_tile.dart';

final class DashboardServicesSection extends StatelessWidget {
  const DashboardServicesSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              'บริการ',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
          ),

          const MarketplaceTile(),

          const AuctionTile(),

          const KaoPayTile(),

          const MoreServicesTile(),
        ],
      ),
    );
  }
}