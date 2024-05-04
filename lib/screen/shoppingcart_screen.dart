import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/authutils.dart';

class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String userId = AuthUtils.getCurrentUserId() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('carts').doc(userId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(child: Text('No items in the shopping cart'));
          } else {
            Map<String, dynamic> cartData = snapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> cartItems = cartData['cartItems'];

            double total = _calculateTotal(cartItems);

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      final item = cartItems[index];
                      return ListTile(
                        title: Text(item['productName']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item['productDescription'] != null)
                              Text(item['productDescription']),
                            Text('Price: \$${item['productPrice']}, Quantity: ${item['quantity']}'),
                            Text('Total: \$${(item['productPrice'] * item['quantity']).toStringAsFixed(2)}'),
                          ],
                        ),
                        leading: _buildProductImage(item['productImage']),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Modify Cart Item'),
                                content: Text('What would you like to do with ${item['productName']}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      removeCartItem(context, userId, item);
                                    },
                                    child: const Text('Remove'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      modifyCartItem(context, userId, item);
                                    },
                                    child: const Text('Modify Quantity'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total: \$${total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset('assets/no-image.png');
    } else {
      return Image.network(
        imageUrl,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/no-image.png');
        },
      );
    }
  }

  void removeCartItem(BuildContext context, String userId, Map<String, dynamic> item) {
    FirebaseFirestore.instance.collection('carts').doc(userId).update({
      'cartItems': FieldValue.arrayRemove([item]),
    }).then((_) {
      Navigator.pop(context);
    }).catchError((error) {
      print('Error removing item from cart: $error');
    });
  }

  void modifyCartItem(BuildContext context, String userId, Map<String, dynamic> item) {
    int quantity = item['quantity'] ?? 0;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int newQuantity = quantity;
        return AlertDialog(
          title: const Text('Modify Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the new quantity:'),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  newQuantity = int.tryParse(value) ?? quantity;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('carts').doc(userId).update({
                  'cartItems': FieldValue.arrayRemove([item]),
                }).then((_) {
                  FirebaseFirestore.instance.collection('carts').doc(userId).update({
                    'cartItems': FieldValue.arrayUnion([
                      {
                        'productName': item['productName'],
                        'productDescription': item['productDescription'], // Include description
                        'productPrice': item['productPrice'],
                        'productImage': item['productImage'], // Include image
                        'quantity': newQuantity,
                      },
                    ]),
                  });
                  Navigator.pop(context);
                }).catchError((error) {
                  print('Error updating item quantity in cart: $error');
                });
              },
              child: const Text('Update Quantity'),
            ),
          ],
        );
      },
    );
  }

  double _calculateTotal(List<dynamic> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      total += (item['productPrice'] * item['quantity']);
    }
    return total;
  }
}
