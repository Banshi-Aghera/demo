import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shell_tab_provider.g.dart';

enum ShellTab { home, categories, society, cart, profile }

/// Selected bottom-nav tab, so any screen can jump to e.g. the cart.
@Riverpod(keepAlive: true)
class ShellTabState extends _$ShellTabState {
  @override
  ShellTab build() => ShellTab.home;

  void select(ShellTab tab) => state = tab;
}
