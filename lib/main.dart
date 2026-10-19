import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
bool _backendConfigured = false;
String? _backendSetupError;

String _redactSetupError(String error) {
  final safeError = error
      .replaceAll(
        RegExp(r'\b(?:sb_(?:publishable|secret)_[A-Za-z0-9_-]+|eyJ[A-Za-z0-9._-]{20,})\b'),
        '[Schlüssel ausgeblendet]',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return safeError.length > 240 ? '${safeError.substring(0, 240)}…' : safeError;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabaseUrl.isNotEmpty && _supabasePublishableKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabasePublishableKey,
      );
      _backendConfigured = true;
    } catch (error) {
      _backendSetupError = error.toString();
    }
  }
  runApp(const StreamHubApp());
}

const _ink = Color(0xFF090B12);
const _panel = Color(0xFF151925);
const _muted = Color(0xFFA5ADBE);
const _violet = Color(0xFFB7A0FF);

// A deliberately small filter list. It does not block ads served from the
// providers' own domains and is not a replacement for AdGuard or uBlock.
final _adContentBlockers = <ContentBlocker>[
  for (final domain in <String>[
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
  ])
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: '.*([./])${domain.replaceAll('.', r'\.')}([/:?#]|\$).*',
      ),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    ),
];
const _filteredServices = <String>{'YouTube', 'Spotify'};
const _adDomains = <String>{
  'doubleclick.net',
  'googleadservices.com',
  'googlesyndication.com',
};

bool _isAdDomain(String host) {
  final normalizedHost = host.toLowerCase();
  return _adDomains.any((domain) =>
      normalizedHost == domain || normalizedHost.endsWith('.$domain'));
}

