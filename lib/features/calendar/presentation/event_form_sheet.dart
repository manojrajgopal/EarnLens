import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/records.dart';
import '../../../domain/money/currency.dart';
import '../../../domain/money/fraction.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';

/// Opens the add/edit form for a user calendar event. In a combined
/// (read-only) view it explains where events are changed instead.
Future<void> showEventForm(BuildContext context, {CalendarEvent? event, required LocalDate date}) async {
  if (ProviderScope.containerOf(context, listen: false).read(isReadOnlyViewProvider)) {
    showMessage(context, const ReadOnlyViewException().message);
    return;
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => _EventForm(event: event, date: date),
  );
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({required this.event, required this.date});
  final CalendarEvent? event;
  final LocalDate date;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.event?.title ?? '');
  late final _notes = TextEditingController(text: widget.event?.notes ?? '');
  late final TextEditingController _amount;
  late LocalDate _date = widget.event?.date ?? widget.date;
  late CalendarEventType _type = widget.event?.type ?? CalendarEventType.reminder;
  late String _sourceId = widget.event?.sourceId ?? '';
  late bool _remind = widget.event?.remind ?? true;

  bool get _editing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    var text = '';
    if (e?.amountMinor != null) {
      final cur = _currency();
      text = Fraction.fromInt(e!.amountMinor!).divInt(cur.minorPerMajor).toDecimalString(cur.minorDigits);
    }
    _amount = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _amount.dispose();
    super.dispose();
  }

  Currency _currency() {
    final src = _sourceId.isEmpty ? null : ref.read(snapshotProvider).source(_sourceId);
    return src == null ? ref.read(currencyProvider) : Currency.byCode(src.currencyCode);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(recordsRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final notes = _notes.text.trim();
    final event = CalendarEvent(
      id: widget.event?.id ?? ref.read(idProvider).newId(),
      title: _title.text.trim(),
      date: _date,
      type: _type,
      createdAt: widget.event?.createdAt ?? now,
      sourceId: _sourceId.isEmpty ? null : _sourceId,
      amountMinor: parseMoney(_amount, _currency()),
      notes: notes.isEmpty ? null : notes,
      remind: _remind,
    );
    final ok = await runGuarded(context, () => repo.saveEvent(event), success: _editing ? 'Event updated' : 'Event added');
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _cancelEvent() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Cancel this event?',
      message: 'It will be removed from your calendar and any reminder for it will stop.',
      confirm: 'Cancel event',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final ok = await runGuarded(context, () => ref.read(recordsRepositoryProvider).cancelEvent(widget.event!.id),
        success: 'Event cancelled');
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sources = ref.watch(sourcesProvider);
    final names = {for (final s in sources) s.id: s.name};
    if (_sourceId.isNotEmpty && !names.containsKey(_sourceId)) names[_sourceId] = 'Removed source';
    final e = widget.event;
    final hasDetails = e != null && (e.sourceId != null || e.amountMinor != null || (e.notes ?? '').isNotEmpty);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Container(
                  width: AppIconSize.badge,
                  height: AppIconSize.badge,
                  decoration: const ShapeDecoration(
                    gradient: AppGradients.orb,
                    shape: BlobBorder(BlobSpec(seed: 13, radius: AppIconSize.badge * 0.42, wobble: 0.5, wave: 1.2)),
                    shadows: AppShadows.glow,
                  ),
                  child: Icon(_editing ? Icons.edit_calendar_rounded : Icons.event_note_outlined, color: AppColors.white),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Semantics(
                      header: true,
                      child: Text(_editing ? 'Edit event' : 'New event', style: AppType.title.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Text('Reminders and notes on your calendar', style: AppType.caption.copyWith(color: c.inkMuted)),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpace.xl),
              TextFormField(
                controller: _title,
                autofocus: !_editing,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Send invoice to client'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: AppSpace.sm),
              DateField(label: 'Date', initial: _date, onChanged: (d) => setState(() => _date = d ?? _date)),
              const SizedBox(height: AppSpace.lg),
              Text('Type', style: AppType.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AppSpace.sm),
              ChoicePills<CalendarEventType>(
                values: CalendarEventType.values,
                selected: _type,
                label: (t) => t.label,
                onSelected: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: AppSpace.lg),
              Material(
                color: c.cardHigh,
                shape: BlobBorder(BlobShapes.cloud(14, radius: 22, wobble: 0.35)),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    maintainState: true,
                    initiallyExpanded: hasDetails,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                    childrenPadding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md),
                    iconColor: c.accentText,
                    collapsedIconColor: c.inkMuted,
                    title: Text('More details', style: AppType.label.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('Income source, amount and notes (optional)',
                        style: AppType.caption.copyWith(color: c.inkMuted)),
                    children: [
                      SelectField<String>(
                        label: 'Income source (optional)',
                        value: _sourceId,
                        values: ['', ...names.keys],
                        itemLabel: (id) => id.isEmpty ? 'None' : names[id]!,
                        onChanged: (v) => setState(() => _sourceId = v),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      MoneyField(
                        controller: _amount,
                        currency: _currency(),
                        label: 'Amount (optional)',
                        required: false,
                      ),
                      const SizedBox(height: AppSpace.lg),
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Notes (optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Material(
                color: c.cardHigh,
                shape: BlobBorder(BlobShapes.cloud(15, radius: 22, wobble: 0.45)),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  shape: BlobBorder(BlobShapes.cloud(15, radius: 22, wobble: 0.45)),
                  secondary: Icon(Icons.notifications_active_outlined, color: c.accentText),
                  title: const Text('Remind me'),
                  subtitle: const Text('Get a notification on this day'),
                  value: _remind,
                  onChanged: (v) => setState(() => _remind = v),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              BusyButton(label: _editing ? 'Save changes' : 'Add event', onPressed: _save, accent: true),
              if (_editing) ...[
                const SizedBox(height: AppSpace.sm),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: c.error, minimumSize: const Size(64, 48)),
                  onPressed: _cancelEvent,
                  icon: const Icon(Icons.event_busy_outlined),
                  label: const Text('Cancel event'),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
