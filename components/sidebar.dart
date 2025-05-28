import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_provider.dart';
import '../navigation/sidebar_provider.dart';
import '../providers/expense_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = context.watch<SidebarProvider>().width;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(1, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildUserSection(context),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMainNavigation(context),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),
                  _buildAdditionalNavigation(context),
                ],
              ),
            ),
          ),
          _buildLogout(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/storm.jpg'),
            backgroundColor: Colors.transparent,
          ),
          SizedBox(width: 12),
          Text(
            'Storm Saver',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A73E8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    final companyName = context.watch<ExpenseProvider>().companyName;
    final companyAddress = context.watch<ExpenseProvider>().companyAddress;
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A73E8),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        children: const [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFF1A73E8), size: 40),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Josh Nimo',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Text(
                            'Administrator',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.business, color: Color(0xFF1A73E8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  companyName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  companyAddress,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '+63 912 345 6789',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.email, color: Colors.deepOrange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'josh.nimo@email.com',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF1A73E8),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                  ),
                  const Text(
                    'Josh Nimo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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

  Widget _buildMainNavigation(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    return Column(
      children: [
        _NavMenuItem(
          title: 'Dashboard',
          icon: Icons.dashboard,
          isSelected: navigation.currentIndex == NavigationProvider.dashboard,
          onTap: () => navigation.setIndex(NavigationProvider.dashboard),
        ),
        _NavMenuItem(
          title: 'Reports',
          icon: Icons.bar_chart,
          isSelected: navigation.currentIndex == NavigationProvider.reports,
          onTap: () => navigation.setIndex(NavigationProvider.reports),
        ),
        _NavMenuItem(
          title: 'Expenses',
          icon: Icons.receipt_long,
          isSelected: navigation.currentIndex == NavigationProvider.expenses,
          onTap: () => navigation.setIndex(NavigationProvider.expenses),
        ),
        _NavMenuItem(
          title: 'Approvals',
          icon: Icons.check_circle_outline,
          isSelected: navigation.currentIndex == NavigationProvider.approvals,
          onTap: () => navigation.setIndex(NavigationProvider.approvals),
        ),
      ],
    );
  }

  Widget _buildAdditionalNavigation(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    return Column(
      children: [
        _NavMenuItem(
          title: 'Settings',
          icon: Icons.settings,
          isSelected: navigation.currentIndex == NavigationProvider.settings,
          onTap: () => navigation.setIndex(NavigationProvider.settings),
        ),
      ],
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _NavMenuItem(
        title: 'Logout',
        icon: Icons.logout,
        onTap: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
      ),
    );
  }
}

class _NavMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? badge;

  const _NavMenuItem({
    Key? key,
    required this.title,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1A73E8).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 