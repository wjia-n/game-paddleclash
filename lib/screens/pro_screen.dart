import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/paddle_themes.dart';
import '../theme/paddle_ui.dart';

/// PRO screen: Free-vs-Pro comparison, real purchases, tip jar, restore.
/// Graceful "available after store setup" state when Play Console products
/// are not configured yet — never a fake buy button.
class ProScreen extends StatefulWidget {
  final ClashAudio audio;
  final ClashSettings settings;
  final ClashStore store;
  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  ClashSettings get _s => widget.settings;
  ClashStore get _store => widget.store;
  PaddleThemeDef get _t =>
      PaddleThemes.byId(_s.themeId, custom: _s.customTheme);

  static const _rows = [
    ['All 3 AI difficulties', '2', '3 ✨'],
    ['Themes', '4', '12 + creator ✨'],
    ['Paddle styles', '4', '8 ✨'],
    ['Ball styles', '4', '8 ✨'],
    ['Custom theme creator', '—', 'Yes ✨'],
    ['Hard AI rival', '—', 'Yes ✨'],
    ['Support indie dev', '💛', '💛💛'],
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.ivory),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Paddle Clash PRO',
              style: ClashText.label(17, t: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 6),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/paddleclash_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Text('Go PRO, smash harder.',
                      style: ClashText.display(26, t: t),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    'One-time unlock. Yours forever, on every device.',
                    style: ClashText.body(14, t: t),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  _comparisonTable(t),
                  const SizedBox(height: 18),
                  _buySection(t),
                  const SizedBox(height: 18),
                  _tipJar(t),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      widget.audio.click();
                      _store.restore();
                    },
                    child: Text('Restore purchases',
                        style: ClashText.label(14,
                            t: t, color: t.accentLight)),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: _store.purchaseError,
                    builder: (_, err, __) => err == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(err,
                                style: ClashText.body(13,
                                    t: t,
                                    color: const Color(0xFFE08080)),
                                textAlign: TextAlign.center),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _comparisonTable(PaddleThemeDef t) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [
          t.tableMid,
          t.tableDark,
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border.all(color: t.accent.withValues(alpha: 0.65), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              color: Colors.black.withValues(alpha: 0.25),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('FEATURE',
                        style: ClashText.label(12,
                            t: t, color: t.accentLight))),
                Expanded(
                    child: Text('FREE',
                        style: ClashText.label(12,
                            t: t, color: t.accentLight),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('PRO',
                        style: ClashText.label(12,
                            t: t, color: t.accentLight),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          for (int i = 0; i < _rows.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                border: i < _rows.length - 1
                    ? Border(
                        bottom: BorderSide(
                            color:
                                t.accent.withValues(alpha: 0.25)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(_rows[i][0],
                          style: ClashText.body(13, t: t))),
                  Expanded(
                      child: Text(_rows[i][1],
                          style: ClashText.body(13, t: t),
                          textAlign: TextAlign.center)),
                  Expanded(
                      child: Text(_rows[i][2],
                          style: ClashText.label(13,
                              t: t, color: t.accentLight),
                          textAlign: TextAlign.center)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buySection(PaddleThemeDef t) {
    if (_s.isPro) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.accent, width: 2),
          color: t.accent.withValues(alpha: 0.15),
        ),
        child: Text('✦  PRO is active — enjoy the full table!  ✦',
            style: ClashText.label(15, t: t, color: t.accentLight),
            textAlign: TextAlign.center),
      );
    }
    final pro = _store.proProduct;
    if (!_store.storeReady || pro == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.3),
          border:
              Border.all(color: t.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          _store.error ?? 'PRO unlock coming soon.',
          style: ClashText.body(14, t: t),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _store.purchaseInProgress,
      builder: (_, busy, __) => WoodButton(
        label: busy ? 'Working…' : 'Unlock PRO — ${pro.price}',
        onTap: busy ? () {} : () => _store.buyPro(),
        theme: t,
        width: double.infinity,
      ),
    );
  }

  Widget _tipJar(PaddleThemeDef t) {
    final coffee = _store.coffeeProduct;
    final choco = _store.chocolateProduct;
    return PlaqueCard(
      theme: t,
      title: '☕  TIP JAR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paddle Clash is free forever. Tips keep the tables polished!',
            style: ClashText.body(13, t: t),
          ),
          const SizedBox(height: 12),
          if (!_store.storeReady)
            Text(
              _store.error ?? 'Tips available after store setup.',
              style: ClashText.body(13,
                  t: t, color: t.ivory.withValues(alpha: 0.6)),
            )
          else
            Row(
              children: [
                if (coffee != null)
                  Expanded(
                      child: _tipBtn(t, '☕ Coffee', coffee.price,
                          () => _store.buyTip(coffee))),
                if (coffee != null && choco != null)
                  const SizedBox(width: 10),
                if (choco != null)
                  Expanded(
                      child: _tipBtn(t, '🍫 Chocolate', choco.price,
                          () => _store.buyTip(choco))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tipBtn(
      PaddleThemeDef t, String label, String price, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: t.accent, width: 2),
        ),
        child: Column(
          children: [
            Text(label, style: ClashText.label(14, t: t)),
            const SizedBox(height: 2),
            Text(price,
                style: ClashText.body(13,
                    t: t, color: t.accentLight)),
          ],
        ),
      ),
    );
  }
}
