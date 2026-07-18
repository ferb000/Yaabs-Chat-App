import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/reactions_api.dart';

final reactionsApiProvider = Provider<ReactionsApi>(
  (ref) => ReactionsApi(ref.watch(dioProvider)),
);
