import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

///Perform operations [$] on data [T]
abstract class TaskProvider<T, $> with ChangeNotifier {
  T _data;

  T get data => _data;

  final BuildContext context;

  TaskProvider(this.context) {
    assert(Scaffold.of(context, nullOk: true)?.mounted == true,
        '$T While handling errors, scaffold provides a way to show errors in snackbars. So, Please wrap your listeners in Scaffold');
    init();
  }

  void init();

  Map<$, DioError> _errors = {};
  Map<$, CancelToken> _cancelTokens = {};
  Set<$> _tasksRunning = Set();

  ///Check if a particular task is being performed
  bool busyWith($ task) => _tasksRunning.contains(task);

  ///If any of the tasks are running, it returns true
  bool get isBusy => _tasksRunning.isNotEmpty;

  ///Has error for any task
  bool get hasError => _errors.isNotEmpty;

  ///Has error for particular task
  bool hasErrorFor($ task) => _errors[task] != null;

  bool get hasData => _data != null;

  DioError error($ task) => _errors[task];

  @protected
  @mustCallSuper
  T setData(T value, $ task) {
    _data = value;
    _errors.remove(task);
    _cancelTokens.remove(task);
    return _data;
  }

  ///Marks [task] as IDLE
  @protected
  @mustCallSuper
  void idleAndNotify($ task) {
    _tasksRunning.remove(task);
    _cancelTokens.remove(busyWith);
    notifyListeners();
  }

  ///Marks [task] as LOADING
  ///Returns [CancelToken] which can be set to API request and can be cancelled on this provider disposal
  @protected
  @mustCallSuper
  CancelToken notifyLoading($ task) {
    _cancelTokens[task] ??= CancelToken();
    _tasksRunning.add(task);
    notifyListeners();
    return _cancelTokens[task];
  }

  ///Cancel or abort operation associated with [tasks].
  void cancel(List<$> tasks, [String reason]) {
    tasks.forEach((_) {
      if (_cancelTokens[_]?.isCancelled == false)
        _cancelTokens[_].cancel('${reason ?? 'IGNORE: Reason not mentioned'}');
      _cancelTokens.remove(_);
    });
  }

  ///[task]  - Indicates which task has got the error
  ///[action] - Required to retry the function in case of No Internet or on retry button
  ///[widgetType] - Indicates where the error has to be shown to the user
  @protected
  @mustCallSuper
  void handleError({
    @required dioError,
    @required $ task,
    VoidCallback action,
    WidgetType widgetType,
  }) {
    if (dioError is! DioError) dioError = DioError(error: dioError);
    dioError = dioError..request ??= RequestOptions();
    dioError..request.extra['action'] = action;
    dioError..request.extra['widgetType'] = widgetType;

    //TODO Report crashlytics here

    //TODO Show error based on dioError and widgetType

    _errors[task] = dioError;
  }

  @override
  @mustCallSuper
  void dispose() {
    cancel(_cancelTokens.keys.toList(growable: false),
        'IGNORE: Disposing $T provider');
    super.dispose();
  }
}

///Call [addScrollListener] in the  [init]
///handles only [ScrollDirection.reverse], [onScroll] is called when the end of scroll is [_loadingOffset] pixels away
///return [Future] in [onScroll] as onScroll will only be triggered after completion of [onScroll]
mixin LoadOnScroll<T, $> on TaskProvider<T, $> {
  ///lock system to prevent multiple trigger of [onScroll]
  bool _lock = false;

  ScrollController _controller = ScrollController();

  ///Bind this controller to the scrollable widget, eg [ListView]
  ScrollController get controller => _controller;

  void scrollToZero() {
    if (_controller.hasClients) {
      _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    }
  }

  ///The pixels after which the data should be loaded.
  ///
  /// For example, if [_loadingOffset] is 300 and  a [ListView] with max scroll extent 1200,
  /// When user scrolls after 900, [onScroll] is triggered.
  static const _loadingOffset = 450.0;

  addScrollListener() {
    _controller.removeListener(_onScroll);
    _controller.addListener(_onScroll);
  }

  removeScrollListener() {
    _controller.removeListener(_onScroll);
  }

  void _onScroll() {
    if (!_lock &&
        _controller.position.userScrollDirection == ScrollDirection.reverse &&
        _controller.offset >
            _controller.position.maxScrollExtent - _loadingOffset) {
      log('OnScroll Load data', name: 'DATA FETCHER');
      _lock = true;
      onScroll().whenComplete(() => _lock = false);
    }
  }

  ///Get next n data on scroll and add it to the [data]
  Future onScroll();

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }
}

enum WidgetType {
  ///[showDialog]
  dialog,

  ///[ScaffoldState.showSnackBar]
  snackBar,

  ///It is displayed on the same widget on which it has to load.
  ///
  /// Example, in [Home] in any tab `X`, data is being loaded on `X` and error is also shown `X`.
  onscreen
}
