import 'package:equatable/equatable.dart';
import 'package:tubes/data/models/events_models.dart';

abstract class EventState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventLoaded extends EventState {
  final List<EventModel> events;

  EventLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class SingleEventLoaded extends EventState {
  final EventModel event;

  SingleEventLoaded(this.event);

  @override
  List<Object?> get props => [event];
}

class EventOperationSuccess extends EventState {}

class EventError extends EventState {
  final String message;

  EventError(this.message);

  @override
  List<Object?> get props => [message];
}