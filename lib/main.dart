import 'package:cached_network_image/cached_network_image.dart';
import 'package:ckan/models/lastsearch.dart';
import 'package:ckan/models/source.dart';
import 'package:ckan/page_results_service.dart';
import 'package:ckan/recipe.dart';
import 'package:ckan/recipe_service.dart';
import 'package:ckan/screens/fvaourites.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

void main() => runApp(
      CKApp(),
    );

class CKApp extends StatelessWidget {
  final Color primarySwatchCK = Colors.lightGreen;
  final Color primarySwatchBBCGF = Colors.teal[300];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => SourceModel()),
        Provider(create: (context) => LastSearchModel()),
      ],
      child: MainApp(
          primarySwatchCK: primarySwatchCK,
          primarySwatchBBCGF: primarySwatchBBCGF),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({
    Key key,
    @required this.primarySwatchCK,
    @required this.primarySwatchBBCGF,
  }) : super(key: key);

  final Color primarySwatchCK;
  final Color primarySwatchBBCGF;

  @override
  Widget build(BuildContext context) {
    var activeSource = Provider.of<SourceModel>(context);
    return MaterialApp(
      title: 'CK',
      theme: ThemeData(
        primaryColor: Colors.blueGrey[400],
        accentColor: Colors.blueGrey[500],
        primarySwatch: (activeSource.active == activeSource.sources[0])
            ? primarySwatchCK
            : primarySwatchBBCGF,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => RecipeSearch(),
      },
    );
  }
}

class RecipeSearch extends StatefulWidget {
  @override
  _RecipeSearchState createState() => _RecipeSearchState();
}

class _RecipeSearchState extends State<RecipeSearch> {
  String searchquery = '';
  String currentPage = "0";
  Set<String> _lastSearches = Set();
  final controller = TextEditingController();
  SearchFilter activeFilter = _searchFiltersCK[0];
  Set<RecipeDetail> _favourites = {};

  static final List<SearchFilter> _searchFiltersCK = [
    SearchFilter("relevanz", ""),
    SearchFilter("bewertung", "o8"),
    SearchFilter("datum", "o3"),
  ];

  static final List<SearchFilter> _searchFiltersBBCGF = [
    SearchFilter("relevance", ""),
    SearchFilter("rating", "votinagapi_weighted_average&order=desc"),
    SearchFilter("date", "created&order=desc"),
  ];

  void _setSearchQueryText() {
    searchquery = controller.text;
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_setSearchQueryText);
  }

  @override
  void dispose() {
    controller.removeListener(_setSearchQueryText);
    controller.dispose();
    super.dispose();
  }

  void _handleTap(String page) {
    setState(() {
      currentPage = page;
    });
    _searchRecipe(searchquery);
  }

  void _handlePillTap(String inp) {
    setState(() {
      searchquery = inp;
      controller.text = inp;
      _searchRecipe(searchquery);
    });
  }

  void _handleActiveFilterChanged(SearchFilter searchFilter) {
    setState(() {
      activeFilter = searchFilter;
    });
    _searchRecipe(searchquery);
  }

  void _handleActiveSourceChanged(RecipeSource source) {}

  void _handleFavouriteViewPressed() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FavouritesView(
                  favourites: _favourites.toList(),
                )));
  }

  void _searchRecipe(String inp) {
      SearchQuery sq = SearchQuery(searchquery, currentPage, activeFilter);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                _showResultsBody(fetchRecipes(sq), sq, _handleTap)),
      );
  }

  @override
  Widget build(BuildContext context) {
    var activeSource = Provider.of<SourceModel>(context);
    var searches = Provider.of<LastSearchModel>(context);

    void _handleDelete(String value) {
      searches.remove(value);
    }

    Widget _sourceButtons(ValueChanged<RecipeSource> handler) {
      return DropdownButton<RecipeSource>(
        value: activeSource.active,
        icon: Icon(Icons.arrow_downward),
        underline: Container(
          height: 2,
          color: Colors.black12,
        ),
        onChanged: handler,
        items: activeSource.sources.map<DropdownMenuItem<RecipeSource>>((i) {
          return DropdownMenuItem<RecipeSource>(
            value: i,
            child: Text(i.name),
          );
        }).toList(),
      );
    }

    void _submitRecipe(String inp) {
      if (inp != '') {
        _searchRecipe(inp);
        searches.add(inp);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('CK'),
        actions: <Widget>[
          _sourceButtons(
            _handleActiveSourceChanged,
            activeSource.sources,
          ),
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: _handleFavouriteViewPressed,
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: TextField(
              controller: controller,
              onSubmitted: _submitRecipe,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.activeSource.name == 'Chefkoch')
                ..._searchFiltersCK
                    .map((i) => _radioWidgetCriteria(
                        i, activeFilter, _handleActiveFilterChanged))
                    .toList(),
              if (widget.activeSource.name == 'BBCGF')
                ..._searchFiltersBBCGF
                    .map((i) => _radioWidgetCriteria(
                        i, activeFilter, _handleActiveFilterChanged))
                    .toList(),
            ],
          ),
          LastSearchGrid(_handleDelete, _handlePillTap, _lastSearches.toList()),
        ],
      ),
    );
  }
}

