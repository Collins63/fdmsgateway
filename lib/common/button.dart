import 'package:fdmsgateway/common/reusableText.dart';
import 'package:flutter/material.dart';

class CustomOutlineBtn extends StatelessWidget {
  const CustomOutlineBtn({super.key, this.width, this.height, required this.text, this.onTap, required this.color, this.color2, required this.icon});

  final double? width;
  final double? height;
  final String text;
  final void Function()? onTap;
  final Color color;
  final Color? color2;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration:  BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: color2,
          border: Border.all(
            width: 1,
            color: color,
          )
        ),
        child: Center(
          child: Row(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: icon
              ),
              const SizedBox(width: 20),
              ReusableText(text: text,
               style: const TextStyle(fontSize:16 ,color: Colors.white,fontWeight:  FontWeight.w600),),
            ],
          ),
        ),
      ),
    );
  }
}