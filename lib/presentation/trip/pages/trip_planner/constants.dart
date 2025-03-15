import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/expense.dart';

const List<Color> contributorColors = [
  Colors.white,
  Colors.pink,
  Colors.blue,
  Colors.yellow,
  Colors.redAccent,
  Colors.deepPurple,
  Colors.cyanAccent
];

const Map<ExpenseCategory, IconData> iconsForCategories = {
  ExpenseCategory.flights: Icons.flight_rounded,
  ExpenseCategory.lodging: Icons.hotel_rounded,
  ExpenseCategory.carRental: Icons.car_rental_outlined,
  ExpenseCategory.publicTransit: Icons.emoji_transportation_rounded,
  ExpenseCategory.food: Icons.fastfood_rounded,
  ExpenseCategory.drinks: Icons.local_drink_rounded,
  ExpenseCategory.sightseeing: Icons.attractions_rounded,
  ExpenseCategory.activities: Icons.confirmation_num_rounded,
  ExpenseCategory.shopping: Icons.shopping_bag_rounded,
  ExpenseCategory.fuel: Icons.local_gas_station_rounded,
  ExpenseCategory.groceries: Icons.local_grocery_store_rounded,
  ExpenseCategory.other: Icons.feed_rounded
};
