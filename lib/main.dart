import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() => runApp(const StreamHubApp());

const _ink = Color(0xFF090B12);
const _panel = Color(0xFF151925);
const _muted = Color(0xFFA5ADBE);
const _violet = Color(0xFFB7A0FF);

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
        home: const HubShell(),
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
    name: 'Netflix', tagline: 'Serien, Filme & Originals',
    url: 'https://www.netflix.com/', icon: Icons.play_arrow_rounded,
    color: Color(0xFFE50914), category: 'Serien & Filme',
    description: 'Serien, Filme, Dokumentationen und Netflix Originals.',
  ),
  StreamingService(
    name: 'Disney+', tagline: 'Disney, Pixar, Marvel & mehr',
    url: 'https://www.disneyplus.com/', icon: Icons.auto_awesome_rounded,
    color: Color(0xFF176BEF), category: 'Serien & Filme',
    description: 'Geschichten von Disney, Pixar, Marvel, Star Wars und National Geographic.',
  ),
  StreamingService(
    name: 'Prime Video', tagline: 'Filme, Serien & Sport',
    url: 'https://www.primevideo.com/', icon: Icons.movie_outlined,
    color: Color(0xFF00A8E0), category: 'Serien & Filme',
    description: 'Filme, Serien, Originals und je nach Abo weitere Channels.',
  ),
  StreamingService(
    name: 'YouTube', tagline: 'Videos, Live & Premium',
    url: 'https://www.youtube.com/', icon: Icons.smart_display_rounded,
    color: Color(0xFFFF0033), category: 'Video',
    description: 'Videos, Livestreams und Creator-Inhalte auf YouTube.',
  ),
  StreamingService(
    name: 'WOW', tagline: 'Serien, Filme & Live-Sport',
    url: 'https://www.wowtv.de/', icon: Icons.bolt_rounded,
    color: Color(0xFF7445D8), category: 'Serien & Filme',
    description: 'Das Streaming-Angebot von WOW mit Serien, Filmen und Sport.',
  ),
  StreamingService(
    name: 'RTL+', tagline: 'Shows, Serien & Live-TV',
    url: 'https://plus.rtl.de/', icon: Icons.live_tv_rounded,
    color: Color(0xFFE45C26), category: 'Live & Shows',
    description: 'Shows, Serien, Reality und weitere RTL+-Inhalte.',
  ),
  StreamingService(
    name: 'Joyn', tagline: 'Mediathek & Live-TV',
    url: 'https://www.joyn.de/', icon: Icons.tv_rounded,
    color: Color(0xFF8A5CF6), category: 'Live & Shows',
    description: 'Mediatheken, Shows und Live-TV auf Joyn.',
  ),
  StreamingService(
    name: 'Paramount+', tagline: 'Filme & Paramount Originals',
    url: 'https://www.paramountplus.com/', icon: Icons.local_movies_outlined,
    color: Color(0xFF0878D1), category: 'Serien & Filme',
    description: 'Filme, Serien und Originals von Paramount+.',
  ),
];

class HubShell extends StatefulWidget {
  const HubShell({super.key});

  @override
  State<HubShell> createState() => _HubShellState();
}

class _HubShellState extends State<HubShell> {
  int _section = 0;
  String _query = '';
  final Set<String> _favorites = <String>{};

  List<StreamingService> get _visibleServices {
    final base = _section == 1
        ? services.where((service) => _favorites.contains(service.name))
        : services;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return base.toList();
    return base.where((service) {
      return '${service.name} ${service.tagline} ${service.category}'
          .toLowerCase().contains(query);
    }).toList();
  }

  void _toggleFavorite(StreamingService service) {
    setState(() {
      if (!_favorites.add(service.name)) _favorites.remove(service.name);
    });
  }

  Future<void> _openService(StreamingService service) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => ProviderPage(service: service),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final page = _section == 2
        ? const AboutPage()
        : _section == 1
            ? _buildCatalog(favoritesOnly: true)
            : _buildCatalog();

