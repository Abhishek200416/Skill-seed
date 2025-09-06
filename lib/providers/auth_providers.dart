import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/app_user.dart';

final authRepoProvider = Provider<AuthRepository>((ref)=>AuthRepository());
final currentUserProvider = FutureProvider<AppUser?>((ref)=>ref.read(authRepoProvider).currentUser());
