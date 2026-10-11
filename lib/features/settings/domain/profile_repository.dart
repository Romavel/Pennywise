import '../../../core/data/write_result.dart';
import 'user_profile.dart';

/// The signed-in user's profile. Implementations throw [AppFailure]
/// subclasses on error.
abstract interface class ProfileRepository {
  /// `null` until the user saves a setting for the first time.
  Stream<UserProfile?> watch();

  Future<WriteResult> save(UserProfile profile);
}