Widget _radioWidgetCriteria(SearchFilter value, SearchFilter groupvalue,
    ValueChanged<SearchFilter> handler) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      Text(value.criterion),
      Radio<SearchFilter>(
        value: value,
        groupValue: groupvalue,
        onChanged: handler,
      ),
    ],
  );
}

FutureBuilder<List<Recipe>> _showResultsBody(
    Future<List<Recipe>> handler, SearchQuery sq, ValueChanged<String> cb) {
  return FutureBuilder(
    future: handler,
    builder: (BuildContext context, AsyncSnapshot<List<Recipe>> snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.none:
          return Container(child: Center(child: Text("Please try again.")));
        case ConnectionState.active:
        case ConnectionState.waiting:
          return Container(child: Center(child: CircularProgressIndicator()));
        case ConnectionState.done:
          if (snapshot.hasError) {
            return Text("Something went wrong: ${snapshot.error}");
          }
          return RecipeGrid(sq, snapshot.data, cb);
      }
      return null;
    },
  );
}

FutureBuilder<RecipeDetail> _showRecipeDetailBody(
    Future<RecipeDetail> handler, ImageProvider image) {
  return FutureBuilder(
    future: handler,
    builder: (BuildContext context, AsyncSnapshot<RecipeDetail> snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.none:
          return Container(child: Center(child: Text("Please try again.")));
        case ConnectionState.active:
        case ConnectionState.waiting:
          return Container(child: Center(child: CircularProgressIndicator()));
        case ConnectionState.done:
          if (snapshot.hasError) {
            return Text("Something went wrong: ${snapshot.error}");
          }
          return RecipeDetailView(
            context: context,
            recipeDetail: snapshot.data,
            image: image,
          );
      }
      return null;
    },
  );
}

class RecipeGrid extends StatefulWidget {
  final SearchQuery searchQuery;
  final List<Recipe> recipes;
  final ValueChanged<String> onChanged;

  RecipeGrid(this.searchQuery, this.recipes, this.onChanged);

  @override
  _RecipeGridState createState() => _RecipeGridState();
}

