// // File: lib/widgets/gradient_container.dart
// // A new reusable widget to apply a dynamic background gradient based on the current theme.

// import 'package:flutter/material.dart';

// class GradientContainer extends StatelessWidget {
//   final Widget child;

//   const GradientContainer({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     // Define the gradients for light and dark modes
//     final darkGradient = LinearGradient(
//       colors: [const Color.fromARGB(255, 4, 0, 6), const Color.fromARGB(255, 5, 0, 52)],
//       begin: Alignment.topLeft,
//       end: Alignment.bottomRight,
//     );

//     final lightGradient = LinearGradient(
//       colors: [const Color.fromARGB(255, 4, 21, 217), Color.fromARGB(255, 185, 18, 231)],
//       begin: Alignment.topLeft,
//       end: Alignment.bottomRight,
//     );

//     return Container(
//       decoration: BoxDecoration(
//         gradient: isDarkMode ? darkGradient : lightGradient,
//       ),
//       child: child,
//     );
//   }
// }
