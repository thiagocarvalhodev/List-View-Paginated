import 'dart:async';

import 'package:flutter/material.dart';
import 'package:list_view_paginated/scroll_helper.dart';
import 'package:rxdart/rxdart.dart';

// TODO: Handle case of the initial list don't fill the entire screen.

/// `T` is model object type.
/// `LoadMore` returns a list of new objects passing the current page `page`
typedef LoadMore<T> = Future<List<T>> Function(int page);

typedef ItemBuilder<T> = Widget Function(T model);

class ListViewPaginated<T> extends StatefulWidget {
  final LoadMore<T> loadMore;
  final ItemBuilder<T> itemBuilder;
  final int pageSize;
  final Key key;

  ListViewPaginated(
      {@required this.loadMore,
      @required this.itemBuilder,
      this.pageSize = 10,
      this.key})
      : super(key: key);

  @override
  _ListViewPaginatedState<T> createState() => _ListViewPaginatedState<T>();
}

class _ListViewPaginatedState<T> extends State<ListViewPaginated<T>> {
  @override
  void initState() {
    super.initState();
    _pageSize = widget.pageSize;
    initStream();
    initList();
  }

  initStream() {
    this
        ._controller
        .listen((ScrollNotification notification) => _loadMore(notification));
  }

  @override
  dispose() {
    _itemsController.close();
    _loadingController.close();
    _controller.close();
    super.dispose();
  }

  ReplaySubject<ScrollNotification> _controller =
      ReplaySubject<ScrollNotification>();

  ReplaySubject<List<T>> _itemsController = ReplaySubject<List<T>>();

  ReplaySubject<bool> _loadingController = ReplaySubject<bool>();

  bool _loading = false;

  bool _hasItemsToLoad = true;

  int _pageSize;

  List<T> _items = [];

  /// current page, for default, inits with one.
  int _currentPage = 1;

  // Call new elements and increment the page.
  _loadMore(ScrollNotification notification) async {
    if (!_loading) {
      _startLoading();
      if (notification.metrics.pixels == notification.metrics.maxScrollExtent) {
        try {
          if (_hasItemsToLoad) {
            List<T> moreItems = await widget.loadMore.call(_currentPage++);

            // If the result is less than the page size, means that is the last page and don't have
            // any item to load.
            if (moreItems.length < _pageSize) _hasItemsToLoad = false;

            _items.addAll(moreItems);

            _itemsController.sink.add(_items);
          }

          _finishLoading();
        } catch (e) {
          _finishLoading();
        }
      }
    }
  }

  initList() async {
    try {
      _startLoading();
      List<T> moreItems = await widget.loadMore.call(_currentPage++);

      _items.addAll(moreItems);

      _itemsController.sink.add(_items);
      _finishLoading();
    } catch (e) {
      _finishLoading();
    }
  }

  bool _onNotification(ScrollNotification scrollInfo) {
    if (scrollInfo is OverscrollNotification) {
      _controller.sink.add(scrollInfo);
    }

    return false;
  }

  void _startLoading() {
    _loading = true;
    _loadingController.sink.add(_loading);
  }

  void _finishLoading() {
    _loading = false;
    _loadingController.sink.add(_loading);
  }

  Widget _buildListView(List<T> items) {
    return StreamBuilder<bool>(
      initialData: false,
      stream: _loadingController.stream,
      builder: (context, snapshot) {
        bool isLoading = snapshot.data;

        return ScrollConfiguration(
          behavior: MyBehavior(),
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: isLoading ? items.length + 1 : items.length,
              itemBuilder: (context, index) {
                if (index >= items.length)
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                return widget.itemBuilder(items[index]);
              }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: _onNotification,
      child: StreamBuilder<List<T>>(
        initialData: _items,
        stream: _itemsController.stream,
        builder: (context, snapshot) {
          return _buildListView(snapshot.data);
        },
      ),
    );
  }
}
