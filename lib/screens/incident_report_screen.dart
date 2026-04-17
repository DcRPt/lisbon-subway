import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/data/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:testable_form_field/testable_form_field.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();

  Station? _station;
  IncidentType? _type;
  int? _severity;
  DateTime? _dateTime;
  String? _notes;

  Future<void> _pickDateTime(Function(DateTime?) onPicked) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime ?? now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime ?? now),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final clamped = picked.isAfter(now) ? now : picked;
    setState(() => _dateTime = clamped);
    onPicked(clamped);
  }

  void _submit() {
    if (_station == null || _type == null || _severity == null || _dateTime == null) {
      _formKey.currentState!.validate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha todos os campos obrigatórios.'),
        backgroundColor: AppColors.kErrorRed,
      ));
      return;
    }

    try {
      context.read<MetroRepository>().attachIncident(
        _station!.id,
        IncidentReport(
          timestamp: _dateTime!,
          rate: _severity!,
          type: _type!,
          notes: _notes?.trim().isEmpty ?? true ? null : _notes,
        ),
      );
      setState(() { _station = null; _type = null; _severity = null; _dateTime = null; _notes = null; });
      _formKey.currentState!.reset();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Incidente registado com sucesso.'),
        backgroundColor: AppColors.kSuccessGreen,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: $e'),
        backgroundColor: AppColors.kErrorRed,
      ));
    }
  }

  Widget _field(String label, Widget child, {bool required = true, bool hasError = false, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.kFieldText)),
          if (required) const Text(' *', style: TextStyle(fontSize: 12, color: AppColors.kErrorRed)),
        ]),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.kFieldBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: hasError ? AppColors.kErrorRed : AppColors.kFieldBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: child,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(errorText, style: const TextStyle(fontSize: 11, color: AppColors.kErrorRed)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stations = context.read<MetroRepository>().getAllStations();
    const ramp = [AppColors.kSuccessGreen, Color(0xFF5A9E3A), Color(0xFFF5A800), Color(0xFFB36B00), AppColors.kErrorRed];

    return Scaffold(
      key: const Key('incidents-report-screen'),
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: AppColors.kNavyBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Reportar incidente',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              TestableFormField<Station>(
                key: const Key('incident-station-selection-field'),
                getValue: () => _station as Station,
                internalSetValue: (state, v) { _station = v; state.didChange(v); },
                validator: (v) => v == null ? 'Preencha a estação' : null,
                onSaved: (v) => _station = v,
                builder: (field) => _field('Estação', DropdownButton<Station>(
                  value: _station, isExpanded: true, underline: const SizedBox(),
                  hint: const Text('Selecione uma estação', style: TextStyle(fontSize: 14, color: AppColors.kFieldText)),
                  items: stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (v) { field.didChange(v); setState(() => _station = v); },
                ), hasError: field.errorText != null, errorText: field.errorText),
              ),
              const SizedBox(height: 16),

              TestableFormField<IncidentType>(
                key: const Key('incident-type-selection-field'),
                getValue: () => _type as IncidentType,
                internalSetValue: (state, v) { _type = v; state.didChange(v); },
                validator: (v) => v == null ? 'Preencha o tipo de incidente' : null,
                onSaved: (v) => _type = v,
                builder: (field) => _field('Tipo de problema', DropdownButton<IncidentType>(
                  value: _type, isExpanded: true, underline: const SizedBox(),
                  hint: const Text('Selecione o tipo de problema', style: TextStyle(fontSize: 14, color: AppColors.kFieldText)),
                  items: IncidentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                  onChanged: (v) { field.didChange(v); setState(() => _type = v); },
                ), hasError: field.errorText != null, errorText: field.errorText),
              ),
              const SizedBox(height: 16),

              TestableFormField<int>(
                key: const Key('incident-rating-field'),
                getValue: () => _severity as int,
                internalSetValue: (state, v) { _severity = v; state.didChange(v); },
                validator: (v) => v == null ? 'Preencha a avaliação' : null,
                onSaved: (v) => _severity = v,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Text('Gravidade', style: TextStyle(fontSize: 12, color: AppColors.kFieldText)),
                      Text(' *', style: TextStyle(fontSize: 12, color: AppColors.kErrorRed)),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        final level = i + 1;
                        final selected = _severity == level;
                        final color = ramp[i];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                            child: GestureDetector(
                              onTap: () { field.didChange(level); setState(() => _severity = level); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selected ? color.withValues(alpha: 0.13) : AppColors.kFieldBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected ? color : (field.errorText != null ? AppColors.kErrorRed : AppColors.kFieldBorder),
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(child: Text('$level',
                                  style: TextStyle(fontSize: 15,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                      color: selected ? color : AppColors.kFieldText),
                                )),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('1 = menor', style: TextStyle(fontSize: 10, color: AppColors.kFieldText)),
                      Text('5 = crítico', style: TextStyle(fontSize: 10, color: AppColors.kFieldText)),
                    ]),
                    if (field.errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(field.errorText!, style: const TextStyle(fontSize: 11, color: AppColors.kErrorRed)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TestableFormField<DateTime>(
                key: const Key('incident-datetime-field'),
                getValue: () => _dateTime as DateTime,
                internalSetValue: (state, v) { _dateTime = v; state.didChange(v); },
                validator: (v) => v == null ? 'Preencha a data e hora' : null,
                onSaved: (v) => _dateTime = v,
                builder: (field) => _field('Data e hora', ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _dateTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(_dateTime!) : 'Selecione a data e hora',
                    style: TextStyle(fontSize: 14, color: _dateTime != null ? const Color(0xFF1A1A2E) : AppColors.kFieldText),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.kFieldText),
                  onTap: () => _pickDateTime(field.didChange),
                ), hasError: field.errorText != null, errorText: field.errorText),
              ),
              const SizedBox(height: 16),

              TestableFormField<String>(
                key: const Key('incident-notes-field'),
                getValue: () => _notes as String,
                internalSetValue: (state, v) { _notes = v; state.didChange(v); },
                onSaved: (v) => _notes = v,
                builder: (field) => _field('Notas', TextField(
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    hintText: 'Descreva brevemente o problema...',
                    hintStyle: TextStyle(fontSize: 14, color: AppColors.kFieldText),
                  ),
                  onChanged: (v) { field.didChange(v); _notes = v; },
                ), required: false),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('incident-form-submit-button'),
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kNavyBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Submeter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}