import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';

class ManageBusesScreen extends StatefulWidget {
  const ManageBusesScreen({super.key});
  @override
  State<ManageBusesScreen> createState() => _ManageBusesScreenState();
}

class _ManageBusesScreenState extends State<ManageBusesScreen> {
  List<Bus> _buses = [];
  List<BusRoute> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final buses = await DBHelper.instance.getBuses();
    final routes = await DBHelper.instance.getRoutes();
    setState(() {
      _buses = buses;
      _routes = routes;
      _loading = false;
    });
  }

  Future<void> _openForm({Bus? bus}) async {
    final numberCtrl = TextEditingController(text: bus?.busNumber ?? '');
    final nameCtrl = TextEditingController(text: bus?.busName ?? '');
    final driverCtrl = TextEditingController(text: bus?.driverName ?? '');
    int? routeId = bus?.routeId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bus == null ? 'Add Bus' : 'Edit Bus',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                AppTextField(controller: numberCtrl, label: 'Bus number', icon: Icons.confirmation_number_outlined),
                const SizedBox(height: 12),
                AppTextField(controller: nameCtrl, label: 'Bus name', icon: Icons.directions_bus_outlined),
                const SizedBox(height: 12),
                AppTextField(controller: driverCtrl, label: 'Driver name', icon: Icons.badge_outlined),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: routeId,
                  decoration: const InputDecoration(labelText: 'Assign route'),
                  items: _routes
                      .map((r) => DropdownMenuItem(value: r.id, child: Text('${r.source} → ${r.destination}')))
                      .toList(),
                  onChanged: (v) => setModalState(() => routeId = v),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: bus == null ? 'Add Bus' : 'Save Changes',
                  icon: Icons.check_rounded,
                  onTap: () async {
                    if (numberCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                    if (bus == null) {
                      await DBHelper.instance.addBus(Bus(
                        busNumber: numberCtrl.text.trim(),
                        busName: nameCtrl.text.trim(),
                        driverName: driverCtrl.text.trim(),
                        routeId: routeId,
                      ));
                    } else {
                      await DBHelper.instance.updateBus(Bus(
                        id: bus.id,
                        busNumber: numberCtrl.text.trim(),
                        busName: nameCtrl.text.trim(),
                        driverName: driverCtrl.text.trim(),
                        routeId: routeId,
                        lastLat: bus.lastLat,
                        lastLng: bus.lastLng,
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
      ),
    );
  }

  Future<void> _delete(Bus bus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text('Remove ${bus.busNumber} · ${bus.busName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.instance.deleteBus(bus.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Buses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bus'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buses.isEmpty
              ? const EmptyState(icon: Icons.directions_bus_outlined, title: 'No buses', subtitle: 'Add your first bus.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: _buses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final b = _buses[i];
                    final route = _routes.where((r) => r.id == b.routeId);
                    return SoftCard(
                      child: Row(
                        children: [
                          const IconBadge(icon: Icons.directions_bus_filled_rounded),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b.busNumber} · ${b.busName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('Driver: ${b.driverName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                Text(route.isNotEmpty ? '${route.first.source} → ${route.first.destination}' : 'No route',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () => _openForm(bus: b), icon: const Icon(Icons.edit_outlined, size: 20)),
                          IconButton(onPressed: () => _delete(b), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
