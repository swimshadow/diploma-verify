import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import 'employer_event.dart';
import 'employer_state.dart';

class EmployerBloc extends Bloc<EmployerEvent, EmployerState> {
  EmployerBloc() : super(EmployerInitial()) {
    on<EmployerLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      EmployerLoadRequested event, Emitter<EmployerState> emit) async {
    emit(EmployerLoading());
    // Employer-specific list endpoints not yet implemented in backend;
    // use local mock data with graceful fallback.
    emit(EmployerLoaded(
      employees: mockEmployees,
      history: mockVerificationHistory,
    ));
  }
}
