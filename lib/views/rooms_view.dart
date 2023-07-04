import 'package:flutter/material.dart';
import 'package:web_rtc/firebase_data_source.dart';
import 'package:web_rtc/views/chat_view.dart';

class RoomsView extends StatefulWidget {
  const RoomsView({
    Key? key,
  }) : super(key: key);

  @override
  State<RoomsView> createState() => _RoomsViewState();
}

class _RoomsViewState extends State<RoomsView> {
  FirebaseDataSource dataSource = FirebaseDataSource();

  Future<void> onRefresh() async {
    setState(() {});
  }

  @override
  void initState(){
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Available Rooms',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white)),
          centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Text(
              'Choose a room to continue...',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            const SizedBox(
              height: 20,
            ),
            RefreshIndicator(
              onRefresh: onRefresh,
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 3,
                child: FutureBuilder(
                  future: dataSource.getAvailableRoomsIDs(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      // Handle any errors that occur during the future operation
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return ListView.separated(
                        separatorBuilder: (context, index) {
                          return const Divider();
                        },
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              if(snapshot.data?[index]!=null){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return  ChatView(
                                        roomId: snapshot.data?[index].toString(),
                                      );
                                    },
                                  ),
                                );
                              }else{
                                print('Room Id is null');
                              }

                            },
                            child: Center(
                              child:
                                  Text(snapshot.data?[index].toString() ?? ''),
                            ),
                          );
                        },
                        itemCount: snapshot.data?.length ?? 0,
                      );
                    }
                  },
                ),
              ),
            ),
            const Text(
              'You can also create a room:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll<Color>(Colors.blue)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const ChatView(
                          roomId: null,
                        );
                      },
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    'Create A Room',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
