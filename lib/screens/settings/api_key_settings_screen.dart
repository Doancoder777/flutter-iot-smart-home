import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Màn hình cài đặt API Key cho Gemini AI
class ApiKeySettingsScreen extends StatefulWidget {
  const ApiKeySettingsScreen({Key? key}) : super(key: key);

  @override
  State<ApiKeySettingsScreen> createState() => _ApiKeySettingsScreenState();
}

class _ApiKeySettingsScreenState extends State<ApiKeySettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('gemini_api_key');
      if (savedKey != null) {
        _apiKeyController.text = savedKey;
      }
    } catch (e) {
      print('Error loading API key: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();

    if (key.isEmpty) {
      _showMessage('Vui lòng nhập API key', isError: true);
      return;
    }

    if (!key.startsWith('AIza')) {
      _showMessage(
        'API key không hợp lệ (phải bắt đầu bằng "AIza")',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', key);
      _showMessage('✅ Đã lưu API key thành công!');

      // Delay before going back
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      _showMessage('❌ Lỗi lưu API key: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _testApiKey() async {
    final key = _apiKeyController.text.trim();

    if (key.isEmpty) {
      _showMessage('Vui lòng nhập API key trước', isError: true);
      return;
    }

    _showMessage('🔍 Đang kiểm tra API key...', duration: 2);

    // Simple validation
    if (key.startsWith('AIza') && key.length > 30) {
      _showMessage('✅ API key hợp lệ!');
    } else {
      _showMessage('❌ API key không đúng định dạng', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false, int duration = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt API Key'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Gemini API Key',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'API key này được sử dụng cho tính năng điều khiển bằng giọng nói với Gemini AI.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '🔗 Lấy API key miễn phí tại:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              // Open URL (you can add url_launcher package)
                              _showMessage(
                                '📋 Copy link: https://aistudio.google.com/app/apikey',
                              );
                            },
                            child: Text(
                              'https://aistudio.google.com/app/apikey',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // API Key input
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_showKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'AIzaSy...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _showKey = !_showKey);
                        },
                      ),
                    ),
                    maxLines: _showKey ? 3 : 1,
                  ),
                  const SizedBox(height: 16),

                  // Test button
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _testApiKey,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Kiểm tra API key'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Save button
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveApiKey,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Đang lưu...' : 'Lưu API Key'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📝 Hướng dẫn lấy API Key:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStep(
                            '1',
                            'Truy cập https://aistudio.google.com/app/apikey',
                          ),
                          _buildStep('2', 'Đăng nhập tài khoản Google'),
                          _buildStep('3', 'Click "Create API key"'),
                          _buildStep('4', 'Copy API key và paste vào ô trên'),
                          _buildStep('5', 'Click "Lưu API Key"'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Warning
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lưu ý bảo mật',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Không chia sẻ API key với người khác. API key được lưu an toàn trên thiết bị của bạn.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
