import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/date_time/local_date.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money_parser.dart';
import 'organic.dart';

/// Amount input that parses to integer minor units without floating point.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.currency,
    required this.label,
    this.helper,
    this.required = true,
    this.allowNegative = false,
    this.allowZero = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final Currency currency;
  final String label;
  final String? helper;
  final bool required;
  final bool allowNegative;
  final bool allowZero;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: currency.minorDigits > 0, signed: allowNegative),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(allowNegative ? r'[0-9.,\-]' : r'[0-9.,]'))],
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          prefixText: '${currency.symbol} ',
        ),
        onChanged: onChanged,
        validator: (v) {
          if ((v ?? '').trim().isEmpty) return required ? 'Enter an amount' : null;
          final minor = MoneyParser.parseMinor(v!, currency, allowNegative: allowNegative);
          if (minor == null) {
            return currency.minorDigits == 0
                ? 'Enter a whole number'
                : 'Enter a valid amount (up to ${currency.minorDigits} decimals)';
          }
          if (!allowZero && minor == 0) return 'Amount must not be zero';
          return null;
        },
      );
}

int? parseMoney(TextEditingController c, Currency currency, {bool allowNegative = false}) =>
    c.text.trim().isEmpty ? null : MoneyParser.parseMinor(c.text, currency, allowNegative: allowNegative);

final _dateFormat = DateFormat('d MMM yyyy');

String formatDate(LocalDate d) => _dateFormat.format(d.toDateTime());

String formatMonth(YearMonth m) => DateFormat('MMMM yyyy').format(m.firstDay.toDateTime());

String formatMonthShort(YearMonth m) => DateFormat('MMM').format(m.firstDay.toDateTime());

/// Tappable field showing a date and opening the platform date picker.
class DateField extends FormField<LocalDate> {
  DateField({
    super.key,
    required String label,
    LocalDate? initial,
    required ValueChanged<LocalDate?> onChanged,
    bool optional = false,
    LocalDate? firstDate,
    LocalDate? lastDate,
    String? helper,
    super.validator,
  }) : super(
          initialValue: initial,
          builder: (state) {
            final context = state.context;
            Future<void> pick() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: (state.value ?? LocalDate.fromDateTime(now)).toDateTime(),
                firstDate: (firstDate ?? LocalDate(1970, 1, 1)).toDateTime(),
                lastDate: (lastDate ?? LocalDate(now.year + 20, 12, 31)).toDateTime(),
              );
              if (picked != null) {
                final d = LocalDate.fromDateTime(picked);
                state.didChange(d);
                onChanged(d);
              }
            }

            return InkWell(
              onTap: pick,
              // Ripple follows the field's organic outline.
              customBorder: const BlobInputBorder(),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  helperText: helper,
                  errorText: state.errorText,
                  suffixIcon: optional && state.value != null
                      ? IconButton(
                          tooltip: 'Clear date',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            state.didChange(null);
                            onChanged(null);
                          },
                        )
                      : const Icon(Icons.calendar_today_rounded, size: 20),
                ),
                child: Text(
                  state.value == null ? (optional ? 'Not set' : 'Choose a date') : formatDate(state.value!),
                  style: AppType.body.copyWith(color: state.value == null ? context.colors.inkMuted : null),
                ),
              ),
            );
          },
        );
}

/// Pill-shaped single choice built on [ChoiceChip]s.
class ChoicePills<T> extends StatelessWidget {
  const ChoicePills({super.key, required this.values, required this.selected, required this.label, required this.onSelected});

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(label(v)),
              selected: v == selected,
              labelStyle: AppType.label.copyWith(
                color: v == selected ? context.colors.accentText : context.colors.ink,
                fontWeight: v == selected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (_) => onSelected(v),
            ),
        ],
      );
}

/// Dropdown styled like other inputs.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final String? helper;

  @override
  // Keyed by value so programmatic changes to [value] are reflected.
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        key: ValueKey<T>(value),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, helperText: helper, helperMaxLines: 3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        items: [for (final v in values) DropdownMenuItem(value: v, child: Text(itemLabel(v)))],
        // T may itself be nullable (e.g. an "All sources" option).
        onChanged: (v) => onChanged(v as T),
      );
}

/// Picks a minute-of-day.
Future<int?> pickMinuteOfDay(BuildContext context, int initial) async {
  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60));
  return t == null ? null : t.hour * 60 + t.minute;
}

String formatMinuteOfDay(int m) {
  final h = m ~/ 60;
  final mm = (m % 60).toString().padLeft(2, '0');
  return '${h.toString().padLeft(2, '0')}:$mm';
}

const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
