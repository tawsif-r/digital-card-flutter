import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/card_data.dart';

class CardBuilderNotifier extends StateNotifier<CardData> {
  CardBuilderNotifier([CardData? initial]) : super(initial ?? CardData.empty());

  void setName(String v) => state = state.copyWith(name: v);
  void setTitle(String? v) => state = state.copyWith(title: v?.isEmpty == true ? null : v);
  void setCompany(String? v) => state = state.copyWith(company: v?.isEmpty == true ? null : v);
  void setPhone(String? v) => state = state.copyWith(phone: v?.isEmpty == true ? null : v);
  void setEmail(String? v) => state = state.copyWith(email: v?.isEmpty == true ? null : v);
  void setWebsite(String? v) => state = state.copyWith(website: v?.isEmpty == true ? null : v);
  void setPhotoUrl(String? v) => state = state.copyWith(photoUrl: v?.isEmpty == true ? null : v);
  void setTemplate(CardTemplate t) => state = state.copyWith(template: t);
  void setAccentColor(String hex) => state = state.copyWith(accentColor: hex);

  void addSocial(SocialLink link) =>
      state = state.copyWith(socials: [...state.socials, link]);

  void removeSocial(int index) {
    final list = List<SocialLink>.from(state.socials)..removeAt(index);
    state = state.copyWith(socials: list);
  }

  void updateSocial(int index, SocialLink link) {
    final list = List<SocialLink>.from(state.socials)..[index] = link;
    state = state.copyWith(socials: list);
  }

  void reset([CardData? data]) => state = data ?? CardData.empty();
}

// Family provider — one instance per card ID (null = new card)
final cardBuilderProvider =
    StateNotifierProvider.family<CardBuilderNotifier, CardData, CardData?>(
  (ref, initial) => CardBuilderNotifier(initial),
);
