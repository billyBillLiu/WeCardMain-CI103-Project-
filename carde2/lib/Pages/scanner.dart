import 'dart:io';
import '../Pages/AuthenticationPages/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/button.dart';
import '../components/textfield.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'pageA.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final qrKey = GlobalKey(debugLabel: "QR");
  QRViewController? controller;
  Barcode? barcode;

  void saveCard(String code) async {
    String userID = await FirebaseAuth.instance.currentUser!.uid;

    if (await isStringInUserCollection(code)) {
      await FirebaseFirestore.instance.collection('users').doc(userID).set({
        'cardCollection': FieldValue.arrayUnion([code])
      }, SetOptions(merge: true));
      cardAdded();
    } else {
      doesNotExist();
    }
  }

  cardAdded() {
    showDialog(
        context: context,
        builder: (context) {
          return const SimpleDialog(
              contentPadding: EdgeInsets.fromLTRB(40, 40, 40, 0),
              title: Text("Card Successfully Added"),
              backgroundColor: Colors.white,
              children: <Widget>[
                SimpleDialogOption(
                  child: Text(""),
                )
              ]);
        });
  }

  doesNotExist() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("User Does Not Exist",
                style: TextStyle(color: Colors.red)),
            backgroundColor: Colors.black,
          );
        });
  }

  Future<bool> isStringInUserCollection(String searchString) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, isEqualTo: searchString)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() async {
    super.reassemble();

    if (Platform.isAndroid) {
      await controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Scaffold(
              body: Stack(alignment: Alignment.center, children: <Widget>[
        buildQrView(context),
        Positioned(
            bottom: 75,
            child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => HomePage()));
                },
                child: exitButton())),
      ])));

  Widget buildQrView(BuildContext context) => QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderLength: 20,
          borderWidth: 10,
          cutOutSize: MediaQuery.of(context).size.width * 0.8,
          borderColor: Colors.green));

  Widget exitButton() => Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromARGB(255, 55, 55, 55),
      ),
      child: Icon(
        Icons.arrow_back,
        color: Colors.red,
      ));

  void _onQRViewCreated(QRViewController controller) {
    setState(() => this.controller = controller);

    controller.scannedDataStream.listen((barcode) {
      controller.pauseCamera();
      final String qrCodeData = barcode.code as String;
      saveCard(qrCodeData);
      Navigator.push(
              context, MaterialPageRoute(builder: (context) => HomePage()))
          .then((value) => controller.resumeCamera());
    });
  }
}
