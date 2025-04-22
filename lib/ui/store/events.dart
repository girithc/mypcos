import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/ui/components/chat.dart';
import 'package:roo_mobile/ui/store/detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> categories = ["Foods", "Supplements", "Seeds", "Drinks"];
  int selectedIndex = 0;

  List<Product> get filteredProducts {
    return products
        .where((product) => product.category == categories[selectedIndex])
        .toList();
  }

  void updateCategory(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 252, 255),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPaddin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categories[selectedIndex],
                  style: GoogleFonts.sriracha(
                    // ✅ Apply Rock Salt font
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Show the dialog containing the chatPage
                    showChatBottomSheet(context);
                    // ✅ Switch to ChatHomePage within the same tab
                    /*
                    (context.findAncestorStateOfType<MyHomePageState>())
                        ?.setState(() {
                          (context.findAncestorStateOfType<MyHomePageState>())
                              ?.showChatHome = false;
                          (context.findAncestorStateOfType<MyHomePageState>())
                              ?.selectedIndex = 2;
                        });

                        */
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(
                            0.5,
                          ), // ✅ Grey shadow with transparency
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(
                            0,
                            3,
                          ), // Shadow position (horizontal, vertical)
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      child: Icon(
                        Icons.auto_awesome,
                        color: const Color.fromARGB(255, 106, 0, 255),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Categories(
            categories: categories,
            selectedIndex: selectedIndex,
            onCategorySelected: updateCategory,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPaddin),
              child: GridView.builder(
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: kDefaultPaddin,
                  crossAxisSpacing: kDefaultPaddin,
                  childAspectRatio: 0.75,
                ),
                itemBuilder:
                    (context, index) => ItemCard(
                      product:
                          filteredProducts[index], // ✅ Use filteredProducts here
                      press:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DetailsScreen(
                                    product: filteredProducts[index],
                                  ), // ✅ Use filteredProducts here
                            ),
                          ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Categories extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const Categories({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPaddin),
      child: SizedBox(
        height: 25,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) => buildCategory(index),
        ),
      ),
    );
  }

  Widget buildCategory(int index) {
    return GestureDetector(
      onTap: () => onCategorySelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPaddin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              categories[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    selectedIndex == index
                        ? Colors.black
                        : Colors.deepPurpleAccent.shade200,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: kDefaultPaddin / 8),
              height: 2,
              width: 30,
              color: selectedIndex == index ? Colors.black : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

const kDefaultPaddin = 20.0;

class Product {
  final String image, title, description, category;
  final int price, size, id;
  final Color color;

  Product({
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.size,
    required this.id,
    required this.color,
    required this.category,
  });
}

List<Product> products = [
  // Foods
  Product(
    id: 1,
    title: "Apple",
    price: 100,
    size: 1,
    description: "A healthy fruit",
    image: "assets/img/profile_pic.png",
    color: Colors.deepPurpleAccent,
    category: "Foods",
  ),
  Product(
    id: 2,
    title: "Banana",
    price: 50,
    size: 1,
    description: "High in potassium",
    image: "assets/img/profile_pic.png",
    color: Colors.purpleAccent,
    category: "Foods",
  ),
  Product(
    id: 3,
    title: "Broccoli",
    price: 80,
    size: 1,
    description: "Rich in vitamins",
    image: "assets/img/profile_pic.png",
    color: Colors.deepPurple,
    category: "Foods",
  ),
  Product(
    id: 4,
    title: "Carrot",
    price: 60,
    size: 1,
    description: "Good for vision",
    image: "assets/img/profile_pic.png",
    color: Colors.indigoAccent,
    category: "Foods",
  ),

  // Supplements
  Product(
    id: 5,
    title: "Protein Shake",
    price: 200,
    size: 2,
    description: "Great for muscle gain",
    image: "assets/img/profile_pic.png",
    color: Colors.purple,
    category: "Supplements",
  ),
  Product(
    id: 6,
    title: "Vitamin C",
    price: 150,
    size: 2,
    description: "Boosts immunity",
    image: "assets/img/profile_pic.png",
    color: Colors.deepPurpleAccent,
    category: "Supplements",
  ),
  Product(
    id: 7,
    title: "Omega-3",
    price: 250,
    size: 2,
    description: "Good for heart health",
    image: "assets/img/profile_pic.png",
    color: Colors.tealAccent,
    category: "Supplements",
  ),
  Product(
    id: 8,
    title: "Collagen",
    price: 180,
    size: 2,
    description: "Improves skin health",
    image: "assets/img/profile_pic.png",
    color: Colors.purpleAccent,
    category: "Supplements",
  ),

  // Seeds
  Product(
    id: 9,
    title: "Chia Seeds",
    price: 50,
    size: 1,
    description: "Rich in fiber",
    image: "assets/img/profile_pic.png",
    color: Colors.lightBlueAccent,
    category: "Seeds",
  ),
  Product(
    id: 10,
    title: "Flax Seeds",
    price: 60,
    size: 1,
    description: "High in omega-3",
    image: "assets/img/profile_pic.png",
    color: Colors.yellowAccent,
    category: "Seeds",
  ),
  Product(
    id: 11,
    title: "Pumpkin Seeds",
    price: 70,
    size: 1,
    description: "Rich in magnesium",
    image: "assets/img/profile_pic.png",
    color: Colors.brown,
    category: "Seeds",
  ),
  Product(
    id: 12,
    title: "Sunflower Seeds",
    price: 65,
    size: 1,
    description: "Good for snacking",
    image: "assets/img/profile_pic.png",
    color: Colors.greenAccent,
    category: "Seeds",
  ),

  // Drinks
  Product(
    id: 13,
    title: "Green Tea",
    price: 75,
    size: 1,
    description: "Boosts metabolism",
    image: "assets/img/profile_pic.png",
    color: Colors.deepPurpleAccent,
    category: "Drinks",
  ),
  Product(
    id: 14,
    title: "Coffee",
    price: 90,
    size: 1,
    description: "Keeps you awake",
    image: "assets/img/profile_pic.png",
    color: Colors.purpleAccent,
    category: "Drinks",
  ),
  Product(
    id: 15,
    title: "Lemon Juice",
    price: 60,
    size: 1,
    description: "Rich in vitamin C",
    image: "assets/img/profile_pic.png",
    color: Colors.indigoAccent,
    category: "Drinks",
  ),
  Product(
    id: 16,
    title: "Almond Milk",
    price: 120,
    size: 1,
    description: "Dairy-free alternative",
    image: "assets/img/profile_pic.png",
    color: Colors.deepPurpleAccent,
    category: "Drinks",
  ),
];

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.product, required this.press});

  final Product product;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(kDefaultPaddin),
              decoration: BoxDecoration(
                color: product.color,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Hero(
                tag: "${product.id}",
                child: Image.asset(product.image),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPaddin / 4),
            child: Text(
              product.title,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          Text(
            "\$${product.price}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
