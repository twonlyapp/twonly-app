import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/utils/misc.dart';

class VoucherView extends StatefulWidget {
  const VoucherView({super.key});

  @override
  State<VoucherView> createState() => _VoucherViewState();
}

class _VoucherViewState extends State<VoucherView> {
  List<Response_Voucher> vouchers = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    Response_Vouchers? resVouchers = await apiService.getVoucherList();
    if (resVouchers != null) {
      setState(() {
        vouchers = resVouchers.vouchers;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final openVoucher = vouchers.where((x) => !x.redeemed && !x.requested);
    final redeemedVoucher = vouchers.where((x) => x.redeemed);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.createOrRedeemVoucher),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.redeemVoucher),
            onTap: () async {
              await redeemVoucher(context);
              initAsync();
            },
          ),
          ListTile(
            title: Text(context.lang.createVoucher),
            onTap: () async {
              await showBuyVoucher(context);
              initAsync();
            },
          ),
          Divider(),
          if (openVoucher.isNotEmpty)
            ListTile(
              title: Text(
                context.lang.openVouchers,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ...openVoucher.map((x) => VoucherCard(voucher: x)),
          if (redeemedVoucher.isNotEmpty)
            ListTile(
              title: Text(
                context.lang.redeemedVouchers,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ...redeemedVoucher.map((x) => VoucherCard(voucher: x)),
        ],
      ),
    );
  }
}

class VoucherCard extends StatefulWidget {
  final Response_Voucher voucher;

  const VoucherCard({super.key, required this.voucher});

  @override
  State<VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends State<VoucherCard> {
  void _copyVoucherId() {
    if (!widget.voucher.redeemed) {
      Clipboard.setData(ClipboardData(text: widget.voucher.voucherId));
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.voucher.voucherId} copied.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRedeemed = widget.voucher.redeemed || widget.voucher.requested;

    Locale myLocale = Localizations.localeOf(context);
    String formattedValue = NumberFormat.currency(
      locale: myLocale.toString(),
      symbol: '€',
      decimalDigits: 2,
    ).format(widget.voucher.valueCents.toInt() / 100);

    return GestureDetector(
      onTap: _copyVoucherId,
      child: Card(
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
                  Text(
                    widget.voucher.voucherId.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          (isRedeemed) ? Colors.grey : context.color.onSurface,
                    ),
                  ),
                  Text(
                    formattedValue,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          (isRedeemed) ? Colors.grey : context.color.onSurface,
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

Future redeemVoucher(BuildContext context) async {
  String voucherCode = '';
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.lang.redeemVoucher),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextField(
                      onChanged: (value) {
                        // Convert to uppercase
                        setState(() {
                          voucherCode = value.toUpperCase();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: context.lang.enterVoucherCode,
                        border: OutlineInputBorder(),
                      ),
                      // Set the text to be uppercase
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.lang.cancel),
          ),
          TextButton(
            onPressed: () async {
              final res = await apiService.redeemVoucher(voucherCode);
              if (!context.mounted) return;
              if (res.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.lang.voucherRedeemed)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorCodeToText(context, res.error))),
                );
              }
              Navigator.of(context).pop();
            },
            child: Text(context.lang.ok),
          ),
        ],
      );
    },
  );
}

Future showBuyVoucher(BuildContext context) async {
  int quantity = 1000;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.lang.createVoucher),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.lang.createVoucherDesc),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              if (quantity <= 100) return;
                              if (quantity <= 1000) {
                                quantity -= 100;
                              } else {
                                quantity -= 500;
                              }
                            });
                          }
                        },
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: Localizations.localeOf(context).toString(),
                          symbol: '€',
                          decimalDigits: 2,
                        ).format(quantity / 100),
                        style: TextStyle(fontSize: 24),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            if (quantity >= 1000) {
                              quantity += 500;
                            } else {
                              quantity += 100;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text(context.lang.cancel),
          ),
          TextButton(
            onPressed: () async {
              final res = await apiService.buyVoucher(quantity);
              if (!context.mounted) return;
              if (res.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.lang.voucherCreated)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorCodeToText(context, res.error))),
                );
              }
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text(context.lang.buy),
          ),
        ],
      );
    },
  );
}
