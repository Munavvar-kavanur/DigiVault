import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'main_screen.dart';

enum PinMode { setup, verify, change }

class PinScreen extends StatefulWidget {
  final PinMode mode;

  const PinScreen({super.key, required this.mode});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _storage = const FlutterSecureStorage();
  String _currentPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _message = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _updateMessage();
  }

  void _updateMessage() {
    setState(() {
      _isError = false;
      switch (widget.mode) {
        case PinMode.setup:
          _message = _isConfirming
              ? 'Confirm your PIN'
              : 'Create a 4-digit PIN';
          break;
        case PinMode.verify:
          _message = 'Enter your PIN';
          break;
        case PinMode.change:
          _message = _isConfirming ? 'Confirm new PIN' : 'Enter new PIN';
          break;
      }
    });
  }

  void _onNumberPressed(String number) {
    if (_currentPin.length < 4) {
      setState(() {
        _currentPin += number;
        _isError = false;
      });

      if (_currentPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDeletePressed() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _handlePinComplete() async {
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 200));

    switch (widget.mode) {
      case PinMode.setup:
      case PinMode.change:
        if (!_isConfirming) {
          setState(() {
            _confirmPin = _currentPin;
            _currentPin = '';
            _isConfirming = true;
            _updateMessage();
          });
        } else {
          if (_currentPin == _confirmPin) {
            await _storage.write(key: 'user_pin', value: _currentPin);
            if (!mounted) return;

            if (widget.mode == PinMode.setup) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            } else {
              Navigator.pop(context); // Return to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN updated successfully')),
              );
            }
          } else {
            _showError('PINs do not match. Try again.');
            _resetSetup();
          }
        }
        break;

      case PinMode.verify:
        final storedPin = await _storage.read(key: 'user_pin');
        if (_currentPin == storedPin) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          _showError('Incorrect PIN');
          setState(() {
            _currentPin = '';
          });
        }
        break;
    }
  }

  void _resetSetup() {
    setState(() {
      _currentPin = '';
      _confirmPin = '';
      _isConfirming = false;
      _updateMessage();
    });
  }

  void _showError(String error) {
    setState(() {
      _message = error;
      _isError = true;
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(
              LucideIcons.lock,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isError ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _currentPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (_isError
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary)
                        : Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                );
              }),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildKey('1'), _buildKey('2'), _buildKey('3')],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildKey('4'), _buildKey('5'), _buildKey('6')],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildKey('7'), _buildKey('8'), _buildKey('9')],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 80), // Empty space for alignment
                      _buildKey('0'),
                      _buildDeleteKey(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return InkWell(
      onTap: _onDeletePressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: const Icon(LucideIcons.delete, size: 28),
      ),
    );
  }
}
