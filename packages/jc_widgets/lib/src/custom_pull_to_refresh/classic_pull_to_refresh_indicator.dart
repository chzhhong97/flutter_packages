import 'package:flutter/material.dart';
import 'package:jc_widgets/src/custom_pull_to_refresh/base_indicator.dart';
import 'package:jc_widgets/src/custom_pull_to_refresh/indicator_preferences.dart';

class ClassicPullToRefreshIndicator extends BaseIndicator{
  const ClassicPullToRefreshIndicator({
    super.key,
    super.pullDownPreferences,
    super.releasePreferences,
    super.loadingPreferences,
    super.completePreferences,
    super.spacing = 15,
  });

  @override
  Widget buildIndicator(BuildContext context, IndicatorPreferences preferences) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if(preferences.indicatorWidget != null)
            SizedBox(
              height: preferences.size,
              width: preferences.size,
              child: FittedBox(
                child: preferences.indicatorWidget,
              ),
            ),
          if(preferences.indicatorWidget != null && preferences.text != null)
            SizedBox(width: spacing,),
          if(preferences.text != null)
            Text(
              preferences.text!,
              style: TextStyle(
                  color: Theme.of(context).primaryColor
              ).merge(preferences.textStyle),
            ),
        ],
      ),
    );
  }
}