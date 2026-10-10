import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../providers/session_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _name;
  late TextEditingController _phone;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionProvider>().currentUser;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img == null) return;
    final session = context.read<SessionProvider>();
    final user = session.currentUser!;
    final updated = user.copyWith(profileImage: img.path);
    await DBHelper.instance.updateUser(updated);
    session.refreshUser(updated);
  }

  Future<void> _save() async {
    final session = context.read<SessionProvider>();
    final user = session.currentUser!;
    final updated = user.copyWith(name: _name.text.trim(), phone: _phone.text.trim());
    await DBHelper.instance.updateUser(updated);
    session.refreshUser(updated);
    setState(() => _editing = false);
  }

  Future<void> _showChangePassword() async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            AppTextField(controller: controller, label: 'New password', icon: Icons.lock_reset_rounded, obscure: true),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Update',
              onTap: () async {
                if (controller.text.length < 6) return;
                final session = context.read<SessionProvider>();
                await DBHelper.instance.updatePassword(session.currentUser!.id!, controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final user = session.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close_rounded : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: (user?.profileImage != null) ? null : null,
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'P',
                      style: const TextStyle(fontSize: 34, color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_editing) ...[
            AppTextField(controller: _name, label: 'Full name', icon: Icons.person_outline_rounded),
            const SizedBox(height: 14),
            AppTextField(controller: _phone, label: 'Phone', icon: Icons.phone_outlined),
            const SizedBox(height: 20),
            GradientButton(label: 'Save Changes', icon: Icons.check_rounded, onTap: _save),
          ] else ...[
            SoftCard(
              child: Column(
                children: [
                  _infoRow(Icons.person_outline_rounded, 'Name', user?.name ?? '-'),
                  const Divider(height: 24),
                  _infoRow(Icons.mail_outline_rounded, 'Email', user?.email ?? '-'),
                  const Divider(height: 24),
                  _infoRow(Icons.phone_outlined, 'Phone', user?.phone ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              onTap: _showChangePassword,
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                  SizedBox(width: 14),
                  Expanded(child: Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600))),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              onTap: () async {
                await session.logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                }
              },
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.danger),
                  SizedBox(width: 14),
                  Expanded(child: Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
