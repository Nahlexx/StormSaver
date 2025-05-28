import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/navigation_provider.dart';
import '../providers/expense_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _loadError;
  String _selectedMenuItem = 'General';
  bool _requireReceipts = true;
  bool _autoApprove = false;
  double _autoApproveThreshold = 1000.0;
  bool _notifySubmitted = true;
  bool _notifyApproved = true;
  bool _notifyRejected = true;
  String _selectedCurrency = 'PHP - Philippine Peso';
  String _selectedFiscalYear = 'January';
  final _thresholdController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _focusNode = FocusNode();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPasswordController = TextEditingController();
  final _companyContactController = TextEditingController();
  final _companyEmailController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _loadError = error.toString();
        });
      }
    });
    _thresholdController.text = _autoApproveThreshold.toString();
    // Load company info from provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ExpenseProvider>();
      await provider.loadCompanyInfo();
      _companyNameController.text = provider.companyName;
      _companyAddressController.text = provider.companyAddress;
      _companyContactController.text = provider.companyContact;
      _companyEmailController.text = provider.companyEmail;
    });
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _taxIdController.dispose();
    _focusNode.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyContactController.dispose();
    _companyEmailController.dispose();
    _companyPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _requireReceipts = prefs.getBool('requireReceipts') ?? true;
        _autoApprove = prefs.getBool('autoApprove') ?? false;
        _autoApproveThreshold = prefs.getDouble('autoApproveThreshold') ?? 1000.0;
        _notifySubmitted = prefs.getBool('notifySubmitted') ?? true;
        _notifyApproved = prefs.getBool('notifyApproved') ?? true;
        _notifyRejected = prefs.getBool('notifyRejected') ?? true;
        _selectedCurrency = prefs.getString('selectedCurrency') ?? 'PHP - Philippine Peso';
        _selectedFiscalYear = prefs.getString('selectedFiscalYear') ?? 'January';
        _thresholdController.text = _autoApproveThreshold.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading settings: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('requireReceipts', _requireReceipts);
      await prefs.setBool('autoApprove', _autoApprove);
      await prefs.setDouble('autoApproveThreshold', _autoApproveThreshold);
      await prefs.setBool('notifySubmitted', _notifySubmitted);
      await prefs.setBool('notifyApproved', _notifyApproved);
      await prefs.setBool('notifyRejected', _notifyRejected);
      await prefs.setString('selectedCurrency', _selectedCurrency);
      await prefs.setString('selectedFiscalYear', _selectedFiscalYear);
    } catch (e) {
      throw Exception('Failed to save settings: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _loadError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isInitialLoading = true;
                  _loadError = null;
                });
                _loadSettings().then((_) {
                  if (mounted) {
                    setState(() => _isInitialLoading = false);
                  }
                }).catchError((error) {
                  if (mounted) {
                    setState(() {
                      _isInitialLoading = false;
                      _loadError = error.toString();
                    });
                  }
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: _buildSettingsContent(),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              'Company Information',
              [
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  enabled: _showPassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyAddressController,
                  decoration: const InputDecoration(labelText: 'Company Address'),
                  enabled: _showPassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyContactController,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  enabled: _showPassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyEmailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: _showPassword,
                ),
                const SizedBox(height: 12),
                if (_showPassword) ...[
                  TextFormField(
                    controller: _companyPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_companyPasswordController.text == 'admin123') {
                        final newName = _companyNameController.text.trim();
                        final newAddress = _companyAddressController.text.trim();
                        final newContact = _companyContactController.text.trim();
                        final newEmail = _companyEmailController.text.trim();
                        if (newName.isNotEmpty && newAddress.isNotEmpty && newContact.isNotEmpty && newEmail.isNotEmpty) {
                          await context.read<ExpenseProvider>().setCompanyInfo(newName, newAddress, newContact, newEmail);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Company info updated!'), backgroundColor: Colors.green),
                          );
                          setState(() { _showPassword = false; _companyPasswordController.clear(); });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.red),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Incorrect password.'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('Save Company Info'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() { _showPassword = false; _companyPasswordController.clear(); });
                    },
                    child: const Text('Cancel'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      setState(() { _showPassword = true; });
                    },
                    child: const Text('Change Company Info'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            _buildSettingsSection(
              'Expense Settings',
              [
                _buildDropdownField(
                  'Default Currency',
                  _selectedCurrency,
                  ['PHP - Philippine Peso', 'USD - US Dollar', 'EUR - Euro'],
                  onChanged: (value) => setState(() => _selectedCurrency = value!),
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  'Fiscal Year Start',
                  _selectedFiscalYear,
                  ['January', 'April', 'July', 'October'],
                  onChanged: (value) => setState(() => _selectedFiscalYear = value!),
                ),
                const SizedBox(height: 16),
                _buildSwitchField(
                  'Require Receipts for Expenses',
                  'Employees must attach receipts for all expenses',
                  _requireReceipts,
                  onChanged: (value) => setState(() => _requireReceipts = value),
                ),
                const SizedBox(height: 16),
                _buildSwitchField(
                  'Auto-approve Expenses Below Threshold',
                  'Automatically approve expenses below the threshold',
                  _autoApprove,
                  onChanged: (value) => setState(() => _autoApprove = value),
                ),
                if (_autoApprove) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Auto-approve Threshold',
                    _autoApproveThreshold.toString(),
                    controller: _thresholdController,
                    keyboardType: TextInputType.number,
                    prefixText: _selectedCurrency.split(' - ')[0] + ' ',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Threshold amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final amount = double.tryParse(value);
                      if (amount != null) {
                        setState(() => _autoApproveThreshold = amount);
                      }
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            _buildSettingsSection(
              'Email Notifications',
              [
                _buildSwitchField(
                  'Expense Submitted',
                  'Notify when an expense report is submitted',
                  _notifySubmitted,
                  onChanged: (value) => setState(() => _notifySubmitted = value),
                ),
                const SizedBox(height: 16),
                _buildSwitchField(
                  'Expense Approved',
                  'Notify when an expense is approved',
                  _notifyApproved,
                  onChanged: (value) => setState(() => _notifyApproved = value),
                ),
                const SizedBox(height: 16),
                _buildSwitchField(
                  'Expense Rejected',
                  'Notify when an expense is rejected',
                  _notifyRejected,
                  onChanged: (value) => setState(() => _notifyRejected = value),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _isLoading ? null : _resetChanges,
                  child: const Text('Reset to Defaults'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _saveSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _resetChanges() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text('Are you sure you want to reset all settings to their default values?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _requireReceipts = true;
        _autoApprove = false;
        _autoApproveThreshold = 1000.0;
        _notifySubmitted = true;
        _notifyApproved = true;
        _notifyRejected = true;
        _selectedCurrency = 'PHP - Philippine Peso';
        _selectedFiscalYear = 'January';
        _thresholdController.text = _autoApproveThreshold.toString();
      });
      _formKey.currentState?.reset();
    }
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String initialValue, {
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixText: prefixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items, {
    void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField(
    String label,
    String description,
    bool value, {
    void Function(bool)? onChanged,
  }) {
    return Tooltip(
      message: description,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
} 