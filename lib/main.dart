import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskprovider/init_loader.dart';
import 'package:taskprovider/task_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Task provider example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ChangeNotifierProvider(
        create: (context) {
          return NotificationProvider(context);
        },
        child: DefaultLoader<NotificationProvider, List<int>, $Notification>(
          task: $Notification.init,
          builder: (context, data, child) {
            final notiProvider =
                Provider.of<NotificationProvider>(context, listen: false);
            return RefreshIndicator(
              onRefresh: notiProvider.refresh,
              child: SingleChildScrollView(
                controller: notiProvider.controller,
                child: Column(
                  children: [
                    for (int i = 0; i < data.length; i++)
                      ListTile(title: Text('${data[i]}')),
                    Consumer<NotificationProvider>(
                      builder: (context, value, child) {
                        if (notiProvider.busyWith($Notification.loadMore)) {
                          return Center(child: CircularProgressIndicator());
                        } else {
                          return SizedBox();
                        }
                      },
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

///########### STATE PROVIDER FOR ABOVE EXAMPLE
///
///
enum $Notification { init, refresh, loadMore }

class NotificationProvider extends TaskProvider<List<int>, $Notification>
    with LoadOnScroll {
  NotificationProvider(BuildContext context) : super(context) {
    addScrollListener();
  }

  @override
  void init() {
    final task = $Notification.init;
    notifyLoading(task);
    Future.delayed(Duration(seconds: 2))
        .then((v) => setData(List.generate(20, (i) => i), task))
        .catchError((err) => handleError(dioError: err, task: task))
        .whenComplete(() => idleAndNotify(task));
  }

  Future refresh() async {
    final task = $Notification.refresh;
    if (busyWith(task)) return;
    notifyLoading(task);
    return Future.delayed(Duration(seconds: 1))
        .then((v) => setData([...List.generate(5, (i) => i), ...data], task))
        .catchError((err) => handleError(dioError: err, task: task))
        .whenComplete(() => idleAndNotify(task));
  }

  @override
  Future onScroll() async {
    final task = $Notification.loadMore;
    if (busyWith(task)) return;
    notifyLoading(task);
    return Future.delayed(Duration(seconds: 1))
        .then((v) => setData([...data, ...List.generate(10, (i) => i)], task))
        .catchError((err) => handleError(dioError: err, task: task))
        .whenComplete(() => idleAndNotify(task));
  }
}