class StreamHubApp extends StatelessWidget {
  const StreamHubApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Stream Hub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _ink,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _violet,
            brightness: Brightness.dark,
            surface: _panel,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          focusColor: _violet.withOpacity(.18),
          hoverColor: Colors.white.withOpacity(.06),
        ),
        home: const LaunchScreen(),
      );
}

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _introAudio = AudioPlayer();
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _scale = Tween<double>(begin: .72, end: 1)
      .animate(CurvedAnimation(parent: _entrance, curve: Curves.elasticOut));
  bool _showHub = false;

  @override
  void initState() {
    super.initState();
    unawaited(_playIntroSound());
    Future<void>.delayed(const Duration(milliseconds: 1850), () {
      if (mounted) setState(() => _showHub = true);
    });
  }

  Future<void> _playIntroSound() async {
    try {
      await _introAudio.setVolume(.16);
      await _introAudio.play(AssetSource('stream_hub_intro.wav'));
    } catch (_) {
      // The visual intro remains usable when a device has no audio output.
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    unawaited(_introAudio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showHub
            ? AuthGate(key: const ValueKey('auth'))
            : Scaffold(
                key: const ValueKey('splash'),
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(.0, -.3),
                      radius: 1.2,
                      colors: [Color(0xFF27203D), _ink],
                    ),
                  ),
                  child: Center(
                    child: FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_violet, Color(0xFF7861EF)],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: _violet.withOpacity(.3),
                                    blurRadius: 48,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.hub_rounded,
                                  color: Color(0xFF171322), size: 54),
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              'STREAM HUB',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 5,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Deine Streaming-Welt an einem Ort',
                              style: TextStyle(color: _muted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_backendConfigured) {
      return AccountScreen(
        backendReady: false,
        setupError: _backendSetupError,
      );
    }

    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final user = auth.currentUser;
        if (user == null) return const AccountScreen(backendReady: true);
        final displayName = user.userMetadata?['display_name'];
        return HubShell(
          key: ValueKey(user.id),
          userId: user.id,
          email: user.email ?? '',
          initialDisplayName:
              displayName is String && displayName.trim().isNotEmpty
                  ? displayName.trim()
                  : null,
        );
      },
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.backendReady,
    this.setupError,
    super.key,
  });

  final bool backendReady;
  final String? setupError;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.backendReady || _busy || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _error = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final email = _emailController.text.trim();
      if (_registering) {
        final response = await auth.signUp(
          email: email,
          password: _passwordController.text,
          data: {'display_name': _nameController.text.trim()},
        );
        if (response.session == null && mounted) {
          setState(() {
            _registering = false;
            _passwordController.clear();
            _message =
                'Fast geschafft: Bitte bestätige deine E-Mail-Adresse. Danach kannst du dich hier anmelden.';
          });
        }
      } else {
        await auth.signInWithPassword(
          email: email,
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error.message));
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Verbindung fehlgeschlagen. Bitte prüfe deine Internetverbindung und versuche es erneut.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyAuthError(String message) {
    final text = message.toLowerCase();
    if (text.contains('invalid login credentials')) {
      return 'E-Mail-Adresse oder Passwort stimmt nicht.';
    }
    if (text.contains('already registered') ||
        text.contains('already been registered')) {
      return 'Für diese E-Mail-Adresse gibt es bereits ein Konto. Melde dich bitte an.';
    }
    if (text.contains('email not confirmed')) {
      return 'Bitte bestätige zuerst den Link in deiner E-Mail.';
    }
    if (text.contains('password should be at least')) {
      return 'Das Passwort ist zu kurz. Verwende mindestens 8 Zeichen.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(.0, -.8),
            radius: 1.25,
            colors: [Color(0xFF27203D), _ink],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandMark(compact: false),
                    const SizedBox(height: 34),
                    Text(
                      _registering
                          ? 'Dein Stream beginnt hier'
                          : 'Willkommen zurück',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _registering
                          ? 'Erstelle dein kostenloses StreamHub-Konto.'
                          : 'Melde dich an, um deinen Hub zu öffnen.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      color: _panel.withOpacity(.96),
                      child: Padding(
                        padding: EdgeInsets.all(width < 400 ? 18 : 26),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_registering) ...[
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  maxLength: 32,
                                  decoration: const InputDecoration(
                                    labelText: 'Anzeigename',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                          ? 'Gib einen Anzeigenamen ein.'
                                          : null,
                                ),
                                const SizedBox(height: 10),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'E-Mail-Adresse',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (value) => value == null ||
                                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                            .hasMatch(value.trim())
                                    ? 'Gib eine gültige E-Mail-Adresse ein.'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                autofillHints: _registering
                                    ? const [AutofillHints.newPassword]
                                    : const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Passwort',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                        () => _showPassword = !_showPassword),
                                    icon: Icon(_showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 8) {
                                    return 'Verwende mindestens 8 Zeichen.';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              if (_registering)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Wir senden dir einen Bestätigungslink per E-Mail.',
                                    style:
                                        TextStyle(color: _muted, fontSize: 12),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              if (_error != null)
                                _AuthMessage(_error!, isError: true),
                              if (_message != null) _AuthMessage(_message!),
                              if (!widget.backendReady)
                                ...[
                                  _AuthMessage(
                                    widget.setupError == null
                                        ? 'Verbinde zuerst ein kostenloses Supabase-Projekt mit StreamHub. Die Anleitung liegt in SUPABASE_SETUP.md. Online-Registrierung wird erst danach freigeschaltet.'
                                        : 'StreamHub konnte den Anmeldedienst nicht starten. Die Diagnose darunter hilft uns, den Fehler zu finden.',
                                    isError: widget.setupError != null,
                                  ),
                                  if (widget.setupError != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: .2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: .12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Technische Diagnose (zum Weiterleiten)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          SelectableText(
                                            _redactSetupError(widget.setupError!),
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _busy || !widget.backendReady
                                    ? null
                                    : _submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text(_registering
                                        ? 'Kostenloses Konto erstellen'
                                        : 'Anmelden'),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() {
                                          _registering = !_registering;
                                          _error = null;
                                          _message = null;
                                        }),
                                child: Text(_registering
                                    ? 'Ich habe schon ein Konto – anmelden'
                                    : 'Noch kein Konto? Kostenlos registrieren'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Deine Streaming-Zugangsdaten bleiben bei den jeweiligen Anbietern.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isError ? Colors.redAccent : _violet).withOpacity(.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: isError ? Colors.redAccent.shade100 : _muted),
        ),
      );
}

class StreamingService {
  const StreamingService({
    required this.name,
    required this.tagline,
    required this.url,
    required this.icon,
    required this.color,
    required this.category,
    required this.description,
  });

  final String name;
  final String tagline;
  final String url;
  final IconData icon;
  final Color color;
  final String category;
  final String description;
}

const services = <StreamingService>[
  StreamingService(
    name: 'Netflix',
    tagline: 'Serien, Filme & Originals',
    url: 'https://www.netflix.com/',
    icon: Icons.play_arrow_rounded,
    color: Color(0xFFE50914),
    category: 'Serien & Filme',
    description: 'Serien, Filme, Dokumentationen und Netflix Originals.',
  ),
  StreamingService(
    name: 'Disney+',
    tagline: 'Disney, Pixar, Marvel & mehr',
    url: 'https://www.disneyplus.com/',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF176BEF),
    category: 'Serien & Filme',
    description:
        'Geschichten von Disney, Pixar, Marvel, Star Wars und National Geographic.',
  ),
  StreamingService(
    name: 'Prime Video',
    tagline: 'Filme, Serien & Sport',
    url: 'https://www.primevideo.com/',
    icon: Icons.movie_outlined,
    color: Color(0xFF00A8E0),
    category: 'Serien & Filme',
    description: 'Filme, Serien, Originals und je nach Abo weitere Channels.',
  ),
  StreamingService(
    name: 'YouTube',
    tagline: 'Videos, Live & Premium',
    url: 'https://www.youtube.com/',
    icon: Icons.smart_display_rounded,
    color: Color(0xFFFF0033),
    category: 'Video',
    description: 'Videos, Livestreams und Creator-Inhalte auf YouTube.',
  ),
  StreamingService(
    name: 'Spotify',
    tagline: 'Musik, Podcasts & Hörbücher',
    url: 'https://open.spotify.com/',
    icon: Icons.music_note_rounded,
    color: Color(0xFF1DB954),
    category: 'Musik',
    description:
        'Musik, Podcasts und Hörbücher auf der offiziellen Spotify-Webseite.',
  ),
  StreamingService(
    name: 'WOW',
    tagline: 'Serien, Filme & Live-Sport',
    url: 'https://www.wowtv.de/',
    icon: Icons.bolt_rounded,
    color: Color(0xFF7445D8),
    category: 'Serien & Filme',
    description: 'Das Streaming-Angebot von WOW mit Serien, Filmen und Sport.',
  ),
  StreamingService(
    name: 'RTL+',
    tagline: 'Shows, Serien & Live-TV',
    url: 'https://plus.rtl.de/',
    icon: Icons.live_tv_rounded,
    color: Color(0xFFE45C26),
    category: 'Live & Shows',
    description: 'Shows, Serien, Reality und weitere RTL+-Inhalte.',
  ),
  StreamingService(
    name: 'Joyn',
    tagline: 'Mediathek & Live-TV',
    url: 'https://www.joyn.de/',
    icon: Icons.tv_rounded,
    color: Color(0xFF8A5CF6),
    category: 'Live & Shows',
    description: 'Mediatheken, Shows und Live-TV auf Joyn.',
  ),
  StreamingService(
    name: 'Paramount+',
    tagline: 'Filme & Paramount Originals',
    url: 'https://www.paramountplus.com/',
    icon: Icons.local_movies_outlined,
    color: Color(0xFF0878D1),
    category: 'Serien & Filme',
    description: 'Filme, Serien und Originals von Paramount+.',
  ),
];

class HubShell extends StatefulWidget {
  const HubShell({
    required this.userId,
    required this.email,
    this.initialDisplayName,
    super.key,
  });

  final String userId;
  final String email;
  final String? initialDisplayName;

  @override
  State<HubShell> createState() => _HubShellState();
}

class _HubShellState extends State<HubShell> {
  int _section = 0;
  String _query = '';
  late String? _profileName = widget.initialDisplayName;
  final Set<String> _favorites = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final rows = await Supabase.instance.client
          .from('user_favorites')
          .select('provider_name')
          .eq('user_id', widget.userId);
      if (!mounted) return;
      setState(() {
        _favorites
          ..clear()
          ..addAll(rows.map((row) => row['provider_name'] as String));
      });
    } catch (_) {
      if (mounted) _showMessage('Favoriten konnten nicht geladen werden.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<StreamingService> get _visibleServices {
    final base = _section == 2
        ? services.where((service) => _favorites.contains(service.name))
        : services;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return base.toList();
    return base.where((service) {
      return '${service.name} ${service.tagline} ${service.category}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  Future<void> _toggleFavorite(StreamingService service) async {
    final wasFavorite = _favorites.contains(service.name);
    setState(() {
      if (wasFavorite) {
        _favorites.remove(service.name);
      } else {
        _favorites.add(service.name);
      }
    });
    try {
      final table = Supabase.instance.client.from('user_favorites');
      if (wasFavorite) {
        await table
            .delete()
            .eq('user_id', widget.userId)
            .eq('provider_name', service.name);
      } else {
        await table.upsert({
          'user_id': widget.userId,
          'provider_name': service.name,
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favorites.add(service.name);
        } else {
          _favorites.remove(service.name);
        }
      });
      _showMessage(
          'Favorit konnte nicht gespeichert werden. Bitte prüfe die Einrichtung.');
    }
  }

  Future<void> _openService(StreamingService service) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => ProviderPage(service: service),
    ));
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _profileName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dein StreamHub-Profil'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          maxLength: 32,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Anzeigename',
            hintText: 'Zum Beispiel Alex',
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name != null && mounted) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return;
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'display_name': trimmed}),
        );
        if (mounted) setState(() => _profileName = trimmed);
      } on AuthException catch (error) {
        _showMessage(
            'Profil konnte nicht gespeichert werden: ${error.message}');
      } catch (_) {
        _showMessage('Profil konnte nicht gespeichert werden.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final page = switch (_section) {
      0 => _buildHome(),
      1 => _buildCatalog(),
      2 => _buildCatalog(favoritesOnly: true),
      _ => _buildProfile(),
    };

    return Scaffold(
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              backgroundColor: const Color(0xFF0E1119),
              selectedIndex: _section,
              onDestinationSelected: (value) =>
                  setState(() => _section = value),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.fromLTRB(0, 28, 0, 36),
                child: _BrandMark(compact: true),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('Startseite'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: Text('Entdecken'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: Text('Favoriten'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Profil'),
                ),
              ],
            ),
          Expanded(child: page),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _section,
              onDestinationSelected: (value) =>
                  setState(() => _section = value),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Start'),
                NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore_rounded),
                    label: 'Entdecken'),
                NavigationDestination(
                    icon: Icon(Icons.favorite_border_rounded),
                    label: 'Favoriten'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
              ],
            ),
    );
  }

  Widget _buildHome() {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 1000
        ? 52.0
        : width >= 760
            ? 36.0
            : 20.0;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 24, horizontalPadding, 32),
            sliver: SliverList.list(children: [
              Row(children: [
                const _BrandMark(compact: false),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Profil',
                  onPressed: () => setState(() => _section = 3),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
              ]),
              const SizedBox(height: 32),
              _WelcomeHero(
                name: _profileName,
                onExplore: () => setState(() => _section = 1),
                onFavorites: () => setState(() => _section = 2),
              ),
              const SizedBox(height: 34),
              _homeServiceRow(
                'Deine Streaming-Dienste',
                'Deine Anbieter direkt griffbereit',
                services,
              ),
              const SizedBox(height: 32),
              _providerSpotlight(services[0],
                  ['Serien entdecken', 'Filme entdecken', 'Originals ansehen']),
              const SizedBox(height: 28),
              _providerSpotlight(services[1],
                  ['Disney & Pixar', 'Marvel & Star Wars', 'Dokus entdecken']),
              const SizedBox(height: 28),
              _providerSpotlight(services[2],
                  ['Serien & Filme', 'Neu im Angebot', 'Sport entdecken']),
              const SizedBox(height: 32),
              _homeServiceRow(
                'Live, Musik & mehr',
                'Video, Musik, Shows und Live-TV',
                services.where((s) => s.category != 'Serien & Filme').toList(),
              ),
              const SizedBox(height: 32),
              _homeServiceRow(
                'Deine Favoriten',
                _favorites.isEmpty
                    ? 'Markiere Anbieter mit dem Herzsymbol, um sie hier zu sammeln'
                    : 'Deine gespeicherten Anbieter',
                services.where((s) => _favorites.contains(s.name)).toList(),
                emptyMessage: 'Noch keine Favoriten gespeichert.',
                showAll: false,
              ),
              const SizedBox(height: 36),
              const Text(
                'Stream Hub ist ein unabhängiger Launcher. Anbieter, Konten und Wiedergabe bleiben bei den jeweiligen Diensten.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _homeServiceRow(
    String title,
    String subtitle,
    List<StreamingService> items, {
    String? emptyMessage,
    bool showAll = true,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: _muted)),
                  ]),
            ),
            if (showAll)
              TextButton(
                onPressed: () => setState(() => _section = 1),
                child: const Text('Alle ansehen'),
              ),
          ]),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _panel, borderRadius: BorderRadius.circular(18)),
              child: Text(emptyMessage ?? 'Hier ist noch nichts gespeichert.',
                  style: const TextStyle(color: _muted)),
            )
          else
            SizedBox(
              height: 158,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final service = items[index];
                  return _ProviderTile(
                    service: service,
                    isFavorite: _favorites.contains(service.name),
                    onFavorite: () => _toggleFavorite(service),
                    onTap: () => _openService(service),
                  );
                },
              ),
            ),
        ],
      );

  Widget _providerSpotlight(StreamingService service, List<String> ideas) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _ServiceLogo(service: service, size: 30),
            const SizedBox(width: 10),
            Expanded(
                child: Text('${service.name} entdecken',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800))),
            TextButton(
                onPressed: () => _openService(service),
                child: const Text('Zum Anbieter')),
          ]),
          const SizedBox(height: 4),
          Text(
              'Starte auf der offiziellen Seite und entdecke dort aktuelle Empfehlungen.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _muted)),
          const SizedBox(height: 14),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ideas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _ProviderIdeaTile(
                service: service,
                title: ideas[index],
                onTap: () => _openService(service),
              ),
            ),
          ),
        ],
      );

  Widget _buildProfile() => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(padding: const EdgeInsets.all(28), children: [
              Text('Dein Profil',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Gestalte deinen StreamHub-Start persönlich.',
                  style: TextStyle(color: _muted)),
              const SizedBox(height: 28),
              Card(
                color: _panel,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: _violet.withOpacity(.18),
                      child: Text(
                        (_profileName?.isNotEmpty == true
                                ? _profileName![0]
                                : 'S')
                            .toUpperCase(),
                        style: const TextStyle(
                            color: _violet,
                            fontSize: 24,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(_profileName ?? 'Willkommen bei Stream Hub',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Text(widget.email,
                              style: const TextStyle(color: _muted)),
                        ])),
                    IconButton(
                        onPressed: _editProfile,
                        tooltip: 'Profil bearbeiten',
                        icon: const Icon(Icons.edit_outlined)),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(_profileName == null
                    ? 'Profil einrichten'
                    : 'Anzeigenamen ändern'),
              ),
              const SizedBox(height: 22),
              const _InfoTile(
                icon: Icons.verified_user_outlined,
                title: 'StreamHub-Konto aktiv',
                body:
                    'Dein Profil wird mit deinem StreamHub-Konto gespeichert. Streaming-Passwörter werden nicht von StreamHub verwaltet.',
              ),
              const SizedBox(height: 12),
              const _InfoTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Favoriten',
                body:
                    'Deine Favoriten werden sicher deinem Konto zugeordnet und erscheinen nach der Anmeldung auch auf deinen anderen Geräten.',
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await Supabase.instance.client.auth.signOut();
                  } catch (_) {
                    _showMessage('Abmeldung fehlgeschlagen.');
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Abmelden'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                ),
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Über Stream Hub'),
              ),
            ]),
          ),
        ),
      );

  Widget _buildCatalog({bool favoritesOnly = false}) {
    final visible = _visibleServices;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width >= 760 ? 44 : 22,
              22,
              MediaQuery.sizeOf(context).width >= 760 ? 44 : 22,
              12,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (MediaQuery.sizeOf(context).width < 760)
                    const _BrandMark(compact: false),
                  if (MediaQuery.sizeOf(context).width < 760)
                    const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              favoritesOnly
                                  ? 'Deine Favoriten'
                                  : 'Alles an einem Ort',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.6,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              favoritesOnly
                                  ? 'Deine gespeicherten Streaming-Dienste.'
                                  : 'Deine Streaming-Dienste. Ein übersichtlicher Startpunkt.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: _muted),
                            ),
                          ],
                        ),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 520)
                        const _StatusPill(),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _SearchField(
                    onChanged: (value) => setState(() => _query = value),
                    hint: 'Anbieter suchen',
                  ),
                  if (!favoritesOnly &&
                      MediaQuery.sizeOf(context).width < 520) ...[
                    const SizedBox(height: 14),
                    const _StatusPill(),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        favoritesOnly ? 'GESPEICHERT' : 'ANBIETER',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: _muted,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${visible.length}',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                favoritesOnly: favoritesOnly,
                hasQuery: _query.trim().isNotEmpty,
                onBrowse: () => setState(() {
                  _section = 1;
                  _query = '';
                }),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width >= 760 ? 44 : 22,
                0,
                MediaQuery.sizeOf(context).width >= 760 ? 44 : 22,
                24,
              ),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = width >= 1120
                      ? 4
                      : width >= 760
                          ? 3
                          : width >= 480
                              ? 2
                              : 1;
                  return SliverGrid.builder(
                    itemCount: visible.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: columns == 1 ? 2.25 : 1.38,
                    ),
                    itemBuilder: (context, index) => ServiceCard(
                      service: visible[index],
                      isFavorite: _favorites.contains(visible[index].name),
                      onFavorite: () => _toggleFavorite(visible[index]),
                      onTap: () => _openService(visible[index]),
                    ),
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Stream Hub ist ein unabhängiger Launcher. Anbieter-Websites und Wiedergabe bleiben unter Kontrolle der jeweiligen Anbieter.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: _muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero(
      {required this.name, required this.onExplore, required this.onFavorites});
  final String? name;
  final VoidCallback onExplore;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF392955), Color(0xFF1B1A2C), Color(0xFF171B27)],
        ),
        border: Border.all(color: _violet.withOpacity(.18)),
      ),
      child: Stack(children: [
        Positioned(
          right: -40,
          top: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [_violet.withOpacity(.2), Colors.transparent]),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? 22 : 34),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                      color: _violet.withOpacity(.13),
                      borderRadius: BorderRadius.circular(24)),
                  child: const Text('DEIN STREAMING-STARTPUNKT',
                      style: TextStyle(
                          color: _violet,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                ),
                const SizedBox(height: 18),
                Text(
                  name == null
                      ? 'Alles, was du streamst.\nAn einem Ort.'
                      : 'Schön, dass du da bist,\n$name.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                      letterSpacing: -.7),
                ),
                const SizedBox(height: 12),
                const Text(
                    'Finde deine Anbieter schnell wieder und spring direkt zu ihren offiziellen Angeboten.',
                    style: TextStyle(color: Color(0xFFD4D0E0), height: 1.5)),
                const SizedBox(height: 22),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  FilledButton.icon(
                      onPressed: onExplore,
                      icon: const Icon(Icons.explore_rounded),
                      label: const Text('Entdecken')),
                  OutlinedButton.icon(
                      onPressed: onFavorites,
                      icon: const Icon(Icons.favorite_border_rounded),
                      label: const Text('Favoriten')),
                ]),
              ]),
        ),
      ]),
    );
  }
}

