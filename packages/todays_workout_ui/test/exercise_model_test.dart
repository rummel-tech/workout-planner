import 'package:flutter_test/flutter_test.dart';
import 'package:todays_workout_ui/models/exercise_model.dart';

void main() {
  group('Exercise Model - Structured Fields', () {
    test('creates exercise with all fields', () {
      final exercise = Exercise(
        name: 'Bench Press',
        sets: 4,
        reps: 8,
        weight: 135.0,
        weightUnit: 'lbs',
        duration: 45,
        rest: 90,
        distance: 0,
        distanceUnit: 'miles',
        notes: 'Focus on form',
      );

      expect(exercise.name, 'Bench Press');
      expect(exercise.sets, 4);
      expect(exercise.reps, 8);
      expect(exercise.weight, 135.0);
      expect(exercise.weightUnit, 'lbs');
      expect(exercise.duration, 45);
      expect(exercise.rest, 90);
      expect(exercise.distance, 0);
      expect(exercise.distanceUnit, 'miles');
      expect(exercise.notes, 'Focus on form');
    });

    test('creates exercise with default values', () {
      final exercise = Exercise();

      expect(exercise.name, '');
      expect(exercise.sets, isNull);
      expect(exercise.reps, isNull);
      expect(exercise.weight, isNull);
      expect(exercise.weightUnit, 'lbs');
      expect(exercise.duration, isNull);
      expect(exercise.rest, isNull);
      expect(exercise.distance, isNull);
      expect(exercise.distanceUnit, 'miles');
      expect(exercise.notes, isNull);
    });

    test('supports sets field', () {
      final exercise = Exercise(name: 'Squats', sets: 5);
      expect(exercise.sets, 5);
    });

    test('supports reps field', () {
      final exercise = Exercise(name: 'Squats', reps: 10);
      expect(exercise.reps, 10);
    });

    test('supports weight field with unit', () {
      final exerciseLbs = Exercise(name: 'Deadlift', weight: 225, weightUnit: 'lbs');
      expect(exerciseLbs.weight, 225);
      expect(exerciseLbs.weightUnit, 'lbs');

      final exerciseKg = Exercise(name: 'Deadlift', weight: 100, weightUnit: 'kg');
      expect(exerciseKg.weight, 100);
      expect(exerciseKg.weightUnit, 'kg');
    });

    test('supports duration field in seconds', () {
      final exercise = Exercise(name: 'Plank', duration: 60);
      expect(exercise.duration, 60);
    });

    test('supports distance field with unit', () {
      final exerciseMiles = Exercise(name: '5K Run', distance: 3.1, distanceUnit: 'miles');
      expect(exerciseMiles.distance, 3.1);
      expect(exerciseMiles.distanceUnit, 'miles');

      final exerciseKm = Exercise(name: '5K Run', distance: 5.0, distanceUnit: 'km');
      expect(exerciseKm.distance, 5.0);
      expect(exerciseKm.distanceUnit, 'km');

      final exerciseMeters = Exercise(name: 'Sprint', distance: 400, distanceUnit: 'meters');
      expect(exerciseMeters.distance, 400);
      expect(exerciseMeters.distanceUnit, 'meters');
    });

    test('supports rest field in seconds', () {
      final exercise = Exercise(name: 'Bench Press', rest: 90);
      expect(exercise.rest, 90);
    });

    test('supports notes field', () {
      final exercise = Exercise(name: 'Pull-ups', notes: 'Use assisted machine if needed');
      expect(exercise.notes, 'Use assisted machine if needed');
    });
  });

  group('Exercise Model - JSON Serialization', () {
    test('toJson includes all non-null fields', () {
      final exercise = Exercise(
        name: 'Bench Press',
        sets: 4,
        reps: 8,
        weight: 135.0,
        weightUnit: 'lbs',
        rest: 90,
        notes: 'Warm up first',
      );

      final json = exercise.toJson();

      expect(json['name'], 'Bench Press');
      expect(json['sets'], 4);
      expect(json['reps'], 8);
      expect(json['weight'], 135.0);
      expect(json['weightUnit'], 'lbs');
      expect(json['rest'], 90);
      expect(json['notes'], 'Warm up first');
    });

    test('toJson excludes null fields', () {
      final exercise = Exercise(name: 'Plank', duration: 60);

      final json = exercise.toJson();

      expect(json['name'], 'Plank');
      expect(json['duration'], 60);
      expect(json.containsKey('sets'), false);
      expect(json.containsKey('reps'), false);
      expect(json.containsKey('weight'), false);
      expect(json.containsKey('rest'), false);
      expect(json.containsKey('notes'), false);
    });

    test('fromJson creates exercise from map', () {
      final json = {
        'name': 'Deadlift',
        'sets': 3,
        'reps': 5,
        'weight': 315.0,
        'weightUnit': 'lbs',
        'rest': 120,
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.name, 'Deadlift');
      expect(exercise.sets, 3);
      expect(exercise.reps, 5);
      expect(exercise.weight, 315.0);
      expect(exercise.weightUnit, 'lbs');
      expect(exercise.rest, 120);
    });

    test('fromJson handles missing fields gracefully', () {
      final json = {'name': 'Stretch'};

      final exercise = Exercise.fromJson(json);

      expect(exercise.name, 'Stretch');
      expect(exercise.sets, isNull);
      expect(exercise.reps, isNull);
      expect(exercise.weight, isNull);
      expect(exercise.weightUnit, 'lbs'); // default
      expect(exercise.distanceUnit, 'miles'); // default
    });

    test('round-trip serialization preserves data', () {
      final original = Exercise(
        name: 'Complex Exercise',
        sets: 4,
        reps: 12,
        weight: 50.5,
        weightUnit: 'kg',
        duration: 30,
        rest: 60,
        distance: 0.5,
        distanceUnit: 'km',
        notes: 'Test notes',
      );

      final json = original.toJson();
      final restored = Exercise.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.sets, original.sets);
      expect(restored.reps, original.reps);
      expect(restored.weight, original.weight);
      expect(restored.weightUnit, original.weightUnit);
      expect(restored.duration, original.duration);
      expect(restored.rest, original.rest);
      expect(restored.distance, original.distance);
      expect(restored.distanceUnit, original.distanceUnit);
      expect(restored.notes, original.notes);
    });
  });

  group('Exercise Model - Summary Display', () {
    test('summary shows sets x reps format', () {
      final exercise = Exercise(name: 'Squats', sets: 4, reps: 10);
      expect(exercise.summary, contains('4 x 10'));
    });

    test('summary shows weight', () {
      final exercise = Exercise(name: 'Bench', sets: 3, reps: 8, weight: 135, weightUnit: 'lbs');
      expect(exercise.summary, contains('135'));
      expect(exercise.summary, contains('lbs'));
    });

    test('summary shows duration', () {
      final exercise = Exercise(name: 'Plank', duration: 60);
      expect(exercise.summary, contains('1m'));
    });

    test('summary shows distance', () {
      final exercise = Exercise(name: 'Run', distance: 5, distanceUnit: 'km');
      expect(exercise.summary, contains('5'));
      expect(exercise.summary, contains('km'));
    });

    test('summary shows rest time', () {
      final exercise = Exercise(name: 'Sets', sets: 3, rest: 90);
      expect(exercise.summary, contains('rest'));
    });
  });

  group('Exercise Model - Copy With', () {
    test('copyWith creates modified copy', () {
      final original = Exercise(name: 'Press', sets: 3, reps: 10);
      final modified = original.copyWith(sets: 4, reps: 12);

      expect(original.sets, 3);
      expect(original.reps, 10);
      expect(modified.sets, 4);
      expect(modified.reps, 12);
      expect(modified.name, 'Press'); // unchanged
    });
  });
}
