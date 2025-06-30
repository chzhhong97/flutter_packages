import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MobileDesignWidget extends StatefulWidget{
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Size aspectRatio;

  const MobileDesignWidget({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 0,
    this.aspectRatio = const Size(9, 16)
  });

  @override
  State<MobileDesignWidget> createState() => _MobileDesignWidgetState();
}

class _MobileDesignWidgetState extends State<MobileDesignWidget> with WidgetsBindingObserver{
  final maxWebAppRatio = 4.8/6.0;
  final minWebAppRatio = 9.0/16.0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = getMobileSize();
    return MobileDesignState(
        mobileSize: size,
        isMobile: getIsMobileWeb(),
        isMobileRatio: getIsMobileRatio(),
        child: Center(
          child: ClipRect(
            child: Container(
              margin: getIsWeb() ? widget.padding ?? EdgeInsets.zero : EdgeInsets.zero,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(getIsWeb() ? widget.borderRadius : 0)
              ),
              child: SizedBox.fromSize(
                size: getIsWeb() ? size : null,
                child: MediaQuery(
                  data: getIsWeb() ? MediaQueryData(size: size) : MediaQuery.of(context),
                  child: widget.child,
                ),
              ),
            ),
          ),
        )
    );
  }

  bool getIsWeb(){
    return !getIsMobileWeb() && !getIsMobileRatio();
  }

  bool getIsMobileRatio(){
    var flutterView = WidgetsBinding.instance.platformDispatcher.views.first;
    var screenSize = flutterView.physicalSize;

    var w = (screenSize.height/16) * 9;
    return screenSize.width <= w;
  }

  double getCurrentWebAppRatio(){
    double currentWebAppRatio = minWebAppRatio;

    var flutterView = WidgetsBinding.instance.platformDispatcher.views.first;
    var screenSize = flutterView.physicalSize;
    currentWebAppRatio = screenSize.width / screenSize.height;
    if(currentWebAppRatio > maxWebAppRatio){
      currentWebAppRatio = maxWebAppRatio;
    }
    else if(currentWebAppRatio < minWebAppRatio){
      currentWebAppRatio = minWebAppRatio;
    }

    return currentWebAppRatio;
  }

  Size getMobileSize(){
    var flutterView = WidgetsBinding.instance.platformDispatcher.views.first;
    var screenSize = flutterView.physicalSize;
    var pixelRatio = flutterView.devicePixelRatio;

    var pixelSize = Size(screenSize.width / pixelRatio, screenSize.height / pixelRatio);

    var mobileSize = Size(
      getMobileRatioWidth(pixelSize, widget.padding?.vertical ?? 0),
      getMobileRatioHeight(pixelSize, widget.padding?.vertical ?? 0),
    );

    //print(screenSize);
    //print(mobileSize);
    var minHeight = 500.0 / pixelRatio;
    //print(minHeight);

    if(mobileSize.height < minHeight){
      mobileSize = Size((minHeight/widget.aspectRatio.height) * widget.aspectRatio.width, minHeight);
    }

    return mobileSize;
  }

  double getMobileRatioWidth(Size windowSize, double padding) => (getMobileRatioHeight(windowSize, padding)/widget.aspectRatio.height) * widget.aspectRatio.width;
  double getMobileRatioHeight(Size windowSize, double padding) => windowSize.height - (padding * 2);

  bool getIsMobileWeb(){
    return kIsWeb && {TargetPlatform.iOS, TargetPlatform.android}.contains(defaultTargetPlatform);
  }
}

class MobileDesignState extends InheritedWidget{
  final Size mobileSize;
  final bool isMobile;
  final bool isMobileRatio;

  const MobileDesignState({
    super.key,
    required this.mobileSize,
    required this.isMobile,
    required this.isMobileRatio,
    required super.child,
  });

  bool get isWeb => !isMobile && !isMobileRatio;

  static MobileDesignState? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<MobileDesignState>();

  @override
  bool updateShouldNotify(covariant MobileDesignState oldWidget) {
    return mobileSize != oldWidget.mobileSize || isMobile != oldWidget.isMobile || isMobileRatio != oldWidget.isMobileRatio;
  }

}
