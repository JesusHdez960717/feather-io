import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BucketCreateForm extends StatefulWidget {
  ///Usa el [BucketCubit] de la pantalla que lo abre, asi el listado se recarga
  ///y la carga/errores los muestra esa pantalla
  static void open(BuildContext context) {
    final key = GlobalKey<BucketCreateFormState>();
    final cubit = context.read<BucketCubit>();
    FormDrawerTemplate.showAsDialog(
      title: app.intl.bucketsCreate,
      description: app.intl.bucketCreateDescription,
      icon: app.assets.icons.storage.bucket,
      footerActions: [
        PrimaryButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          title: app.intl.cancel,
          h: 40,
          w: 100,
        ),
        PrimaryButton.primary(
          onPressed: () {
            key.currentState?.submit();
          },
          title: app.intl.bucketsCreate,
          h: 40,
          w: 160,
          icon: app.assets.icons.actions.add,
        ),
      ],
      child: BlocProvider.value(
        value: cubit,
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
      return app.intl.bucketNameRequired;
    }
    if (value.length < 3 || value.length > 63) {
      return app.intl.bucketNameLength;
    }
    final regex = RegExp(r'^[a-z0-9-]+$');
    if (!regex.hasMatch(value)) {
      return app.intl.bucketNameChars;
    }
    if (value.startsWith('-') || value.endsWith('-')) {
      return app.intl.bucketNameHyphenEdges;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BucketCubit, BucketState>(
      listenWhen: (previous, current) => current is BucketProcessingOKState,
      listener: (context, state) => app.navigator.pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: app.intl.bucketCreateSectionGeneral,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFormInput(
                    controller: _nameController,
                    label: app.intl.bucketCreateNameLabel,
                    hint: app.intl.bucketCreateNameHint,
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
              title: app.intl.bucketCreateSectionAdditional,
              child: AppFormInput(
                label: app.intl.bucketCreateDescriptionLabel,
                controller: _descriptionController,
                hint: app.intl.bucketCreateDescriptionHint,
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
        buildItem(app.intl.bucketNameLength, isLenOk),
        buildItem(app.intl.bucketRuleChars, isCharsOk),
        buildItem(app.intl.bucketRuleHyphens, true),
        buildItem(
          app.intl.bucketRuleHyphenEdges,
          noHyphenStartEnd || name.isEmpty,
        ),
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
