import 'package:crack/screens/inventory_screen.dart';
import 'package:crack/screens/dashboard_screen.dart';
import 'package:crack/screens/login_screen.dart';
import 'package:crack/services/auth_api_service.dart';
import 'package:crack/services/inventory_api_service.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.administratorName});
  final String administratorName;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entrance = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openInventory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryScreen(service: InventoryApiService()),
      ),
    );
  }

  void _openDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  Future<void> _logout() async {
    await AuthApiService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/welcome-industrial-ai.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .38, .72, 1],
                colors: [
                  Color(0xC9000000),
                  Color(0x8F000000),
                  Color(0xB8000000),
                  Color(0xF5000000),
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xE6000000), Color(0x3D000000)],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 42,
                  ),
                  child: FadeTransition(
                    opacity: _entrance,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .06),
                        end: Offset.zero,
                      ).animate(_entrance),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AdminBar(
                            name: widget.administratorName,
                            onLogout: _logout,
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 700 ? 100 : 42,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF45B0B),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x663D1500),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'CONTROL INDUSTRIAL  ·  ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'BIENVENIDO A',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'EL MUNDO\nDEL PERNO',
                            style: TextStyle(
                              color: Colors.white,
                              height: .93,
                              fontSize: 47,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.5,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 54,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF45B0B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'PERNOS  ·  MAQUINARIA  ·  AUTOMOTRIZ',
                                style: TextStyle(
                                  color: Color(0xFFFFB27C),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: const Text(
                              'Gestiona precios, existencias y alertas de almacén desde una sola herramienta.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              _Capability(
                                icon: Icons.inventory_2_outlined,
                                label: 'Stock en vivo',
                              ),
                              _Capability(
                                icon: Icons.sell_outlined,
                                label: 'Editar precios',
                              ),
                              _Capability(
                                icon: Icons.warning_amber_rounded,
                                label: 'Alertas',
                              ),
                            ],
                          ),
                          const SizedBox(height: 38),
                          FilledButton.icon(
                            onPressed: _openDashboard,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: const Color(0xFFF45B0B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0x99501C00),
                            ),
                            icon: const Icon(Icons.dashboard_outlined),
                            label: const Text(
                              'ABRIR DASHBOARD ADMINISTRATIVO',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: .4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _openInventory,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                            ),
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('ABRIR INVENTARIO'),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: Colors.white54,
                                size: 17,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Sesión administrativa protegida',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBar extends StatelessWidget {
  const _AdminBar({required this.name, required this.onLogout});
  final String name;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .48),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: Color(0xFFFFA65A),
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hola, $name',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 9),
      IconButton.filled(
        onPressed: onLogout,
        tooltip: 'Cerrar sesión',
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFFDE0D4),
          foregroundColor: const Color(0xFF55210D),
        ),
        icon: const Icon(Icons.logout_rounded),
      ),
    ],
  );
}

class _Capability extends StatelessWidget {
  const _Capability({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .46),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFF8A3D), size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
