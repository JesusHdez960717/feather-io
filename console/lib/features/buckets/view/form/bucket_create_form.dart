import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BucketCreateForm extends StatefulWidget {
  static void open(BuildContext context) {
    final key = GlobalKey<BucketCreateFormState>();
    FormDrawerTemplate.showAsDialog(
      title: 'Create Bucket',
      description: 'Configure high-performance object storage parameters, redundancy, and protection policies.',
      icon: app.assets.icons.storage.bucket,
      footerActions: [
        PrimaryButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          title: 'Cancel',
          h: 40,
          w: 100,
        ),
        PrimaryButton.primary(
          onPressed: () {
            key.currentState?.submit();
          },
          title: 'Create Bucket',
          h: 40,
          w: 160,
          icon: app.assets.icons.actions.add,
        ),
      ],
      child: BlocProvider(
        create: (context) => BucketCubit(app.di.find(), app.di.find()),
        lazy: false,
        child: BucketCreateForm(key: key),
      ),
    );
  }

  const BucketCreateForm({super.key});

  @override
  State<BucketCreateForm> createState() => BucketCreateFormState();
}

class BucketCreateFormState extends State<BucketCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final BucketCubit cubit;

  @override
  void initState() {
    super.initState();

    cubit = context.read<BucketCubit>();

    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bucket name is required';
    }
    if (value.length < 3 || value.length > 63) {
      return 'Between 3 and 63 characters';
    }
    final regex = RegExp(r'^[a-z0-9-]+$');
    if (!regex.hasMatch(value)) {
      return 'Lowercase, numbers and hyphens only';
    }
    if (value.startsWith('-') || value.endsWith('-')) {
      return 'Cannot start or end with a hyphen';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BucketCubit, BucketState>(
      listener: (context, state) {
        if (state is BucketProcessInProgressState) {
          app.loading.show();
        } else {
          app.loading.hide();
        }

        if (state is BucketProcessingOKState) {
          app.navigator.pop();
        } else if (state is BucketProcessingErrorState) {
          app.snack.showError(message: state.message, context: context);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '01 General Configuration',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFormInput(
                    controller: _nameController,
                    label: 'Bucket Identifier',
                    hint: 'my-bucket-name',
                    showCounter: true,
                    maxLength: 63,
                    validator: _validateName,
                  ),

                  app.dimensions.padding.m.gap(),
                  _buildValidationList(),
                ],
              ),
            ),
            app.dimensions.padding.xl.gap(),
            _buildSection(
              title: '02 Additional Info',
              child: AppFormInput(
                label: 'Description (Optional)',
                controller: _descriptionController,
                hint: 'Brief description of the bucket usage',
                maxLines: 3,
                showCounter: true,
                maxLength: 1024,
                height: 120,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: app.textTheme.labelLarge?.copyWith(
            color: app.colors.primary.primaryFaded,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        app.dimensions.padding.l.gap(),
        Container(
          padding: EdgeInsets.all(app.dimensions.padding.l),
          decoration: BoxDecoration(
            color: app.colors.primary.background2,
            borderRadius: app.dimensions.border.borderRadius.m,
            border: Border.all(
              color: app.colors.neutral.grey5.withValues(alpha: 0.3),
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildValidationList() {
    final name = _nameController.text;
    final isLenOk = name.length >= 3 && name.length <= 63;
    final isCharsOk = RegExp(r'^[a-z0-9-]+$').hasMatch(name) || name.isEmpty;
    final noHyphenStartEnd = !name.startsWith('-') && !name.endsWith('-');

    Widget buildItem(String text, bool ok) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.circle_outlined,
            size: 14,
            color: ok ? app.colors.primary.green : app.colors.neutral.grey4,
          ),
          app.dimensions.padding.xs.gap(),
          Text(
            text,
            style: app.textTheme.bodySmall?.copyWith(
              color: ok ? app.colors.neutral.grey2 : app.colors.neutral.grey4,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: app.dimensions.padding.l,
      runSpacing: app.dimensions.padding.s,
      children: [
        buildItem('Between 3 and 63 chars', isLenOk),
        buildItem('Lowercase & numbers only', isCharsOk),
        buildItem('Hyphens allowed', true),
        buildItem('No hyphen at start/end', noHyphenStartEnd || name.isEmpty),
      ],
    );
  }

  void submit() {
    if (_formKey.currentState?.validate() ?? false) {
      cubit.createBucket(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );
    }
  }
}
