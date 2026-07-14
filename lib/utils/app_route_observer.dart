import 'package:flutter/material.dart';

/// Lets long-lived screens react when a page pushed above them is dismissed.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
