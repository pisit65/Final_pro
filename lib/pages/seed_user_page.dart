import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:faker/faker.dart';
import '../services/pocketbase_service.dart';
import '../models.dart';

class SeedMemberPage extends StatefulWidget {
  const SeedMemberPage({super.key});

  @override
  State<SeedMemberPage> createState() => _SeedMemberPageState();
}

class _SeedMemberPageState extends State<SeedMemberPage> {
  final pb = PBService('http://127.0.0.1:8090');
  final faker = Faker();

  final RxList<Member> members = <Member>[].obs;
  final RxBool loading = false.obs;

  Future<void> loadMembers() async {
    loading.value = true;
    try {
      final data = await pb.listMembers();
      print('📋 Loaded ${data.length} members');
      members.assignAll(data);
    } catch (e) {
      print('❌ Error loading members: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<void> addRandomMember() async {
    loading.value = true;
    try {
      final m = Member(
        id: 'tmp',
        name: faker.person.name(),
        email: faker.internet.email(),
        role: faker.job.title(),
        created: DateTime.now(),
        updated: DateTime.now(),
      );
      await pb.createMember(m);
      await Future.delayed(const Duration(milliseconds: 300));
      await loadMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 เพิ่มสมาชิกแบบสุ่ม 1 คนแล้ว!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ เพิ่มข้อมูลล้มเหลว: $e')),
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> editMember(Member member) async {
    final nameCtrl = TextEditingController(text: member.name);
    final emailCtrl = TextEditingController(text: member.email);
    final roleCtrl = TextEditingController(text: member.role);

    final updated = await showDialog<Member>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('✏️ แก้ไขข้อมูลสมาชิก'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อ')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'อีเมล')),
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'ตำแหน่ง / บทบาท')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                Member(
                  id: member.id,
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  role: roleCtrl.text,
                  created: member.created,
                  updated: DateTime.now(),
                ),
              );
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (updated != null) {
      await pb.updateMember(updated);
      await loadMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ แก้ไขข้อมูลสำเร็จ!')),
      );
    }
  }

  Future<void> deleteMember(Member member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🗑️ ลบสมาชิก'),
        content: Text('คุณต้องการลบ "${member.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await pb.deleteMember(member.id);
      await loadMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ ลบสมาชิก ${member.name} เรียบร้อยแล้ว!')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 จัดการสมาชิก / สุ่มข้อมูล'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadMembers,
          ),
        ],
      ),
      body: Obx(() {
        if (loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (members.isEmpty) {
          return const Center(
            child: Text(
              'ยังไม่มีข้อมูลสมาชิก\nกดปุ่มด้านล่างเพื่อสุ่มข้อมูล',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: loadMembers,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: members.length,
            itemBuilder: (_, i) {
              final m = members[i];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${m.email}\n${m.role}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        editMember(m);
                      } else if (value == 'delete') {
                        deleteMember(m);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('✏️ แก้ไข')),
                      PopupMenuItem(value: 'delete', child: Text('🗑️ ลบ')),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addRandomMember,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.person_add),
        label: const Text('สุ่ม 1 คน'),
      ),
    );
  }
}
