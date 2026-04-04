import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import 'employer_event.dart';
import 'employer_state.dart';

class EmployerBloc extends Bloc<EmployerEvent, EmployerState> {
  EmployerBloc() : super(EmployerInitial()) {
    on<EmployerLoadRequested>(_onLoad);
  }

  void _onLoad(EmployerLoadRequested event, Emitter<EmployerState> emit) {
    emit(EmployerLoading());
    emit(EmployerLoaded(
      employees: mockEmployees,
      history: mockVerificationHistory,
    ));
  }
}
