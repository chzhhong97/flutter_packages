enum PrintColor{

  black(30),
  red(31),
  green(32),
  yellow(33),
  blue(34),
  magenta(35),
  cyan(36),
  white(37),
  reset(0);

  final int colorCode;

  const PrintColor(this.colorCode);

  String get escapeCode => '\x1B[${colorCode}m';
  void printColor(Object? object){
    print("$escapeCode$object${PrintColor.reset.escapeCode}");
  }

  @override
  String toString() => escapeCode;
}