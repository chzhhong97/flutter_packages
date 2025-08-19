import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jc_widgets/jc_widgets.dart';

class GroupListPlusExample extends StatefulWidget {
  const GroupListPlusExample({super.key});

  @override
  _GroupListPlusExampleState createState() => _GroupListPlusExampleState();
}

class _GroupListPlusExampleState extends State<GroupListPlusExample> with TickerProviderStateMixin{
  Map<String, List<int>> groupMap = {};

  final FocusNode focusNode = FocusNode();
  final AutoScrollController<String, String> _controller = AutoScrollController();

  final GlobalKey _sliverAppBarKey = GlobalKey();

  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GroupListPlus<String, String>.gridView(
          itemList: List.generate(100, (i) => getRandomString(10)),
          axis: Axis.horizontal,
          groupBy: (String element) => element[0].toUpperCase(),
          sortGroupBy: (a, b) => a.compareTo(b),
          gridViewConfig: GridViewConfig(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10
          ),
          subListPadding: EdgeInsets.all(10),
          groupItemBuilder: (context, index, item, isSelected, isEmpty){
            return Container(
              height: 100,
              color: isSelected ? Colors.red : Colors.white,
              child: Text(
                item,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            );
          },
          groupHeaderBuilder: (context, index, group, state){
            return Container(
              color: Colors.green,
              padding: EdgeInsets.only(
                  top: 16,
                  left: 24,
                  right: 24
              ),
              child: AnimatedText(
                  group,
                  key: ValueKey(group),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700
                  ),
                  duration: const Duration(milliseconds: 200),
                  textAlign: TextAlign.left
              ),
            );
          },
          itemBuilder: (context, index, group, item, width){
            return Container(
              height: width,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Text(item),
            );
          },
          /*itemSeparatorBuilder: (context, index){
            return Container(
              height: 1,
              color: Colors.black,
            );
          },*/
          itemListContainer: (context, child){
            return Container(
              color: Colors.white,
              child: child,
            );
          },
          nestedScrollViewBodyBuilder: (context, child){
            return TabBarView(
              controller: _tabController,
              children: [
                child,
                CustomScrollView(
                  slivers: [
                    SliverPinnedOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
                    SliverToBoxAdapter(
                      child: Container(
                        height: MediaQuery.of(context).size.height * .75,
                        color: Colors.amber,
                        child: Text("TOP"),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                      "Tab 3"
                  ),
                ),
              ],
            );
          },
          onRefresh: () async {
            setState(() {});
          },
          groupListFlex: .2,
          /*groupListBuilder: (children){
            return Row(
              children: children,
            );
          },*/
          scrollOffset: (offset){
            return ObserverUtils.calcPersistentHeaderExtent(
              key: _sliverAppBarKey,
              offset: offset,
            );
          },
          sliverHeaderList: (context, _) => [
            DynamicHeightSliverAppBar(
              appBarKey: _sliverAppBarKey,
              elevation: 4,
              pinned: true,
              forceElevated: true,
              leading: Center(
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: IconButton(
                      onPressed: () => Navigator.pop(this.context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      )
                  ),
                ),
              ),
              titleBuilder: (context, isCollapsed){
                print(isCollapsed);
                return AnimatedOpacity(
                  opacity: isCollapsed ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Test Title",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Stack(
                        children: [
                          Container(
                            height: 200 + kToolbarHeight,
                            color: Colors.red,
                          ),
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: kToolbarHeight,
                            child: Text(
                                "Test Title",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                  preferredSize: Size.fromHeight(kToolbarHeight),
                  child: Container(
                    color: Colors.blue,
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                      indicatorWeight: 3,
                      unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xffBDBDBD),
                          fontSize: 14),
                      tabs: List.generate(3, (e){
                        return Tab(text: "Tab $e");
                      }).toList(),
                    ),
                  )
              ),
            ),
          ],
          emptyWidget: const Center(
            child: Text("This is empty"),
          ),
        ),
      ),
    );
  }

  List<Menu> getMenuList(int numberOfGroups, int itemsPerGroup){
    List<Menu> items = [];

    for (int groupIndex = 1; groupIndex <= numberOfGroups; groupIndex++) {
      items.add(
          Menu(
              promoList: List.generate(itemsPerGroup, (i) => Promo(id: 'Category $groupIndex, Promo $i')),
              productList: List.generate(itemsPerGroup, (i) => Product(id: 'Category $groupIndex, Product $i')),
              categoryId: 'Category $groupIndex'
          )
      );
    }

    print(items.length);

    return items;
  }

  String getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random random = Random();

    return String.fromCharCodes(
      List.generate(length, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}

class Menu{
  final List<Promo> promoList;
  final List<Product> productList;
  final String categoryId;

  const Menu({
    required this.promoList,
    required this.productList,
    required this.categoryId,
  });
}

class Promo{
  final String id;

  const Promo({
    required this.id,
  });
}

class Product{
  final String id;

  const Product({
    required this.id,
  });
}