class _ProviderIdeaTile extends StatelessWidget {
  const _ProviderIdeaTile(
      {required this.service, required this.title, required this.onTap});
  final StreamingService service;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        child: Material(
          color: service.color.withOpacity(.16),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: service.color, size: 20),
                    Row(children: [
                      Expanded(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      const Icon(Icons.arrow_outward_rounded,
                          size: 16, color: _muted),
                    ]),
                  ]),
            ),
          ),
        ),
      );
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile(
      {required this.service,
      required this.isFavorite,
      required this.onFavorite,
      required this.onTap});
  final StreamingService service;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 238,
        child: Material(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _ServiceLogo(service: service, size: 52),
                const SizedBox(width: 13),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text(service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(service.tagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _muted, fontSize: 11, height: 1.3)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 13, color: service.color),
                        const SizedBox(width: 5),
                        Text('Angebot öffnen',
                            style: TextStyle(
                                color: service.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ])),
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: isFavorite
                      ? 'Aus Favoriten entfernen'
                      : 'Zu Favoriten hinzufügen',
                  onPressed: onFavorite,
                  icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20),
                  color: isFavorite ? const Color(0xFFFF7596) : _muted,
                ),
              ]),
            ),
          ),
        ),
      );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_violet, Color(0xFF7D68F2)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hub_rounded, color: Color(0xFF171322)),
          ),
          if (!compact) ...[
            const SizedBox(width: 11),
            Text('STREAM HUB',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: 1.8)),
          ],
        ],
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF201C31),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _violet.withOpacity(.2)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.open_in_new_rounded, size: 15, color: _violet),
          SizedBox(width: 7),
          Text('Offizielle Anbieter-Websites', style: TextStyle(fontSize: 12)),
        ]),
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged, required this.hint});
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: _panel,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _violet, width: 1.3),
          ),
        ),
      );
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
    super.key,
  });

  final StreamingService service;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: _panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withOpacity(.06)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          focusColor: Colors.white.withOpacity(.1),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ServiceLogo(service: service, size: 48),
                    const Spacer(),
                    IconButton(
                      tooltip: isFavorite
                          ? 'Aus Favoriten entfernen'
                          : 'Zu Favoriten hinzufügen',
                      onPressed: onFavorite,
                      icon: Icon(isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded),
                      color: isFavorite ? const Color(0xFFFF7596) : _muted,
                    ),
                  ],
                ),
                const Spacer(),
                Text(service.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(service.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: _muted)),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(Icons.open_in_new_rounded,
                        size: 14, color: _violet),
                    const SizedBox(width: 6),
                    Text('Anbieter öffnen',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: _violet, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(service.category,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: _muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _ServiceLogo extends StatelessWidget {
  const _ServiceLogo({required this.service, this.size = 50});
  final StreamingService service;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: service.color,
          borderRadius: BorderRadius.circular(size * .28),
          boxShadow: [
            BoxShadow(color: service.color.withOpacity(.24), blurRadius: 18)
          ],
        ),
        child: Icon(service.icon, color: Colors.white, size: size * .58),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.favoritesOnly,
      required this.hasQuery,
      required this.onBrowse});
  final bool favoritesOnly;
  final bool hasQuery;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                favoritesOnly && !hasQuery
                    ? Icons.favorite_border_rounded
                    : Icons.search_off_rounded,
                size: 42,
                color: _muted),
            const SizedBox(height: 14),
            Text(hasQuery ? 'Kein Anbieter gefunden' : 'Noch keine Favoriten',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
                hasQuery
                    ? 'Passe deine Suche an.'
                    : 'Speichere Anbieter über das Herzsymbol.',
                style: const TextStyle(color: _muted)),
            if (favoritesOnly) ...[
              const SizedBox(height: 16),
              TextButton(
                  onPressed: onBrowse, child: const Text('Anbieter entdecken')),
            ],
          ]),
        ),
      );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(28), children: [
              const _BrandMark(compact: false),
              const SizedBox(height: 36),
              Text('Ein Hub. Deine Dienste.',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text(
                  'Stream Hub ist ein früher, noch unvollständiger Prototyp. Er soll ein zentraler Startpunkt für Angebote wie Netflix, Disney+ und Prime Video werden und deren offizielle Websites in einem eigenen Bereich öffnen.',
                  style: TextStyle(color: _muted, height: 1.5)),
              const SizedBox(height: 24),
              const _InfoTile(
                icon: Icons.verified_user_outlined,
                title: 'Dein Konto bleibt beim Anbieter',
                body:
                    'Melde dich nur auf der offiziellen Anbieterseite an. Stream Hub fragt keine Passwörter ab und betreibt keinen Video-Proxy.',
              ),
              const SizedBox(height: 12),
              const _InfoTile(
                icon: Icons.shield_outlined,
                title: 'Wiedergabe hängt vom Anbieter ab',
                body:
                    'Einige Dienste blockieren eingebettete Browser oder verlangen zertifizierte Apps. DRM-Wiedergabe und Anmeldung sind in diesem Prototyp nicht garantiert.',
              ),
              const SizedBox(height: 12),
              const _InfoTile(
                icon: Icons.handshake_outlined,
                title: 'Anbieterfreigaben stehen noch aus',
                body:
                    'Wir planen, mit Netflix, Disney+, Amazon und weiteren Anbietern die Bedingungen zu klären und nötige schriftliche Freigaben einzuholen. Bestätigungen liegen noch nicht vor; Anmeldung und Wiedergabe sind daher nicht zugesichert.',
              ),
              const SizedBox(height: 24),
              Text('Stream Hub • Diagnose v0.3.3',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: _muted)),
            ]),
          ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        color: _panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: _violet),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(body,
                      style: const TextStyle(color: _muted, height: 1.4)),
                ])),
          ]),
        ),
      );
}

