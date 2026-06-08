import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gazprof/core/constants.dart';
import '../../core/theme_provider.dart';

class PaymentTypeDialog extends StatelessWidget {
  final String currentPaymentType;

  const PaymentTypeDialog({super.key, required this.currentPaymentType});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardCreateCommand,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.cardOutline, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: theme.brandBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.brandBlue.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.swap_horiz, color: Color(0xFF0779B7), size: 32),
              ),
              const SizedBox(height: 18),
              Text("Schimbă tipul de plată", style: TextStyle(color: theme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _paymentOption(context, theme, PaymentType.cash.value, 'Cash', Icons.money, Colors.green),
              const SizedBox(height: 12),
              _paymentOption(context, theme, PaymentType.card.value, 'Card', Icons.credit_card, theme.brandBlue),
              const SizedBox(height: 12),
              _paymentOption(context, theme, PaymentType.invoice.value, 'Factura', Icons.receipt, theme.statusTextInAsteptare),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity, height: 48,
                  decoration: BoxDecoration(
                    color: theme.isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Center(child: Text("Înapoi", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOption(BuildContext context, ThemeProvider theme, String value, String label, IconData icon, Color color) {
    final isSelected = currentPaymentType.toLowerCase() == value;
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : (theme.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.3) : (theme.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600))),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

class UnassignOrderDialog extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const UnassignOrderDialog({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardCreateCommand,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.unfold_more_outlined,
                  color: Color(0xFFFF6B00),
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Retragi alocarea?",
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Comanda va reveni la statusul 'În așteptare' și va fi disponibilă pentru alți șoferi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Builder(builder: (context) {
                        final blocAp = orderData['bloc_apartament'] ?? '';
                        final adresaFull = blocAp.isNotEmpty ? '${orderData['adresa_livrare']}, $blocAp' : '${orderData['adresa_livrare'] ?? '-'}';
                        return Text(
                          adresaFull,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Înapoi",
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Da, retrage",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
