import 'marketplace_review.dart';

/// Which reports the order issue queue lists.
enum OrderIssueQueueFilter {
  /// Waiting for the seller or staff, newest report first.
  open,

  /// Withdrawn or decided, newest decision first.
  closed,
}

/// What staff decide on an open report.
enum OrderIssueDecision {
  /// Cancel the order and refund the buyer in full.
  refund,

  /// Complete the order and pay the seller.
  release,

  /// No fault found: the order carries on and the buyer gets the receive window again.
  dismiss,
}

/// The order behind a report, as staff see it.
class OrderIssueOrder {
  const OrderIssueOrder({
    required this.id,
    this.orderNumber,
    this.status,
    this.total = 0,
    this.paymentMethod,
    this.escrowStatus,
    this.paidAt,
    this.shippedAt,
    this.receiveBy,
    this.carrier,
    this.trackingNumber,
    this.productTitle,
  });

  factory OrderIssueOrder.fromJson(Object? json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const <String, dynamic>{};
    return OrderIssueOrder(
      id: map['id'] as String? ?? '',
      orderNumber: map['order_number'] as String?,
      status: map['status'] as String?,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String?,
      escrowStatus: map['escrow_status'] as String?,
      paidAt: _date(map['paid_at']),
      shippedAt: _date(map['shipped_at']),
      receiveBy: _date(map['receive_by']),
      carrier: map['carrier'] as String?,
      trackingNumber: map['tracking_number'] as String?,
      productTitle: map['product_title'] as String?,
    );
  }

  final String id;
  final String? orderNumber;

  /// `public.orders.order_status`: shipped while staff can still decide.
  final String? status;
  final double total;

  /// wallet or mock.
  final String? paymentMethod;

  /// holding, disputed, released or refunded.
  final String? escrowStatus;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? receiveBy;
  final String? carrier;
  final String? trackingNumber;
  final String? productTitle;
}

/// One line of the order's history (`public.order_events`).
class OrderIssueEvent {
  const OrderIssueEvent({required this.event, this.note, this.createdAt});

  final String event;
  final String? note;
  final DateTime? createdAt;
}

/// A problem a Secondhand buyer reported after shipping. While it is open the
/// money stays in escrow; staff refund the buyer, pay the seller, or dismiss it.
class OrderIssueCase {
  const OrderIssueCase({
    required this.id,
    required this.kind,
    required this.status,
    this.detail,
    this.resolutionNote,
    this.resolvedByName,
    this.createdAt,
    this.resolvedAt,
    this.order,
    this.buyer,
    this.seller,
    this.sortAt,
    this.events = const [],
    this.history = const [],
  });

  factory OrderIssueCase.fromJson(Map<String, dynamic> json) => OrderIssueCase(
    id: json['id'] as String? ?? '',
    kind: json['kind'] as String? ?? '',
    status: json['status'] as String? ?? 'open',
    detail: json['detail'] as String?,
    resolutionNote: json['resolution_note'] as String?,
    resolvedByName: json['resolved_by_name'] as String?,
    createdAt: _date(json['created_at']),
    resolvedAt: _date(json['resolved_at']),
    order: json['order'] is Map ? OrderIssueOrder.fromJson(json['order']) : null,
    buyer: json['buyer'] is Map ? ReviewParty.fromJson(json['buyer']) : null,
    seller: json['seller'] is Map ? ReviewParty.fromJson(json['seller']) : null,
    sortAt: _date(json['sort_at']),
    events: [
      if (json['events'] case final List rows)
        for (final row in rows)
          if (row is Map)
            OrderIssueEvent(
              event: row['event'] as String? ?? '',
              note: row['note'] as String?,
              createdAt: _date(row['created_at']),
            ),
    ],
    history: [
      if (json['history'] case final List rows)
        for (final row in rows)
          if (row is Map) OrderIssueCase.fromJson(Map<String, dynamic>.from(row)),
    ],
  );

  final String id;

  /// not_arrived, not_as_described or cancel_request.
  final String kind;

  /// open, withdrawn, refunded, released or dismissed.
  final String status;
  final String? detail;
  final String? resolutionNote;
  final String? resolvedByName;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final OrderIssueOrder? order;
  final ReviewParty? buyer;
  final ReviewParty? seller;

  /// The queue's paging date.
  final DateTime? sortAt;

  /// Only filled by the detail.
  final List<OrderIssueEvent> events;

  /// Earlier reports on the same order; only filled by the detail.
  final List<OrderIssueCase> history;

  bool get isOpen => status == 'open';

  /// Staff decide only while the report is open and the item is on its way.
  bool get decidable => isOpen && order?.status == 'shipped';
}

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;
