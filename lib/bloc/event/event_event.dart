import 'package:equatable/equatable.dart';
import 'package:tubes/data/models/events_models.dart';

abstract class EventEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEventsByOwner extends EventEvent {
  final String ownerId;

  LoadEventsByOwner(this.ownerId);

  @override
  List<Object?> get props => [ownerId];
}

class LoadEventById extends EventEvent {
  final String id;

  LoadEventById(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateEvent extends EventEvent {
  final EventModel event;

  CreateEvent(this.event);

  @override
  List<Object?> get props => [event];
}

class UpdateEvent extends EventEvent {
  final String id;
  final EventModel event;

  UpdateEvent(this.id, this.event);

  @override
  List<Object?> get props => [id, event];
}

class JoinEvent extends EventEvent {
  final String eventId;
  final String userId;

  JoinEvent(this.eventId, this.userId);

  @override
  List<Object> get props => [eventId, userId];
}

class DeleteEvent extends EventEvent {
  final String id;

  DeleteEvent(this.id);

  @override
  List<Object?> get props => [id];
}