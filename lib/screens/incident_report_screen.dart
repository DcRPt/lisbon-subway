import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';
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
  DateTime _dateTime = DateTime.now();
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
    if (_station == null || _type == null || _severity == null) {
      _formKey.currentState!.validate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha todos os campos obrigatórios.'),
        backgroundColor: Color(0xFFC0392B),
      ));
      return;
    }

    try {
      context.read<MetroRepository>().attachIncident(
        _station!.id,
        IncidentReport(
          timestamp: _dateTime,
          rate: _severity!,
          type: _type!,
          notes: _notes?.trim().isEmpty ?? true ? null : _notes,
        ),
      );
      setState(() { _station = null; _type = null; _severity = null; _dateTime = DateTime.now(); _notes = null; });
      _formKey.currentState!.reset();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Incidente registado com sucesso.'),
        backgroundColor: Color(0xFF2E7D6B),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: $e'),
        backgroundColor: const Color(0xFFC0392B),
      ));
    }
  }

  Widget _field(String label, Widget child, {bool required = true, bool hasError = false, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B7A))),
          if (required) const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFC0392B))),
        ]),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F0EB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: hasError ? const Color(0xFFC0392B) : const Color(0xFFD8D6CF)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: child,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(errorText, style: const TextStyle(fontSize: 11, color: Color(0xFFC0392B))),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stations = context.read<MetroRepository>().getAllStations();
    const ramp = [Color(0xFF2E7D6B), Color(0xFF5A9E3A), Color(0xFFF5A800), Color(0xFFB36B00), Color(0xFFC0392B)];

    return Scaffold(
      key: const Key('incidents-report-screen'),
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003087),
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

              // Station
              TestableFormField<Station>(
                key: const Key('incident-station-selection-field'),
                getValue: () => _station as Station,
                internalSetValue: (state, v) { _station = v; state.didChange(v); },
                validator: (v) => v == null ? 'Preencha a estação' : null,
                onSaved: (v) => _station = v,
                builder: (field) => _field('Estação', DropdownButton<Station>(
                  value: _station, isExpanded: true, underline: const SizedBox(),
                  hint: const Text('Selecione uma estação', style: TextStyle(fontSize: 14, color: Color(0xFF6B6B7A))),
                  items: stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (v) { field.didChange(v); setState(() => _station = v); },
                ), hasError: field.errorText != null, errorText: field.errorText),
              ),
              const SizedBox(height: 16),

              // Problem type
              TestableFormField<IncidentType>(
                key: const Key('incident-type-selection-field'),
                getValue: () => _type as IncidentType,
                internalSetValue: (state, v) { _type = v; state.didChange(v); },
                validator: (v) => v == null ? 'Preencha o tipo de incidente' : null,
                onSaved: (v) => _type = v,
                builder: (field) => _field('Tipo de problema', DropdownButton<IncidentType>(
                  value: _type, isExpanded: true, underline: const SizedBox(),
                  hint: const Text('Selecione o tipo de problema', style: TextStyle(fontSize: 14, color: Color(0xFF6B6B7A))),
                  items: IncidentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                  onChanged: (v) { field.didChange(v); setState(() => _type = v); },
                ), hasError: field.errorText != null, errorText: field.errorText),
              ),
              const SizedBox(height: 16),

              // Severity — no container, custom layout
              TestableFormField<int>(
                key: const Key('incident-rating-field'),
                getValue: () => _severity as int,
                internalSetValue: (state, v) { _severity = v; state.didChange(v); },
                validator: (v) => v == null ? 'Preencha a avaliação' : null,
                onSaved: (v) => _severity = v,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('Gravidade', style: TextStyle(fontSize: 12, color: Color(0xFF6B6B7A))),
                      const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFC0392B))),
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
                                  color: selected ? color.withValues(alpha: 0.13) : const Color(0xFFF2F0EB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected ? color : (field.errorText != null ? const Color(0xFFC0392B) : const Color(0xFFD8D6CF)),
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(child: Text('$level',
                                  style: TextStyle(fontSize: 15,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                      color: selected ? color : const Color(0xFF6B6B7A)),
                                )),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('1 = menor', style: TextStyle(fontSize: 10, color: Color(0xFF6B6B7A))),
                      Text('5 = crítico', style: TextStyle(fontSize: 10, color: Color(0xFF6B6B7A))),
                    ]),
                    if (field.errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(field.errorText!, style: const TextStyle(fontSize: 11, color: Color(0xFFC0392B))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date and time
              TestableFormField<DateTime>(
                key: const Key('incident-datetime-field'),
                getValue: () => _dateTime,
                internalSetValue: (state, v) { _dateTime = v; state.didChange(v); },
                onSaved: (v) => _dateTime = v!,
                builder: (field) => _field('Data e hora', ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(_dateTime),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B6B7A)),
                  onTap: () => _pickDateTime(field.didChange),
                ), hasError: field.errorText != null, errorText: field.errorText),
              ),
              const SizedBox(height: 16),

              // Notes (optional)
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
                    hintStyle: TextStyle(fontSize: 14, color: Color(0xFF6B6B7A)),
                  ),
                  onChanged: (v) { field.didChange(v); _notes = v; },
                ), required: false),
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('incident-form-submit-button'),
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003087),
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