import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../features/students/presentation/screens/students_list_screen.dart';

import '../../features/classes/presentation/screens/clasess_list_screen.dart';

import '../../features/attendance/presentation/screens/attendance_list_screen.dart';

import '../../features/devices/presentation/screens/devices_list_screen.dart';

import '../../features/users/presentation/screens/users_list_screen.dart';

import '../../features/library/presentation/screens/library_borrow_screen.dart';
import '../../features/library/presentation/screens/library_return_screen.dart';
import '../../features/library/presentation/screens/books_list_screen.dart';

import '../presentation/splash_screen.dart';

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, _) => notifyListeners());
  }
}

//Diarahkan ke halaman beda beda tiap role
String _homeFor(UserRole role) {
  return switch (role) {
    UserRole.pustakawan => '/books',
    UserRole.admin => '/dashboard',
    UserRole.guru => '/dashboard',
    UserRole.orangTua => '/dashboard', //kalo dah ada role siswa ini diganti jadi siswa
  };
}

//Pembagian akses buat setiap route
const Map<String, List<UserRole>> _routeAccess = {
  '/dashboard'      : [UserRole.admin, UserRole.guru],
  '/students'       : [UserRole.admin, UserRole.guru],
  '/classes'        : [UserRole.admin, UserRole.guru],
  '/attendance'     : [UserRole.admin, UserRole.guru],
  '/users'          : [UserRole.admin],
  '/devices'        : [UserRole.admin],
  '/books'          : [UserRole.admin, UserRole.pustakawan],
  '/library/borrow' : [UserRole.admin, UserRole.pustakawan],
  '/library/return' : [UserRole.admin, UserRole.pustakawan],
};

bool _canAccess(UserRole role, String location) {
  final allowed = _routeAccess[location];
  if (allowed == null) return true;
  return allowed.contains(role);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      if (authState.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final user = authState.valueOrNull;
      final isLoggedIn = user != null && !authState.hasError;

      if (!isLoggedIn){
        return location == '/login' ? null : '/login';
      } 
      
      if (location == '/login' || location == '/splash') {
        return _homeFor(user.role);
      }
      if (!_canAccess(user.role, location)) {
        return _homeFor(user.role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',         builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login',          builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/dashboard',      builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/students',       builder: (context, state) => const StudentsListScreen()),
      GoRoute(path: '/classes',        builder: (context, state) => const ClassesListScreen()),
      GoRoute(path: '/attendance',     builder: (context, state) => const AttendanceListScreen()),
      GoRoute(path: '/users',          builder: (context, state) => const UsersListScreen()),
      GoRoute(path: '/devices',        builder: (context, state) => const DevicesListScreen()),
      GoRoute(path: '/library/borrow', builder: (context, state) => const LibraryBorrowScreen()),
      GoRoute(path: '/library/return', builder: (context, state) => const LibraryReturnScreen()),
      GoRoute(path: '/books',          builder: (context, state) => const BooksListScreen()),
    ],
  );
});