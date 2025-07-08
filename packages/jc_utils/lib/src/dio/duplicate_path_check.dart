class DuplicatePathCheck {
  final String apiPath;

  /// if absolute is true the provided [apiPath] will need to be exact to trigger the check
  /// else it will check with contains
  final bool absolute;

  const DuplicatePathCheck({required this.apiPath, this.absolute = false});

  bool isSameAPIPath(String other) {
    if (absolute) return apiPath == other;
    return other.contains(apiPath);
  }
}