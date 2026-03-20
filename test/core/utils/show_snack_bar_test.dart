import 'package:flutter_test/flutter_test.dart';
import 'package:rainy/core/utils/show_snack_bar.dart';
import 'package:rainy/core/utils/snackbar_overlay.dart';

void main() {
  tearDown(() {
    SnackBarOverlay.instance.hide();
  });

  test('showSnackBar forwards message to overlay', () {
    showSnackBar('Network error', isError: true);

    final data = SnackBarOverlay.instance.snackBarNotifier.value;
    expect(data?.message, 'Network error');
    expect(data?.isError, isTrue);
  });
}
