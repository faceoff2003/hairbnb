// Fichier: lib/models/email_notification.dart

class EmailNotification {
  final String toEmail;
  final String toName;
  final String subject;
  final String templateId;
  final Map<String, dynamic> templateData;
  final int? rendezVousId;

  EmailNotification({
    required this.toEmail,
    required this.toName,
    required this.subject,
    required this.templateId,
    required this.templateData,
    this.rendezVousId,
  });

  Map<String, dynamic> toJson() {
    return {
      'toEmail': toEmail,
      'toName': toName,
      'subject': subject,
      'templateId': templateId,
      'templateData': templateData,
      'rendezVousId': rendezVousId,
    };
  }

  factory EmailNotification.fromJson(Map<String, dynamic> json) {
    return EmailNotification(
      toEmail: json['toEmail'],
      toName: json['toName'],
      subject: json['subject'],
      templateId: json['templateId'],
      templateData: json['templateData'],
      rendezVousId: json['rendezVousId'],
    );
  }
}