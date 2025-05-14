import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';

class SearchPrendasViewModel extends ChangeNotifier {
  final ValueNotifier<List<Map<String, dynamic>>> resultsNotifier =
      ValueNotifier([]);
  final List<Map<String, dynamic>> _originalResults = [];
  String _query = '';

  String? _selectedStore;
  double? _minPrice;
  double? _maxPrice;

  double? get minPrice => _minPrice;
  set minPrice(double? value) {
    _minPrice = value;
    notifyListeners();
  }

  double? get maxPrice => _maxPrice;
  set maxPrice(double? value) {
    _maxPrice = value;
    notifyListeners();
  }

  String? get selectedStore => _selectedStore;
  set selectedStore(String? value) {
    _selectedStore = value;
    notifyListeners();
  }

  List<String> get allStores =>
      _originalResults
          .map((item) => item['store']?.toString() ?? '')
          .toSet()
          .where((store) => store.isNotEmpty)
          .toList();

  void setQuery(String value) {
    _query = value;
  }

  Future<void> search() async {
    if (_query.isEmpty) return;
    final uri = Uri.parse('$baseURL/api/search-prendas?q=$_query');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _originalResults.clear();
        _originalResults.addAll(List<Map<String, dynamic>>.from(data));
        resultsNotifier.value = List<Map<String, dynamic>>.from(
          _originalResults,
        );
      } else {
        resultsNotifier.value = [];
      }
    } catch (e) {
      resultsNotifier.value = [];
    }
  }

  void applyFilters({String? store, double? minPrice, double? maxPrice}) {
    _selectedStore = store ?? _selectedStore;
    _minPrice = minPrice ?? _minPrice;
    _maxPrice = maxPrice ?? _maxPrice;
    final filtered =
        _originalResults.where((item) {
          final itemStore = item['store']?.toLowerCase() ?? '';
          final itemPrice =
              double.tryParse(
                item['price']?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
              ) ??
              0;

          final storeMatch =
              _selectedStore == null ||
              itemStore.contains(_selectedStore!.toLowerCase());
          final priceMatch =
              (_minPrice == null || itemPrice >= _minPrice!) &&
              (_maxPrice == null || itemPrice <= _maxPrice!);

          return storeMatch && priceMatch;
        }).toList();

    resultsNotifier.value = filtered;
    notifyListeners();
  }

  void resetFilters() {
    _selectedStore = null;
    _minPrice = null;
    _maxPrice = null;
    resultsNotifier.value = List<Map<String, dynamic>>.from(_originalResults);
  }

  // void loadMockData() {
  //   final List<Map<String, dynamic>> mockData = [
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3bb74c6e3951c460b0a9f943f7bb4adba.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/13882541709069727226?gl=us",
  //       "price": "\$17.49",
  //       "product":
  //           "Fashion Nova Vestido Work of Art Strapless Rayon Blend Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3a15c97e08a29ab15424fc34a61cc9bc2.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/3802264001515689819?gl=us",
  //       "price": "\$32.89",
  //       "product":
  //           "Fashion Nova Backless Embellished Sleeveless Sequin Deep V-Neck, All Types Mini Dress in Multi Color",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a32fbee68fdaf37efede25bea7e72a285a.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/13930566414071688571?gl=us",
  //       "price": "\$52.99",
  //       "product":
  //           "72styles Infinity Dress Women's with Bandeau Convertible Bridesmaid Dress",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a334bf6ccda99cab74d27b57e0bce29690.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/14384766915986676160?gl=us",
  //       "price": "\$20.99",
  //       "product": "Fashion Nova Vestido Mini It's Happy Hour Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3d0382f75daab5d5abe5c4499c0dcedcc.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/11450446176179104697?gl=us",
  //       "price": "\$55.99",
  //       "product": "Fashion Nova Embellished Off Shoulder Sequin Maxi Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3095e228ca363a04833e0c06ec275cc5b.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/4911914687892259225?gl=us",
  //       "price": "\$34.99",
  //       "product":
  //           "FENSACE Women's Floral Short Sleeve Wrap V Neck A-Line Midi Dress",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3c76e3ab1c1b02b70e0b81442cb54d892.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/2155309570589141598?gl=us",
  //       "price": "\$38.49",
  //       "product": "Fashion Nova Vestido Maxi Chelsea Printed Linen Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a301c730a03c41e1b1f91a4fd33e45884d.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/1821816520200633289?gl=us",
  //       "price": "\$25.89",
  //       "product": "Fashion Nova Vestido Mini Fruncido Sucker for Love",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3487ccc631e7b3f6b58f6af9044275d5c.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/6222634619622481269?gl=us",
  //       "price": "\$37.99",
  //       "product": "Women's Flowy V-Neck Short Sleeve Shift Dress",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a33b57d314ea6aff8975301804b056acba.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/8626263096486826323?gl=us",
  //       "price": "\$27.99",
  //       "product": "Fashion Nova Vestido Mini Christy Sequin T-Shirt",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3c0e1259cd35228a1963bdf275e0465e5.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/16852098553538831440?gl=us",
  //       "price": "\$34.99",
  //       "product":
  //           "Fashion Nova Cut Out Embellished One Shoulder Sequin Mini Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3e5886f6b5267031fba338f7636b668a3.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/6661480359990398057?gl=us",
  //       "price": "\$13.98",
  //       "product": "Fashion Nova Vestido Midi At A Glance Long Sleeve",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a30986f2f387e3de30bd8ae3e27cbcb341.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/1604569920056650943?gl=us",
  //       "price": "\$34.99",
  //       "product": "Women's Casual Square Neck A-Line Midi Dress with Pockets",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3062b0b9bfcaa0950e72d815072a85f26.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/13942573953477540553?gl=us",
  //       "price": "\$38.49",
  //       "product":
  //           "Fashion Nova Vestido Maxi No Second Changes Lace Trim Split Hem Sleeveless Maxi Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a310cc847e21fc77fca77ec77daa16c907.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/12103641280584743632?gl=us",
  //       "price": "\$38.49",
  //       "product": "Fashion Nova Vestido Mini Dolled Up Eyelet Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3a3769f741ecf52011d177d2568db690a.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/12420152857921338343?gl=us",
  //       "price": "\$9.98",
  //       "product": "Women's Loose U Neck Sleeveless Sundress with Pockets",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a373d6c9f0006d4fc92f265d64ac0cd5d4.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/13252021171127444341?gl=us",
  //       "price": "\$59.49",
  //       "product":
  //           "Fashion Nova Vestido On The Rise Sequin Sweetheart Gown with High Slit",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3860c65fa04be51b51c6345d6a7557418.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/11856966408509967178?gl=us",
  //       "price": "\$24.49",
  //       "product": "Fashion Nova Vestido Simple and Sweet Ruched Mesh Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a31e90a531e8b8dea3486f512ea11bd41d.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/8736169590380447802?gl=us",
  //       "price": "\$53.99",
  //       "product": "Maxigerui Women's Boho Floral Print Midi Dress",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a30171ec729a6ddfce0dff94009b955d87.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/3144458676113244998?gl=us",
  //       "price": "\$31.49",
  //       "product": "Fashion Nova Vestido Midi Make Me Roar Satin Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a37248ae8d8711e8a053071ad2cb70b2f3.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/3793614291018180808?gl=us",
  //       "price": "\$17.49",
  //       "product": "Fashion Nova Vestido Midi Fruncido Keep Up Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a39c65b1f8b794d63c10978fdaad999987.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/4904459099829595915?gl=us",
  //       "price": "\$34.99",
  //       "product":
  //           "Fashion Nova Vestido Maxi Ignore The Romance Off Shoulder Tricot Maxi Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a38c8243a49a2f0332293c3db8730f5931.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/716032082639773238?gl=us",
  //       "price": "\$59.99",
  //       "product": "Women's Boho Flowy Floral Midi Corset Lace Up Sundress",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3865c769d9855c02342db3497d959cbf2.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/8546894242237297499?gl=us",
  //       "price": "\$24.49",
  //       "product": "Fashion Nova Vestido Mini Fruncido Center of The Party",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3ce5c61a5026d1de8817727e6c86ac975.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/10360469956361831260?gl=us",
  //       "price": "\$27.99",
  //       "product": "Fashion Nova Vestido Midi Fruncido Chelsea",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3d77189f9ea7375e644e9c6eaa95414da.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/6314607260938131450?gl=us",
  //       "price": "\$50.99",
  //       "product": "Elegant Spaghetti Strap Floral Maxi Dress",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a316246742a8d739a016b0861759603f46.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/13287347382799533870?gl=us",
  //       "price": "\$27.99",
  //       "product":
  //           "Fashion Nova Puff Sleeve Long Sleeve Mesh Sweetheart Did You Me Midi Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a349195212712aba3f366b83d34843c088.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/18297373718609672611?gl=us",
  //       "price": "\$27.99",
  //       "product": "Fashion Nova Vestido Mini Waiting for Ur Love Tricot Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3442a4b717c9c324519add8b449745b1d.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/17216434884123819798?gl=us",
  //       "price": "\$36.99",
  //       "product":
  //           "Cupshe Ornate Diamond Neck Twist & Keyhole Maxi Dress - Cobalt - XL",
  //       "store": "Walmart - Cupshe",
  //     },
  //     {
  //       "imagen":
  //           "https://serpapi.com/searches/6824bb23af5fdc887579ed5c/images/c189cab62cdbff04290d6d5986af03a3e073dc4d7318e8a5ef5358cae83471dc.webp",
  //       "link":
  //           "https://www.google.com/shopping/product/2323568934225204744?gl=us",
  //       "price": "\$13.98",
  //       "product": "Fashion Nova Vestido Midi Organza Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcSpL4MhYtQSBZdHWQ1q7HcY4LBP49ohwkkAjpowaSTUDEmduxuYgKiBQOYA2ueOv_vE0bDHcGXHGBFGme1oy3cy8msO8rhtnGVZ-v5wu9ZG",
  //       "link":
  //           "https://www.google.com/shopping/product/13365752023301924173?gl=us",
  //       "price": "\$37.99",
  //       "product": "Women's V-Neck Ruffle Shift Dress",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcSPfvSXGSzGfLERdYEiKSfIA6f5aSpIwM3Is_gbjZCl4cgSpCyJnr9tXrO1Jgid12crTzUeMEizN3ZGV9k5LuAS77g8Cf4iXTxlZzRjHaS2K2dDm0ylUU99JA",
  //       "link":
  //           "https://www.google.com/shopping/product/1828460473403607925?gl=us",
  //       "price": "\$34.99",
  //       "product":
  //           "Fashion Nova Vestido Maxi On Scene Corset Waist Sleeveless Tricot Maxi Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn2.gstatic.com/shopping?q=tbn:ANd9GcQ05yrDTjHUgoccy31HQ2BvxbBycUheeZsgYq2ylDKlCkPQyq3dCUrGwZzsTX_G6EJ1-5bn4Rhaa5kjh-dyiZ9rbV8wQdtmnMFljGQNVFg9yfEmQC9Pu6mu",
  //       "link":
  //           "https://www.google.com/shopping/product/18372410428753226829?gl=us",
  //       "price": "\$27.99",
  //       "product": "Fashion Nova Vestido Midi Bills Paid",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcSMJZDFfqwdlT1Lyz-4kS-92FG-Boh7dVZfFPYkXv2T_Kl9EMmpN3Lb-Ukxtz-eTlygYKn6y79wdC69j8WmZ8xsB9HrkzRDd12dq4WpcdBW",
  //       "link":
  //           "https://www.google.com/shopping/product/9329623423076793340?gl=us",
  //       "price": "\$29.99",
  //       "product": "Women's Casual Sleeveless Sundress with Pockets",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcSBAw7Kk_W7JSU3S6r60XcK0oJ7YpMdNAwP2ZnNsGM1ZFvQBJdeOKm_fVc_Rh4wTmJuVio_Ny4QM8in9-e64rICv9KIXCnsEsumCie-NO3gWdnfW061Rb74HA",
  //       "link":
  //           "https://www.google.com/shopping/product/16125967444337597032?gl=us",
  //       "price": "\$25.89",
  //       "product":
  //           "Fashion Nova Vestido Micro Mini Just for The Night Lace Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcSVORngRmj8hUoEwAX-yfT0XmIF4U_SkB_f10GRScaEa9p77iZiYcmd4bMyCFeQ5MAWT0t-UfBA7k6_1nBJYr1KV-D890WUl4gX5cCh35D0sjvD7t-3vjyFiw",
  //       "link":
  //           "https://www.google.com/shopping/product/11260022870434505401?gl=us",
  //       "price": "\$139.99",
  //       "product":
  //           "Fashion Nova Julianne Feather Trim Metallic Strapless Sequin Maxi Dress",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn2.gstatic.com/shopping?q=tbn:ANd9GcTeb_GR_Rl6H8o9__vCIBaZ-qK_V5ki3DJ6xcB8MTq-Vgb4S7OZuxpgPsdBbvijgoVn2-hxpkDahJm8Cflm_BN8Y4D4OHW4P9k1vc8z_5yt3zrhQHK2FSVWJA",
  //       "link":
  //           "https://www.google.com/shopping/product/11063295230271410961?gl=us",
  //       "price": "\$53.99",
  //       "product":
  //           "YMDUCH Women's Elegant Sleeveless Off Shoulder Bodycon Long Formal Party Evening Dress",
  //       "store": "Amazon.com - Seller",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcR4H4AwAa6lXMoJwgYkdNTHKGG8GG7R7TnMA4TqBgb8mkAQsdk1ZG3TmCLm0tysjVz7q-UL_GI0hRxE8puV2z_BWFLAOPbMjPYmNz7sRamVDE1tdL3uBkvx",
  //       "link":
  //           "https://www.google.com/shopping/product/7039168628672137303?gl=us",
  //       "price": "\$8.00",
  //       "product":
  //           "Fashion Nova Vestido Mini Simple Square Neck Ruched Sleeveless",
  //       "store": "Fashion Nova",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcR1PgOt61tcqTGlhghXibAByq9ma2_4LWU4AHB6FNpYkVGj7l3PsexN5BrERu7HENbKr7bIBgVnSA7uvv2vdSFx6to4A3m11K1HJDP2Hic1wVZeJQ9br61nGg",
  //       "link":
  //           "https://www.google.com/shopping/product/14865847970809880979?gl=us",
  //       "price": "\$44.99",
  //       "product":
  //           "Women's Cupshe Astrid Sleeveless V-neck Tassel Ruching Dress",
  //       "store": "Kohl's",
  //     },
  //     {
  //       "imagen":
  //           "https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcQ9NTW0MPfB6OkDTldPtDXGrSmyS19V9MxusXpQelmcUhoBNBVtbfe4_9_4htHBj07iOivScJXph65P_nDI1Vvh4azwYVgkEyOEP8QMZbgDhaGre_VU1whNMnI",
  //       "link":
  //           "https://www.google.com/shopping/product/17027589991016798808?gl=us",
  //       "price": "\$31.49",
  //       "product": "Fashion Nova Vestido Mini Bandage Make It Coquette",
  //       "store": "Fashion Nova",
  //     },
  //   ];

  //   _originalResults.clear();
  //   _originalResults.addAll(mockData);
  //   applyFilters();
  // }
}