    return Scaffold(
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              backgroundColor: const Color(0xFF0E1119),
              selectedIndex: _section,
              onDestinationSelected: (value) => setState(() => _section = value),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.fromLTRB(0, 28, 0, 36),
                child: _BrandMark(compact: true),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: Text('Entdecken'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: Text('Favoriten'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.info_outline_rounded),
                  selectedIcon: Icon(Icons.info_rounded),
                  label: Text('Info'),
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
              onDestinationSelected: (value) => setState(() => _section = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded), label: 'Entdecken'),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded), label: 'Favoriten'),
                NavigationDestination(
                  icon: Icon(Icons.info_outline_rounded), label: 'Info'),
              ],
            ),
    );
  }

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
                              favoritesOnly ? 'Deine Favoriten' : 'Alles an einem Ort',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              favoritesOnly
                                  ? 'Deine gespeicherten Streaming-Dienste.'
                                  : 'Deine Streaming-Dienste. Ein übersichtlicher Startpunkt.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _muted),
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
                  if (!favoritesOnly && MediaQuery.sizeOf(context).width < 520) ...[
                    const SizedBox(height: 14),
                    const _StatusPill(),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        favoritesOnly ? 'GESPEICHERT' : 'ANBIETER',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _muted, letterSpacing: 1.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${visible.length}', style: const TextStyle(fontSize: 12)),
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
                  _section = 0;
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
                  final columns = width >= 1120 ? 4 : width >= 760 ? 3 : width >= 480 ? 2 : 1;
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
              gradient: const LinearGradient(colors: [_violet, Color(0xFF7D68F2)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hub_rounded, color: Color(0xFF171322)),
          ),
          if (!compact) ...[
            const SizedBox(width: 11),
            Text('STREAM HUB', style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
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
                      tooltip: isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
                      onPressed: onFavorite,
                      icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                      color: isFavorite ? const Color(0xFFFF7596) : _muted,
                    ),
                  ],
                ),
                const Spacer(),
                Text(service.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(service.tagline, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _muted)),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(Icons.open_in_new_rounded, size: 14, color: _violet),
                    const SizedBox(width: 6),
                    Text('Anbieter öffnen', style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _violet, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(service.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _muted)),
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
          boxShadow: [BoxShadow(color: service.color.withOpacity(.24), blurRadius: 18)],
        ),
        child: Icon(service.icon, color: Colors.white, size: size * .58),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.favoritesOnly, required this.hasQuery, required this.onBrowse});
  final bool favoritesOnly;
  final bool hasQuery;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(favoritesOnly && !hasQuery ? Icons.favorite_border_rounded : Icons.search_off_rounded,
              size: 42, color: _muted),
            const SizedBox(height: 14),
            Text(hasQuery ? 'Kein Anbieter gefunden' : 'Noch keine Favoriten',
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(hasQuery ? 'Passe deine Suche an.' : 'Speichere Anbieter über das Herzsymbol.',
              style: const TextStyle(color: _muted)),
            if (favoritesOnly) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onBrowse, child: const Text('Anbieter entdecken')),
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
              Text('Ein Hub. Deine Dienste.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text('Stream Hub ist ein früher, noch unvollständiger Prototyp. Er soll ein zentraler Startpunkt für Angebote wie Netflix, Disney+ und Prime Video werden und deren offizielle Websites in einem eigenen Bereich öffnen.',
                style: TextStyle(color: _muted, height: 1.5)),
              const SizedBox(height: 24),
              const _InfoTile(
                icon: Icons.verified_user_outlined,
                title: 'Dein Konto bleibt beim Anbieter',
                body: 'Melde dich nur auf der offiziellen Anbieterseite an. Stream Hub fragt keine Passwörter ab und betreibt keinen Video-Proxy.',
              ),
              const SizedBox(height: 12),
              const _InfoTile(
                icon: Icons.shield_outlined,
                title: 'Wiedergabe hängt vom Anbieter ab',
                body: 'Einige Dienste blockieren eingebettete Browser oder verlangen zertifizierte Apps. DRM-Wiedergabe und Anmeldung sind in diesem Prototyp nicht garantiert.',
              ),
              const SizedBox(height: 12),
              const _InfoTile(
                icon: Icons.handshake_outlined,
                title: 'Anbieterfreigaben stehen noch aus',
                body: 'Wir planen, mit Netflix, Disney+, Amazon und weiteren Anbietern die Bedingungen zu klären und nötige schriftliche Freigaben einzuholen. Bestätigungen liegen noch nicht vor; Anmeldung und Wiedergabe sind daher nicht zugesichert.',
              ),
              const SizedBox(height: 24),
              Text('Stream Hub • Prototyp', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _muted)),
            ]),
          ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.body});
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(color: _muted, height: 1.4)),
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
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _BackIntent(),
        SingleActivator(LogicalKeyboardKey.browserBack): _BackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BackIntent: CallbackAction<_BackIntent>(onInvoke: (_) { _handleBack(); return null; }),
        },
        child: PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) { if (!didPop) _back(); },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(tooltip: 'Zurück', onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
              titleSpacing: 0,
              title: Row(children: [
                _ServiceLogo(service: service, size: 34),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(service.name, style: const TextStyle(fontSize: 16)),
                  Text(_host.isEmpty ? 'Offizielle Website' : _host,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _muted),
                    overflow: TextOverflow.ellipsis),
                ])),
              ]),
              actions: [
                IconButton(tooltip: 'Neu laden', onPressed: () => _controller?.reload(), icon: const Icon(Icons.refresh_rounded)),
                IconButton(tooltip: 'Dashboard', onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), icon: const Icon(Icons.home_outlined)),
              ],
              bottom: _progress < 1
                  ? PreferredSize(preferredSize: const Size.fromHeight(3),
                    child: LinearProgressIndicator(value: _progress == 0 ? null : _progress))
                  : null,
            ),
            body: Column(children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF201C31),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: _violet),
                  SizedBox(width: 8),
                  Expanded(child: Text('Offizielle Anbieterseite. Anmeldung und Wiedergabe können im eingebetteten Browser eingeschränkt sein.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFD8D1EC)))),
                ]),
              ),
              if (_loadError != null)
                MaterialBanner(
                  content: Text('Die Seite konnte nicht geladen werden: $_loadError'),
                  actions: [TextButton(onPressed: () { setState(() => _loadError = null); _controller?.reload(); }, child: const Text('Erneut versuchen'))],
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
                  ),
                  onWebViewCreated: (controller) => _controller = controller,
                  onLoadStart: (controller, url) {
                    if (mounted) setState(() { _host = url?.host ?? ''; _loadError = null; });
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
