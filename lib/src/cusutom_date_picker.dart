import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

TextStyle _textStyle = const TextStyle();
bool _useMagnifier = true;
double _itemExtent = 60.0;
double _offAxisFraction = 0.3;
double _squeeze = 1.25;
double _magnification = 2.35 / 2.1;
SelectOverlayDecoration? _overlayDecoration;

String Function(int day) _getDatePickerDay = (int day) => '$day';

String Function(int month) _getDatePickerMonth = (int month) => '$month';

String Function(int year) _getDatePickerYear = (int year) => '$year';

class SelectOverlayDecoration {
  final BorderRadiusGeometry? borderRadius;
  final Color? color;

  SelectOverlayDecoration({
    this.borderRadius,
    this.color,
  });
}

class CustomDatePickerController extends ChangeNotifier {
  final DateTime initialDateTime;
  final DateTime? minimumDate;
  final DateTime? maximumDate;

  // The controller of the day picker. There are cases where the selected value
  // of the picker is invalid (e.g. February 30th 2018), and this _dayController
  // is responsible for jumping to a valid value.
  @protected
  late FixedExtentScrollController _dayController;
  @protected
  late FixedExtentScrollController _monthController;
  @protected
  late FixedExtentScrollController _yearController;

  bool _isDayPickerScrolling = false;
  bool _isMonthPickerScrolling = false;
  bool _isYearPickerScrolling = false;

  set isDayPickerScrolling(bool isScroll) {
    _isDayPickerScrolling = isScroll;
    notifyListeners();
  }

  set isMonthPickerScrolling(bool isScroll) {
    _isMonthPickerScrolling = isScroll;
    notifyListeners();
  }

  set isYearPickerScrolling(bool isScroll) {
    _isYearPickerScrolling = isScroll;
    notifyListeners();
  }

  bool get isScrolling =>
      _isDayPickerScrolling ||
      _isMonthPickerScrolling ||
      _isYearPickerScrolling;

