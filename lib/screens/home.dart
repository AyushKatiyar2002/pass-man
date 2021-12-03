import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:helpful_components/common_snapshot_responses.dart';
import 'package:helpful_components/helpful_components.dart';
import 'package:passman/networks/account_syncer.dart';
import 'package:passman/networks/api_calls.dart';
import 'package:passman/networks/secret_syncer.dart';
import 'package:passman/objects/accounts_list.dart';
import 'package:passman/screens/mpass.dart';
import 'package:passman/utils/globals.dart';

import 'add_update_account.dart';
import 'add_update_note.dart';

class HomeScreen extends StatefulWidget {
  static const route = "/home";

  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _provider = AccountsList.provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: FirebaseAuth.instance.signOut,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            IconButton(
              onPressed: () => Modular.to.pushNamed(MPassword.route),
              icon: Icon(Icons.vpn_key),
            ),
          ],
        ),
      ),
      body: FutureBuilder<AccountsListProvider>(
          future: _provider,
          builder: (context, snapshot) {
            if (snapshot.hasError) throw snapshot.error!;
            return CommonAsyncSnapshotResponses(
              snapshot,
              builder: (AccountsListProvider _provider) => Consumer(
                builder: (_, ref, __) {
                  final _accountsList = ref.watch(_provider);
                  AccountSyncer.instance
                      .then((provider) => ref.watch(provider));
                  SecretSyncer.instance.then((provider) => ref.watch(provider));

                  return Center(
                    child: Container(
                      constraints:
                          BoxConstraints(maxWidth: Globals.webMaxWidth),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListView.builder(
                        itemCount: _accountsList.accounts.values.length,
                        itemBuilder: (_, i) =>
                            Consumer(builder: (context, _ref, _) {
                          final _accProvider =
                              _accountsList.accounts.values.toList()[i];
                          final _url = _ref
                              .watch(_accProvider.select((value) => value.url));
                          final logoUrl = Api.logo(_url);
                          final key = GlobalKey();

                          final popUp = (OverlayEntry overlayEntry) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          _ref
                                              .read(_provider)
                                              .remove(_ref.read(_accProvider));
                                          overlayEntry.remove();
                                        },
                                        child: Text(
                                          'Delete',
                                          style:
                                              Globals.kBodyText1Style.copyWith(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                          final logo = FutureBuilder<List<String>>(
                            future: logoUrl,
                            builder: (_, snapshot) {
                              late final Function(List<String>, [int index])
                                  _image;
                              _image = (List<String> urls, [int index = 0]) {
                                if (urls.length <= index) return Container();
                                return Image.network(
                                  urls[index],
                                  width: 10.w,
                                  height: 10.w,
                                  errorBuilder: (context, _, __) =>
                                      _image(urls, index + 1),
                                );
                              };
                              if (snapshot.data == null) return Container();
                              final __image = _image(snapshot.data!);
                              if (__image is Image)
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _image(snapshot.data!),
                                    SizedBox(width: 5.w),
                                  ],
                                );
                              return __image;
                            },
                          );

                          return Card(
                            key: key,
                            child: InkWell(
                              onTap: () {
                                Modular.to.pushNamed(
                                  AddUpdateAccount.route,
                                  arguments: _accProvider,
                                );
                              },
                              onLongPress: () {
                                showPopup(
                                  showBarrierColor: true,
                                  context: context,
                                  builder: (overlayEntry) => Popup(
                                    parentKey: key,
                                    child: popUp(overlayEntry),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 100,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    logo,
                                    Text(
                                      _url,
                                      style: TextStyle(fontSize: 4.w),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
      floatingActionButton: SpeedDial(
        child: Icon(Icons.add),
        children: [
          SpeedDialChild(
            label: "Add/update Password",
            child: Icon(Icons.security),
            onTap: () {
              Modular.to.pushNamed(AddUpdateAccount.route);
            },
          ),
          SpeedDialChild(
            label: "Add/update Note",
            child: Icon(Icons.note_add),
            onTap: () {
              Modular.to.pushNamed(AddUpdateNote.route);
            },
          ),
        ],
      ),
    );
  }
}
