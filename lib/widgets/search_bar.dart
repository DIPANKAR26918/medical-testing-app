import 'package:flutter/material.dart';
import '../screens/search_screen.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // এখানে পরে search expand, suggestions ইত্যাদি যোগ করবি
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, animation, _) => const SearchScreen(),
            transitionsBuilder: (_, animation, _, child) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color.fromARGB(255, 99, 230, 223),
            width: 1.8,
          ),
        ),
        child: Row(
          children: [
            Image.asset('assets/images/search.png', width: 25, height: 25),

            const SizedBox(width: 12),

            const Expanded(
              child: Text(
                "Search for tests, packages & more",
                style: TextStyle(
                  color: Color.fromARGB(255, 115, 115, 115),
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
