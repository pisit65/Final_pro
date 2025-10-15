import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/pocketbase_service.dart';
import '../models.dart';
import 'edit_member_page.dart';

class MembersController extends GetxController {
  final PBService service;
  MembersController(this.service);

  final members = <Member>[].obs;
  final loading = false.obs;

  Future<void> fetch() async {
    loading.value = true;
    try {
      members.value = await service.listMembers();
    } finally {
      loading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetch();
  }
}

class MembersListPage extends StatelessWidget {
  final MembersController c = Get.put(MembersController(PBService('http://127.0.0.1:8090')));

  MembersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.members.isEmpty) {
          return const Center(child: Text('No members. Pull to refresh or seed.'));
        }
        return RefreshIndicator(
          onRefresh: () => c.fetch(),
          child: ListView.separated(
            itemCount: c.members.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = c.members[i];
              return ListTile(
                title: Text(m.name),
                subtitle: Text('${m.email} • ${m.role}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.to(() => EditMemberPage(memberId: m.id))!.then((_) => c.fetch()),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // เพิ่มตัวอย่างรวดเร็ว
          final newMember = Member(
            id: 'tmp',
            name: 'New User',
            email: 'new.user.${DateTime.now().millisecondsSinceEpoch}@example.com',
            role: 'Intern',
            created: DateTime.now(),
            updated: DateTime.now(),
          );
          await c.service.createMember(newMember);
          await c.fetch();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
