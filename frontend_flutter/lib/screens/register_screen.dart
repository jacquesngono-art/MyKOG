import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../theme.dart';
import '../main_app.dart';
import '../utils/country_data.dart';
import '../services/first_launch_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MyKOGColors.primaryDark, MyKOGColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
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
              SizedBox(height: 40.h),
              _inputField("Nom", nameCtrl),
              SizedBox(height: 20.h),
              _phoneFieldWithCountry(),
              SizedBox(height: 35.h),
              _registerButton(context),
              SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {bool isPhone = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
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
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Sélecteur de pays avec drapeau
          GestureDetector(
            onTap: () => _showCountryPicker(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCountry.flag,
                    style: TextStyle(fontSize: 20.sp),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    selectedCountry.dialCode,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Champ de saisie du numéro
          Expanded(
            child: TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
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
      backgroundColor: MyKOGColors.primaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String searchQuery = '';
          List<Country> filteredCountries = CountryData.countries;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(16.w),
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
                SizedBox(height: 16.h),
                // Barre de recherche
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
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
                SizedBox(height: 16.h),
                // Liste des pays
                Expanded(
                  child: filteredCountries.isEmpty
                      ? Center(
                          child: Text(
                            "Aucun pays trouvé",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16.sp,
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
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.h, horizontal: 16.w),
                                margin: EdgeInsets.only(bottom: 4.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? MyKOGColors.accent.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      country.flag,
                                      style: TextStyle(fontSize: 24.sp),
                                    ),
          SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            country.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          Text(
                                            country.dialCode,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: MyKOGColors.accent,
                                        size: 20.sp,
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
                // Utiliser le numéro de téléphone complet (avec code pays) comme email pour la compatibilité avec le modèle User
                await context.read<UserProvider>().registerUser(name, fullPhoneNumber);
                
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
        padding: EdgeInsets.symmetric(vertical: 18.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: loading ? Colors.white38 : MyKOGColors.accent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          loading ? "Creating..." : "Create Account",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
      ).animate().fadeIn().slideY(),
    );
  }
}
