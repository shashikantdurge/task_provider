import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskprovider/task_provider.dart';

typedef Widget CustomLoader<P>(P provider, Widget loader);

class DefaultLoader<P extends TaskProvider, D, $> extends StatelessWidget {
  ///The task that the loader is listening to.
  ///It must be the task that is defined in [DataFetcher.initData]
  final $ task;

  ///This is built when [DataFetcher] finished with non-null data.
  final ValueWidgetBuilder<D> builder;
  final Widget child;

  final CustomLoader<P> customLoader;

  const DefaultLoader({
    Key key,
    @required this.task,
    @required this.builder,
    this.customLoader,
    this.child,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Selector<P, D>(
      builder: (context, data, _) {
        if (data != null) return builder(context, data, child);
        return Consumer<P>(builder: (context, provider, child) {
          Widget state;
          if (provider.busyWith(task))
            state = CircularProgressIndicator();
          else if (provider.hasError)
            state = Text('DEFAULT ERROR WIDGET');
          else
            state = Text('SOMETHING WENT WRONG!');
          state = Center(child: state);
          if (customLoader != null) return customLoader(provider, state);
          return state;
        });
      },
      selector: (context, provider) => provider.data,
    );
  }
}
