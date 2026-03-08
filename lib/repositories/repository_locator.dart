import 'dinner_repository.dart';
import 'match_repository.dart';

/// Provides access to the app's repositories for the agent tool layer.
class RepositoryLocator {
  /// Creates a repository locator.
  const RepositoryLocator({
    required this.dinner,
    required this.match,
  });

  /// Dinner and invite repository.
  final DinnerRepository dinner;

  /// Match and attendance repository.
  final MatchRepository match;
}
