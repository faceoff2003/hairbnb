import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hairbnb/pages/profil/services/update_services/phone_update/phone_update_service.dart';
import '../../../../../models/current_user.dart';

class PhoneEditWidget extends StatefulWidget {
  final CurrentUser currentUser;
  final Color primaryColor;
  final Color successColor;
  final Color errorColor;
  final Function(bool) setLoadingState;

  const PhoneEditWidget({
    super.key,
    required this.currentUser,
    required this.primaryColor,
    required this.successColor,
    required this.errorColor,
    required this.setLoadingState,
  });

  @override
  State<PhoneEditWidget> createState() => _PhoneEditWidgetState();
}

class _PhoneEditWidgetState extends State<PhoneEditWidget> {
  late TextEditingController _phoneController;
  bool _isValidating = false;
  PhoneValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.currentUser.numeroTelephone ?? '');
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _isValidating = true;
      });

      // Débounce la validation pour éviter trop d'appels
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final validation = PhoneUpdateService.validatePhoneNumber(_phoneController.text);
          setState(() {
            _validationResult = validation;
            _isValidating = false;
          });
        }
      });
    } else {
      setState(() {
        _validationResult = null;
        _isValidating = false;
      });
    }
  }

  Future<void> _updatePhoneNumber() async {
    final newPhone = _phoneController.text.trim();

    if (newPhone.isEmpty) {
      _showSnackBar('Veuillez saisir un numéro de téléphone', widget.errorColor, Icons.warning);
      return;
    }

    // Vérifier la validation avant de continuer
    if (_validationResult == null || !_validationResult!.isValid) {
      _showSnackBar('Veuillez corriger le format du numéro de téléphone', widget.errorColor, Icons.error);
      return;
    }

    final success = await PhoneUpdateService.updateUserPhoneNumber(
      context,
      widget.currentUser,
      newPhone,
      successGreen: widget.successColor,
      errorRed: widget.errorColor,
      setLoadingState: widget.setLoadingState,
    );

    if (success) {
      Navigator.of(context).pop(); // Fermer le dialog
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.phone, color: widget.primaryColor),
          const SizedBox(width: 12),
          const Text(
            "Modifier le téléphone",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Saisissez votre nouveau numéro de téléphone :",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Champ de saisie du téléphone
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]')),
            ],
            decoration: InputDecoration(
              labelText: "Numéro de téléphone",
              hintText: "+32 123 45 67 89",
              prefixIcon: Icon(Icons.phone, color: widget.primaryColor),
              suffixIcon: _isValidating
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : _validationResult != null
                  ? Icon(
                _validationResult!.isValid
                    ? Icons.check_circle
                    : Icons.error,
                color: _validationResult!.isValid
                    ? widget.successColor
                    : widget.errorColor,
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.errorColor, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.errorColor, width: 2),
              ),
            ),
          ),

          // Message de validation
          if (_validationResult != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _validationResult!.isValid ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: _validationResult!.isValid ? widget.successColor : widget.errorColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _validationResult!.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: _validationResult!.isValid ? widget.successColor : widget.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Informations sur les formats acceptés
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: widget.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      "Formats acceptés :",
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "• +32 123 45 67 89 (Belgique)\n"
                      "• +33 1 23 45 67 89 (France)\n"
                      "• 012 34 56 78 (National)",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: _validationResult?.isValid == true ? _updatePhoneNumber : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Sauvegarder"),
        ),
      ],
    );
  }
}

/// Fonction utilitaire pour afficher le widget d'édition du téléphone
void showPhoneEditDialog(
    BuildContext context,
    CurrentUser currentUser, {
      Color primaryColor = const Color(0xFF7B61FF),
      Color successColor = Colors.green,
      Color errorColor = Colors.red,
      required Function(bool) setLoadingState,
    }) {
  showDialog(
    context: context,
    builder: (context) => PhoneEditWidget(
      currentUser: currentUser,
      primaryColor: primaryColor,
      successColor: successColor,
      errorColor: errorColor,
      setLoadingState: setLoadingState,
    ),
  );
}