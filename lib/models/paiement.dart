class Paiement {
  final int? idTblPaiement;
  final int rendezVousId;
  final int? utilisateurId;
  final double montantPaye;
  final DateTime datePaiement;
  final StatutPaiement statut;
  final MethodePaiement? methode;
  final String? stripePaymentIntentId;
  final String? stripeChargeId;
  final String? stripeCustomerId;
  final String? stripeCheckoutSessionId;
  final String? emailClient;
  final String? receiptUrl;

  Paiement({
    this.idTblPaiement,
    required this.rendezVousId,
    this.utilisateurId,
    required this.montantPaye,
    required this.datePaiement,
    required this.statut,
    this.methode,
    this.stripePaymentIntentId,
    this.stripeChargeId,
    this.stripeCustomerId,
    this.stripeCheckoutSessionId,
    this.emailClient,
    this.receiptUrl,
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      idTblPaiement: json['idTblPaiement'],
      rendezVousId: json['rendez_vous'],
      utilisateurId: json['utilisateur'],
      montantPaye: double.parse(json['montant_paye'].toString()),
      datePaiement: DateTime.parse(json['date_paiement']),
      statut: StatutPaiement.fromJson(json['statut']),
      methode: json['methode'] != null ? MethodePaiement.fromJson(json['methode']) : null,
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      stripeChargeId: json['stripe_charge_id'],
      stripeCustomerId: json['stripe_customer_id'],
      stripeCheckoutSessionId: json['stripe_checkout_session_id'],
      emailClient: json['email_client'],
      receiptUrl: json['receipt_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblPaiement': idTblPaiement,
      'rendez_vous': rendezVousId,
      'utilisateur': utilisateurId,
      'montant_paye': montantPaye,
      'date_paiement': datePaiement.toIso8601String(),
      'statut': statut.toJson(),
      'methode': methode?.toJson(),
      'stripe_payment_intent_id': stripePaymentIntentId,
      'stripe_charge_id': stripeChargeId,
      'stripe_customer_id': stripeCustomerId,
      'stripe_checkout_session_id': stripeCheckoutSessionId,
      'email_client': emailClient,
      'receipt_url': receiptUrl,
    };
  }
}

class StatutPaiement {
  final int? idTblPaiementStatut;
  final String code;
  final String libelle;

  StatutPaiement({
    this.idTblPaiementStatut,
    required this.code,
    required this.libelle,
  });

  factory StatutPaiement.fromJson(Map<String, dynamic> json) {
    return StatutPaiement(
      idTblPaiementStatut: json['idTblPaiementStatut'],
      code: json['code'],
      libelle: json['libelle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblPaiementStatut': idTblPaiementStatut,
      'code': code,
      'libelle': libelle,
    };
  }
}

class MethodePaiement {
  final int? idTblMethodePaiement;
  final String code;
  final String libelle;

  MethodePaiement({
    this.idTblMethodePaiement,
    required this.code,
    required this.libelle,
  });

  factory MethodePaiement.fromJson(Map<String, dynamic> json) {
    return MethodePaiement(
      idTblMethodePaiement: json['idTblMethodePaiement'],
      code: json['code'],
      libelle: json['libelle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblMethodePaiement': idTblMethodePaiement,
      'code': code,
      'libelle': libelle,
    };
  }
}





// class Paiement {
//   final double montantPaye;
//   final DateTime datePaiement;
//   final String methode;
//   final String statut;
//
//   Paiement({
//     required this.montantPaye,
//     required this.datePaiement,
//     required this.methode,
//     required this.statut,
//   });
//
//   factory Paiement.fromJson(Map<String, dynamic> json) {
//     return Paiement(
//       montantPaye: json['montant_paye'].toDouble(),
//       datePaiement: DateTime.parse(json['date_paiement']),
//       methode: json['methode'],
//       statut: json['statut'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'montant_paye': montantPaye,
//       'date_paiement': datePaiement.toIso8601String(),
//       'methode': methode,
//       'statut': statut,
//     };
//   }
// }
