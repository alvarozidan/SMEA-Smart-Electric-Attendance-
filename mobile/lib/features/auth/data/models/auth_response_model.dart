class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json){
    final accessToken = json['accessToken'] as String?;
    final refreshToken = json['refreshToken'] as String?;

    if (accessToken == null || refreshToken == null){
      throw const FormatException(
        'Response login tidak sesuai kontrak: accesstoken/refreshToken hilang',
      );
    }

    return AuthResponseModel(
      accessToken: accessToken, 
      refreshToken: refreshToken
      );
  }

  final String accessToken;
  final String refreshToken;
}