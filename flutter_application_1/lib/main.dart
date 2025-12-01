import 'package:flutter/material.dart';

/// Точка входа приложения: запускает корневой виджет [MainApp].
void main() {
  runApp(const MainApp());
}

/// Корневой виджет, задающий глобальную тему и стартовый экран.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF5F6FB),
      ),
      home: const _ScreenSwitcher(),
    );
  }
}

/// Оболочка, которая хранит индекс выбранного экрана и отображает его.
class _ScreenSwitcher extends StatefulWidget {
  const _ScreenSwitcher();

  @override
  State<_ScreenSwitcher> createState() => _ScreenSwitcherState();
}

class _ScreenSwitcherState extends State<_ScreenSwitcher> {
  int _currentIndex = 0;

  /// Список всех шаблонов, между которыми можно переключаться.
  static const List<Widget> _screens = [
    _RelaxScreen(),
    _MedinowScreen(),
    _ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // BottomNavigationBar служит панелью выбора нужного шаблона.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0FA9A2),
        unselectedItemColor: Colors.grey.shade500,
        onTap: (value) => setState(() => _currentIndex = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement_outlined),
            label: 'Relax',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            label: 'Medinow',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Экран с карточкой релаксации и списком сеансов.
class _RelaxScreen extends StatelessWidget {
  const _RelaxScreen();

  @override
  Widget build(BuildContext context) {
    // Подготовленный список данных для генерации карточек сеансов.
    final sessions = [
      _Session(
        title: 'Sweet Memories',
        subtitle: 'December 29 Pre-Launch',
        accent: const Color(0xFF5D9CFF),
      ),
      _Session(
        title: 'A Day Dream',
        subtitle: 'December 29 Pre-Launch',
        accent: const Color(0xFF20C997),
      ),
      _Session(
        title: 'Mind Explore',
        subtitle: 'December 29 Pre-Launch',
        accent: const Color(0xFFFFC35C),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(),
              const SizedBox(height: 32),
              ...sessions.map((session) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SessionTile(session: session),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка с обложкой, описанием и CTA-кнопкой.
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Image.asset(
                'pics/image.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peter Mach',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mind Deep Relax',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202340),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Join the Community as we prepare over 33 days to relax and feel joy with the mind and happines session across the World.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow, size: 22),
                    label: const Text('Play Next Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0FA9A2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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

/// Простая модель данных для элемента списка сеансов.
class _Session {
  const _Session({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;
}

/// Виджет одного элемента в списке сеансов.
class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final _Session session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: session.accent.withOpacity(0.15),
            child: Icon(
              Icons.play_arrow_rounded,
              color: session.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202340),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

/// Экран профиля организатора мероприятий.
class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  static const Color _primary = Color(0xFF5265FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _ProfileAppBar(),
                    const SizedBox(height: 24),
                    const CircleAvatar(
                      radius: 52,
                      backgroundImage: AssetImage('pics/img.png'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Albert Flores',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Карточка с блоком статистики (Followers/Following/Events).
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _StatTile(label: 'Followers', value: '2.368'),
                          _VerticalDivider(),
                          _StatTile(label: 'Following', value: '346'),
                          _VerticalDivider(),
                          _StatTile(label: 'Events', value: '13'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Пара CTA-кнопок: Follow и Messages.
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Follow'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                side: const BorderSide(
                                    color: _primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Messages'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Переключатели вкладок (активен About).
                    Row(
                      children: const [
                        Expanded(
                          child: _SegmentButton(
                            label: 'About',
                            selected: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _SegmentButton(
                            label: 'Events',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _SegmentButton(
                            label: 'Reviews',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'About',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Основной текст блока About.
                    const Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
                      'eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut '
                      'enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut.',
                      style: TextStyle(
                        color: Color(0xFF6C6D7A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Ссылка для раскрытия описания.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Read more...',
                          style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Верхняя панель профиля с кнопкой «назад» и меню.
class _ProfileAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () {},
        ),
        const Text(
          'Organizer',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        _RoundButton(
          icon: Icons.more_horiz,
          onPressed: () {},
        ),
      ],
    );
  }
}

/// Скругленная кнопка с тенью, использующаяся в `AppBar`.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF9AA1FF)),
      ),
    );
  }
}

/// Блок с числом и подписью (Followers, Following, Events).
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A8D9F),
          ),
        ),
      ],
    );
  }
}

/// Тонкая разделительная линия между блоками статистики.
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: const Color(0xFFE6E8F4),
    );
  }
}

/// Переключатель вкладок “About / Events / Reviews”.
class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEBEDFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: selected ? _ProfileScreen._primary : const Color(0xFFD6DAF2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _ProfileScreen._primary : const Color(0xFF8A8D9F),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Экран приветствия приложения Medinow с кнопками входа.
class _MedinowScreen extends StatelessWidget {
  const _MedinowScreen();

  static const Color _primary = Color(0xFF00A79F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                'medinow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Meditate With Us!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 42),
              _MedinowButton(
                label: 'Sign in with Apple',
                textColor: Colors.black,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 16),
              _MedinowButton(
                label: 'Continue with Email or Phone',
                textColor: Colors.black,
                backgroundColor: const Color(0xFF95E1DB),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Continue With Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const Spacer(),
              Image.asset(
                'pics/image copy.png',
                fit: BoxFit.contain,
                height: 220,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Унифицированная кнопка для варианта входа на экране Medinow.
class _MedinowButton extends StatelessWidget {
  const _MedinowButton({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
