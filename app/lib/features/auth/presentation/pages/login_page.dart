import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../controllers/auth_controller.dart';
import '../widgets/demo_account_picker.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    return Scaffold(
      body: SafeArea(
        child: isWide
            ? Row(
                children: const [
                  Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 4, child: _LoginFormPanel()),
                ],
              )
            : const _LoginFormPanel(showCompactBrand: true),
      ),
    );
  }
}

/// แผงซ้ายบนจอกว้าง — โชว์ตัวตนของแบรนด์และฟีเจอร์เด่น
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Logo(size: 64, light: true),
          const SizedBox(height: 28),
          Text(
            'auth_login_brand_headline'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'auth_login_brand_subheadline'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          _FeatureLine(
            icon: Icons.table_restaurant_rounded,
            text: 'auth_login_feature_tables'.tr,
          ),
          _FeatureLine(
            icon: Icons.soup_kitchen_rounded,
            text: 'auth_login_feature_kds'.tr,
          ),
          _FeatureLine(
            icon: Icons.point_of_sale_rounded,
            text: 'auth_login_feature_billing'.tr,
          ),
          _FeatureLine(
            icon: Icons.insights_rounded,
            text: 'auth_login_feature_reports'.tr,
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFormPanel extends GetView<AuthController> {
  const _LoginFormPanel({this.showCompactBrand = false});

  final bool showCompactBrand;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showCompactBrand) ...[
                  const Center(child: _Logo(size: 56)),
                  const SizedBox(height: 20),
                ],
                Text(
                  'auth_login_title'.tr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'auth_login_subtitle'.tr,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: controller.usernameController,
                  validator: controller.validateUsername,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: 'auth_username_label'.tr,
                    hintText: 'auth_username_hint'.tr,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                Obx(
                  () => TextFormField(
                    controller: controller.passwordController,
                    validator: controller.validatePassword,
                    obscureText: controller.obscurePassword.value,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => controller.submitLogin(),
                    decoration: InputDecoration(
                      labelText: 'auth_password_label'.tr,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: controller.toggleObscure,
                        icon: Icon(
                          controller.obscurePassword.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                ),

                Obx(() {
                  final message = controller.errorMessage.value;
                  if (message == null) return const SizedBox(height: 24);
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                Obx(
                  () => FilledButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.submitLogin,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text('auth_login_title'.tr),
                  ),
                ),

                const SizedBox(height: 28),
                if (AppConfig.demoMode) ...[
                  const _DemoModeBanner(),
                  const SizedBox(height: 14),
                ],
                const DemoAccountPicker(),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    AppConfig.demoMode
                        ? 'auth_login_footer_demo'.tr
                        : 'auth_login_footer_connected'.trParams({
                            'url': AppConfig.baseUrl,
                          }),
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// แจ้งผู้ที่มาลองใช้ว่ากำลังอยู่ในโหมดสาธิตที่ไม่มีเซิร์ฟเวอร์
class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_rounded, size: 18, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'auth_demo_mode_banner'.tr,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.info,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.size = 56, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(
            Icons.restaurant_menu_rounded,
            size: size * 0.55,
            color: light ? Colors.white : AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PaynEat',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: light ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              'POS SYSTEM',
              style: TextStyle(
                fontSize: size * 0.17,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: light ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
