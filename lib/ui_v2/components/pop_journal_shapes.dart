import 'package:flutter/material.dart';

class PopJournalButtonClipper extends CustomClipper<Path> {
  const PopJournalButtonClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(15, 0)
    ..lineTo(size.width - 18, 0)
    ..quadraticBezierTo(size.width - 3, 0, size.width - 2, 15)
    ..lineTo(size.width - 7, size.height - 12)
    ..quadraticBezierTo(
      size.width - 8,
      size.height,
      size.width - 22,
      size.height,
    )
    ..lineTo(16, size.height)
    ..quadraticBezierTo(2, size.height, 2, size.height - 14)
    ..lineTo(7, 16)
    ..quadraticBezierTo(8, 2, 15, 0)
    ..close();

  @override
  bool shouldReclip(covariant PopJournalButtonClipper oldClipper) => false;
}

class PopJournalCardClipper extends CustomClipper<Path> {
  const PopJournalCardClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(18, 0)
    ..lineTo(size.width - 18, 0)
    ..quadraticBezierTo(size.width, 0, size.width, 18)
    ..lineTo(size.width, size.height - 20)
    ..quadraticBezierTo(size.width, size.height, size.width - 22, size.height)
    ..lineTo(17, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height - 18)
    ..lineTo(0, 18)
    ..quadraticBezierTo(0, 0, 18, 0)
    ..close();

  @override
  bool shouldReclip(covariant PopJournalCardClipper oldClipper) => false;
}
