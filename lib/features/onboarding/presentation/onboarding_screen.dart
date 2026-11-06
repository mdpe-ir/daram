import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/branding/daram_logo.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: LucideIcons.sparkles,
      title: 'فقط حرف بزن، دارام ثبت می‌کند',
      description: 'لازم نیست فرم پر کنی. بنویس «امروز ۲۵۰ هزار تومان ناهار خوردم» و دارام پیش‌نویس می‌سازد؛ قبل از ثبت، خودت تأیید می‌کنی.',
      kind: _PageKind.chat,
    ),
    _OnboardingPage(
      icon: LucideIcons.shieldCheck,
      title: 'پول و داده‌ات روی گوشی خودت',
      description: 'همه اطلاعات مالی و گفتگوها به‌صورت محلی ذخیره می‌شوند. دارام نه حساب کاربری می‌خواهد، نه به بانک وصل می‌شود و نه داده‌ات را می‌فروشد.',
      kind: _PageKind.privacy,
    ),
    _OnboardingPage(
      icon: LucideIcons.keyRound,
      title: 'دستیار خودت را وصل کن',
      description: 'کلید API خودت را وارد کن؛ با OpenAI، Anthropic، Gemini یا هر سرویس سازگار. هزینه و انتخاب مدل دست خودت است.',
      kind: _PageKind.provider,
    ),
  ];

  void _finish({bool openSettings = false}) {
    ref.read(settingsControllerProvider.notifier).completeOnboarding();
    context.go(openSettings ? '/settings/ai' : '/chat');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Scaffold(
      body: Stack(
        children: [
          const DaramAura(intensity: 0.9),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      const DaramLogo(markSize: 34),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _finish(),
                        child: const Text('رد کردن'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) =>
                        _PageContent(page: _pages[index], index: index),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _pages.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 24 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? colors.accent
                                    : colors.border,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_page == _pages.length - 1) ...[
                        PrimaryButton(
                          label: 'شروع گفتگو',
                          icon: LucideIcons.sparkles,
                          onPressed: () => _finish(),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => _finish(openSettings: true),
                          child: const Text('اول دستیار را تنظیم می‌کنم'),
                        ),
                      ] else
                        PrimaryButton(
                          label: 'ادامه',
                          onPressed: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PageKind { chat, privacy, provider }

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.kind,
  });

  final IconData icon;
  final String title;
  final String description;
  final _PageKind kind;
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page, required this.index});

  final _OnboardingPage page;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                      height: 250,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.accent.withValues(
                              alpha: colors.isDark ? 0.18 : 0.10,
                            ),
                            colors.gradientEnd.withValues(
                              alpha: colors.isDark ? 0.06 : 0.04,
                            ),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: colors.border),
                      ),
                      child: _Artwork(kind: page.kind, icon: page.icon),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.04, end: 0),
                const SizedBox(height: 30),
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 12),
                Text(
                  page.description,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: colors.textSecondary, height: 1.8),
                ),
                const SizedBox(height: 18),
                if (page.kind == _PageKind.privacy)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      StatusPill(
                        label: 'بدون حساب کاربری',
                        color: Color(0xFF10B981),
                        icon: LucideIcons.check,
                      ),
                      StatusPill(
                        label: 'بدون ابر',
                        color: Color(0xFF3B82F6),
                        icon: LucideIcons.hardDrive,
                      ),
                      StatusPill(
                        label: 'قابل بکاپ',
                        color: Color(0xFFF59E0B),
                        icon: LucideIcons.download,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.kind, required this.icon});

  final _PageKind kind;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    switch (kind) {
      case _PageKind.chat:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _Bubble(
                text: 'امروز ۲۵۰ هزار تومان ناهار خوردم',
                isUser: true,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DaramMark(size: 22, withBackground: false),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'هزینه ناهار آماده شد؛ تأیید می‌کنی؟',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.expense.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.utensils,
                      size: 17,
                      color: colors.expense,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'خوراک و رستوران',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          '۲۵۰٬۰۰۰ تومان',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: 'پیش‌نویس',
                    color: colors.warning,
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        );
      case _PageKind.privacy:
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final radius in [190.0, 145.0])
                Container(
                  width: radius,
                  height: radius,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.18),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: DaramMark(size: 78),
              ),
              Positioned(
                top: 18,
                right: 22,
                child: _Badge(
                  icon: LucideIcons.wifiOff,
                  color: colors.transfer,
                ),
              ),
              Positioned(
                bottom: 22,
                left: 18,
                child: _Badge(icon: LucideIcons.lock, color: colors.income),
              ),
              Positioned(
                bottom: 34,
                right: 10,
                child: _Badge(
                  icon: LucideIcons.smartphone,
                  color: colors.warning,
                ),
              ),
            ],
          ),
        );
      case _PageKind.provider:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  const DaramMark(size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'اتصال امن به سرویس هوش مصنوعی',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 14),
                  for (final provider in [
                    'سازگار با OpenAI',
                    'Anthropic',
                    'Gemini',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 15,
                            color: colors.income,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            'کلید خودت',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'کلید API فقط در حافظه امن دستگاه ذخیره می‌شود.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.textMuted),
            ),
          ],
        );
    }
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? colors.chatUser : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}
