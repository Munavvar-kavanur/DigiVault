import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../providers/password_provider.dart';
import '../providers/theme_provider.dart';
import '../services/google_sheets_service.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _categoryController = TextEditingController();

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      Provider.of<PasswordProvider>(
        context,
        listen: false,
      ).addCategory(_categoryController.text);
      _categoryController.clear();
    }
  }

  void _deleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$category"?'),
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
              ).deleteCategory(category);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, String oldCategory) {
    final controller = TextEditingController(text: oldCategory);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<PasswordProvider>(
                  context,
                  listen: false,
                ).updateCategory(oldCategory, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGoogleSheetsDialog(BuildContext context) {
    final provider = Provider.of<PasswordProvider>(context, listen: false);
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Sheets Sync'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Create a new Google Sheet.\n'
                  '2. Go to Extensions > Apps Script.\n'
                  '3. Paste the code below and Save.\n'
                  '4. Deploy as Web App (Execute as: Me, Access: Anyone).\n'
                  '5. Paste the Web App URL below.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Show code dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Apps Script Code'),
                        content: SingleChildScrollView(
                          child: SelectableText(
                            GoogleSheetsService.scriptCode,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: GoogleSheetsService.scriptCode,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copied to clipboard'),
                                ),
                              );
                            },
                            child: const Text('Copy Code'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.code),
                  label: const Text('View Script Code'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Web App URL',
                    hintText: 'https://script.google.com/...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    if (urlController.text.isEmpty) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Testing connection...')),
                    );

                    final result = await GoogleSheetsService().testConnection(
                      urlController.text,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                      if (result['success'] == true) {
                        final version = result['version'] as String;
                        if (version == '2.0') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connection Successful! (v2.0)'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Script Update Required'),
                              content: Text(
                                'Connected, but script version is old (v$version).\n\n'
                                'Please update your Apps Script code to the latest version (v2.0) to enable saving data.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Connection Failed'),
                            content: Text(
                              'Could not connect to the script.\n\n'
                              'Error: ${result['message']}\n\n'
                              'Possible reasons:\n'
                              '1. URL is incorrect (should end in /exec)\n'
                              '2. Script not deployed as "Web App"\n'
                              '3. "Who has access" is not set to "Anyone"\n'
                              '4. You are testing on Web (CORS issue) - try "Sync Now" instead.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.wifi),
                  label: const Text('Test Connection'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                provider.setSheetsUrl(urlController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuration saved. Syncing...'),
                  ),
                );
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final passwordProvider = Provider.of<PasswordProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Toggler
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                      child: SwitchListTile(
                        title: const Text(
                          'Dark Mode',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode
                                ? LucideIcons.moon
                                : LucideIcons.sun,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Security Section
                    Text(
                      'Security',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).cardTheme.color,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                LucideIcons.lock,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: const Text(
                              'Change PIN',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(LucideIcons.chevronRight),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PinScreen(mode: PinMode.change),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.1),
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: const Icon(
                                LucideIcons.sheet,
                                color: Colors.green,
                              ),
                            ),
                            title: const Text(
                              'Google Sheets Sync',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  passwordProvider.isCloudSyncEnabled
                                      ? 'Connected'
                                      : 'Not Configured',
                                  style: TextStyle(
                                    color: passwordProvider.isCloudSyncEnabled
                                        ? Colors.green
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                if (passwordProvider.isCloudSyncEnabled &&
                                    passwordProvider.lastSyncTime != null)
                                  Text(
                                    'Last synced: ${DateTime.now().difference(passwordProvider.lastSyncTime!).inMinutes} mins ago',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (passwordProvider.isCloudSyncEnabled) ...[
                                  IconButton(
                                    icon: const Icon(LucideIcons.refreshCw),
                                    tooltip: 'Sync Now',
                                    onPressed: () async {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Syncing...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                      await passwordProvider.syncNow();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.externalLink),
                                    tooltip: 'Edit Google Sheet Data',
                                    onPressed: () {
                                      passwordProvider.openSheet();
                                    },
                                  ),
                                ],
                                const Icon(LucideIcons.chevronRight),
                              ],
                            ),
                            onTap: () => _showGoogleSheetsDialog(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Manage Categories Section
                    Text(
                      'Manage Categories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _categoryController,
                            decoration: InputDecoration(
                              labelText: 'New Category',
                              hintText: 'e.g. Work',
                              prefixIcon: const Icon(LucideIcons.plus),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardTheme.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _addCategory,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(LucideIcons.plus),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Categories List
            if (passwordProvider.categories.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.tag,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No categories added yet.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final category = passwordProvider.categories[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).cardTheme.color,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: Icon(
                            LucideIcons.tag,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                LucideIcons.edit3,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                _showEditCategoryDialog(context, category);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteCategory(category),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: passwordProvider.categories.length),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}
