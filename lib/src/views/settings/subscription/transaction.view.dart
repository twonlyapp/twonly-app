import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/utils/misc.dart';

class TransactionView extends StatefulWidget {
  const TransactionView({
    required this.transactions,
    required this.formattedBalance,
    super.key,
  });
  final List<Response_Transaction>? transactions;
  final String formattedBalance;

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.transactionHistory),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: context.color.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  widget.formattedBalance,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode(context) ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          if (widget.transactions != null)
            ...widget.transactions!.map((x) => TransactionCard(transaction: x))
        ],
      ),
    );
  }
}

class TransactionCard extends StatefulWidget {
  const TransactionCard({required this.transaction, super.key});
  final Response_Transaction transaction;

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  String typeToText(Response_TransactionTypes type) {
    switch (type) {
      case Response_TransactionTypes.Cash:
        return context.lang.transactionCash;
      case Response_TransactionTypes.PlanUpgrade:
        return context.lang.transactionPlanUpgrade;
      case Response_TransactionTypes.Refund:
        return context.lang.transactionRefund;
      case Response_TransactionTypes.ThanksForTesting:
        return context.lang.transactionThanksForTesting;
      case Response_TransactionTypes.Unknown:
        return context.lang.transactionUnknown;
      case Response_TransactionTypes.VoucherCreated:
        return context.lang.transactionVoucherCreated;
      case Response_TransactionTypes.VoucherRedeemed:
        return context.lang.transactionVoucherRedeemed;
      case Response_TransactionTypes.AutoRenewal:
        return context.lang.transactionAutoRenewal;
    }
    return type.toString();
  }

  @override
  Widget build(BuildContext context) {
    final myLocale = Localizations.localeOf(context);
    final formattedValue = NumberFormat.currency(
      locale: myLocale.toString(),
      symbol: '€',
      decimalDigits: 2,
    ).format(widget.transaction.depositCents.toInt() / 100);

    final timestamp = DateTime.fromMillisecondsSinceEpoch(
        widget.transaction.createdAtUnixTimestamp.toInt() * 1000);

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeToText(widget.transaction.transactionType),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMMd(myLocale.toString()).format(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedValue,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (widget.transaction.depositCents < 0)
                        ? Colors.red
                        : context.color.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
