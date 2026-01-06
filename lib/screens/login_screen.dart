import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false; // Per mostrare un cerchietto mentre carica

  // FUNZIONE DI LOGIN GOOGLE
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fa partire il flusso di login (apre il popup di Google)
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // L'utente ha annullato il login (tasto indietro)
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Otteniamo i dettagli di autenticazione dalla richiesta
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Creiamo una credenziale per Firebase usando i token di Google
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Entriamo in Firebase con quella credenziale
      await FirebaseAuth.instance.signInWithCredential(credential);

      // NOTA: Non serve navigare manualmente alla Home.
      // Il "Portiere" in main.dart noterà il login e cambierà pagina da solo.
    } catch (e) {
      print("Errore durante il login: $e");
      setState(() {
        _isLoading = false;
      });

      // Mostriamo un avviso di errore
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore Login: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary, // Sfondo colorato
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min, // La card è alta quanto basta
              children: [
                // Icona o Logo
                const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Colors.teal,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gestione Spese',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Accedi per salvare i tuoi dati',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Bottone o Caricamento
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.login), // Icona generica per ora
                    label: const Text('Accedi con Google'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
