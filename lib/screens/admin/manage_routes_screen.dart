import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});
  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  List<BusRoute> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final routes = await DBHelper.instance.getRoutes();
    setState(() {
      _routes = routes;
      _loading = false;
    });
  }

  Future<void> _openForm({BusRoute? route}) async {
    final sourceCtrl = TextEditingController(text: route?.source ?? '');
    final destCtrl = TextEditingController(text: route?.destination ?? '');
    final stopsCtrl = TextEditingController(text: route?.stops ?? '');
    final distanceCtrl = TextEditingController(text: route?.distanceKm.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(route == null ? 'Create Route' : 'Edit Route',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              AppTextField(controller: sourceCtrl, label: 'Source', icon: Icons.trip_origin_rounded),
              const SizedBox(height: 12),
              AppTextField(controller: destCtrl, label: 'Destination', icon: Icons.flag_outlined),
              const SizedBox(height: 12),
              AppTextField(controller: stopsCtrl, label: 'Stops (comma separated)', icon: Icons.pin_drop_outlined),
              const SizedBox(height: 12),
              AppTextField(controller: distanceCtrl, label: 'Distance (km)', icon: Icons.straighten_rounded,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              GradientButton(
                label: route == null ? 'Create Route' : 'Save Changes',
                icon: Icons.check_rounded,
                onTap: () async {
                  final distance = double.tryParse(distanceCtrl.text.trim()) ?? 0;
                  if (sourceCtrl.text.trim().isEmpty || destCtrl.text.trim().isEmpty) return;
                  if (route == null) {
                    await DBHelper.instance.addRoute(BusRoute(
                      source: sourceCtrl.text.trim(),
                      destination: destCtrl.text.trim(),
                      stops: stopsCtrl.text.trim(),
                      distanceKm: distance,
                    ));
                  } else {
                    await DBHelper.instance.updateRoute(BusRoute(
                      id: route.id,
                      source: sourceCtrl.text.trim(),
                      destination: destCtrl.text.trim(),
                      stops: stopsCtrl.text.trim(),
                      distanceKm: distance,
                    ));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BusRoute route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Remove ${route.source} → ${route.destination}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.instance.deleteRoute(route.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Routes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Route'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? const EmptyState(icon: Icons.alt_route_rounded, title: 'No routes', subtitle: 'Create your first route.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: _routes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = _routes[i];
                    return SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const IconBadge(icon: Icons.alt_route_rounded, gradient: AppColors.amberGradient),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${r.source} → ${r.destination}',
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('${r.distanceKm.toStringAsFixed(1)} km',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(onPressed: () => _openForm(route: r), icon: const Icon(Icons.edit_outlined, size: 20)),
                              IconButton(onPressed: () => _delete(r), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: r.stopList.map((s) => StatusChip(label: s, color: AppColors.primary)).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
