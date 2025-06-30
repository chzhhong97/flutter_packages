part of 'slide_show.dart';

class SlideShowController{
  SlideShowFunction? _slideShowFunction;
  SlideShowController();

  void attach(SlideShowFunction slideShowFunction){
    _slideShowFunction = slideShowFunction;
  }

  void detach(){
    _slideShowFunction = null;
  }

  void startAutoPlay() => _slideShowFunction?.startAutoPlay();
  void stopAutoPlay() => _slideShowFunction?.stopAutoPlay();
}