import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public_profile.dart';
import '../repositories/swap_repository.dart';
import 'auth_provider.dart';

final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  return SwapRepository(FirebaseFirestore.instance);
});

/// Streams the signed-in user's [PublicProfile] (or null if not created yet).
final myProfileProvider = StreamProvider<PublicProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.read(swapRepositoryProvider).watchMyProfile(user.uid);
});