  CustomDatePickerController({
    required this.initialDateTime,
    this.minimumDate,
    this.maximumDate,
  }) {
    final selectedDay = initialDateTime.day;
    final selectedMonth = initialDateTime.month;
    final selectedYear = initialDateTime.year;

    _dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
    _monthController =
        FixedExtentScrollController(initialItem: selectedMonth - 1);
    _yearController = FixedExtentScrollController(initialItem: selectedYear);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void animatedToDate(DateTime date) {
    final targetDay = date.day;
    final targetMonth = date.month;
    final targetYear = date.year;

    _dayController.animateTo(
      _itemExtent * (targetDay - 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _monthController.animateTo(
      _itemExtent * (targetMonth - 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _yearController.animateTo(
      _itemExtent * targetYear,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class CustomDatePicker extends StatefulWidget {
  final CustomDatePickerController controller;
  final Function(DateTime newDate) onDateTimeChange;
  final bool? useMagnifier;
  final double? itemExtent;
  final double? offAxisFraction;
  final double? squeeze;
  final double? magnification;
  final TextStyle? itemTextStyle;
  final SelectOverlayDecoration? selectOverlayDecoration;
  final String Function(int day)? setDayDisplayText;
  final String Function(int month)? setMonthDisplayText;
  final String Function(int year)? setYearDisplayText;

  CustomDatePicker({
    Key? key,
    required this.controller,
    required this.onDateTimeChange,
    this.itemExtent,
    this.offAxisFraction,
    this.squeeze,
    this.itemTextStyle,
    this.setDayDisplayText,
    this.setMonthDisplayText,
    this.setYearDisplayText,
    this.useMagnifier,
    this.magnification,
    this.selectOverlayDecoration,
  }) : super(key: key) {
    if (itemExtent != null) {
      _itemExtent = itemExtent!;
    }
    if (itemTextStyle != null) {
      _textStyle = itemTextStyle!;
    }
    if (offAxisFraction != null) {
      _offAxisFraction = offAxisFraction!;
    }
    if (squeeze != null) {
      _squeeze = squeeze!;
    }
    if (setDayDisplayText != null) {
      _getDatePickerDay = setDayDisplayText!;
    }
    if (setMonthDisplayText != null) {
      _getDatePickerMonth = setMonthDisplayText!;
    }
    if (setYearDisplayText != null) {
      _getDatePickerYear = setYearDisplayText!;
    }
    if (useMagnifier != null) {
      _useMagnifier = useMagnifier!;
    }
    if (magnification != null) {
      _magnification = magnification!;
    }
    if (selectOverlayDecoration != null) {
      _overlayDecoration = selectOverlayDecoration!;
    }
  }

  @override
  State<StatefulWidget> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  // The currently selected values of the picker.
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;

  late DateTime selectedDateTime;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.controller.initialDateTime.day;
    selectedMonth = widget.controller.initialDateTime.month;
    selectedYear = widget.controller.initialDateTime.year;
    selectedDateTime = DateTime(
      widget.controller.initialDateTime.year,
      widget.controller.initialDateTime.month,
      widget.controller.initialDateTime.day,
    );
  }

  DateTime _lastDayInMonth(int year, int month) => DateTime(year, month + 1, 0);

  bool get _isCurrentDateValid {
    // The current date selection represents a range [minSelectedData, maxSelectDate].
    final DateTime minSelectedDate =
        DateTime(selectedYear, selectedMonth, selectedDay);
    final DateTime maxSelectedDate =
        DateTime(selectedYear, selectedMonth, selectedDay + 1);

    final bool minCheck =
        widget.controller.minimumDate?.isBefore(maxSelectedDate) ?? true;
    final bool maxCheck =
        widget.controller.maximumDate?.isBefore(minSelectedDate) ?? false;

    return minCheck && !maxCheck && minSelectedDate.day == selectedDay;
  }

  // One or more pickers have just stopped scrolling.
  void _pickerDidStopScrolling() {
    // Call setState to update the greyed out days/months/years, as the currently
    // selected year/month may have changed.
    setState(() {});

    if (widget.controller.isScrolling) {
      return;
    }

    // Whenever scrolling lands on an invalid entry, the picker
    // automatically scrolls to a valid one.
    final DateTime minSelectDate =
        DateTime(selectedYear, selectedMonth, selectedDay);
    final DateTime maxSelectDate =
        DateTime(selectedYear, selectedMonth, selectedDay + 1);

    final bool minCheck =
        widget.controller.minimumDate?.isBefore(maxSelectDate) ?? true;
    final bool maxCheck =
        widget.controller.maximumDate?.isBefore(minSelectDate) ?? false;

    if (!minCheck || maxCheck) {
      // We have minCheck === !maxCheck.
      final DateTime targetDate = minCheck
          ? widget.controller.maximumDate!
          : widget.controller.minimumDate!;
      _scrollToDate(targetDate);
      return;
    }

    // Some months have less days (e.g. February). Go to the last day of that month
    // if the selectedDay exceeds the maximum.
    if (minSelectDate.day != selectedDay) {
      final DateTime lastDay = _lastDayInMonth(selectedYear, selectedMonth);
      _scrollToDate(lastDay);
    }
  }

  void _scrollToDate(DateTime newDate) {
    SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
      if (selectedYear != newDate.year) {
        _animateColumnControllerToItem(
            widget.controller._yearController, newDate.year);
      }

      if (selectedMonth != newDate.month) {
        _animateColumnControllerToItem(
            widget.controller._monthController, newDate.month - 1);
      }

      if (selectedDay != newDate.day) {
        _animateColumnControllerToItem(
            widget.controller._dayController, newDate.day - 1);
      }
    });
  }

  void _animateColumnControllerToItem(
      FixedExtentScrollController controller, int targetItem) {
    controller.animateToItem(
      targetItem,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 200),
    );
  }

  void _notifyDateChange({
    required DateTime newDate,
  }) {
    if (newDate != selectedDateTime) {
      selectedDateTime = newDate;
      widget.onDateTimeChange(selectedDateTime);
    }
  }

  Widget _buildDayPicker() {
    final int daysInCurrentMonth =
        _lastDayInMonth(selectedYear, selectedMonth).day;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          widget.controller.isDayPickerScrolling = true;
        } else if (notification is ScrollEndNotification) {
          widget.controller.isDayPickerScrolling = false;
          if (_isCurrentDateValid) {
            _notifyDateChange(
              newDate: DateTime(selectedYear, selectedMonth, selectedDay),
            );
          }
        }
        return false;
      },
      child: CupertinoPicker(
        scrollController: widget.controller._dayController,
        itemExtent: _itemExtent,
        useMagnifier: _useMagnifier,
        magnification: _magnification,
        squeeze: _squeeze,
        selectionOverlay: const SizedBox(),
        offAxisFraction: _offAxisFraction,
        onSelectedItemChanged: (int index) {
          selectedDay = index + 1;
        },
        looping: true,
        children: List<Widget>.generate(daysInCurrentMonth, (index) {
          final day = index + 1;
          return Center(
            child: Text(
              _getDatePickerDay(day),
              style: _textStyle,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          widget.controller.isMonthPickerScrolling = true;
        } else if (notification is ScrollEndNotification) {
          widget.controller.isMonthPickerScrolling = false;
          _pickerDidStopScrolling();
          if (_isCurrentDateValid) {
            _notifyDateChange(
              newDate: DateTime(selectedYear, selectedMonth, selectedDay),
            );
          }
        }

        return false;
      },
      child: CupertinoPicker(
        scrollController: widget.controller._monthController,
        itemExtent: _itemExtent,
        useMagnifier: _useMagnifier,
        magnification: _magnification,
        squeeze: _squeeze,
        selectionOverlay: const SizedBox(),
        onSelectedItemChanged: (int index) {
          selectedMonth = index + 1;
        },
        looping: true,
        children: List<Widget>.generate(12, (index) {
          final int month = index + 1;

          return Center(
            child: Text(
              _getDatePickerMonth(month),
              style: _textStyle,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildYearPicker() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          widget.controller.isYearPickerScrolling = true;
        } else if (notification is ScrollEndNotification) {
          widget.controller.isYearPickerScrolling = false;
          _pickerDidStopScrolling();
          if (_isCurrentDateValid) {
            _notifyDateChange(
              newDate: DateTime(selectedYear, selectedMonth, selectedDay),
            );
          }
        }
        return false;
      },
      child: CupertinoPicker.builder(
        scrollController: widget.controller._yearController,
        itemExtent: _itemExtent,
        useMagnifier: _useMagnifier,
        magnification: _magnification,
        squeeze: _squeeze,
        selectionOverlay: const SizedBox(),
        offAxisFraction: -_offAxisFraction,
        onSelectedItemChanged: (int index) {
          selectedYear = index;
        },
        itemBuilder: (context, year) {
          if (year < (widget.controller.minimumDate?.year ?? 1900)) {
            return null;
          }

          if (year > (widget.controller.maximumDate?.year ?? 2100)) {
            return null;
          }

          return Center(
            child: Text(
              _getDatePickerYear(year),
              style: _textStyle,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              top: constraints.maxHeight / 2 -
                  (_itemExtent * _magnification / 2),
              left: 0,
              right: 0,
              child: Container(
                height: _itemExtent * _magnification,
                decoration: BoxDecoration(
                  color: _overlayDecoration?.color ?? const Color(0xFFF6F6F6),
                  borderRadius: _overlayDecoration?.borderRadius ??
                      BorderRadius.circular(_itemExtent * 0.167),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: _buildYearPicker()),
                Expanded(child: _buildMonthPicker()),
                Expanded(child: _buildDayPicker()),
              ],
            ),
          ],
        );
      },
    );
  }
}
