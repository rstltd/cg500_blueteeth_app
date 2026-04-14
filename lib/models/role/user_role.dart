/// User role for command access control.
///
/// - [normal]: field operator. Sees only a small whitelist of safe device
///   configuration commands and cannot manually type commands.
/// - [developer]: full access to all commands and manual command input.
///
/// The role is in-memory only. Every cold start defaults to [normal];
/// switching to [developer] requires the password stored in [RoleService].
enum UserRole { normal, developer }

extension UserRoleX on UserRole {
  bool get isDeveloper => this == UserRole.developer;
  bool get isNormal => this == UserRole.normal;
}
