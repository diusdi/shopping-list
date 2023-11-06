import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-c8053-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data. Please try again later';
      });
    }

    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = jsonDecode(response.body);
    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }

    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  }

  void _addForm() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeList(GroceryItem groceryItem) async {
    final groceryIndex = _groceryItems.indexOf(groceryItem);
    setState(() {
      _groceryItems.remove(groceryItem);
    });

    final url = Uri.https('flutter-prep-c8053-default-rtdb.firebaseio.com',
        'shopping-list/${groceryItem.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(groceryIndex, groceryItem);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No item added yet'));

    if (_isLoading) {
      setState(() {
        content = const Center(child: CircularProgressIndicator());
      });
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
                background: Container(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                ),
                onDismissed: (direction) {
                  _removeList(_groceryItems[index]);
                },
                key: ValueKey(_groceryItems[index].id),
                child: ListTile(
                  title: Text(_groceryItems[index].name),
                  leading: Container(
                    height: 24,
                    width: 24,
                    color: _groceryItems[index].category.color,
                  ),
                  trailing: Text(_groceryItems[index].quantity.toString()),
                ),
              ));
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(onPressed: _addForm, icon: const Icon(Icons.add)),
        ],
      ),
      body: content,
    );
  }
}
