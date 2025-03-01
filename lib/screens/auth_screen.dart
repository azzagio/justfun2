import 'package:flutter/material.dart';
import 'package:simple_dating_app/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String _gender = 'male';
  String _lookingFor = 'female';

  final AuthService _authService = AuthService();

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        List<String>? lookingForList = _lookingFor == 'both'
            ? ['male', 'female']
            : _lookingFor != null ? [_lookingFor] : null;
        await _authService.registerWithEmail(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
          int.parse(_ageController.text),
          _gender,
          lookingForList,
        );
      }
    } catch (e) {
      if (mounted) { // Vérification mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.favorite,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              _isLogin ? 'Welcome Back!' : 'Create an Account',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        int? age = int.tryParse(value);
                        if (age == null || age < 18) {
                          return 'You must be at least 18 years old';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('I am a:'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'male',
                          groupValue: _gender,
                          onChanged: (value) => setState(() => _gender = value!),
                        ),
                        const Text('Male'),
                        Radio<String>(
                          value: 'female',
                          groupValue: _gender,
                          onChanged: (value) => setState(() => _gender = value!),
                        ),
                        const Text('Female'),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Looking for:'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'male',
                          groupValue: _lookingFor,
                          onChanged: (value) => setState(() => _lookingFor = value!),
                        ),
                        const Text('Male'),
                        Radio<String>(
                          value: 'female',
                          groupValue: _lookingFor,
                          onChanged: (value) => setState(() => _lookingFor = value!),
                        ),
                        const Text('Female'),
                        Radio<String>(
                          value: 'both',
                          groupValue: _lookingFor,
                          onChanged: (value) => setState(() => _lookingFor = value!),
                        ),
                        const Text('Both'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!_isLogin && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isLogin ? 'Login' : 'Register'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin
                        ? 'Don\'t have an account? Register'
                        : 'Already have an account? Login'),
                  ),
                  const SizedBox(height: 16),
                  const Text('- OR -'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                await _authService.signInWithGoogle();
                              } catch (e) {
                                if (mounted) { // Vérification mounted
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}