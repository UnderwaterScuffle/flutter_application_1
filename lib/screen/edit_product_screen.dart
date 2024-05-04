import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController productNameController = TextEditingController();
    TextEditingController productPriceController = TextEditingController();
    TextEditingController productDescriptionController = TextEditingController();
    TextEditingController productImageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: productNameController,
              decoration: const InputDecoration(labelText: 'Nombre del Producto'),
            ),
            TextFormField(
              controller: productPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio del Producto'),
            ),
            TextFormField(
              controller: productDescriptionController,
              decoration: const InputDecoration(labelText: 'Descripción del Producto'),
            ),
            TextFormField(
              controller: productImageController,
              decoration: const InputDecoration(labelText: 'URL de la Imagen del Producto'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String productName = productNameController.text.trim();
                String productDescription = productDescriptionController.text.trim();
                String productImage = productImageController.text.trim();
                String productPriceText = productPriceController.text.trim();
                if (productName.isNotEmpty && productDescription.isNotEmpty && productImage.isNotEmpty && productPriceText.isNotEmpty) {
                  try {
                    double productPrice = double.parse(productPriceText);
                    addProductToFirestore(productName, productPrice, productDescription, productImage);
                    Navigator.pushNamed(context, 'list');
                  } catch (error) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error'),
                          content: const Text('El precio debe ser un número válido.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: const Text('Por favor, complete todos los campos para agregar el producto.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Aceptar'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Text('Agregar Producto'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addProductToFirestore(String productName, double productPrice, String productDescription, String productImage) async {
    try {
      await FirebaseFirestore.instance.collection('products').add({
        'productName': productName,
        'productPrice': productPrice,
        'productDescription': productDescription,
        'productImage': productImage,
      });
    } catch (error) {
      print('Error adding product: $error');
    }
  }
}