import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart';
import 'package:twonly/src/utils/misc.dart';

class TransactionView extends StatefulWidget {
  const TransactionView(
      {super.key, required this.transactions, required this.formattedBalance});
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
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: context.color.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
  final Response_Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

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
    }
    return type.toString();
  }

  @override
  Widget build(BuildContext context) {
    final myLocale = Localizations.localeOf(context);
    String formattedValue = NumberFormat.currency(
      locale: myLocale.toString(),
      symbol: '€',
      decimalDigits: 2,
    ).format(widget.transaction.depositCents.toInt() / 100);

    DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(
        widget.transaction.createdAtUnixTimestamp.toInt() * 1000);

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeToText(widget.transaction.transactionType),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMMd(myLocale.toString()).format(timestamp),
                      style: TextStyle(
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
