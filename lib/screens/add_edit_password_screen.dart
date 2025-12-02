import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/password_entry.dart';
import '../providers/password_provider.dart';
import '../utils/password_generator.dart';
import '../widgets/neon_background.dart';

class AddEditPasswordScreen extends StatefulWidget {
  final PasswordEntry? entry;

  const AddEditPasswordScreen({super.key, this.entry});

  @override
  State<AddEditPasswordScreen> createState() => _AddEditPasswordScreenState();
}

class _AddEditPasswordScreenState extends State<AddEditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _websiteController;
  late TextEditingController _notesController;
  String? _selectedCategory;

  // Generator State
  bool _isGeneratorExpanded = false;
  double _generatorLength = 16;
  bool _useUppercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _usernameController = TextEditingController(
      text: widget.entry?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.entry?.password ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.entry?.website ?? '',
    );
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
    _selectedCategory = widget.entry?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<PasswordProvider>(context, listen: false);
      if (widget.entry == null) {
        provider.addEntry(
          _titleController.text,
          _usernameController.text,
          _passwordController.text,
          _websiteController.text.isEmpty ? null : _websiteController.text,
          _selectedCategory,
          _notesController.text.isEmpty ? null : _notesController.text,
        );
      } else {
        final updatedEntry = PasswordEntry(
          id: widget.entry!.id,
          title: _titleController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          website: _websiteController.text.isEmpty
              ? null
              : _websiteController.text,
          category: _selectedCategory,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        provider.updateEntry(updatedEntry);
      }
      Navigator.pop(context);
    }
  }

  void _generatePassword() {
    final newPassword = PasswordGenerator.generate(
      length: _generatorLength.toInt(),
      useUppercase: _useUppercase,
      useNumbers: _useNumbers,
      useSymbols: _useSymbols,
    );
    _passwordController.text = newPassword;
  }

  void _copyPassword() {
    if (_passwordController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _passwordController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.2),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        widget.entry == null ? 'Add Password' : 'Edit Password',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Credentials Section
                        _buildSectionHeader(context, 'Credentials'),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF0F172A).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.08
                                        : 0.3,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _titleController,
                                    label: 'Title',
                                    hint: 'e.g. Google',
                                    icon: LucideIcons.type,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a title';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _usernameController,
                                    label: 'Username/Email',
                                    icon: LucideIcons.user,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a username';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: LucideIcons.lock,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      return null;
                                    },
                                  ),
                                  // Inline Password Generator
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: _isGeneratorExpanded
                                        ? Container(
                                            margin: const EdgeInsets.only(
                                              top: 16,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).dividerColor.withOpacity(0.1),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Generator',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                    ),
                                                    TextButton.icon(
                                                      onPressed:
                                                          _generatePassword,
                                                      icon: const Icon(
                                                        LucideIcons.refreshCw,
                                                        size: 14,
                                                      ),
                                                      label: const Text(
                                                        'Regenerate',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      style: TextButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        minimumSize: Size.zero,
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Length: ${_generatorLength.toInt()}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                    Expanded(
                                                      child: SliderTheme(
                                                        data:
                                                            SliderTheme.of(
                                                              context,
                                                            ).copyWith(
                                                              trackHeight: 2,
                                                              thumbShape:
                                                                  const RoundSliderThumbShape(
                                                                    enabledThumbRadius:
                                                                        6,
                                                                  ),
                                                            ),
                                                        child: Slider(
                                                          value:
                                                              _generatorLength,
                                                          min: 8,
                                                          max: 32,
                                                          divisions: 24,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              _generatorLength =
                                                                  value;
                                                              _generatePassword();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                _buildCompactSwitch(
                                                  'Uppercase',
                                                  _useUppercase,
                                                  (v) {
                                                    setState(() {
                                                      _useUppercase = v;
                                                      _generatePassword();
                                                    });
                                                  },
                                                ),
                                                _buildCompactSwitch(
                                                  'Numbers',
                                                  _useNumbers,
                                                  (v) {
                                                    setState(() {
                                                      _useNumbers = v;
                                                      _generatePassword();
                                                    });
                                                  },
                                                ),
                                                _buildCompactSwitch(
                                                  'Symbols',
                                                  _useSymbols,
                                                  (v) {
                                                    setState(() {
                                                      _useSymbols = v;
                                                      _generatePassword();
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Details Section
                        _buildSectionHeader(context, 'Details'),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF0F172A).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.08
                                        : 0.3,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _websiteController,
                                    label: 'Website',
                                    hint: 'https://example.com',
                                    icon: LucideIcons.globe,
                                    keyboardType: TextInputType.url,
                                  ),
                                  const SizedBox(height: 16),
                                  Consumer<PasswordProvider>(
                                    builder: (context, provider, child) {
                                      return DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        decoration: InputDecoration(
                                          labelText: 'Category',
                                          prefixIcon: const Icon(
                                            LucideIcons.tag,
                                            size: 20,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withOpacity(0.5),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 14,
                                              ),
                                        ),
                                        items:
                                            {
                                              ...provider.categories,
                                              if (_selectedCategory != null)
                                                _selectedCategory!,
                                            }.map((String category) {
                                              return DropdownMenuItem<String>(
                                                value: category,
                                                child: Text(category),
                                              );
                                            }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedCategory = newValue;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _notesController,
                                    label: 'Notes',
                                    icon: LucideIcons.stickyNote,
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.4),
                            ),
                            child: const Text(
                              'Save Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildCompactSwitch(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Transform.scale(
          scale: 0.8,
          child: Switch(value: value, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isPassword = false,
  }) {
    bool isObscured = isPassword;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: controller,
          obscureText: isObscured,
          style: isObscured && isPassword
              ? const TextStyle(
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )
              : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: isPassword
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.copy, size: 20),
                        tooltip: 'Copy Password',
                        onPressed: _copyPassword,
                      ),
                      IconButton(
                        icon: Icon(
                          _isGeneratorExpanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.wand2,
                          color: _isGeneratorExpanded
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          size: 20,
                        ),
                        tooltip: 'Generate Password',
                        onPressed: () {
                          this.setState(() {
                            _isGeneratorExpanded = !_isGeneratorExpanded;
                            if (_isGeneratorExpanded &&
                                controller.text.isEmpty) {
                              _generatePassword();
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isObscured ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            isObscured = !isObscured;
                          });
                        },
                      ),
                    ],
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            isDense: true,
          ),
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
        );
      },
    );
  }
}
