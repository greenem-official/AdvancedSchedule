import 'dart:ffi';
import 'dart:ui';

import 'package:flutter7/data/blacklist/categories.dart';
import 'package:flutter7/models/lesson.dart';

const List<FieldDef> fieldDefs = [
  FieldDef(
    id: 'discipline',
    uniquePath: 'disciplineOid',
    displayPath: 'discipline',
    title: 'Дисциплина',
  ),
  FieldDef(
    id: 'group',
    uniquePath: 'groupGUID',
    displayPath: 'group',
    title: 'Группа',
  ),
  FieldDef(
    id: 'lecturer',
    uniquePath: 'lecturerCustomUID',
    displayPath: 'lecturer',
    title: 'Лектор',
  ),
  FieldDef(
    id: 'stream',
    uniquePath: 'streamOid',
    displayPath: 'stream',
    title: 'Поток',
  ),
  FieldDef(
    id: 'building',
    uniquePath: 'buildingGid',
    displayPath: 'building',
    title: 'Адрес',
  ),
  FieldDef(
    id: 'auditorium',
    uniquePath: 'auditoriumGUID',
    displayPath: 'auditorium',
    title: 'Аудитория',
  ),
  FieldDef(
    id: 'dayOfWeek',
    uniquePath: 'dayOfWeek',
    displayPath: 'dayOfWeekString',
    title: 'День недели',
  ),
  FieldDef(
    id: 'lessonType',
    uniquePath: 'kindOfWorkOid',
    displayPath: 'kindOfWork',
    title: 'Тип занятия',
  ),
];

final Map<String, FieldDef> fieldMap = {
  for (final f in fieldDefs) f.id: f,
};

const List<LessonType> lessonTypes = [
  LessonType(
    internalName: "lecture",
    displayName: "Лекция",
    typeOid: 132,
    color: Color(0xFF65D06A), // мягкий зелёный
  ),
  LessonType(
    internalName: "seminar",
    displayName: "Семинар",
    typeOid: 143,
    color: Color(0xFFE8C641), // мягкий жёлтый
  ),
  LessonType(
    internalName: "exam",
    displayName: "Экзамен",
    typeOid: 154,
    color: Color(0xFFBA68C8), // мягкий фиолетовый
  ),
  LessonType(
    internalName: "re-exam",
    displayName: "Повторный экзамен",
    typeOid: 159,
    color: Color(0xFFFFA726), // мягкий оранжевый
  ),
  LessonType(
    internalName: "test",
    displayName: "Зачёт",
    typeOid: 160,
    color: Color(0xFFF48FB1), // мягкий розовый
  ),
  LessonType(
    internalName: "re-test",
    displayName: "Повторный зачёт",
    typeOid: 158,
    color: Color(0xFFFFA726), // такой же мягкий оранжевый
  ),
];

final Map<int, LessonType> lessonTypeMapById = {
  for (final l in lessonTypes) l.typeOid: l,
};