class _RecipeGridState extends State<RecipeGrid> {
  bool bottomOfPage = false;
  ScrollController _controller = ScrollController();
  Listener listener = Listener();
  PageResultsService _prs = PageResultsService();

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent - 40.0) {
      setState(() {
        bottomOfPage = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollListener);
    super.dispose();
  }

  void _showNextResults() {
    widget.onChanged(_prs.nextPage(widget.searchQuery.page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.searchQuery.searchterm),
      ),
      floatingActionButton: bottomOfPage
          ? FloatingActionButton(
              onPressed: _showNextResults,
              child: Icon(Icons.arrow_forward),
            )
          : Container(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GridView.extent(
              maxCrossAxisExtent: 480.00,
              controller: _controller,
              children: widget.recipes
                  .map((i) => RecipeSearchItem(recipe: i))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeSearchItem extends StatefulWidget {
  final Recipe recipe;

  RecipeSearchItem({Key key, this.recipe}) : super(key: key);

  @override
  _RecipeSearchItemState createState() => _RecipeSearchItemState();
}

class _RecipeSearchItemState extends State<RecipeSearchItem> {
  ImageProvider image;

  void _showRecipe(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return _showRecipeDetailBody(
        fetchRecipeDetail(widget.recipe.url),
        image,
      );
    }));
  }

  @override
  void initState() {
    super.initState();
    image = CachedNetworkImageProvider(widget.recipe.thumbnail);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRecipe(context),
      child: GridTile(
        child: Hero(
          tag: widget.recipe.thumbnail,
          child: FadeInImage(
            placeholder: MemoryImage(kTransparentImage),
            image: image,
            fit: BoxFit.fitWidth,
          ),
        ),
        footer: GridTileBar(
          backgroundColor: Colors.black54,
          title: Text(widget.recipe.title),
          subtitle: Text("Difficulty: " +
              widget.recipe.difficulty +
              ", Preptime: " +
              widget.recipe.preptime),
        ),
      ),
    );
  }
}

class _RecipeInfoRow extends StatelessWidget {
  const _RecipeInfoRow({
    Key key,
    @required this.rowLabel,
    @required this.rowInfo,
    this.rowTextColor,
  }) : super(key: key);

  final String rowLabel;
  final String rowInfo;
  final Color rowTextColor;

  @override
  Widget build(BuildContext context) {
    TextStyle ts = TextStyle(color: rowTextColor);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: 8.0,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(rowLabel, style: ts),
          ),
          Text(rowInfo, style: ts),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }
}

class RecipeDetailView extends StatefulWidget {
  final BuildContext context;
  final RecipeDetail recipeDetail;
  final ImageProvider image;
  final PaletteGenerator generator;

  RecipeDetailView(
      {this.context, this.recipeDetail, this.image, this.generator});

