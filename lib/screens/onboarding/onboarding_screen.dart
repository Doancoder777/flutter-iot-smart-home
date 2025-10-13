import 'package:flutter/material.dart';
import 'widgets/onboarding_page.dart';

/// Màn hình giới thiệu ứng dụng lần đầu
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Chào mừng đến với Smart Home',
      'description':
          'Điều khiển nhà thông minh của bạn một cách dễ dàng và tiện lợi',
      'image': 'welcome',
      'color': Colors.blue,
    },
    {
      'title': 'Giám sát cảm biến',
      'description':
          'Theo dõi nhiệt độ, độ ẩm, chất lượng không khí và nhiều hơn nữa',
      'image': 'sensors',
      'color': Colors.green,
    },
    {
      'title': 'Điều khiển thiết bị',
      'description': 'Bật/tắt thiết bị từ xa, điều chỉnh servo và tự động hóa',
      'image': 'devices',
      'color': Colors.orange,
    },
    {
      'title': 'Tự động hóa thông minh',
      'description': 'Tạo quy tắc tự động để nhà bạn hoạt động thông minh hơn',
      'image': 'automation',
      'color': Colors.purple,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _handleSkip,
                child: const Text('Bỏ qua', style: TextStyle(fontSize: 16)),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return OnboardingPage(
                    title: page['title'],
                    description: page['description'],
                    imagePath: page['image'],
                    backgroundColor: page['color'],
                  );
                },
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index),
              ),
            ),
            const SizedBox(height: 40),

            // Next/Done button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Bắt đầu' : 'Tiếp theo',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _pages[_currentPage]['color']
            : Colors.grey[400],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _handleNext() {
    if (_currentPage == _pages.length - 1) {
      _handleDone();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleSkip() {
    _handleDone();
  }

  void _handleDone() {
    // Lưu trạng thái đã xem onboarding
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
