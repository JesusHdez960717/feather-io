import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class NoDataPage extends StatelessWidget {
  final String? title;

  const NoDataPage({this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
          right: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
          bottom: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              app.dimensions.padding.xxl.gap(),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: app.dimensions.padding.xxl,
                ),
                child: Text(
                  title ?? 'No data',
                  style: app.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              (5 * app.dimensions.padding.xxl).gap(),
            ],
          ),
        ),
      ),
    );
  }
}