  @override
  _RecipeDetailViewState createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {
  PaletteGenerator generator;
  Color bgcolor;
  Color txtcolor;
  Color appiconcolor = Colors.black;
  Duration _duration = Duration(milliseconds: 1000);
  bool isFavourite = false;

  Future<void> _updatePaletteGenerator(ImageProvider image) async {
    generator = await PaletteGenerator.fromImageProvider(
      image,
      maximumColorCount: 8,
    );
    bgcolor = generator.lightMutedColor?.color ?? Colors.white;
    txtcolor = generator.lightMutedColor?.bodyTextColor ?? Colors.black87;
    appiconcolor = generator.lightMutedColor?.titleTextColor ?? Colors.black87;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _updatePaletteGenerator(widget.image);
  }

  void handleFavouriteButtonPress() {
    setState(() {
      isFavourite = !isFavourite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    const double _kRecipeViewerMaxWidth = 460.0;
    final bool _fullWidth = _size.width < _kRecipeViewerMaxWidth;

    Widget _recipeIngredientsView() {
      return AnimatedContainer(
        duration: _duration,
        color: bgcolor,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var ingredient in widget.recipeDetail.ingredients)
                    new _IngredientsLine(
                        ingredient: ingredient, txtcolor: txtcolor),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _recipeMethodView() {
      return AnimatedContainer(
        duration: _duration,
        color: bgcolor,
        child: ListView(
          children: <Widget>[
            Stack(
              children: [
                buildFadeInImage(_size),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    onPressed: handleFavouriteButtonPress,
                    child: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2.0, 1.0, 2.0, 1.0),
              child: Text(
                widget.recipeDetail.method,
                style: TextStyle(color: txtcolor),
              ),
            ),
          ],
        ),
      );
    }

    Widget _recipeInfoView() {
      return AnimatedContainer(
        duration: _duration,
        color: bgcolor,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(0.5, 0, 0.5, 10.0),
              child: SizedBox(
                width: _fullWidth ? _size.width : _kRecipeViewerMaxWidth,
                height: _size.height / 2.0,
                child: FadeInImage(
                  image: widget.image,
                  fit: BoxFit.fitWidth,
                  placeholder: MemoryImage(kTransparentImage),
                ),
              ),
            ),
            _RecipeInfoRow(
              rowLabel: "Difficulty",
              rowInfo: widget.recipeDetail.difficulty,
              rowTextColor: txtcolor,
            ),
            _RecipeInfoRow(
                rowLabel: "Rating",
                rowInfo: widget.recipeDetail.rating,
                rowTextColor: txtcolor),
            _RecipeInfoRow(
              rowLabel: "Cooking Time",
              rowInfo: widget.recipeDetail.cookingtime,
              rowTextColor: txtcolor,
            ),
          ],
        ),
      );
    }

    AppBar appBar = AppBar(
        title: Text(
          widget.recipeDetail.title,
          style: TextStyle(color: txtcolor),
        ),
        iconTheme: IconThemeData(color: appiconcolor),
        backgroundColor: bgcolor,
        textTheme: TextTheme(headline6: TextStyle(color: txtcolor)),
        bottom: TabBar(tabs: <Widget>[
          Tab(
              icon: Icon(
            Icons.description,
            color: txtcolor,
          )),
          Tab(icon: Icon(Icons.list, color: appiconcolor)),
          Tab(icon: Icon(Icons.info, color: appiconcolor)),
        ]));
    return DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: appBar,
          body: TabBarView(
            children: <Widget>[
              _recipeMethodView(),
              _recipeIngredientsView(),
              _recipeInfoView(),
            ],
          )),
    );
  }

  Widget buildFadeInImage(Size size) {
    return Container(
      width: size.width,
      constraints: BoxConstraints(
        maxHeight: size.height / 2.4,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4.0, 0, 4.0),
        child: Image(
          image: widget.image,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}

class _IngredientsLine extends StatelessWidget {
  const _IngredientsLine({
    Key key,
    @required this.ingredient,
    @required this.txtcolor,
  }) : super(key: key);

  final RecipeIngredient ingredient;
  final Color txtcolor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            Text(
              ingredient.amount + ' ',
              style: TextStyle(color: txtcolor ?? Colors.black),
            ),
            Text(
              ingredient.ingredient,
              style: TextStyle(color: txtcolor ?? Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class LastSearchGrid extends StatelessWidget {
  final ValueChanged<String> onDeleted;
  final ValueChanged<String> onTapped;
  final List<String> _lastSearches;

  LastSearchGrid(this.onDeleted, this.onTapped, this._lastSearches);

  void _handleOnDelete(String value) {
    onDeleted(value);
  }

  void _handleOnTap(String value) {
    onTapped(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Wrap(
      spacing: 12.0,
      runSpacing: 4.0,
      children: _lastSearches
          .map((i) => LastSearchWidget(i, _handleOnDelete, _handleOnTap))
          .toList(),
    ));
  }
}

class LastSearchWidget extends StatelessWidget {
  final String value;
  final ValueChanged<String> onDeleted;
  final ValueChanged<String> onTapped;

  LastSearchWidget(this.value, this.onDeleted, this.onTapped);

  void _handleOnDelete() {
    onDeleted(value);
  }

  void _handleTap() {
    onTapped(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Chip(
        label: GestureDetector(
          child: Text(value),
          onTap: _handleTap,
        ),
        deleteIcon: Icon(Icons.delete),
        onDeleted: _handleOnDelete,
      ),
    );
  }
}
