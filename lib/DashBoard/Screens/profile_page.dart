import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gosaiji DashBoard'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Image.asset('assets/images/naambrahmanew.png'),
          Spacer(),
          Image.asset(
            'assets/images/gosaiji4.png',
            height: 150,
          ),
          //Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'ॐ जटिने दण्डिने नित्यं लम्बोदर शरीरिणे।\nकमंडलु निषंगाय तस्मै ब्रम्हात्मने नमः।।',
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.brown.shade700,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
            ),
          ),
          Spacer(),
          Text(
            'Teachings (Updesh) of Gosaiji',
            style: TextStyle(
                fontSize: 20,
                color: Colors.brown.shade700,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          //Spacer(),
          Padding(
            padding: const EdgeInsets.only(
                top: 10,
                left: 13.0), // Adjust the left padding value as needed
            child: Text(
              ' -  Days will not remain the same like today\n -  Do not speak highly of self\n -  Do not speak ill of others\n -  The best virtue is non-violence\n -  Be kind to all living beings\n -  Have faith in the scriptures of saint and great men\n -  Give up everything that does not comply with the conduct of great men\n -  No enemy is greater than pride',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.brown.shade800,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Spacer(),
          // Text(
          //   'Read more about Shri Shri Gosaiji at our website',
          //   style: TextStyle(
          //       fontSize: 16,
          //       color: Colors.brown.shade700,
          //       fontStyle: FontStyle.italic,
          //       fontWeight: FontWeight.bold),
          //   textAlign: TextAlign.center,
          // ),
          Spacer(),
          //Image.asset('assets/bhajogurunew.png'), // Replace with your image path
        ],
      ),
    );
  }
}