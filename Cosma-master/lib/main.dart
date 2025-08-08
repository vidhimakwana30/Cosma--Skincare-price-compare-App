import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher_string.dart';

void main() {
  runApp(const CosmaApp());
}

class CosmaApp extends StatelessWidget {
  const CosmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosma Beauty',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFF06292),
        scaffoldBackgroundColor: const Color(0xFFFCE4EC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF06292),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(query: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF48FB1),
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.spa,
                      size: 70,
                      color: Colors.yellow[100],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Name
                  const Text(
                    'Cosma',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                  const Text(
                    'Your Beauty Product Finder',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search beauty products...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFF06292),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF06292),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Search Products',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Popular Categories
                  const Text(
                    'Popular Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildCategoryChip('Skincare'),
                      _buildCategoryChip('Makeup'),
                      _buildCategoryChip('Fragrances'),
                      _buildCategoryChip('Haircare'),
                      _buildCategoryChip('Korean Beauty'),
                      _buildCategoryChip('Natural Products'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return InkWell(
      onTap: () {
        _searchController.text = label;
        _search();
      },
      child: Chip(
        label: Text(label),
        labelStyle: const TextStyle(
          color: Color(0xFFF06292),
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color(0xFFFFEBEE),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF8BBD0)),
        ),
      ),
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://cosma-eight.vercel.app';
  // Maximum retry attempts
  static const int maxRetries = 5;
  // Delay between retries (in seconds)
  static const int retryDelay = 5;
  // Enable mock data if server is unreachable
  static const bool enableMockData = true;

  // Safely parse JSON response and handle errors
  static List<Map<String, dynamic>> _parseJsonResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        debugPrint('Unexpected response format: not a list');
        return [];
      }
    } catch (e) {
      debugPrint('JSON parsing error: $e');
      return [];
    }
  }

  // Retry mechanism for API calls with detailed logging
  static Future<http.Response?> _retryableGetRequest(Uri uri) async {
    int attempts = 0;
    late Object lastError;

    // Add headers to request
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Mobile Safari/537.36',
      'Connection': 'keep-alive',
      'Origin': 'https://cosma-eight.vercel.app'
    };

    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint('Attempt $attempts to fetch from ${uri.toString()}');

        final response = await http
            .get(
              uri,
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response headers: ${response.headers}');
        debugPrint(
            'Response body (first 100 chars): ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}');

        if (response.statusCode == 200) {
          return response;
        } else {
          debugPrint(
              'API error (status: ${response.statusCode}). Retrying in $retryDelay seconds...');
        }
      } catch (e) {
        lastError = e;
        debugPrint('Request error: $e. Retrying in $retryDelay seconds...');
      }

      // Wait before retry
      if (attempts < maxRetries) {
        await Future.delayed(Duration(seconds: retryDelay));
      }
    }

    // If we got here, all retries failed
    debugPrint('All $maxRetries requests failed. Last error: $lastError');
    return null;
  }

  // Generate mock data for Nykaa products
  static List<Map<String, dynamic>> _getMockNykaaProducts(String query) {
    debugPrint('Using mock data for Nykaa with query: $query');
    return [
      {
        'name': 'Nykaa Naturals Face Wash - $query Special',
        'price': '₹349',
        'link': 'https://www.nykaa.com/products/face-wash',
        'image':
            'https://images-static.nykaa.com/media/catalog/product/tr:w-200,h-200,cm-pad_resize/8/9/8904245709815_1.jpg',
        'source': 'Nykaa',
      },
      {
        'name': 'Nykaa $query Cream with Natural Extracts',
        'price': '₹499',
        'link': 'https://www.nykaa.com/products/cream',
        'image':
            'https://images-static.nykaa.com/media/catalog/product/tr:w-200,h-200,cm-pad_resize/5/3/53ce6518904245703677_1.jpg',
        'source': 'Nykaa',
      },
      {
        'name': 'Nykaa Best of $query Kit',
        'price': '₹999',
        'link': 'https://www.nykaa.com/products/kit',
        'image':
            'https://images-static.nykaa.com/media/catalog/product/tr:w-200,h-200,cm-pad_resize/2/4/24cf0e78904245700065_1.jpg',
        'source': 'Nykaa',
      },
    ];
  }

  // Generate mock data for Amazon products
  static List<Map<String, dynamic>> _getMockAmazonProducts(String query) {
    debugPrint('Using mock data for Amazon with query: $query');
    return [
      {
        'name': 'Amazon Brand $query Moisturizer with Hyaluronic Acid',
        'price': '₹599',
        'link': 'https://www.amazon.in/product/moisturizer',
        'image': 'https://m.media-amazon.com/images/I/61ze2WIs58L._SL1500_.jpg',
        'source': 'Amazon',
      },
      {
        'name': 'Premium $query Serum by Amazon Basics',
        'price': '₹799',
        'link': 'https://www.amazon.in/product/serum',
        'image': 'https://m.media-amazon.com/images/I/71JZ9qlEXhL._SL1500_.jpg',
        'source': 'Amazon',
      },
      {
        'name': 'Amazon Exclusive $query Night Cream',
        'price': '₹449',
        'link': 'https://www.amazon.in/product/night-cream',
        'image': 'https://m.media-amazon.com/images/I/71LJqgQdDtL._SL1500_.jpg',
        'source': 'Amazon',
      },
    ];
  }

  static Future<List<Map<String, dynamic>>> fetchNykaaProducts(
      String query) async {
    try {
      // Try direct URL with query parameter instead
      final uri =
          Uri.parse('$baseUrl/scrape_nykaa_f/${Uri.encodeComponent(query)}/');
      final response = await _retryableGetRequest(uri);

      if (response != null) {
        final products = _parseJsonResponse(response.body);
        if (products.isNotEmpty) {
          return products;
        }
      }

      // If we get here, either the request failed or returned empty results
      debugPrint('Unable to fetch Nykaa products from API');

      // Return mock data if enabled
      if (enableMockData) {
        return _getMockNykaaProducts(query);
      }

      return [];
    } catch (e) {
      debugPrint('Nykaa fetch error: $e');

      // Return mock data if enabled
      if (enableMockData) {
        return _getMockNykaaProducts(query);
      }

      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAmazonProducts(
      String query) async {
    try {
      // Try direct URL with query parameter instead
      final uri =
          Uri.parse('$baseUrl/scrape_amazon_f/${Uri.encodeComponent(query)}/');
      final response = await _retryableGetRequest(uri);

      if (response != null) {
        final products = _parseJsonResponse(response.body);
        if (products.isNotEmpty) {
          return products;
        }
      }

      // If we get here, either the request failed or returned empty results
      debugPrint('Unable to fetch Amazon products from API');

      // Return mock data if enabled
      if (enableMockData) {
        return _getMockAmazonProducts(query);
      }

      return [];
    } catch (e) {
      debugPrint('Amazon fetch error: $e');

      // Return mock data if enabled
      if (enableMockData) {
        return _getMockAmazonProducts(query);
      }

      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllProducts(
      String query) async {
    try {
      // Show loading in console
      debugPrint('Fetching all products for query: $query');

      // Attempt to get products from both sources
      final nykaaProducts = await fetchNykaaProducts(query);
      final amazonProducts = await fetchAmazonProducts(query);

      final List<Map<String, dynamic>> allProducts = [];

      // Add Nykaa products if any
      for (var product in nykaaProducts) {
        try {
          allProducts.add({
            'name': product['name'] ?? 'Unknown Product',
            'price': product['price'] ?? 'N/A',
            'link': product['link'] ?? '',
            'image': product['image'] ?? '',
            'source': 'Nykaa',
          });
        } catch (e) {
          debugPrint('Error processing Nykaa product: $e');
        }
      }

      // Add Amazon products if any
      for (var product in amazonProducts) {
        try {
          allProducts.add({
            'name': product['name'] ?? 'Unknown Product',
            'price': product['price'] ?? 'N/A',
            'link': product['link'] ?? '',
            'image': product['image'] ?? '',
            'source': 'Amazon',
          });
        } catch (e) {
          debugPrint('Error processing Amazon product: $e');
        }
      }

      debugPrint('Total products fetched: ${allProducts.length}');
      if (allProducts.isEmpty) {
        debugPrint('WARNING: No products were fetched from either source');
      }

      return allProducts;
    } catch (e) {
      debugPrint('Error in fetchAllProducts: $e');

      // In case of complete failure, return a mix of mock data
      if (enableMockData) {
        final nykaa = _getMockNykaaProducts(query);
        final amazon = _getMockAmazonProducts(query);
        return [...nykaa, ...amazon];
      }

      return [];
    }
  }
}

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({
    super.key,
    required this.query,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  String _currentFilter = 'All'; // 'All', 'Nykaa', 'Amazon'
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _productsFuture = ApiService.fetchAllProducts(widget.query);

    _productsFuture.then((products) {
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    if (_currentFilter == 'All') {
      return _allProducts;
    } else {
      return _allProducts
          .where((product) => product['source'] == _currentFilter)
          .toList();
    }
  }

  Future<void> _launchProductUrl(String url) async {
    if (url == 'N/A' || url.isEmpty) return;

    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open product link')),
        );
      }
    }
  }

  Widget _filterChip(String label) {
    final isSelected = _currentFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = label;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFF06292),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF880E4F),
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF8BBD0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFFFCE4EC),
              child: product['image'] != null &&
                      product['image'].toString().isNotEmpty
                  ? Image.network(
                      product['image'].toString(),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFFF06292),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.shopping_bag,
                            size: 50,
                            color: Color(0xFFF06292),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.shopping_bag,
                        size: 50,
                        color: Color(0xFFF06292),
                      ),
                    ),
            ),
          ),

          // Product info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product['name']?.toString() ?? 'Product Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF880E4F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product['price']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC407A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Source indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: product['source'] == 'Nykaa'
                        ? const Color(0xFFFCE4EC)
                        : const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Source: ${product['source']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: product['source'] == 'Nykaa'
                          ? const Color(0xFFEC407A)
                          : Colors.blue,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // View Product button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (product['link'] != null &&
                          product['link'].toString().isNotEmpty) {
                        _launchProductUrl(product['link'].toString());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF06292),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Product',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.spa,
              size: 24,
              color: Colors.yellow[100],
            ),
            const SizedBox(width: 10),
            const Text('Cosma'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      body: Column(
        children: [
          // Results header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Results for "${widget.query}"',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC407A),
              ),
            ),
          ),

          // Main content area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFFF06292),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Searching for products...',
                          style: TextStyle(
                            color: Color(0xFF880E4F),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Color(0xFFF8BBD0),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Error loading products:\n$_errorMessage',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF880E4F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF06292),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : _allProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: Color(0xFFF8BBD0),
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  'No products found. Please try a different search.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF880E4F),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF06292),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('New Search'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Filter chips
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _filterChip('All'),
                                    const SizedBox(width: 10),
                                    _filterChip('Nykaa'),
                                    const SizedBox(width: 10),
                                    _filterChip('Amazon'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Product count
                              Text(
                                'Showing ${_getFilteredProducts().length} products',
                                style: const TextStyle(
                                  color: Color(0xFF880E4F),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Product list
                              Expanded(
                                child: _getFilteredProducts().isEmpty
                                    ? Center(
                                        child: Text(
                                          'No products found in $_currentFilter. Try another filter.',
                                          style: const TextStyle(
                                            color: Color(0xFF880E4F),
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount:
                                            _getFilteredProducts().length,
                                        itemBuilder: (context, index) {
                                          return _buildProductCard(
                                              _getFilteredProducts()[index]);
                                        },
                                      ),
                              ),
                            ],
                          ),
          ),

          // New Search button at bottom
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF06292),
                  side: const BorderSide(color: Color(0xFFF06292)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'New Search',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
