import 'package:flutter/material.dart';

const _cropIds = {'corn', 'tomato', 'flower', 'apple', 'herbs', 'blueberry'};

String farmAsset(String name) => 'assets/farm/$name.png';

/// 0 = sprout (under 34%), 1 = growing, 2 = ripe.
int growthLevel(int progress, int needed, {required bool ripe}) {
  if (ripe) return 2;
  return needed > 0 && progress / needed >= 0.34 ? 1 : 0;
}

class CropArt extends StatelessWidget {
  final String? crop;
  final int level;
  final double size;

  const CropArt({super.key, required this.crop, required this.level, required this.size});

  @override
  Widget build(BuildContext context) {
    final id = _cropIds.contains(crop) ? crop : 'herbs';
    return ExcludeSemantics(
      child: Image.asset(
        farmAsset('crop-$id-$level'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      ),
    );
  }
}

class FarmImage extends StatelessWidget {
  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;

  const FarmImage(this.name, {super.key, this.width, this.height, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image.asset(farmAsset(name), width: width, height: height, fit: fit),
    );
  }
}
