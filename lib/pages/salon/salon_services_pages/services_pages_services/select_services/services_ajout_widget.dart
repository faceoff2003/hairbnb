import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/pages/salon/gallery/add_gallery_page.dart';

import '../../../../../models/services.dart';
import 'create_firsts_services_api/services_api_service.dart';

class ServicesAjoutesWidget extends StatefulWidget {
  final CurrentUser currentUser;
  final List<Service> servicesAjoutes;
  final bool isLoading;
  final VoidCallback onRefresh;

  const ServicesAjoutesWidget({
    super.key,
    required this.currentUser,
    required this.servicesAjoutes,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<ServicesAjoutesWidget> createState() => _ServicesAjoutesWidgetState();
}

class _ServicesAjoutesWidgetState extends State<ServicesAjoutesWidget> {
  bool _isTestingApi = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(bottom: BorderSide(color: Colors.green.shade200)),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Mes services ajoutés",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
            ),
            // Bouton de refresh
            IconButton(
              onPressed: widget.onRefresh,
              icon: Icon(Icons.refresh, color: Colors.green.shade600, size: 16),
              tooltip: "Recharger les services",
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isLoading)
              const Text("Chargement...")
            else
              Text(
                "${widget.servicesAjoutes.length} service(s)",
                style: TextStyle(color: Colors.green.shade600, fontSize: 12),
              ),
            // Info de debug
            Text(
              "UserID: ${widget.currentUser.idTblUser} | Debug actif",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
        children: [
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.servicesAjoutes.isEmpty)
            _construireEtatVide()
          else
            _construireListeServices(),

          // Section debug
          _construireSectionDebug(),
        ],
      ),
    );
  }

  Widget _construireEtatVide() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            "Aucun service ajouté pour le moment",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AddGalleryPage()),
              );
            },
            icon: const Icon(Icons.photo_library),
            label: const Text("Aller à la galerie"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireListeServices() {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.servicesAjoutes.length,
            itemBuilder: (context, index) {
              final service = widget.servicesAjoutes[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.intitule,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (service.description.isNotEmpty)
                            Text(
                              service.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.green.shade400, size: 16),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AddGalleryPage()),
                );
              },
              icon: const Icon(Icons.photo_library),
              label: const Text("Aller à la galerie"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construireSectionDebug() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🔍 Debug Info:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "• UserID: ${widget.currentUser.idTblUser}",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            "• Services chargés: ${widget.servicesAjoutes.length}",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            "• État loading: ${widget.isLoading}",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isTestingApi ? null : _testerApi,
            icon: _isTestingApi
                ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(Icons.bug_report, size: 14),
            label: Text(
              _isTestingApi ? "Test en cours..." : "Test API",
              style: TextStyle(fontSize: 10),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: Size(0, 30),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testerApi() async {
    setState(() => _isTestingApi = true);

    try {
      if (kDebugMode) {
        print("🔄 DEBUG: Test API direct");
      }
      if (kDebugMode) {
        print("🔄 UserID utilisé: ${widget.currentUser.idTblUser}");
      }

      final services = await ServicesApiService.chargerServicesAjoutes(widget.currentUser.idTblUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Debug: ${services.length} services récupérés. Vérifiez la console."),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors du test API: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors du test: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingApi = false);
      }
    }
  }
}