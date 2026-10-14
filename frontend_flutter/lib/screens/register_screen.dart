import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../providers/user_provider.dart';
import '../theme.dart';
import '../main_app.dart';
import '../utils/country_data.dart';
import '../services/first_launch_service.dart';
import '../config/api_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  bool loading = false;
  Country selectedCountry = CountryData.countries.first; // Cameroun par défaut
  File? _photoFile;
  final _picker = ImagePicker();

  /// Choisir une photo depuis la galerie
  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => _photoFile = File(picked.path));
      }
    } catch (e) {
      debugPrint('Erreur sélection photo: $e');
    }
  }

  /// Uploader la photo vers /api/upload → retourne l'URL stable /api/files/{key}
  Future<String?> _uploadPhoto() async {
    if (_photoFile == null) return null;
    try {
      final base = await ApiConfig.getBaseUrl();
      final request = http.MultipartRequest('POST', Uri.parse('$base/api/upload'))
        ..files.add(
            await http.MultipartFile.fromPath('file', _photoFile!.path));
      final res = await request.send().timeout(const Duration(seconds: 30));
      if (res.statusCode == 201) {
        final body = json.decode(await res.stream.bytesToString());
        if (body['key'] != null) {
          return '$base/api/files/${Uri.encodeComponent(body['key'])}';
        }
      }
    } catch (e) {
      debugPrint('⚠️ Upload photo de profil échoué: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.appColors.background, context.appColors.surfaceVariant],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Creer votre compte\nMyKOG",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ).animate().fadeIn().slideY(),
                const SizedBox(height: 32),
                _avatarPicker(),
                const SizedBox(height: 24),
                _inputField("Nom", nameCtrl),
                const SizedBox(height: 20),
                _phoneFieldWithCountry(),
                const SizedBox(height: 35),
                _registerButton(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: MyKOGColors.accent.withValues(alpha: 0.6),
                  width: 2,
                  style: _photoFile == null
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                ),
                image: _photoFile != null
                    ? DecorationImage(
                        image: FileImage(_photoFile!), fit: BoxFit.cover)
                    : null,
              ),
              child: _photoFile == null
                  ? Icon(Icons.add_a_photo_outlined,
                      color: Colors.white.withValues(alpha: 0.7), size: 32)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              _photoFile == null
                  ? 'Ajouter une photo (optionnel)'
                  : 'Changer la photo',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _inputField(String label, TextEditingController ctrl, {bool isPhone = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: MyKOGColors.accent,
        decoration: InputDecoration(
          labelText: label,
          hintText: isPhone ? "+237 6XX XXX XXX" : null,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          prefixIcon: isPhone 
              ? Icon(Icons.phone, color: Colors.white.withValues(alpha: 0.7))
              : null,
        ),
      ),
    );
  }

  Widget _phoneFieldWithCountry() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Sélecteur de pays avec drapeau
          GestureDetector(
            onTap: () => _showCountryPicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCountry.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedCountry.dialCode,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Champ de saisie du numéro
          Expanded(
            child: TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: MyKOGColors.accent,
              decoration: InputDecoration(
                labelText: "Téléphone",
                hintText: "6XX XXX XXX",
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String searchQuery = '';
          List<Country> filteredCountries = CountryData.countries;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sélectionner un pays",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // Barre de recherche
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Rechercher un pays...",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    onChanged: (query) {
                      setModalState(() {
                        searchQuery = query.toLowerCase();
                        if (query.isEmpty) {
                          filteredCountries = CountryData.countries;
                        } else {
                          filteredCountries = CountryData.countries.where((country) {
                            return country.name.toLowerCase().contains(searchQuery) ||
                                country.dialCode.contains(searchQuery) ||
                                country.code.toLowerCase().contains(searchQuery);
                          }).toList();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Liste des pays
                Expanded(
                  child: filteredCountries.isEmpty
                      ? Center(
                          child: Text(
                            "Aucun pays trouvé",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCountries.length,
                          itemBuilder: (context, index) {
                            final country = filteredCountries[index];
                            final isSelected = country.code == selectedCountry.code;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedCountry = country;
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? MyKOGColors.accent.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      country.flag,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            country.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          Text(
                                            country.dialCode,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: MyKOGColors.accent,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _registerButton(BuildContext context) {
    return GestureDetector(
      onTap: loading
          ? null
          : () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                return;
              }

              // Validation basique du numéro de téléphone
              // Nettoyer le numéro (enlever espaces, tirets, etc.)
              final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
              
              // Vérifier que le numéro n'est pas vide
              if (cleanPhone.isEmpty) {
                return;
              }

              // Construire le numéro complet avec le code pays
              final fullPhoneNumber = '${selectedCountry.dialCode}$cleanPhone';
              
              // Validation du numéro complet (code pays + numéro)
              final phoneRegex = RegExp(r'^\+[0-9]{1,4}[0-9]{6,14}$');
              if (!phoneRegex.hasMatch(fullPhoneNumber)) {
                return;
              }

              setState(() => loading = true);

              try {
                // Upload de la photo de profil si choisie
                final photoUrl = await _uploadPhoto();

                // Utiliser le numéro de téléphone complet (avec code pays) comme email pour la compatibilité avec le modèle User
                await context.read<UserProvider>().registerUser(
                    name, fullPhoneNumber,
                    profileImageUrl: photoUrl);
                
                // Marquer l'inscription comme complétée
                await FirstLaunchService.setRegistrationCompleted();
              } catch (e) {
                setState(() => loading = false);
                return;
              }

              setState(() => loading = false);

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainApp()),
                );
              }
            },
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: loading ? Colors.white38 : MyKOGColors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          loading ? "Creating..." : "Create Account",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ).animate().fadeIn().slideY(),
    );
  }
}
