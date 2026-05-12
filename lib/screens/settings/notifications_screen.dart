import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _emailEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Preferencias de notificaciones',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFF3F4F6), // gray-100
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Notificaciones push
            _buildSectionHeader('Notificaciones push'),
            const SizedBox(height: 24),
            _buildSwitchItem(
              title: 'Me gusta',
              value: _likesEnabled,
              onChanged: (val) => setState(() => _likesEnabled = val),
            ),
            const SizedBox(height: 24),
            _buildSwitchItem(
              title: 'Comentarios',
              value: _commentsEnabled,
              onChanged: (val) => setState(() => _commentsEnabled = val),
            ),
            
            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF3F4F6), height: 1), // gray-100
            const SizedBox(height: 32),
            
            // Section: Correo electrónico
            _buildSectionHeader('Correo electrónico'),
            const SizedBox(height: 24),
            _buildSwitchItem(
              title: 'Anuncios de la universidad',
              value: _emailEnabled,
              onChanged: (val) => setState(() => _emailEnabled = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Color(0xFF6B7280), // gray-500
      ),
    );
  }

  Widget _buildSwitchItem({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: Colors.black,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE5E7EB), // gray-200
        ),
      ],
    );
  }
}
