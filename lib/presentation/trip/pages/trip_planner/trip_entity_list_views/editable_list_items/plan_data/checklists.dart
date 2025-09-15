import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list_item.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';

class CheckListsView extends StatefulWidget {
  const CheckListsView(
      {required this.checkLists, required this.onCheckListsChanged, super.key});

  final List<CheckListFacade> checkLists;
  final Function() onCheckListsChanged;

  @override
  State<CheckListsView> createState() => _CheckListsViewState();
}

class _CheckListsViewState extends State<CheckListsView> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        var checkList = widget.checkLists.elementAt(index);
        return _CheckList(
          checkList: checkList,
          checkListChanged: () {
            widget.onCheckListsChanged();
          },
          onDeleted: () {
            setState(() {
              widget.checkLists.removeAt(index);
            });
            widget.onCheckListsChanged();
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Padding(padding: EdgeInsets.symmetric(vertical: 3.0));
      },
      itemCount: widget.checkLists.length,
    );
  }
}

class _CheckList extends StatefulWidget {
  final Function() checkListChanged;
  final Function() onDeleted;
  final CheckListFacade checkList;

  const _CheckList(
      {required this.checkList,
      required this.checkListChanged,
      required this.onDeleted});

  @override
  State<_CheckList> createState() => _CheckListState();
}

class _CheckListState extends State<_CheckList> {
  late TextEditingController _titleEditingController;

  @override
  Widget build(BuildContext context) {
    _titleEditingController =
        TextEditingController(text: widget.checkList.title);
    return Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _createTitle(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: _createAddButton(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: IconButton(
                  onPressed: widget.onDeleted,
                  icon: const Icon(Icons.delete),
                ),
              ),
            ],
          ),
          Divider(),
          _ReOrderableCheckListItems(
            checkList: widget.checkList,
            checkListItemsChanged: () {
              widget.checkListChanged();
            },
          ),
        ],
      ),
    );
  }

  TextButton _createAddButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        widget.checkList.items.add(CheckListItem(item: '', isChecked: false));
        widget.checkListChanged();
        setState(() {});
      },
      label: Text(context.localizations.addItem),
      icon: const Icon(Icons.add_rounded),
    );
  }

  TextField _createTitle() {
    return TextField(
      minLines: 1,
      maxLines: 1,
      onChanged: (newValue) {
        if (newValue != widget.checkList.title) {
          widget.checkList.title = newValue;
          widget.checkListChanged();
        }
      },
      controller: _titleEditingController,
      decoration: InputDecoration(
        focusedBorder: InputBorder.none,
        border: InputBorder.none,
        hintText: context.localizations.checkListTitle,
      ),
    );
  }
}

class _ReOrderableCheckListItems extends StatefulWidget {
  final CheckListFacade checkList;
  final Function() checkListItemsChanged;

  const _ReOrderableCheckListItems(
      {required this.checkList, required this.checkListItemsChanged});

  @override
  State<_ReOrderableCheckListItems> createState() =>
      _ReOrderableCheckListItemsState();
}

class _ReOrderableCheckListItemsState
    extends State<_ReOrderableCheckListItems> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      onReorder: _onReorder,
      children: List.generate(
        widget.checkList.items.length,
        (index) {
          var checkListItem = widget.checkList.items.elementAt(index);
          return Padding(
            padding: const EdgeInsets.all(8.0),
            key: GlobalKey(),
            child: _createCheckListItem(checkListItem, index),
          );
        },
      ),
    );
  }

  _CheckListItem _createCheckListItem(CheckListItem checkListItem, int index) {
    return _CheckListItem(
      checkListItem: checkListItem,
      callback: (checkListItem) {
        widget.checkList.items[index] = checkListItem;
        widget.checkListItemsChanged();
      },
      onDeleted: () {
        setState(() {
          widget.checkList.items.removeAt(index);
        });
        widget.checkListItemsChanged();
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = widget.checkList.items.removeAt(oldIndex);
    widget.checkList.items.insert(newIndex, item);
    widget.checkListItemsChanged();
    setState(() {});
  }
}

class _CheckListItem extends StatefulWidget {
  final CheckListItem checkListItem;
  final Function(CheckListItem) callback;
  final Function() onDeleted;

  const _CheckListItem(
      {required this.checkListItem,
      required this.callback,
      required this.onDeleted,
      super.key});

  @override
  State<_CheckListItem> createState() => _CheckListItemState();
}

class _CheckListItemState extends State<_CheckListItem> {
  late TextEditingController _itemEditingController;
  late CheckListItem _checkListItem;

  @override
  void initState() {
    super.initState();
    _checkListItem = CheckListItem(
        item: widget.checkListItem.item,
        isChecked: widget.checkListItem.isChecked);
    _itemEditingController = TextEditingController(text: _checkListItem.item);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: TextField(
              controller: _itemEditingController,
              decoration: const InputDecoration(border: InputBorder.none),
              onChanged: (newValue) {
                if (newValue != _checkListItem.item) {
                  _checkListItem.item = newValue;
                  widget.callback(_checkListItem);
                }
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: Checkbox.adaptive(
              value: _checkListItem.isChecked,
              onChanged: (value) {
                setState(() {
                  _checkListItem.isChecked = value ?? false;
                  widget.callback(_checkListItem);
                });
              }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: SizedBox(
            height: 25,
            width: 25,
            child: IconButton(
              padding: EdgeInsets.zero,
              style: ButtonStyle(
                shape: WidgetStateProperty.all<CircleBorder>(
                  CircleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              onPressed: widget.onDeleted,
              icon: const Icon(Icons.remove_rounded),
            ),
          ),
        )
      ],
    );
  }
}