class ProviderPage extends StatefulWidget {
  const ProviderPage({required this.service, super.key});
  final StreamingService service;

  @override
  State<ProviderPage> createState() => _ProviderPageState();
}

class _ProviderPageState extends State<ProviderPage> {
  InAppWebViewController? _controller;
  double _progress = 0;
  String? _loadError;
  String _host = '';
  bool _showInfoBanner = true;
  Timer? _infoBannerTimer;

  @override
  void initState() {
    super.initState();
    _infoBannerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showInfoBanner = false);
    });
  }

  @override
  void dispose() {
    _infoBannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _back() async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleBack() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;
    final shouldFilterAds = _filteredServices.contains(service.name);
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _BackIntent(),
        SingleActivator(LogicalKeyboardKey.browserBack): _BackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BackIntent: CallbackAction<_BackIntent>(onInvoke: (_) {
            _handleBack();
            return null;
          }),
        },
        child: PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                  tooltip: 'Zurück',
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back_rounded)),
              titleSpacing: 0,
              title: Row(children: [
                _ServiceLogo(service: service, size: 34),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Text(service.name, style: const TextStyle(fontSize: 16)),
                      Text(_host.isEmpty ? 'Offizielle Website' : _host,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: _muted),
                          overflow: TextOverflow.ellipsis),
                    ])),
              ]),
              actions: [
                IconButton(
                    tooltip: 'Neu laden',
                    onPressed: () => _controller?.reload(),
                    icon: const Icon(Icons.refresh_rounded)),
                IconButton(
                    tooltip: 'Dashboard',
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_outlined)),
              ],
              bottom: _progress < 1
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(3),
                      child: LinearProgressIndicator(
                          value: _progress == 0 ? null : _progress))
                  : null,
            ),
            body: Column(children: [
              if (_showInfoBanner)
                Container(
                  width: double.infinity,
                  color: const Color(0xFF201C31),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: _violet),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      _filteredServices.contains(service.name) && isWindows
                          ? 'Der experimentelle Werbefilter ist unter Windows wegen eines Stabilitätsfehlers vorübergehend deaktiviert.'
                          : _filteredServices.contains(service.name)
                              ? 'Experimenteller Filter aktiv: ausgewählte externe Werbedomains werden blockiert. Werbung des Anbieters kann weiter erscheinen.'
                              : 'Offizielle Anbieterseite. Anmeldung und Wiedergabe können im eingebetteten Browser eingeschränkt sein.',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFD8D1EC)),
                    )),
                  ]),
                ),
              if (_loadError != null)
                MaterialBanner(
                  content: Text(
                      'Die Seite konnte nicht geladen werden: $_loadError'),
                  actions: [
                    TextButton(
                        onPressed: () {
                          setState(() => _loadError = null);
                          _controller?.reload();
                        },
                        child: const Text('Erneut versuchen'))
                  ],
                ),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(service.url)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: true,
                    supportMultipleWindows: false,
                    javaScriptCanOpenWindowsAutomatically: false,
                    // Let WebView2 handle normal navigation natively. The Windows
                    // plugin pauses every navigation while an async Dart callback
                    // decides whether to resume it; YouTube performs many rapid
                    // redirects and this interception can leave its renderer stuck.
                    useShouldOverrideUrlLoading: false,
                    allowsBackForwardNavigationGestures: true,
                    // Restrict the experimental content filter to YouTube and
                    // Spotify. Other providers' pages remain untouched.
                    contentBlockers: shouldFilterAds && !isWindows
                        ? _adContentBlockers
                        : null,
                    // The Windows plugin's request interception hook can crash
                    // the native WebView2 renderer (access violation). Keep
                    // the experimental filter on platforms where the plugin
                    // provides a stable content-blocker implementation.
                    useShouldInterceptRequest: false,
                  ),
                  onWebViewCreated: (controller) => _controller = controller,
                  onLoadStart: (controller, url) {
                    if (mounted) {
                      setState(() {
                        _host = url?.host ?? '';
                        _loadError = null;
                      });
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    if (mounted) setState(() => _progress = progress / 100);
                  },
                  onReceivedError: (controller, request, error) {
                    if (request.isForMainFrame == true && mounted) {
                      setState(() => _loadError = error.description);
                    }
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BackIntent extends Intent {
  const _BackIntent();
}
