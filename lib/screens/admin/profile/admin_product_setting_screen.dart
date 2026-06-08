import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// --- THEME & PROVIDERS ---
import 'package:gazprof/core/constants.dart';
import '../../../../core/theme_provider.dart';

class AdminProductSettingScreen extends StatefulWidget {
  const AdminProductSettingScreen({super.key});

  @override
  State<AdminProductSettingScreen> createState() => _AdminProductSettingScreenState();
}

class _AdminProductSettingScreenState extends State<AdminProductSettingScreen> {
  final TextEditingController _numeController = TextEditingController();
  final TextEditingController _pretController = TextEditingController();

  @override
  void dispose() {
    _numeController.dispose();
    _pretController.dispose();
    super.dispose();
  }

  void _showAddProductDialog(ThemeProvider theme) {
    _numeController.clear();
    _pretController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardCreateCommand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Adaugă produs nou", 
          style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _numeController,
              style: TextStyle(color: theme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Nume produs (ex: Butelie 10kg)",
                hintStyle: TextStyle(color: theme.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.cardOutline)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.brandBlue)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _pretController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: theme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Preț implicit",
                suffixText: "lei",
                hintStyle: TextStyle(color: theme.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.cardOutline)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.brandBlue)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Anulează", style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final nume = _numeController.text.trim();
              final pret = double.tryParse(_pretController.text.trim()) ?? 0.0;
              
              if (nume.isNotEmpty && pret > 0) {
                final snapshot = await FirebaseFirestore.instance.collection(FirestoreCollections.products).get();
                await FirebaseFirestore.instance.collection(FirestoreCollections.products).add({
                  'nume': nume,
                  'pret': pret,
                  'pozitie': snapshot.docs.length,
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text("Salvează", style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(String docId, String currentName, double currentPrice, ThemeProvider theme) {
    final TextEditingController priceEditController = TextEditingController(text: currentPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardCreateCommand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Editează preț - $currentName", 
          style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: priceEditController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            suffixText: "lei", 
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.brandBlue)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.brandBlue, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Anulează", style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final noulPret = double.tryParse(priceEditController.text.trim());
              if (noulPret != null && noulPret > 0) {
                await FirebaseFirestore.instance.collection(FirestoreCollections.products).doc(docId).update({'pret': noulPret});
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text("Salvează", style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String docId, String productName, ThemeProvider theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardCreateCommand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Șterge produs", 
          style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Sigur dorești să ștergi produsul \"$productName\"? Această acțiune nu poate fi anulată.",
          style: TextStyle(color: theme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Anulează", style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection(FirestoreCollections.products).doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Șterge", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary), 
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Setări produse", 
          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: theme.sectionLabel.withOpacity(0.3), height: 1.0),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.brandBlue, size: 24), 
            onPressed: () => _showAddProductDialog(theme),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(FirestoreCollections.products).orderBy('pozitie').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Eroare la încărcarea datelor", style: TextStyle(color: theme.textPrimary)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "Niciun produs salvat în cloud.", 
                style: TextStyle(color: theme.textSecondary, fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              final String nume = data['nume'] ?? 'Produs';
              final double pret = (data['pret'] ?? 0.0).toDouble();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.cardFill,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: theme.cardOutline, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nume, 
                        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "${pret.toStringAsFixed(0)} lei", 
                          style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () => _showEditPriceDialog(docId, nume, pret, theme),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.brandBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.edit_outlined, color: theme.brandBlue, size: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDeleteConfirmDialog(docId, nume, theme),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}