import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:jc_widgets/src/custom_pull_to_refresh/custom_pull_to_refresh.dart';

import 'indicator_preferences.dart';

abstract class BaseIndicator extends StatelessWidget{
  /// Default text = Pull down to Refresh, Icon = Icons.keyboard_arrow_down
  final IndicatorPreferences? pullDownPreferences;
  /// Default text = Release to refresh, Icon = Icons.keyboard_arrow_up
  final IndicatorPreferences? releasePreferences;
  /// Default text = Refreshing..., Icon = CircularProgressIndicator
  final IndicatorPreferences? loadingPreferences;
  /// Default text = Success, Icon = Icons.check
  final IndicatorPreferences? completePreferences;
  final double spacing;

  const BaseIndicator({
    super.key,
    this.pullDownPreferences,
    this.releasePreferences,
    this.loadingPreferences,
    this.completePreferences,
    required this.spacing,
  });

  IndicatorPreferences get defaultPullDownPreferences => const IndicatorPreferences(
    text: 'Pull down to refresh',
    indicatorWidget: Icon(Icons.keyboard_arrow_down),
  );
  IndicatorPreferences get defaultReleasePreferences => const IndicatorPreferences(
    text: 'Release to refresh',
    indicatorWidget: Icon(Icons.keyboard_arrow_up),
  );
  IndicatorPreferences get defaultLoadingPreferences => const IndicatorPreferences(
    text: 'Refreshing...',
    indicatorWidget: CircularProgressIndicator(),
  );
  IndicatorPreferences get defaultCompletePreferences => const IndicatorPreferences(
    text: 'Success',
    indicatorWidget: Icon(Icons.check),
  );

  @override
  Widget build(BuildContext context) {
    return buildIndicator(context, getIndicatorPreferences(CustomRefreshState.of(context)?.state));
  }

  Widget buildIndicator(BuildContext context, IndicatorPreferences preferences);

  IndicatorPreferences getIndicatorPreferences(IndicatorState? state){
    if(state == IndicatorState.armed) return defaultReleasePreferences.merge(releasePreferences);
    if(state == IndicatorState.loading || state == IndicatorState.settling) return defaultLoadingPreferences.merge(loadingPreferences);
    if(state == IndicatorState.complete) return defaultCompletePreferences.merge(completePreferences);

    return defaultPullDownPreferences.merge(pullDownPreferences);
  }
}