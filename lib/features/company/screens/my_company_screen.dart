import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/company_provider.dart';
import '../domain/company_model.dart';
import '../../../core/router/routes.dart';

class MyCompanyScreen extends ConsumerWidget {
  const MyCompanyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProvider);

    return companyAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('My Company')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (company) {
        if (company == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(Routes.companyOnboard);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _CompanyView(company: company);
      },
    );
  }
}

class _CompanyView extends StatelessWidget {
  const _CompanyView({required this.company});

  final CompanyModel company;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Company')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.business, size: 36, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Center(child: Text(company.name, style: tt.headlineSmall)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${company.size} employees',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          Text('About', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text(company.description, style: tt.bodyLarge),
        ],
      ),
    );
  }
}
