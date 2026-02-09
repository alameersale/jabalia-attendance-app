class Employee {
  final int id;
  final String name;
  final String? employeeNumber;
  final String? idNumber;
  final String? phone;
  final String? departmentName;
  bool isPresent;
  bool isEarly;
  String? checkInTime;

  Employee({
    required this.id,
    required this.name,
    this.employeeNumber,
    this.idNumber,
    this.phone,
    this.departmentName,
    this.isPresent = false,
    this.isEarly = false,
    this.checkInTime,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'] ?? '',
      employeeNumber: json['employee_number'],
      idNumber: json['id_number'],
      phone: json['phone'],
      departmentName: json['department']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employee_number': employeeNumber,
      'id_number': idNumber,
      'phone': phone,
      'department_name': departmentName,
    };
  }

  // للتخزين المحلي
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'employee_number': employeeNumber,
      'id_number': idNumber,
      'phone': phone,
      'department_name': departmentName,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      employeeNumber: map['employee_number'],
      idNumber: map['id_number'],
      phone: map['phone'],
      departmentName: map['department_name'],
    );
  }
}
