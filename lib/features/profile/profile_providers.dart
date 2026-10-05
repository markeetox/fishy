import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final userDocStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value(null);
  }
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserDocStream(user.uid);
});

final userEarnedBadgesProvider =
    StreamProvider<Map<String, DateTime>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value({});
  }
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserEarnedBadgesStream(user.uid);
});

final publicProfileDocProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserDocStream(uid);
});

final publicProfileBadgesProvider =
    StreamProvider.family<Map<String, DateTime>, String>((ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserEarnedBadgesStream(uid);
});
