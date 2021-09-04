import 'package:flutter/material.dart';

class CommonAsyncSnapshotResponses<T> extends StatelessWidget {
  CommonAsyncSnapshotResponses(
    this.snapshot, {
    this.builder,
    this.onLoading = const Center(child: CircularProgressIndicator()),
  });

  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data)? builder;
  final Widget onLoading;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) return onLoading;
    if (snapshot.hasError) {
      print(snapshot.error);
      return Center(child: Text("Some Error occurred"));
    }
    if (!snapshot.hasData) return Center(child: Text("Nothing Here!"));
    return builder == null ? Container() : builder!(snapshot.data!);
  }
}
