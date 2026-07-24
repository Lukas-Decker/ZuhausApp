package de.lukas.multiapp

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity statt FlutterActivity: local_auth braucht eine
// FragmentActivity, um den Biometrie-Dialog anzeigen zu koennen.
class MainActivity : FlutterFragmentActivity()
