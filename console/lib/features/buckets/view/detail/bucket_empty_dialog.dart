import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// Confirmation to empty a bucket: the button is only enabled after typing its name
class BucketEmptyDialog extends StatefulWidget {
  static void show({
    required BucketModel bucket,
    required VoidCallback onConfirm,
  }) {
    DialogTemplate.open(
      title: app.intl.bucketEmptyTitle,
      w: 480,
      h: 380,
      child: BucketEmptyDialog(bucket: bucket, onConfirm: onConfirm),
    );
  }

  final BucketModel bucket;
  final VoidCallback onConfirm;

  const BucketEmptyDialog({
    required this.bucket,
    required this.onConfirm,
    super.key,
  });

  @override
  State<BucketEmptyDialog> createState() => _BucketEmptyDialogState();
}

class _BucketEmptyDialogState extends State<BucketEmptyDialog> {
  final _controller = TextEditingController();

  bool get _matches => _controller.text == widget.bucket.name;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_matches) return;
    app.navigator.pop();
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final bucket = widget.bucket;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            app.intl.bucketEmptyConfirm(
              bucket.objectCount,
              app.storageFormatter.formatSize(bucket.sizeBytes),
              bucket.name,
            ),
            textAlign: TextAlign.center,
            style: app.textTheme.titleMedium,
          ),
          app.dimensions.padding.xl.gap(),
          AppFormInput(
            controller: _controller,
            autofocus: true,
            label: app.intl.bucketEmptyTypeName(bucket.name),
            hint: bucket.name,
            helperText: app.intl.bucketEmptyTypeNameHelper,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
          ),
          app.dimensions.padding.xl.gap(),
          Row(
            children: [
              Expanded(
                child: PrimaryButton.primary(
                  onPressed: () => app.navigator.pop(),
                  title: app.intl.cancel,
                  color: app.colors.primary.background3,
                ),
              ),
              app.dimensions.padding.l.gap(),
              Expanded(
                child: PrimaryButton.primary(
                  onPressed: _matches ? _confirm : null,
                  title: app.intl.bucketEmptyTitle,
                  color: app.colors.primary.errorAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
