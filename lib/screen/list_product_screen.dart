import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListProductScreen extends StatelessWidget {
  const ListProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userId = (ModalRoute.of(context)!.settings.arguments as String?) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de productos'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'shopping_cart');
            },
            icon: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay productos disponibles'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (BuildContext context, int index) {
                final productData = snapshot.data!.docs[index];
                return ListTile(
                  title: Text(productData['productName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productData['productDescription']),
                      Text('\$${productData['productPrice'].toStringAsFixed(2)}'),
                    ],
                  ),
                  leading: _buildProductImage(productData['productImage']),
                  onTap: () {
                    _showQuantityDialog(context, productData, userId);
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, 'add_product');
        },
        child: const Icon(Icons.add),
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

  void _showQuantityDialog(BuildContext context, DocumentSnapshot productData, String userId) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar al Carrito'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingrese la cantidad:'),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  quantity = int.tryParse(value) ?? 1;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                addToCart(productData, quantity, userId);
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> addToCart(DocumentSnapshot productData, int quantity, String userId) async {
    try {
      final cartDoc = FirebaseFirestore.instance.collection('carts').doc(userId);
      final cartSnapshot = await cartDoc.get();
      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> cartItems = cartData['cartItems'];
        bool productExists = false;
        for (var item in cartItems) {
          if (item['productName'] == productData['productName']) {
            final int newQuantity = item['quantity'] + quantity;
            await cartDoc.update({
              'cartItems': cartItems.map((e) {
                if (e['productName'] == productData['productName']) {
                  e['quantity'] = newQuantity;
                }
                return e;
              }).toList(),
            });
            productExists = true;
            break;
          }
        }
        if (!productExists) {
          await cartDoc.update({
            'cartItems': FieldValue.arrayUnion([
              {
                'productName': productData['productName'],
                'productDescription': productData['productDescription'],
                'productPrice': productData['productPrice'],
                'productImage': productData['productImage'],
                'quantity': quantity,
              }
            ]),
          });
        }
      } else {
        await cartDoc.set({
          'cartItems': [
            {
              'productName': productData['productName'],
              'productDescription': productData['productDescription'],
              'productPrice': productData['productPrice'],
              'productImage': productData['productImage'],
              'quantity': quantity,
            }
          ]
        });
      }
    } catch (error) {
      print('Error adding product to cart: $error');
    }
  }
}
