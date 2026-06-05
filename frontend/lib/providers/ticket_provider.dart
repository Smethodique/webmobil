import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ticket_service.dart';

final ticketRefreshProvider = StateProvider<int>((ref) => 0);

// Same provider — backend returns all tickets for expert, user's own for student
final ticketsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(ticketRefreshProvider);
  final res = await TicketService.getTickets();
  return res.cast<Map<String, dynamic>>();
});

// Alias for use in expert screens (same underlying call)
final userTicketsProvider = ticketsProvider;
