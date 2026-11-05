class ApiConfig {
  // La app siempre habla con la API; nunca lleva credenciales de TiDB.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://activity-api-git-main-issasegovia0710s-projects.vercel.app/api',
  );
}
