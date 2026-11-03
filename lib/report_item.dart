import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportItemButton extends StatelessWidget {
  const ReportItemButton({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.flag_outlined),
    label: const Text('Report / Пожаловаться'),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (dialogContext) => _ReportForm(itemId: itemId),
    ),
  );
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({required this.itemId});
  final String itemId;
  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final controller = TextEditingController();
  String reason = 'child_safety';
  bool busy = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (controller.text.trim().length < 10) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first / Сначала войдите')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await client.from('safety_reports').insert({
        'reporter_id': user.id,
        'find_id': widget.itemId,
        'category': reason,
        'details': controller.text.trim(),
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Report submitted / Жалоба отправлена')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Send failed / Ошибка отправки')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Report / Пожаловаться'),
    content: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: reason,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'child_safety', child: Text('Child safety / Защита детей')),
            DropdownMenuItem(value: 'abuse', child: Text('Abuse / Нарушение')),
            DropdownMenuItem(value: 'spam', child: Text('Spam / Спам')),
            DropdownMenuItem(value: 'other', child: Text('Other / Другое')),
          ],
          onChanged: busy ? null : (v) => setState(() => reason = v ?? reason),
        ),
        TextField(
          controller: controller,
          maxLength: 2000,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Details / Подробности'),
        ),
      ]),
    ),
    actions: [
      TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Cancel / Отмена')),
      FilledButton(onPressed: busy ? null : send, child: const Text('Send / Отправить')),
    ],
  );
}
