import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/world_content.dart';
import '../../../core/save_controller.dart';
import 'continent_screen.dart';
import 'discovery_cards_screen.dart';
import 'find_mission.dart';
import 'passport_screen.dart';
import 'travel_animation.dart';
import 'world_map_screen.dart';

// ---------------------------------------------------------------------------
// Navigation state
// ---------------------------------------------------------------------------

enum _WorldView {
  map,
  traveling,
  continent,
  mission,
  cards,
}

// ---------------------------------------------------------------------------
// AroundTheWorldScreen — root controller
// ---------------------------------------------------------------------------

/// Root screen for the Around the World land.
///
/// Manages the full navigation stack in-place so the travel animation can
/// span the full screen without a separate route. State machine:
///
///   map → traveling → continent → mission | cards
///                ↑                           ↓
///            (back to map)          (back to continent)
///
/// The passport overlay is shown on top of whichever view is active.
class AroundTheWorldScreen extends ConsumerStatefulWidget {
  const AroundTheWorldScreen({super.key});

  @override
  ConsumerState<AroundTheWorldScreen> createState() =>
      _AroundTheWorldScreenState();
}

class _AroundTheWorldScreenState extends ConsumerState<AroundTheWorldScreen> {
  _WorldView _view = _WorldView.map;
  Continent? _activeContinent;
  bool _showPassport = false;
  bool _isFirstVisit = false;

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _pickContinent(Continent c) {
    // Determine if this is a first visit to this continent
    final visited =
        ref.read(saveControllerProvider).value?.world.visited ?? {};
    _isFirstVisit = visited[c.id] != true;

    setState(() {
      _activeContinent = c;
      _view = _WorldView.traveling;
    });
  }

  void _onArrived() {
    setState(() => _view = _WorldView.continent);
  }

  void _backToMap() {
    setState(() {
      _view = _WorldView.map;
      _activeContinent = null;
      _showPassport = false;
    });
  }

  void _backToContinent() {
    setState(() => _view = _WorldView.continent);
  }

  void _goToMission() {
    setState(() => _view = _WorldView.mission);
  }

  void _goToCards() {
    setState(() => _view = _WorldView.cards);
  }

  void _onMissionComplete() {
    setState(() => _view = _WorldView.continent);
  }

  List<DiscoveryCard> _cardsForContinent(Continent c) {
    return kDiscoveryCards.where((card) => card.id.startsWith(c.id)).toList();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final continent = _activeContinent;

    Widget body;
    switch (_view) {
      case _WorldView.map:
        body = WorldMapScreen(
          onContinentSelected: _pickContinent,
          onPassport: () => setState(() => _showPassport = true),
        );

      case _WorldView.traveling:
        body = TravelAnimation(
          continent: continent!,
          onArrive: _onArrived,
        );

      case _WorldView.continent:
        body = ContinentScreen(
          continent: continent!,
          firstVisit: _isFirstVisit,
          onMission: _goToMission,
          onCards: _goToCards,
          onBack: _backToMap,
        );

      case _WorldView.mission:
        body = FindMissionScreen(
          continent: continent!,
          onBack: _backToContinent,
          onComplete: _onMissionComplete,
        );

      case _WorldView.cards:
        body = DiscoveryDeckScreen(
          continent: continent!,
          cards: _cardsForContinent(continent),
          onBack: _backToContinent,
        );
    }

    return Stack(
      children: [
        body,
        if (_showPassport)
          PassportScreen(onClose: () => setState(() => _showPassport = false)),
      ],
    );
  }
}
