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
  static const String contactAdd = '/contacts/add';
  static const String contactDetail = '/contacts/detail/:id';
  static const String networking = '/networking';
  static const String me = '/me';
  static const String meetings = '/meetings';
  static const String todos = '/todos';
  static const String mail = '/mail';
  static const String settings = '/settings';

  static const String companyOnboard = '/company/onboard';
  static const String cardIssue = '/cards/issue';
  static const String issuedCards = '/issued';
  static const String employeeDashboard = '/employee/dashboard';
  static const String employeeSettings = '/employee/settings';
  static const String employeeMe = '/employee/me';
  static const String employeeMeetings = '/employee/meetings';
  static const String employeeTodos = '/employee/todos';
  static const String employeeContacts = '/employee/contacts';
  static const String employeeContactAdd = '/employee/contacts/add';
  static const String employeeContactDetail = '/employee/contacts/detail/:id';
  static const String employeeNetworking = '/employee/networking';

  // Messaging
  static const String threads = '/comms';
  static const String employeeThreads = '/employee/messaging';

  static String cardDetailPath(String id) => '/cards/$id';
  static String cardEditPath(String id) => '/cards/$id/edit';
  static String publicCardPath(String slug) => '/c/$slug';
  static String contactDetailPath(String id) => '/contacts/detail/$id';
  static String employeeContactDetailPath(String id) =>
      '/employee/contacts/detail/$id';
  static String threadDetailPath(String id) => '/comms/$id';
  static String employeeThreadDetailPath(String id) => '/employee/messaging/$id';
}
