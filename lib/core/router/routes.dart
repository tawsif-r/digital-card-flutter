class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String cardNew = '/cards/new';
  static const String cardDetail = '/cards/:id';
  static const String cardEdit = '/cards/:id/edit';
  static const String publicCard = '/c/:slug';

  static String cardDetailPath(String id) => '/cards/$id';
  static String cardEditPath(String id) => '/cards/$id/edit';
  static String publicCardPath(String slug) => '/c/$slug';
}
