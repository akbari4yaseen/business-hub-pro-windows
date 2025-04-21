/// A data class representing company information.
class CompanyInfo {
  final String? name;
  final String? whatsApp;
  final String? phone;
  final String? email;
  final String? address;
  final String? logo;

  CompanyInfo({
    this.name,
    this.whatsApp,
    this.phone,
    this.email,
    this.address,
    this.logo,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      name: map['name'] as String?,
      whatsApp: map['whats_app'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      logo: map['logo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'whats_app': whatsApp,
      'phone': phone,
      'email': email,
      'address': address,
      'logo': logo,
    };
  }

  CompanyInfo copyWith({
    String? name,
    String? whatsApp,
    String? phone,
    String? email,
    String? address,
    String? logo,
  }) {
    return CompanyInfo(
      name: name ?? this.name,
      whatsApp: whatsApp ?? this.whatsApp,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      logo: logo ?? this.logo,
    );
  }
}
