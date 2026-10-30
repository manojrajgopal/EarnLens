import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';

/// Colours offered for account avatars (the chart series palette).
List<Color> get accountColors => AppColors.series;

/// Emoji offered when creating an account, in addition to each type's default.
const accountEmoji = [
  '🙂', '😎', '👩', '👨', '👧', '👦', '👵', '👴', //
  '👨‍👩‍👧', '🤝', '🏢', '💻', '🎨', '🛠️', '🚗', '🏠', //
  '🌱', '⭐', '🔥', '💎', '🎯', '📚', '🎵', '✨',
];

final _decoded = <String, Uint8List>{};

/// Decoded profile photo, cached so avatars don't decode base64 every frame.
Uint8List? _photo(String? base64) {
  if (base64 == null || base64.isEmpty) return null;
  if (_decoded.length > 32) _decoded.clear();
  try {
    return _decoded.putIfAbsent(base64, () => base64Decode(base64));
  } on FormatException {
    return null;
  }
}

/// Round avatar of an individual or combined account: a photo, or an emoji
/// on the account's colour. [locked] adds a small padlock badge.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    super.key,
    required this.emoji,
    required this.colorIndex,
    this.image,
    this.size = 44,
    this.locked = false,
    this.ring = false,
    this.semanticLabel,
  });

  AccountAvatar.of(Account a, {Key? key, double size = 44, bool locked = false, bool ring = false})
      : this(
          key: key,
          emoji: a.emoji,
          colorIndex: a.colorIndex,
          image: a.avatarImage,
          size: size,
          locked: locked,
          ring: ring,
          semanticLabel: a.name,
        );

  AccountAvatar.combined(CombinedAccount c, {Key? key, double size = 44, bool ring = false})
      : this(
          key: key,
          emoji: c.emoji,
          colorIndex: c.colorIndex,
          image: c.avatarImage,
          size: size,
          ring: ring,
          semanticLabel: c.name,
        );

  final String emoji;
  final int colorIndex;
  final String? image;
  final double size;
  final bool locked;

  /// White ring and glow, for the active account.
  final bool ring;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.seriesAt(colorIndex);
    final photo = _photo(image);
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: photo == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(color, Colors.white, 0.45)!, color],
              )
            : null,
        border: ring ? Border.all(color: context.colors.card, width: size > 40 ? 3 : 2) : null,
        boxShadow: ring ? AppShadows.glow : null,
        image: photo == null ? null : DecorationImage(image: MemoryImage(photo), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: photo == null
          ? Text(emoji, style: TextStyle(fontSize: size * 0.46, height: 1), textScaler: TextScaler.noScaling)
          : null,
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(clipBehavior: Clip.none, children: [
            avatar,
            if (locked)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.card(Theme.of(context).brightness),
                  ),
                  child: Icon(Icons.lock_rounded, size: size * 0.26, color: context.colors.accentText),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Overlapping avatars of a combined account's members.
class MemberStack extends StatelessWidget {
  const MemberStack({super.key, required this.members, this.size = 28, this.max = 4});
  final List<Account> members;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(max).toList();
    final extra = members.length - shown.length;
    final step = size * 0.62;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      width: count == 0 ? 0 : size + step * (count - 1),
      height: size,
      child: Stack(children: [
        for (final (i, m) in shown.indexed)
          Positioned(
            left: step * i,
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.colors.card, width: 2)),
              child: AccountAvatar.of(m, size: size - 4),
            ),
          ),
        if (extra > 0)
          Positioned(
            left: step * shown.length,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.accentSoft,
                border: Border.all(color: context.colors.card, width: 2),
              ),
              child: Text('+$extra', style: AppType.caption.copyWith(color: context.colors.accentText)),
            ),
          ),
      ]),
    );
  }
}

/// Crops [bytes] (any image format the platform decodes) to a centred square
/// and scales it to [size] pixels, returning base64 PNG for storage.
Future<String> squareAvatarPng(Uint8List bytes, {int size = 192}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final side = image.width < image.height ? image.width : image.height;
  final src = Rect.fromLTWH((image.width - side) / 2, (image.height - side) / 2, side.toDouble(), side.toDouble());
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    src,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..filterQuality = FilterQuality.high,
  );
  final out = await recorder.endRecording().toImage(size, size);
  final png = await out.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  out.dispose();
  if (png == null) throw const FormatException('Could not encode the photo');
  return base64Encode(png.buffer.asUint8List());
}
