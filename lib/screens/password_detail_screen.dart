import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/password_entry.dart';
import '../providers/password_provider.dart';
import 'add_edit_password_screen.dart';
import '../widgets/neon_background.dart';

class PasswordDetailScreen extends StatefulWidget {
  final PasswordEntry entry;

  const PasswordDetailScreen({super.key, required this.entry});

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _isPasswordVisible = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password'),
        content: const Text('Are you sure you want to delete this password?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<PasswordProvider>(
                context,
                listen: false,
              ).deleteEntry(widget.entry.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PasswordProvider>(context);
    final currentEntry = provider.entries.firstWhere(
      (e) => e.id == widget.entry.id,
      orElse: () => widget.entry,
    );

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditPasswordScreen(
                                    entry: currentEntry,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              color: Colors.red,
                            ),
                            onPressed: _deleteEntry,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors:
                                Theme.of(context).brightness == Brightness.dark
                                ? [
                                    Theme.of(context).cardTheme.color!,
                                    Theme.of(
                                      context,
                                    ).cardTheme.color!.withOpacity(0.8),
                                  ]
                                : [Colors.white, Colors.grey.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  currentEntry.title.isNotEmpty
                                      ? currentEntry.title[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentEntry.title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentEntry.username,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Theme.of(context).cardTheme.color,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailTile(
                              context,
                              icon: LucideIcons.user,
                              title: 'Username',
                              value: currentEntry.username,
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.1),
                            ),
                            _buildPasswordTile(context, currentEntry.password),
                            if (currentEntry.website != null &&
                                currentEntry.website!.isNotEmpty) ...[
                              Divider(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                              ),
                              _buildDetailTile(
                                context,
                                icon: LucideIcons.globe,
                                title: 'Website',
                                value: currentEntry.website!,
                              ),
                            ],
                            if (currentEntry.category != null &&
                                currentEntry.category!.isNotEmpty) ...[
                              Divider(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                              ),
                              _buildDetailTile(
                                context,
                                icon: LucideIcons.tag,
                                title: 'Category',
                                value: currentEntry.category!,
                              ),
                            ],
                            if (currentEntry.notes != null &&
                                currentEntry.notes!.isNotEmpty) ...[
                              Divider(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                              ),
                              _buildDetailTile(
                                context,
                                icon: LucideIcons.stickyNote,
                                title: 'Notes',
                                value: currentEntry.notes!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: IconButton(
        icon: const Icon(LucideIcons.copy, size: 20),
        onPressed: () => _copyToClipboard(value, title),
      ),
    );
  }

  Widget _buildPasswordTile(BuildContext context, String password) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          LucideIcons.lock,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: const Text(
        'Password',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        _isPasswordVisible ? password : '••••••••',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.copy, size: 20),
            onPressed: () => _copyToClipboard(password, 'Password'),
          ),
        ],
      ),
    );
  }
}
