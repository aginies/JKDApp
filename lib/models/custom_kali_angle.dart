import 'kali_angle_elements.dart';

class CustomKaliAngle {
  final int id;
  final String name;
  final List<DrawingElement> elements;

  CustomKaliAngle({
    required this.id,
    required this.name,
    required this.elements,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  factory CustomKaliAngle.fromJson(Map<String, dynamic> json) {
    return CustomKaliAngle(
      id: json['id'] as int,
      name: json['name'] as String,
      elements: (json['elements'] as List)
          .map((e) => DrawingElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
