import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/soul_button.dart';
import '../../../core/widgets/soul_text_field.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companionNameController = TextEditingController(text: 'Soulie');
  String _companionGender = 'female';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companionNameController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final companionName = _companionNameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an email or phone number')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).register(
          displayName: name,
          email: email.isNotEmpty ? email : null,
          phoneNumber: phone.isNotEmpty ? phone : null,
          password: password,
          companionName: companionName.isNotEmpty ? companionName : 'Soulie',
          companionGender: _companionGender,
        );

    if (success && mounted) {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Space'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Begin Your Journey',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Soulm8Theme.textLight,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us a little about you and your companion.',
                style: TextStyle(fontSize: 14, color: Soulm8Theme.textMuted),
              ),
              const SizedBox(height: 24),

              if (authState.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              SoulTextField(
                controller: _nameController,
                hintText: 'Your nickname or name',
                labelText: 'Your Name',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              SoulTextField(
                controller: _phoneController,
                hintText: 'e.g. 9876543210',
                labelText: 'Mobile Number (For friends to find you)',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              SoulTextField(
                controller: _emailController,
                hintText: 'e.g. you@example.com',
                labelText: 'Email Address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              SoulTextField(
                controller: _passwordController,
                hintText: 'At least 6 characters',
                labelText: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Soulm8Theme.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Companion Setup Section
              const Divider(color: Colors.white12, height: 32),
              const Text(
                'AI Companion Customization',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Soulm8Theme.softPeach,
                ),
              ),
              const SizedBox(height: 12),
              SoulTextField(
                controller: _companionNameController,
                hintText: 'Name your companion (default: Soulie)',
                labelText: 'Companion Name',
                prefixIcon: Icons.favorite_border,
              ),
              const SizedBox(height: 16),
              const Text(
                'Companion Persona Gender',
                style: TextStyle(
                  color: Soulm8Theme.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _genderChoiceChip('Female', 'female'),
                  const SizedBox(width: 12),
                  _genderChoiceChip('Male', 'male'),
                ],
              ),
              const SizedBox(height: 32),

              SoulButton(
                text: 'Create My Sanctuary',
                isLoading: authState.isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderChoiceChip(String label, String value) {
    final isSelected = _companionGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _companionGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Soulm8Theme.primaryRose.withOpacity(0.2)
                : Soulm8Theme.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Soulm8Theme.primaryRose : Colors.white12,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Soulm8Theme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
