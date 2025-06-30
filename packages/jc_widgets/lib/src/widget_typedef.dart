import 'package:flutter/material.dart';

typedef ItemIndexedWidgetBuilder<T> = Widget Function(BuildContext context, int index, T item);
typedef DialogBuilder = Widget Function(BuildContext context, void Function([dynamic]) popDialog, void Function(SnackBar snackBar) showSnackBar);