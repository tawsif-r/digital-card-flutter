enum CardTemplate { minimal, bold, glass }

extension CardTemplateX on CardTemplate {
  String get value => name;

  static CardTemplate fromString(String s) =>
      CardTemplate.values.firstWhere((e) => e.name == s, orElse: () => CardTemplate.minimal);
}

class SocialLink {
  const SocialLink({required this.platform, required this.url});

  final String platform;
  final String url;

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
        platform: json['platform'] as String,
        url: json['url'] as String,
      );

  Map<String, dynamic> toJson() => {'platform': platform, 'url': url};

  SocialLink copyWith({String? platform, String? url}) => SocialLink(
        platform: platform ?? this.platform,
        url: url ?? this.url,
      );
}

class CardData {
  const CardData({
    required this.name,
    this.title,
    this.company,
    this.phone,
    this.email,
    this.website,
    this.socials = const [],
    this.photoUrl,
    required this.template,
    required this.accentColor,
  });

  final String name;
  final String? title;
  final String? company;
  final String? phone;
  final String? email;
  final String? website;
  final List<SocialLink> socials;
  final String? photoUrl;
  final CardTemplate template;
  final String accentColor;

  factory CardData.empty() => const CardData(
        name: '',
        template: CardTemplate.minimal,
        accentColor: '#1A73E8',
      );

  factory CardData.fromJson(Map<String, dynamic> json) => CardData(
        name: json['name'] as String? ?? '',
        title: json['title'] as String?,
        company: json['company'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
        socials: (json['socials'] as List<dynamic>? ?? [])
            .map((e) => SocialLink.fromJson(e as Map<String, dynamic>))
            .toList(),
        photoUrl: json['photo_url'] as String?,
        template: CardTemplateX.fromString(json['template'] as String? ?? 'minimal'),
        accentColor: json['accent_color'] as String? ?? '#1A73E8',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (title != null) 'title': title,
        if (company != null) 'company': company,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        'socials': socials.map((s) => s.toJson()).toList(),
        if (photoUrl != null) 'photo_url': photoUrl,
        'template': template.value,
        'accent_color': accentColor,
      };

  CardData copyWith({
    String? name,
    Object? title = _sentinel,
    Object? company = _sentinel,
    Object? phone = _sentinel,
    Object? email = _sentinel,
    Object? website = _sentinel,
    List<SocialLink>? socials,
    Object? photoUrl = _sentinel,
    CardTemplate? template,
    String? accentColor,
  }) =>
      CardData(
        name: name ?? this.name,
        title: title == _sentinel ? this.title : title as String?,
        company: company == _sentinel ? this.company : company as String?,
        phone: phone == _sentinel ? this.phone : phone as String?,
        email: email == _sentinel ? this.email : email as String?,
        website: website == _sentinel ? this.website : website as String?,
        socials: socials ?? this.socials,
        photoUrl: photoUrl == _sentinel ? this.photoUrl : photoUrl as String?,
        template: template ?? this.template,
        accentColor: accentColor ?? this.accentColor,
      );
}

const _sentinel = Object();
