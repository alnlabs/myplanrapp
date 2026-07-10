import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const shellFromMoreQueryKey = 'from';
const shellFromMoreQueryValue = 'more';

bool openedFromMore(BuildContext context) {
  return GoRouterState.of(context).uri.queryParameters[shellFromMoreQueryKey] ==
      shellFromMoreQueryValue;
}

String shellRouteFromMore(String path) {
  final uri = Uri.parse(path);
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          shellFromMoreQueryKey: shellFromMoreQueryValue,
        },
      )
      .toString();
}
