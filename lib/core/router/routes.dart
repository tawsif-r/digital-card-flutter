class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String publicCard = '/c/:slug';

  // Shell routes
  static const String home = '/home';
  static const String cards = '/cards';
  static const String cardNew = '/cards/new';
  static const String cardDetail = '/cards/:id';
  static const String cardEdit = '/cards/:id/edit';
  static const String company = '/company';
  static const String comms = '/comms';
  static const String others = '/others';
  static const String contacts = '/contacts';
  static const String networking = '/networking';
  static const String me = '/me';
  static const String meetings = '/meetings';
  static const String todos = '/todos';
  static const String mail = '/mail';
  static const String settings = '/settings';

  static String cardDetailPath(String id) => '/cards/$id';
  static String cardEditPath(String id) => '/cards/$id/edit';
  static String publicCardPath(String slug) => '/c/$slug';
}
