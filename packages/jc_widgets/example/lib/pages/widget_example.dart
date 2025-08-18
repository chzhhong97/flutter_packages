import 'package:flutter/material.dart';
import 'package:jc_widgets/jc_widgets.dart';

class WidgetExample extends StatefulWidget {
  const WidgetExample({super.key});

  @override
  State<WidgetExample> createState() => _WidgetExampleState();
}

class _WidgetExampleState extends State<WidgetExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                color: Colors.red,
                child: MultilineText.texts(
                    [
                  Text(
                    "",
                    maxLines: 1,
                  ),
                  Text(
                    "Line 2",
                    maxLines: 1,
                  ),
                  Text(
                    "Line 3",
                    maxLines: 1,
                  ),
                ],
                  spacing: [
                    10,
                    10
                  ],
                  alignment: Alignment.center,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
