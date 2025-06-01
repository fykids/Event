import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tubes/bloc/event/event_event.dart';
import 'package:tubes/bloc/event/event_state.dart';
import 'package:tubes/data/repositories/event_repository.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository repository;

  EventBloc({required this.repository}) : super(EventInitial()) {
    on<LoadEventsByOwner>(_onLoadEventsByOwner);
    on<LoadEventById>(_onLoadEventById);
    on<CreateEvent>(_onCreateEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<JoinEvent>(_onJoinEvent);
    on<DeleteEvent>(_onDeleteEvent);
  }

  Future<void> _onJoinEvent(JoinEvent event, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      await repository.joinEvent(event.eventId, event.userId);
      emit(EventOperationSuccess());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onLoadEventsByOwner(
    LoadEventsByOwner event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      final events = await repository.getEventsByOwner(event.ownerId);
      emit(EventLoaded(events));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onLoadEventById(
    LoadEventById event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      final loaded = await repository.getEventById(event.id);
      if (loaded != null) {
        emit(SingleEventLoaded(loaded));
      } else {
        emit(EventError('Event tidak ditemukan'));
      }
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onCreateEvent(
    CreateEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      await repository.createEvent(event.event);
      emit(EventOperationSuccess());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      await repository.updateEvent(event.id, event.event);
      emit(EventOperationSuccess());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      await repository.deleteEvent(event.id);
      emit(EventOperationSuccess());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }
}
